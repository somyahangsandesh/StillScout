import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'face_quality_detector.dart';

/// On-device polish — gentle levels, clarity, and optional face exposure.
/// Conservative by design: a bad polish is worse than no polish.
class StillScoutAutoPolish {
  StillScoutAutoPolish._();

  static final Map<String, String> _cache = {};

  static Future<String?> polishToCache(
    String sourcePath, {
    NormalizedFaceBounds? face,
  }) async {
    try {
      final source = File(sourcePath);
      if (!await source.exists()) return null;

      final stat = await source.stat();
      final cacheKey = '$sourcePath:${stat.modified.millisecondsSinceEpoch}';
      final hit = _cache[cacheKey];
      if (hit != null && File(hit).existsSync()) return hit;

      final bytes = await source.readAsBytes();
      final polished = await compute(
        _polishBytesInIsolate,
        _PolishPayload(
          bytes: bytes,
          faceLeft: face?.left,
          faceTop: face?.top,
          faceRight: face?.right,
          faceBottom: face?.bottom,
        ),
      );
      if (polished == null) return null;

      final tempDir = await getTemporaryDirectory();
      final outPath =
          '${tempDir.path}/stillscout_polish_${stat.modified.millisecondsSinceEpoch}.jpg';
      await File(outPath).writeAsBytes(polished, flush: true);

      _cache[cacheKey] = outPath;
      if (_cache.length > 24) {
        _cache.remove(_cache.keys.first);
      }
      return outPath;
    } catch (e) {
      debugPrint('[StillScoutAutoPolish] polish failed: $e');
      return null;
    }
  }

  static Future<String?> polishWithFaceDetection(
    String sourcePath, {
    FaceQualityDetector? faceDetector,
  }) async {
    NormalizedFaceBounds? face;
    if (faceDetector != null && faceDetector.isRealDetector) {
      face = await faceDetector.detectPrimaryFaceBounds(sourcePath);
    }
    return polishToCache(sourcePath, face: face);
  }

  static img.Image polishImage(
    img.Image source, {
    NormalizedFaceBounds? face,
  }) {
    final inputMean = _meanLuma(source);
    var image = _normalizeSource(source);

    image = img.adjustColor(
      image,
      contrast: 1.05,
      brightness: 1.02,
      saturation: 1.04,
      gamma: 0.98,
    );

    if (face != null && _faceBoundsValid(face)) {
      image = _applyFaceExposure(image, face, boost: 0.05);
    }

    image = _sharpen(image, amount: 0.22);
    image = _liftShadows(image, amount: 0.03);

    if (!_isPlausibleOutput(source, image, inputMean)) {
      return _normalizeSource(source);
    }
    return image;
  }

  static Uint8List? encodePolishedJpeg(img.Image image, {int quality = 92}) {
    try {
      return Uint8List.fromList(img.encodeJpg(image, quality: quality));
    } catch (_) {
      return null;
    }
  }

  static Uint8List? _polishBytesInIsolate(_PolishPayload payload) {
    try {
      final decoded = img.decodeImage(payload.bytes);
      if (decoded == null) return null;

      NormalizedFaceBounds? face;
      if (payload.faceLeft != null &&
          payload.faceTop != null &&
          payload.faceRight != null &&
          payload.faceBottom != null) {
        face = NormalizedFaceBounds(
          left: payload.faceLeft!,
          top: payload.faceTop!,
          right: payload.faceRight!,
          bottom: payload.faceBottom!,
        );
      }

      final polished = polishImage(decoded, face: face);
      return encodePolishedJpeg(polished);
    } catch (_) {
      return null;
    }
  }

  static img.Image _normalizeSource(img.Image source) {
    final oriented = img.bakeOrientation(img.Image.from(source));
    if (oriented.numChannels == 3) return oriented;

    final out = img.Image(
      width: oriented.width,
      height: oriented.height,
      numChannels: 3,
    );
    for (var y = 0; y < oriented.height; y++) {
      for (var x = 0; x < oriented.width; x++) {
        final p = oriented.getPixel(x, y);
        out.setPixelRgb(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt());
      }
    }
    return out;
  }

  static bool _faceBoundsValid(NormalizedFaceBounds face) {
    return face.width > 0.05 &&
        face.height > 0.05 &&
        face.right > face.left &&
        face.bottom > face.top;
  }

  static double _meanLuma(img.Image image) {
    var sum = 0.0;
    var count = 0;
    final step = (image.width / 32).ceil().clamp(1, image.width);
    for (var y = 0; y < image.height; y += step) {
      for (var x = 0; x < image.width; x += step) {
        final p = image.getPixel(x, y);
        sum += _luma(p.r, p.g, p.b);
        count++;
      }
    }
    return count == 0 ? 128 : sum / count;
  }

  static bool _isPlausibleOutput(
    img.Image before,
    img.Image after,
    double beforeMean,
  ) {
    final afterMean = _meanLuma(after);
    if (afterMean < 18 || afterMean > 245) return false;
    if ((afterMean - beforeMean).abs() > 90) return false;

    var clipped = 0;
    var samples = 0;
    final step = (after.width / 24).ceil().clamp(1, after.width);
    for (var y = 0; y < after.height; y += step) {
      for (var x = 0; x < after.width; x += step) {
        final p = after.getPixel(x, y);
        samples++;
        if (p.r < 8 && p.g < 8 && p.b < 8) clipped++;
        if (p.r > 250 && p.g < 30 && p.b < 30) clipped++;
      }
    }
    return samples == 0 || clipped / samples < 0.35;
  }

  static img.Image _applyFaceExposure(
    img.Image image,
    NormalizedFaceBounds face, {
    required double boost,
  }) {
    final w = image.width;
    final h = image.height;
    final cx = face.centerX * w;
    final cy = face.centerY * h;
    final rx = (face.width * w * 0.55).clamp(12.0, w / 2.0);
    final ry = (face.height * h * 0.55).clamp(12.0, h / 2.0);

    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final dx = (x - cx) / rx;
        final dy = (y - cy) / ry;
        final dist = dx * dx + dy * dy;
        if (dist > 1) continue;
        final weight = (1 - dist) * boost;
        final p = image.getPixel(x, y);
        p.r = _clampByte(p.r + 255 * weight);
        p.g = _clampByte(p.g + 255 * weight);
        p.b = _clampByte(p.b + 255 * weight * 0.96);
      }
    }
    return image;
  }

  static img.Image _sharpen(img.Image image, {required double amount}) {
    final blurred = img.gaussianBlur(img.Image.from(image), radius: 1);
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final o = image.getPixel(x, y);
        final b = blurred.getPixel(x, y);
        o.r = _clampByte(o.r + (o.r - b.r) * amount);
        o.g = _clampByte(o.g + (o.g - b.g) * amount);
        o.b = _clampByte(o.b + (o.b - b.b) * amount);
      }
    }
    return image;
  }

  static img.Image _liftShadows(img.Image image, {required double amount}) {
    for (final p in image) {
      final l = _luma(p.r, p.g, p.b) / 255.0;
      final lift = (1 - l) * amount;
      p.r = _clampByte(p.r + 255 * lift);
      p.g = _clampByte(p.g + 255 * lift);
      p.b = _clampByte(p.b + 255 * lift);
    }
    return image;
  }

  static double _luma(num r, num g, num b) => 0.299 * r + 0.587 * g + 0.114 * b;

  static int _clampByte(num v) => v.round().clamp(0, 255);
}

class _PolishPayload {
  const _PolishPayload({
    required this.bytes,
    this.faceLeft,
    this.faceTop,
    this.faceRight,
    this.faceBottom,
  });

  final Uint8List bytes;
  final double? faceLeft;
  final double? faceTop;
  final double? faceRight;
  final double? faceBottom;
}
