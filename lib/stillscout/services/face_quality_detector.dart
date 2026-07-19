import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

/// Abstract interface for eye-open / expression quality detection.
///
/// The default implementation [NeutralFaceQualityDetector] returns a
/// conservative neutral score (68/100) — identical to the Phase 1 heuristic
/// baseline — so the scoring pipeline always has a value regardless of whether
/// an ML model is wired in.
///
/// [VisionFaceQualityDetector] uses Apple's Vision framework via a native
/// method channel to run VNDetectFaceLandmarksRequest on-device.  Eye openness
/// is derived from Eye Aspect Ratio (EAR) computed on the landmark contour
/// points — no network, no API key, sub-100 ms per frame on a modern iPhone.
abstract interface class FaceQualityDetector {
  /// Returns an open-eyes quality score (0–100) for the image at [filePath].
  ///
  /// Returns null if the image cannot be decoded or no face is detected
  /// (callers should treat null as "use neutral baseline").
  Future<int?> detectOpenEyesScore(String filePath);

  /// Largest detected face as normalized bounds — used by [StillScoutAutoPolish]
  /// for portrait exposure weighting. Null when no face is found.
  Future<NormalizedFaceBounds?> detectPrimaryFaceBounds(String filePath);

  /// Whether this detector performs real ML inference (true) or just returns
  /// the neutral baseline (false). Used to decide whether to run the face
  /// detection phase and for UI attribution via [ScoreSource.hybrid].
  bool get isRealDetector;

  /// Rich on-device analysis when supported (Apple Vision). Returns null
  /// when the detector has no multi-signal analysis path.
  Future<VisionFrameAnalysis?> analyzeFrame(String filePath);

  /// Release native resources.
  Future<void> close();
}

/// Default: neutral baseline — no ML dependency, no platform plugin wiring.
class NeutralFaceQualityDetector implements FaceQualityDetector {
  const NeutralFaceQualityDetector();

  static const int _neutralScore = 68;

  @override
  Future<int?> detectOpenEyesScore(String filePath) async => _neutralScore;

  @override
  Future<NormalizedFaceBounds?> detectPrimaryFaceBounds(String filePath) async =>
      null;

  @override
  bool get isRealDetector => false;

  @override
  Future<VisionFrameAnalysis?> analyzeFrame(String filePath) async => null;

  @override
  Future<void> close() async {}
}

/// Full result from one `analyzeFrame` Vision call.
///
/// Combining all signals in one round-trip avoids calling the native channel
/// (and therefore Vision) twice per frame — the old code did that because
/// [detectOpenEyesScore] and [detectPrimaryFaceBounds] each triggered a full
/// Vision request. Now a single call populates all fields and the result is
/// cached for the life of one scoring pass.
class VisionFrameAnalysis {
  const VisionFrameAnalysis({
    required this.eyeScore,
    required this.faceCaptureQuality,
    required this.nativeBlurScore,
    required this.faceSharpnessScore,
    required this.saliencyScore,
    required this.faceAreaNorm,
    required this.ruleOfThirdsScore,
    required this.aestheticsScore,
    required this.yaw,
    required this.roll,
    this.faceBounds,
  });

  /// 0–100 composite: best-face selection × EAR sigmoid × face sharpness ×
  /// framing bonus × pose penalty × blink penalty × confidence.
  final int eyeScore;

  /// Apple's neural face-quality score (0–1). -1 if no face detected.
  final double faceCaptureQuality;

  /// 0–1 full-image Laplacian sharpness (luma channel, vImage).
  final double nativeBlurScore;

  /// 0–1 face-crop Laplacian sharpness — measures sharpness where it matters.
  /// -1 when no face is detected. Prefer this over [nativeBlurScore] for
  /// portrait frames because it ignores intentional background bokeh.
  final double faceSharpnessScore;

  /// 0–1 attention-saliency concentration score from
  /// VNGenerateAttentionBasedSaliencyImageRequest (iOS 13+).
  /// High value = well-isolated, visually prominent subject.
  final double saliencyScore;

  /// Normalised face bounding-box area (width × height, 0–1).
  /// 0.0 when no face detected. Useful for Portrait-mode size bonus.
  final double faceAreaNorm;

  /// 0–1 rule-of-thirds composition score.
  /// High value = face centroid near a ⅓-grid power point (ideal composition).
  /// 0.5 = neutral (centroid in centre or no face).
  final double ruleOfThirdsScore;

  /// Always -1.0 (forward-compatibility placeholder for aesthetics API).
  final double aestheticsScore;

  /// Head yaw in radians. Positive = face turned right.
  final double yaw;

  /// Head roll in radians. Positive = tilted clockwise.
  final double roll;

  /// Best-quality detected face bounds (UIKit origin, 0–1). Null = no face.
  final NormalizedFaceBounds? faceBounds;

  bool get hasFace => faceBounds != null;
}

/// On-device Apple Vision frame analyser (iOS only).
///
/// The Swift plugin (`VisionFaceDetectorPlugin`) now runs a single Vision
/// pipeline that produces:
///   - `eyeScore`           : blended EAR + faceCaptureQuality + pose penalty
///   - `faceCaptureQuality` : Apple neural face-quality (0–1)
///   - `nativeBlurScore`    : Laplacian sharpness (0–1)
///   - `aestheticsScore`    : VNGenerateImageAestheticsScores (iOS 17+, else -1)
///   - `yaw`, `roll`        : head pose in radians
///   - `left/top/right/bottom`: face bounds, UIKit coords
///
/// Results are cached per file path for the duration of one scoring pass so
/// that [detectOpenEyesScore] and [detectPrimaryFaceBounds] (which the
/// existing pipeline calls separately) never trigger two Vision requests.
class VisionFaceQualityDetector implements FaceQualityDetector {
  VisionFaceQualityDetector();

  static const MethodChannel _channel = MethodChannel(
    'com.stillscout/vision_face_detector',
  );

  /// In-flight + completed cache: path → result.
  /// Cleared between scoring passes via [clearCache].
  final Map<String, Future<VisionFrameAnalysis?>> _analysisCache = {};

  @override
  bool get isRealDetector => true;

  // ── Public interface (FaceQualityDetector) ──────────────────────────────

  @override
  Future<int?> detectOpenEyesScore(String filePath) async {
    final analysis = await _getAnalysis(filePath);
    if (analysis == null) return null;
    return analysis.eyeScore;
  }

  @override
  Future<NormalizedFaceBounds?> detectPrimaryFaceBounds(String filePath) async {
    final analysis = await _getAnalysis(filePath);
    return analysis?.faceBounds;
  }

  /// Returns the full [VisionFrameAnalysis] for [filePath], re-using a cached
  /// result if this path was already analysed.
  @override
  Future<VisionFrameAnalysis?> analyzeFrame(String filePath) =>
      _getAnalysis(filePath);

  /// Call this between scouting sessions to free the in-memory cache.
  void clearCache() => _analysisCache.clear();

  // ── Private ─────────────────────────────────────────────────────────────

  /// Looks up or initiates a Vision analysis for [filePath]. Returns a shared
  /// Future so concurrent callers for the same path never double-fire.
  Future<VisionFrameAnalysis?> _getAnalysis(String filePath) {
    return _analysisCache.putIfAbsent(filePath, () => _runAnalysis(filePath));
  }

  Future<VisionFrameAnalysis?> _runAnalysis(String filePath) async {
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'analyzeFrame',
        {'filePath': filePath},
      );
      if (raw == null) return null;
      return _parse(raw);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }

  VisionFrameAnalysis? _parse(Map<Object?, Object?> raw) {
    double? d(String key) => (raw[key] as num?)?.toDouble();

    final eyeRaw   = d('eyeScore')           ?? 0.68;
    final fcq      = d('faceCaptureQuality')  ?? -1.0;
    final blur     = d('nativeBlurScore')     ?? 0.5;
    final faceBlur = d('faceSharpnessScore')  ?? -1.0;
    final saliency = d('saliencyScore')       ?? 0.5;
    final faceArea = d('faceAreaNorm')        ?? 0.0;
    final rotScore = d('ruleOfThirdsScore')   ?? 0.5;
    final aes      = d('aestheticsScore')     ?? -1.0;
    final yaw      = d('yaw')                 ?? 0.0;
    final roll     = d('roll')                ?? 0.0;

    final left   = d('left');
    final top    = d('top');
    final right  = d('right');
    final bottom = d('bottom');

    NormalizedFaceBounds? bounds;
    if (left != null && top != null && right != null && bottom != null) {
      bounds = NormalizedFaceBounds(
        left:   left.clamp(0.0, 1.0),
        top:    top.clamp(0.0, 1.0),
        right:  right.clamp(0.0, 1.0),
        bottom: bottom.clamp(0.0, 1.0),
      );
    }

    return VisionFrameAnalysis(
      eyeScore:          (eyeRaw * 100).round().clamp(1, 100),
      faceCaptureQuality: fcq,
      nativeBlurScore:   blur.clamp(0.0, 1.0),
      faceSharpnessScore: faceBlur < 0 ? -1.0 : faceBlur.clamp(0.0, 1.0),
      saliencyScore:     saliency.clamp(0.0, 1.0),
      faceAreaNorm:      faceArea.clamp(0.0, 1.0),
      ruleOfThirdsScore: rotScore.clamp(0.0, 1.0),
      aestheticsScore:   aes,
      yaw:               yaw,
      roll:              roll,
      faceBounds:        bounds,
    );
  }

  /// Analyses the audio track of [videoPath] and returns timestamps (ms) where
  /// RMS energy exceeds mean + 1.5σ — audio "peaks" that coincide with music
  /// beats or speech onsets.
  ///
  /// Returns an empty map when no audio track is present or analysis fails.
  /// Map key = timestamp (ms), value = normalised energy 0–1.
  Future<Map<int, double>> analyzeAudioPeaks(String videoPath) async {
    try {
      final raw = await _channel.invokeListMethod<Map<Object?, Object?>>(
        'analyzeAudioPeaks',
        {'videoPath': videoPath},
      );
      if (raw == null || raw.isEmpty) return {};
      return {
        for (final entry in raw)
          (entry['timestampMs'] as num).toInt():
              (entry['energy'] as num).toDouble().clamp(0.0, 1.0),
      };
    } on PlatformException {
      return {};
    } on MissingPluginException {
      return {};
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> close() async {
    clearCache();
  }

  // Kept for internal image-dimension fallback only.
  static Future<(double, double)?> imageDimensions(String filePath) async {
    try {
      final decoded = img.decodeImage(await File(filePath).readAsBytes());
      if (decoded == null) return null;
      return (decoded.width.toDouble(), decoded.height.toDouble());
    } catch (_) {
      return null;
    }
  }
}

/// Normalized face rectangle (0–1) for exposure weighting in auto-polish.
class NormalizedFaceBounds {
  const NormalizedFaceBounds({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get centerX => (left + right) / 2;
  double get centerY => (top + bottom) / 2;
  double get width => (right - left).clamp(0.01, 1.0);
  double get height => (bottom - top).clamp(0.01, 1.0);

  factory NormalizedFaceBounds.fromPixelRect({
    required double left,
    required double top,
    required double right,
    required double bottom,
    required double imageWidth,
    required double imageHeight,
  }) {
    final w = imageWidth > 0 ? imageWidth : 1.0;
    final h = imageHeight > 0 ? imageHeight : 1.0;
    return NormalizedFaceBounds(
      left: (left / w).clamp(0.0, 1.0),
      top: (top / h).clamp(0.0, 1.0),
      right: (right / w).clamp(0.0, 1.0),
      bottom: (bottom / h).clamp(0.0, 1.0),
    );
  }
}
