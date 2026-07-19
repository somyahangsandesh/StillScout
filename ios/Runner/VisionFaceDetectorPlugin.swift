import Flutter
import UIKit
import Vision
import Accelerate
import AVFoundation

/// Flutter method-channel plugin — Apple Vision frame-quality analyser.
///
/// Channel: com.stillscout/vision_face_detector
/// Method:  analyzeFrame(filePath: String)
///
/// Returned payload (all Doubles):
///   eyeScore            0–1   Composite face+eye quality (see formula below)
///   faceCaptureQuality  0–1   Apple neural face-quality; -1 = no face
///   nativeBlurScore     0–1   Full-image Laplacian sharpness
///   faceSharpnessScore  0–1   Face-crop Laplacian sharpness;  -1 = no face
///   saliencyScore       0–1   Attention-saliency concentration score
///   faceAreaNorm        0–1   Normalised face bbox area (w×h);  0 = no face
///   aestheticsScore     -1    Forward-compat placeholder
///   yaw                 rad   Head turn (±); 0 = no face
///   roll                rad   Head tilt (±); 0 = no face
///   left/top/right/bottom     UIKit-origin face bbox; absent = no face
///
/// eyeScore formula (per face, best face wins):
///   raw  = fcq×0.48 + earSigmoid×0.30 + faceSharpness×0.14 + framingBonus×0.08
///   final = raw × posePenalty × blinkPenalty × confidenceFactor
///
/// The legacy "detectFace" method is aliased to "analyzeFrame".
@objc class VisionFaceDetectorPlugin: NSObject, FlutterPlugin {

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.stillscout/vision_face_detector",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(VisionFaceDetectorPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "analyzeAudioPeaks" {
      guard let args = call.arguments as? [String: Any],
            let videoPath = args["videoPath"] as? String
      else {
        result(FlutterError(code: "INVALID_ARGS", message: "videoPath is required", details: nil))
        return
      }
      DispatchQueue.global(qos: .utility).async {
        self.analyzeAudioPeaks(videoPath: videoPath) { peaks in
          DispatchQueue.main.async { result(peaks) }
        }
      }
      return
    }

    guard call.method == "analyzeFrame" || call.method == "detectFace" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard let args = call.arguments as? [String: Any],
          let filePath = args["filePath"] as? String
    else {
      result(FlutterError(code: "INVALID_ARGS", message: "filePath is required", details: nil))
      return
    }
    DispatchQueue.global(qos: .userInitiated).async {
      self.analyzeFrame(at: filePath) { payload in
        DispatchQueue.main.async { result(payload) }
      }
    }
  }

  // MARK: – Main pipeline ────────────────────────────────────────────────────

  private func analyzeFrame(
    at filePath: String,
    completion: @escaping ([String: Any]?) -> Void
  ) {
    guard let cgImage = loadCGImage(at: filePath) else {
      completion(nil)
      return
    }

    // ── 1. Full-image sharpness (Laplacian on luma, 200 px wide) ────────────
    let globalBlur = laplacianSharpness(cgImage)

    // ── 2. Attention saliency (iOS 13+, safe at our 15.5 minimum) ───────────
    let saliency = attentionSaliencyScore(cgImage)

    // ── 3. Face landmarks + faceCaptureQuality ───────────────────────────────
    let request = VNDetectFaceLandmarksRequest()
    request.revision = VNDetectFaceLandmarksRequestRevision3
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

    do {
      try handler.perform([request])
    } catch {
      completion([
        "nativeBlurScore":    globalBlur,
        "faceSharpnessScore": -1.0,
        "saliencyScore":      saliency,
        "faceAreaNorm":       0.0,
        "ruleOfThirdsScore":  0.5,
        "aestheticsScore":    -1.0,
        "faceCaptureQuality": -1.0,
        "eyeScore":           0.68,
        "yaw":                0.0,
        "roll":               0.0,
      ])
      return
    }

    guard let observations = request.results, !observations.isEmpty else {
      completion([
        "nativeBlurScore":    globalBlur,
        "faceSharpnessScore": -1.0,
        "saliencyScore":      saliency,
        "faceAreaNorm":       0.0,
        "ruleOfThirdsScore":  0.5,
        "aestheticsScore":    -1.0,
        "faceCaptureQuality": -1.0,
        "eyeScore":           0.68,
        "yaw":                0.0,
        "roll":               0.0,
      ])
      return
    }

    // ── 4. Pick the best-quality face (not just the largest) ────────────────
    //
    // Each face is scored by a fast heuristic so the BEST face
    // (e.g. the one with open eyes) wins even if it is smaller.
    var bestScore = -1.0
    var bestFace  = observations[0]

    for face in observations {
      let quick = quickFaceScore(face, cgImage: cgImage)
      if quick > bestScore {
        bestScore = quick
        bestFace  = face
      }
    }

    let face = bestFace

    // ── 5. Face bounds → UIKit coords ────────────────────────────────────────
    let vbb      = face.boundingBox
    let uiLeft   = Double(vbb.minX)
    let uiTop    = Double(1.0 - vbb.maxY)
    let uiRight  = Double(vbb.maxX)
    let uiBottom = Double(1.0 - vbb.minY)
    let faceArea = Double(vbb.width * vbb.height)

    // ── 6. Face-region sharpness (measures sharpness where it matters) ───────
    let faceSharpness = faceCropSharpness(cgImage, bbox: vbb)

    // ── 7. faceCaptureQuality (Apple's neural face-quality score) ────────────
    //    Available iOS 15+; use earScore as fallback (see step 8).
    let earScoreRaw = computeEARScore(from: face.landmarks)
    let fcqRaw = face.faceCaptureQuality.map { Double($0) }
    let fcq = fcqRaw ?? earScoreRaw   // If Apple's model has no result, trust EAR

    // ── 8. Per-eye EAR + asymmetric-blink penalty ────────────────────────────
    let (leftEAR, rightEAR) = perEyeEAR(from: face.landmarks)
    let blinkPenalty = asymmetricBlinkPenalty(leftEAR, rightEAR)

    // ── 9. Head pose penalty ──────────────────────────────────────────────────
    let yaw:  Double = face.yaw.map  { Double(truncating: $0) } ?? 0.0
    let roll: Double = face.roll.map { Double(truncating: $0) } ?? 0.0

    let yawPenalty  = headPosePenalty(abs(yaw),  gentleLimit: 0.35, hardLimit: 0.65)
    let rollPenalty = headPosePenalty(abs(roll), gentleLimit: 0.26, hardLimit: 0.52)
    let posePenaltyMultiplier = (1.0 - yawPenalty) * (1.0 - rollPenalty)

    // ── 10. Face confidence factor ────────────────────────────────────────────
    //    VNFaceObservation.confidence: 0–1. Low-confidence detections are
    //    noisy (partial faces, artefacts) — soft-penalise rather than discard.
    let conf = Double(face.confidence)
    let confidenceFactor = 0.6 + 0.4 * smoothstep(conf, lo: 0.55, hi: 0.90)

    // ── 11. Face framing bonus ────────────────────────────────────────────────
    //    Reward faces that sit naturally within the frame (not clipped).
    let framingBonus = faceFramingBonus(vbb)

    // ── 12. Rule-of-thirds / golden-ratio composition score ──────────────────
    //    Measures how close the face centroid sits to the four power points
    //    (⅓/⅔ grid intersections). High score = subject is well-composed.
    let faceCentroid = CGPoint(x: vbb.midX, y: 1.0 - vbb.midY)  // Vision→UIKit y-flip
    let rotScore = ruleOfThirdsScore(centroid: faceCentroid)

    // ── 13. Composite eye/face score ─────────────────────────────────────────
    //    Weights: fcq 48% | EAR (sigmoid) 30% | face sharpness 14% | framing 8%
    //    Then apply pose penalty, blink penalty, and confidence factor.
    let earSig   = earSigmoid(earScoreRaw)
    let raw      = fcq * 0.48 + earSig * 0.30 + faceSharpness * 0.14 + framingBonus * 0.08
    let eyeScore = (raw * posePenaltyMultiplier * (1.0 - blinkPenalty) * confidenceFactor)
                   .clamped(to: 0.0...1.0)

    let payload: [String: Any] = [
      "eyeScore":              eyeScore,
      "faceCaptureQuality":    fcqRaw ?? -1.0,
      "nativeBlurScore":       globalBlur,
      "faceSharpnessScore":    faceSharpness,
      "saliencyScore":         saliency,
      "faceAreaNorm":          faceArea.clamped(to: 0.0...1.0),
      "ruleOfThirdsScore":     rotScore,
      "aestheticsScore":       -1.0,
      "yaw":                   yaw,
      "roll":                  roll,
      "left":                  uiLeft,
      "top":                   uiTop,
      "right":                 uiRight,
      "bottom":                uiBottom,
    ]
    completion(payload)
  }

  // MARK: – Quick face quality heuristic (for multi-face selection) ──────────

  /// Lightweight score used to pick the best face when multiple are detected.
  /// Avoids the expensive face-crop Laplacian — only uses FCQ + EAR + area.
  private func quickFaceScore(_ face: VNFaceObservation, cgImage: CGImage) -> Double {
    let ear  = computeEARScore(from: face.landmarks)
    let fcq  = face.faceCaptureQuality.map { Double($0) } ?? ear
    let area = Double(face.boundingBox.width * face.boundingBox.height)
    let conf = Double(face.confidence)
    let yaw  = face.yaw.map  { abs(Double(truncating: $0)) } ?? 0.0
    let roll = face.roll.map { abs(Double(truncating: $0)) } ?? 0.0
    let posePenalty = headPosePenalty(yaw, gentleLimit: 0.35, hardLimit: 0.65)
                    + headPosePenalty(roll, gentleLimit: 0.26, hardLimit: 0.52)
    // Small area bonus so larger faces break ties, but eye quality can still win.
    let areaBonus = min(area * 0.3, 0.12)
    return (fcq * 0.55 + ear * 0.35 + areaBonus) * (1.0 - posePenalty * 0.5) * conf
  }

  // MARK: – Face-region Laplacian sharpness ─────────────────────────────────

  /// Measures sharpness inside the face bounding box with 20% padding.
  /// Returns the full-image score (already computed) as fallback.
  private func faceCropSharpness(_ cgImage: CGImage, bbox vbb: CGRect) -> Double {
    let iw = CGFloat(cgImage.width)
    let ih = CGFloat(cgImage.height)
    // Vision bbox: origin bottom-left. CGImage crop: origin top-left.
    let padX = vbb.width  * iw * 0.20
    let padY = vbb.height * ih * 0.20
    let cropX = max(0, vbb.minX * iw - padX)
    let cropY = max(0, (1.0 - vbb.maxY) * ih - padY)
    let cropW = min(iw - cropX, vbb.width  * iw + 2 * padX)
    let cropH = min(ih - cropY, vbb.height * ih + 2 * padY)

    guard cropW >= 20, cropH >= 20,
          let cropped = cgImage.cropping(
            to: CGRect(x: cropX, y: cropY, width: cropW, height: cropH)
          )
    else { return 0.5 }

    return laplacianSharpness(cropped)
  }

  // MARK: – Attention saliency ──────────────────────────────────────────────

  /// Returns 0–1 saliency score.
  ///   – High score: one or two dominant, high-confidence salient objects (good
  ///     subject isolation / clear composition).
  ///   – Low score:  many competing salient regions (cluttered / chaotic frame).
  ///   – 0.5 neutral when the request fails.
  private func attentionSaliencyScore(_ cgImage: CGImage) -> Double {
    let saliencyRequest = VNGenerateAttentionBasedSaliencyImageRequest()
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    do {
      try handler.perform([saliencyRequest])
    } catch {
      return 0.5
    }
    guard let obs = saliencyRequest.results?.first as? VNSaliencyImageObservation,
          let objects = obs.salientObjects, !objects.isEmpty
    else { return 0.5 }

    let maxConf = objects.map { Double($0.confidence) }.max() ?? 0.5
    // Penalise clutter: each extra salient region above 2 reduces score slightly.
    let count = objects.count
    let clutterPenalty = max(0.0, Double(count - 2) * 0.06)
    return (maxConf - clutterPenalty).clamped(to: 0.20...1.0)
  }

  // MARK: – Full-image Laplacian sharpness ──────────────────────────────────

  /// 0–1 sharpness via Laplacian variance on the luma channel.
  /// Calibrated: sharp iPhone photo ≈ 0.85+, heavy blur < 0.35.
  private func laplacianSharpness(_ cgImage: CGImage) -> Double {
    let targetWidth  = 200
    let scale        = Double(targetWidth) / Double(cgImage.width)
    let targetHeight = max(1, Int(Double(cgImage.height) * scale))

    var format = vImage_CGImageFormat(
      bitsPerComponent: 8,
      bitsPerPixel: 8,
      colorSpace: Unmanaged.passRetained(CGColorSpaceCreateDeviceGray()),
      bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
      version: 0,
      decode: nil,
      renderingIntent: .defaultIntent
    )

    var src = vImage_Buffer(); var dst = vImage_Buffer()
    defer { format.colorSpace?.release(); free(src.data); free(dst.data) }

    guard vImageBuffer_InitWithCGImage(&src, &format, nil, cgImage,
            vImage_Flags(kvImageNoFlags)) == kvImageNoError,
          vImageBuffer_Init(&dst, vImagePixelCount(targetHeight),
            vImagePixelCount(targetWidth), 8,
            vImage_Flags(kvImageNoFlags)) == kvImageNoError,
          vImageScale_Planar8(&src, &dst, nil,
            vImage_Flags(kvImageHighQualityResampling)) == kvImageNoError
    else { return 0.5 }

    var kern: [Int16] = [0, 1, 0, 1, -4, 1, 0, 1, 0]
    var lap = vImage_Buffer()
    guard vImageBuffer_Init(&lap, dst.height, dst.width, 8,
            vImage_Flags(kvImageNoFlags)) == kvImageNoError
    else { return 0.5 }
    defer { free(lap.data) }

    guard vImageConvolve_Planar8(&dst, &lap, nil, 0, 0,
            &kern, 3, 3, 1, 0 as Pixel_8,
            vImage_Flags(kvImageEdgeExtend)) == kvImageNoError
    else { return 0.5 }

    let n = Int(lap.width * lap.height)
    guard n > 0, let data = lap.data else { return 0.5 }
    let ptr = data.assumingMemoryBound(to: UInt8.self)

    var mean = 0.0
    for i in 0..<n { mean += Double(ptr[i]) }
    mean /= Double(n)

    var variance = 0.0
    for i in 0..<n { let d = Double(ptr[i]) - mean; variance += d * d }
    variance /= Double(n)

    // Calibration: variance ~900 → sharp; ~80 → blurry.
    // Gamma-lift so mid-range values are well spread.
    return pow(min(variance / 900.0, 1.0), 0.42)
  }

  // MARK: – Eye Aspect Ratio ─────────────────────────────────────────────────

  /// Combined EAR: average of both eyes (or whichever is available).
  private func computeEARScore(from landmarks: VNFaceLandmarks2D?) -> Double {
    guard let lm = landmarks else { return 0.68 }
    let (l, r) = perEyeEAR(from: lm)
    switch (l, r) {
    case let (lv?, rv?): return earSigmoid((lv + rv) / 2.0)
    case let (lv?, nil): return earSigmoid(lv)
    case let (nil, rv?): return earSigmoid(rv)
    default:             return 0.68
    }
  }

  /// Returns raw (unscaled) per-eye EAR values for blink asymmetry detection.
  private func perEyeEAR(from landmarks: VNFaceLandmarks2D?) -> (Double?, Double?) {
    guard let lm = landmarks else { return (nil, nil) }
    return (rawEAR(lm.leftEye), rawEAR(lm.rightEye))
  }

  /// Standard EAR: mean vertical diameter ÷ horizontal width.
  private func rawEAR(_ eye: VNFaceLandmarkRegion2D?) -> Double? {
    guard let eye = eye else { return nil }
    let pts = eye.normalizedPoints
    guard pts.count >= 6 else { return nil }
    let n = pts.count
    let p0   = pts[0]
    let pMid = pts[n / 2]
    let horizontal = hypot(Double(pMid.x - p0.x), Double(pMid.y - p0.y))
    guard horizontal > 1e-6 else { return nil }
    let pairs = max(1, n / 2 - 1)
    var vertSum = 0.0
    for i in 1...pairs {
      let t = pts[i]; let b = pts[n - i]
      vertSum += hypot(Double(b.x - t.x), Double(b.y - t.y))
    }
    return vertSum / (Double(pairs) * horizontal)
  }

  /// Smooth sigmoid EAR mapping:
  ///   EAR 0.00 → 0.00  (eye shut)
  ///   EAR 0.14 → 0.50  (half-open / squint)
  ///   EAR 0.26 → 0.88  (normal open)
  ///   EAR 0.36 → 0.97  (wide open)
  ///   EAR 0.42 → 0.98  (no extra credit for extra-wide)
  private func earSigmoid(_ raw: Double) -> Double {
    // Logistic: 1/(1+exp(-k*(x-x0))); k=14, x0=0.22
    let k = 14.0; let x0 = 0.22
    return 1.0 / (1.0 + exp(-k * (raw - x0)))
  }

  // MARK: – Asymmetric blink penalty ────────────────────────────────────────

  /// A partial blink (one eye much more closed than the other) looks unnatural.
  /// Returns a penalty 0–0.65 that is applied to the eye score.
  private func asymmetricBlinkPenalty(_ leftEAR: Double?, _ rightEAR: Double?) -> Double {
    guard let l = leftEAR, let r = rightEAR else { return 0.0 }
    let asymmetry = abs(l - r)
    // Smooth ramp: 0 below 0.09, full penalty at 0.30
    return smoothstep(asymmetry, lo: 0.09, hi: 0.30) * 0.65
  }

  // MARK: – Head pose penalty ───────────────────────────────────────────────

  /// Quadratic ramp: 0 below [gentleLimit], 1 at [hardLimit].
  private func headPosePenalty(_ absAngle: Double, gentleLimit: Double, hardLimit: Double) -> Double {
    guard absAngle > gentleLimit else { return 0.0 }
    let t = min((absAngle - gentleLimit) / (hardLimit - gentleLimit), 1.0)
    return t * t
  }

  // MARK: – Face framing bonus ──────────────────────────────────────────────

  /// Returns 0–1 bonus for a well-framed, non-clipped face.
  ///   – Face fully inside frame and not too small → full bonus
  ///   – Clipped edges, very small, or very large → reduced bonus
  private func faceFramingBonus(_ vbb: CGRect) -> Double {
    // Penalise faces that bleed off the frame edges.
    let clipPenalty = max(0.0,
      (-vbb.minX) +
      (-vbb.minY) +
      (vbb.maxX - 1.0) +
      (vbb.maxY - 1.0)
    ) * 4.0   // edge overshoot (normalised) scaled to 0–1 range

    // Reward moderate face size: 8–45% of frame area is ideal.
    let area = Double(vbb.width * vbb.height)
    let sizePenalty: Double
    if area < 0.015 {
      sizePenalty = 0.5   // too small / probably noise
    } else if area > 0.70 {
      sizePenalty = 0.2   // face fills most of frame — tightly cropped
    } else {
      sizePenalty = 0.0
    }

    return (1.0 - clipPenalty.clamped(to: 0.0...1.0) - sizePenalty).clamped(to: 0.0...1.0)
  }

  // MARK: – Rule-of-thirds composition score ───────────────────────────────

  /// Returns 0–1 scoring how close a point sits to the four ⅓-grid power
  /// points: (⅓,⅓), (⅓,⅔), (⅔,⅓), (⅔,⅔).
  ///
  ///   1.0  = centroid exactly on a power point (perfect composition)
  ///   0.75 = centroid on the horizontal or vertical ⅓ lines
  ///   0.5  = centroid in the centre (acceptable but not ideal)
  ///   0.0  = centroid in a corner
  ///
  /// Coordinates are in UIKit normalised space (origin top-left, 0–1).
  private func ruleOfThirdsScore(centroid: CGPoint) -> Double {
    let cx = Double(centroid.x)
    let cy = Double(centroid.y)

    // Distance to the nearest power point (normalised Euclidean).
    let powerPoints: [(Double, Double)] = [
      (1.0/3.0, 1.0/3.0), (1.0/3.0, 2.0/3.0),
      (2.0/3.0, 1.0/3.0), (2.0/3.0, 2.0/3.0),
    ]
    let minDist = powerPoints
      .map { hypot(cx - $0.0, cy - $0.1) }
      .min() ?? 1.0

    // Maximum possible distance from a power point in the unit square ≈ 0.47.
    let maxDist = 0.47
    // Smooth falloff: at exactly 0 → 1.0; at maxDist → 0.0.
    let proximity = 1.0 - (minDist / maxDist).clamped(to: 0.0...1.0)
    // Gamma-lift so mid-range compositions are rewarded rather than penalised.
    return pow(proximity, 0.55)
  }

  // MARK: – Audio peak analysis ─────────────────────────────────────────────

  /// Decodes the audio track of a video file and returns timestamps (ms) where
  /// RMS energy exceeds mean + 1.5 × stddev — useful for identifying shots
  /// that coincide with music beats or speech peaks.
  ///
  /// Returns an array of dictionaries with keys:
  ///   "timestampMs"  Int    — centre of the 500 ms analysis window
  ///   "energy"       Double — normalised energy 0–1
  private func analyzeAudioPeaks(videoPath: String, completion: @escaping ([[String: Any]]) -> Void) {
    let url = URL(fileURLWithPath: videoPath)
    let asset = AVURLAsset(url: url)

    guard let audioTrack = asset.tracks(withMediaType: .audio).first else {
      completion([])
      return
    }

    let outputSettings: [String: Any] = [
      AVFormatIDKey:              kAudioFormatLinearPCM,
      AVLinearPCMBitDepthKey:     16,
      AVLinearPCMIsFloatKey:      false,
      AVLinearPCMIsBigEndianKey:  false,
      AVLinearPCMIsNonInterleaved: false,
    ]

    guard let reader = try? AVAssetReader(asset: asset) else {
      completion([])
      return
    }

    let output = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: outputSettings)
    guard reader.canAdd(output) else { completion([]); return }
    reader.add(output)
    guard reader.startReading() else { completion([]); return }

    // Analyse in 500 ms windows at 44.1 kHz stereo → ~44100 samples/window.
    let windowSize = 44100
    var windowSamples: [Float] = []
    windowSamples.reserveCapacity(windowSize * 2)
    var allEnergies: [Double] = []
    var windowTimestamps: [Int] = []
    var currentTimeMs = 250  // Centre of first window

    while let sampleBuffer = output.copyNextSampleBuffer() {
      guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { continue }
      let length = CMBlockBufferGetDataLength(blockBuffer)
      guard length > 0 else { continue }
      var dataBytes = [UInt8](repeating: 0, count: length)
      CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: length, destination: &dataBytes)
      let int16Count = length / 2
      dataBytes.withUnsafeBytes { rawPtr in
        let int16Ptr = rawPtr.bindMemory(to: Int16.self)
        for i in 0..<int16Count {
          windowSamples.append(Float(int16Ptr[i]) / 32768.0)
          if windowSamples.count >= windowSize {
            let rms = sqrt(windowSamples.reduce(0) { $0 + $1 * $1 } / Float(windowSize))
            allEnergies.append(Double(rms))
            windowTimestamps.append(currentTimeMs)
            currentTimeMs += 500
            windowSamples.removeAll(keepingCapacity: true)
          }
        }
      }
    }

    guard !allEnergies.isEmpty else { completion([]); return }

    let mean   = allEnergies.reduce(0, +) / Double(allEnergies.count)
    let variance = allEnergies.map { ($0 - mean) * ($0 - mean) }.reduce(0, +)
                  / Double(allEnergies.count)
    let stddev  = sqrt(variance)
    let threshold = mean + 1.5 * stddev
    let normMax   = mean + 3.0 * stddev  // reference ceiling for normalisation

    var peaks: [[String: Any]] = []
    for (i, energy) in allEnergies.enumerated() where energy > threshold {
      peaks.append([
        "timestampMs": windowTimestamps[i],
        "energy":      (energy / max(normMax, 1e-9)).clamped(to: 0.0...1.0),
      ])
    }
    completion(peaks)
  }

  // MARK: – Helpers ─────────────────────────────────────────────────────────

  /// Smooth Hermite interpolation between [lo] and [hi] (maps to 0–1).
  private func smoothstep(_ x: Double, lo: Double, hi: Double) -> Double {
    let t = ((x - lo) / (hi - lo)).clamped(to: 0.0...1.0)
    return t * t * (3.0 - 2.0 * t)
  }

  private func loadCGImage(at filePath: String) -> CGImage? {
    guard let uiImage = UIImage(contentsOfFile: filePath) else { return nil }
    return uiImage.cgImage ?? uiImage.ciImage.flatMap { ci in
      CIContext().createCGImage(ci, from: ci.extent)
    }
  }
}

// MARK: – Comparable extension ────────────────────────────────────────────────

extension Comparable {
  fileprivate func clamped(to range: ClosedRange<Self>) -> Self {
    return min(max(self, range.lowerBound), range.upperBound)
  }
}
