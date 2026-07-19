import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'face_quality_detector.dart';

/// On-device polish — gentle levels, clarity, and optional face exposure.
/// Conservative by design: a bad polish is worse than no polish.
///
/// All pixel work is forced through uint8 RGB before encode. That avoids the
/// red/blue/white channel corruption that can happen when `image` filters run
/// on float / multi-channel JPEG decodes and then get re-encoded.
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
        final evictedPath = _cache.remove(_cache.keys.first);
        if (evictedPath != null) {
          try {
            final evicted = File(evictedPath);
            if (evicted.existsSync()) evicted.deleteSync();
          } catch (_) {}
        }
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
    var image = _toUint8Rgb(source);

    // Manual gentle levels — avoid `adjustColor`, which can corrupt channels
    // on non-uint8 / multi-channel JPEG sources.
    image = _gentleLevels(image);
    if (face != null && _faceBoundsValid(face)) {
      image = _applyFaceExposure(image, face, boost: 0.08);
    }
    image = _sharpen(image, amount: 0.16);
    image = _liftShadows(image, amount: 0.025);
    image = _toUint8Rgb(image);

    if (!_isPlausibleOutput(source, image, inputMean)) {
      return _toUint8Rgb(source);
    }
    return image;
  }

  static Uint8List? encodePolishedJpeg(img.Image image, {int quality = 92}) {
    try {
      return Uint8List.fromList(
        img.encodeJpg(_toUint8Rgb(image), quality: quality),
      );
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

  /// Force a stable uint8 RGB buffer so later pixel math + JPEG encode
  /// cannot pick up float / RGBA / palette channel quirks.
  static img.Image _toUint8Rgb(img.Image source) {
    final oriented = img.bakeOrientation(source);
    if (oriented.format == img.Format.uint8 && oriented.numChannels == 3) {
      return img.Image.from(oriented);
    }

    final converted = oriented.convert(
      format: img.Format.uint8,
      numChannels: 3,
    );
    if (converted.format == img.Format.uint8 && converted.numChannels == 3) {
      return converted;
    }

    final out = img.Image(
      width: oriented.width,
      height: oriented.height,
      numChannels: 3,
      format: img.Format.uint8,
    );
    for (var y = 0; y < oriented.height; y++) {
      for (var x = 0; x < oriented.width; x++) {
        final p = oriented.getPixel(x, y);
        out.setPixelRgb(
          x,
          y,
          p.r.toInt().clamp(0, 255),
          p.g.toInt().clamp(0, 255),
          p.b.toInt().clamp(0, 255),
        );
      }
    }
    return out;
  }

  static img.Image _gentleLevels(img.Image image) {
    // contrast ~1.04, brightness ~1.015, saturation ~1.03 — applied in RGB.
    const contrast = 1.04;
    const brightness = 1.015;
    const saturation = 1.03;
    for (final p in image) {
      var r = p.r * brightness;
      var g = p.g * brightness;
      var b = p.b * brightness;

      r = ((r - 128) * contrast) + 128;
      g = ((g - 128) * contrast) + 128;
      b = ((b - 128) * contrast) + 128;

      final gray = _luma(r, g, b);
      r = gray + (r - gray) * saturation;
      g = gray + (g - gray) * saturation;
      b = gray + (b - gray) * saturation;

      p.r = _clampByte(r);
      p.g = _clampByte(g);
      p.b = _clampByte(b);
    }
    return image;
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

    var bad = 0;
    var samples = 0;
    final step = (after.width / 24).ceil().clamp(1, after.width);
    for (var y = 0; y < after.height; y += step) {
      for (var x = 0; x < after.width; x += step) {
        final p = after.getPixel(x, y);
        final r = p.r.toInt();
        final g = p.g.toInt();
        final b = p.b.toInt();
        samples++;
        // Near-black / near-white blowouts.
        if (r < 8 && g < 8 && b < 8) bad++;
        if (r > 250 && g > 250 && b > 250) bad++;
        // Channel-cast corruption (classic broken polish colors).
        if (r > 250 && g < 40 && b < 40) bad++;
        if (b > 250 && r < 40 && g < 40) bad++;
        if (r > 250 && g > 250 && b < 40) bad++; // yellow-white cast
        if (r < 40 && g > 250 && b > 250) bad++; // cyan cast
      }
    }
    return samples == 0 || bad / samples < 0.20;
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
        final lift = 255 * weight;
        p.r = _clampByte(p.r + lift);
        p.g = _clampByte(p.g + lift);
        p.b = _clampByte(p.b + lift);
      }
    }
    return image;
  }

  static img.Image _sharpen(img.Image image, {required double amount}) {
    final base = _toUint8Rgb(image);
    final blurred = img.gaussianBlur(img.Image.from(base), radius: 1);
    for (var y = 0; y < base.height; y++) {
      for (var x = 0; x < base.width; x++) {
        final o = base.getPixel(x, y);
        final b = blurred.getPixel(x, y);
        o.r = _clampByte(o.r + (o.r - b.r) * amount);
        o.g = _clampByte(o.g + (o.g - b.g) * amount);
        o.b = _clampByte(o.b + (o.b - b.b) * amount);
      }
    }
    return base;
  }

  static img.Image _liftShadows(img.Image image, {required double amount}) {
    for (final p in image) {
      final l = _luma(p.r, p.g, p.b) / 255.0;
      final lift = (1 - l) * amount;
      final delta = 255 * lift;
      p.r = _clampByte(p.r + delta);
      p.g = _clampByte(p.g + delta);
      p.b = _clampByte(p.b + delta);
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
