import 'dart:io';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

/// Abstract interface for eye-open / expression quality detection.
///
/// The default implementation [NeutralFaceQualityDetector] returns a
/// conservative neutral score (68/100) — identical to the Phase 1 heuristic
/// baseline — so the scoring pipeline always has a value regardless of whether
/// an ML model is wired in.
///
/// [MlKitFaceQualityDetector] uses Google ML Kit's on-device face detection
/// with `enableClassification: true` to read `leftEyeOpenProbability` and
/// `rightEyeOpenProbability` directly from the native ML model — no network,
/// no API key, sub-100ms per frame on a modern iPhone.
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

  /// Release native resources. Call when the detector is no longer needed
  /// (e.g. app lifecycle pause, or after a full scoring session completes).
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
  Future<void> close() async {}
}

/// On-device ML Kit face detector.
///
/// Lazily initialises the [FaceDetector] on first use and reuses it across
/// the entire scoring session (creating it per-frame would waste native init
/// overhead). Call [close] after the session ends to release the model.
///
/// Threading note: [FaceDetector.processImage] dispatches to a native thread
/// internally, but the Dart call itself must come from the main isolate — ML
/// Kit uses platform channels which are not available inside `compute()`.
/// The [FrameScoringService] deliberately runs face detection AFTER the
/// `compute()`-based heuristic pass for this reason.
class MlKitFaceQualityDetector implements FaceQualityDetector {
  MlKitFaceQualityDetector();

  FaceDetector? _detector;

  FaceDetector get _lazyDetector {
    _detector ??= FaceDetector(
      options: FaceDetectorOptions(
        // Classification gives us leftEyeOpenProbability and
        // rightEyeOpenProbability — the two values we need.
        enableClassification: true,
        // Performance mode: fast is ~2-3× quicker than accurate and more than
        // adequate for still-frame quality scoring.
        performanceMode: FaceDetectorMode.fast,
        // We only need classification data, not landmarks or contours.
        enableLandmarks: false,
        enableContours: false,
        enableTracking: false,
        // Only care about the dominant face in the frame.
        minFaceSize: 0.05,
      ),
    );
    return _detector!;
  }

  @override
  bool get isRealDetector => true;

  @override
  Future<int?> detectOpenEyesScore(String filePath) async {
    final face = await _primaryFace(filePath);
    if (face == null) return null;

    final left = face.leftEyeOpenProbability;
    final right = face.rightEyeOpenProbability;

    if (left == null && right == null) return null;

    final avgProb = (left != null && right != null)
        ? (left + right) / 2.0
        : (left ?? right)!;

    return (avgProb * 100).round().clamp(1, 100);
  }

  @override
  Future<NormalizedFaceBounds?> detectPrimaryFaceBounds(String filePath) async {
    final face = await _primaryFace(filePath);
    if (face == null) return null;

    final dims = await _imageDimensions(filePath);
    if (dims == null) return null;

    final box = face.boundingBox;
    return NormalizedFaceBounds.fromPixelRect(
      left: box.left,
      top: box.top,
      right: box.right,
      bottom: box.bottom,
      imageWidth: dims.$1,
      imageHeight: dims.$2,
    );
  }

  Future<Face?> _primaryFace(String filePath) async {
    try {
      final inputImage = InputImage.fromFilePath(filePath);
      final faces = await _lazyDetector.processImage(inputImage);
      if (faces.isEmpty) return null;

      return faces.reduce((a, b) {
        final aArea = a.boundingBox.width * a.boundingBox.height;
        final bArea = b.boundingBox.width * b.boundingBox.height;
        return aArea >= bArea ? a : b;
      });
    } catch (_) {
      return null;
    }
  }

  Future<(double, double)?> _imageDimensions(String filePath) async {
    try {
      final inputImage = InputImage.fromFilePath(filePath);
      final meta = inputImage.metadata;
      if (meta != null && meta.size.width > 0 && meta.size.height > 0) {
        return (meta.size.width.toDouble(), meta.size.height.toDouble());
      }
    } catch (_) {}

    try {
      final decoded = img.decodeImage(await File(filePath).readAsBytes());
      if (decoded == null) return null;
      return (decoded.width.toDouble(), decoded.height.toDouble());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> close() async {
    await _detector?.close();
    _detector = null;
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
