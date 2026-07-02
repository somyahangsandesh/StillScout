import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

import '../data/models/frame_score_metadata.dart';

/// Offline fallback scorer — used when the vision LLM is unconfigured,
/// unreachable, or rate-limited. Runs pure pixel analysis (no ML model, no
/// network), so it's deterministic, fast, and works on a plane with no wifi.
///
/// Honest about its limits: blur and lighting are well-defined signal
/// processing problems we *can* solve from pixels alone. "Open eyes" needs a
/// face/landmark model we don't ship on-device, so that axis returns a
/// neutral baseline rather than pretending to detect anything — the UI
/// labels heuristic scores as "Estimated · Offline" so creators know the
/// difference from a real AI judgment.
class FrameHeuristicScorer {
  FrameHeuristicScorer._();

  /// Analysis runs on a small downsample — plenty of signal for blur/
  /// lighting/composition, far cheaper than processing the full 1280px frame.
  static const int _analysisWidth = 160;

  /// Synchronous, CPU-only — designed to be called from inside an isolate
  /// (see [scoreFilesInIsolate]) so it never blocks the UI thread.
  static FrameScoreMetadata scoreFile(String filePath) {
    try {
      final bytes = File(filePath).readAsBytesSync();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return _fallback();

      final small = img.copyResize(
        decoded,
        width: decoded.width > _analysisWidth ? _analysisWidth : decoded.width,
        interpolation: img.Interpolation.average,
      );
      final gray = img.grayscale(small);
      final luma = _lumaGrid(gray);

      final blur = _blurScore(luma);
      final lighting = _lightingScore(luma);
      final composition = _compositionScore(luma);

      return FrameScoreMetadata(
        blurScore: blur,
        lightingScore: lighting,
        openEyesScore: _neutralOpenEyesScore,
        compositionScore: composition,
        source: ScoreSource.heuristic,
      );
    } catch (_) {
      return _fallback();
    }
  }

  /// Batch entry point for `compute()` — keeps isolate spawn overhead to one
  /// hop per batch instead of one per frame.
  static Map<String, FrameScoreMetadata> scoreFilesInIsolate(
    List<String> filePaths,
  ) {
    final results = <String, FrameScoreMetadata>{};
    for (final path in filePaths) {
      results[path] = scoreFile(path);
    }
    return results;
  }

  static const int _neutralOpenEyesScore = 68;

  static FrameScoreMetadata _fallback() => const FrameScoreMetadata(
        blurScore: 50,
        lightingScore: 50,
        openEyesScore: _neutralOpenEyesScore,
        compositionScore: 50,
        source: ScoreSource.heuristic,
      );

  static List<List<int>> _lumaGrid(img.Image gray) {
    final grid = List.generate(
      gray.height,
      (_) => List<int>.filled(gray.width, 0),
      growable: false,
    );
    for (var y = 0; y < gray.height; y++) {
      for (var x = 0; x < gray.width; x++) {
        grid[y][x] = gray.getPixel(x, y).r.toInt();
      }
    }
    return grid;
  }

  /// Variance of a discrete Laplacian — the classic, cheap blur estimator.
  /// Sharp images have high-frequency edges everywhere (high variance);
  /// blurry images are smooth (low variance). Normalized empirically against
  /// typical phone-camera footage so the 1-100 scale feels meaningful.
  static int _blurScore(List<List<int>> luma) {
    final h = luma.length;
    final w = h > 0 ? luma[0].length : 0;
    if (h < 3 || w < 3) return 50;

    final laplacians = <double>[];
    for (var y = 1; y < h - 1; y++) {
      for (var x = 1; x < w - 1; x++) {
        final lap = luma[y - 1][x] +
            luma[y + 1][x] +
            luma[y][x - 1] +
            luma[y][x + 1] -
            4 * luma[y][x];
        laplacians.add(lap.toDouble());
      }
    }
    if (laplacians.isEmpty) return 50;

    final mean = laplacians.reduce((a, b) => a + b) / laplacians.length;
    final variance = laplacians
            .map((v) => (v - mean) * (v - mean))
            .reduce((a, b) => a + b) /
        laplacians.length;

    // Empirical scaling: variance ~0 (flat blur) → score ~5; variance ~900+
    // (tack-sharp edges) → score ~98. sqrt compresses the long tail.
    final score = 5 + (math.sqrt(variance) * 6.2);
    return score.clamp(1, 100).round();
  }

  /// Mean luma with a penalty for both underexposure and blown highlights.
  static int _lightingScore(List<List<int>> luma) {
    final flat = luma.expand((row) => row);
    if (flat.isEmpty) return 50;

    final values = flat.toList();
    final mean = values.reduce((a, b) => a + b) / values.length;

    var clipped = 0;
    for (final v in values) {
      if (v <= 4 || v >= 251) clipped++;
    }
    final clippedRatio = clipped / values.length;

    // Ideal exposure sits around mid-gray (~120-150 on a 0-255 scale).
    final distanceFromIdeal = (mean - 135).abs();
    final exposureScore = (100 - distanceFromIdeal * 0.9).clamp(0, 100);
    final clippingPenalty = clippedRatio * 60;

    final score = exposureScore - clippingPenalty;
    return score.clamp(1, 100).round();
  }

  /// Rule-of-thirds proxy: sharp images tend to concentrate visual energy
  /// (edges/contrast) near the four intersection points rather than evenly
  /// smeared across the frame. Cheap Sobel-magnitude energy at each
  /// intersection vs. the frame average approximates "is something
  /// interesting placed where the eye looks first".
  static int _compositionScore(List<List<int>> luma) {
    final h = luma.length;
    final w = h > 0 ? luma[0].length : 0;
    if (h < 9 || w < 9) return 55;

    double energyAt(int cx, int cy) {
      var sum = 0.0;
      var count = 0;
      final radius = (math.min(w, h) * 0.12).round().clamp(2, 30);
      for (var y = cy - radius; y <= cy + radius; y++) {
        for (var x = cx - radius; x <= cx + radius; x++) {
          if (y <= 0 || y >= h - 1 || x <= 0 || x >= w - 1) continue;
          final gx = luma[y][x + 1] - luma[y][x - 1];
          final gy = luma[y + 1][x] - luma[y - 1][x];
          sum += math.sqrt((gx * gx + gy * gy).toDouble());
          count++;
        }
      }
      return count == 0 ? 0 : sum / count;
    }

    final thirdX1 = (w / 3).round();
    final thirdX2 = (w * 2 / 3).round();
    final thirdY1 = (h / 3).round();
    final thirdY2 = (h * 2 / 3).round();

    final intersections = [
      energyAt(thirdX1, thirdY1),
      energyAt(thirdX2, thirdY1),
      energyAt(thirdX1, thirdY2),
      energyAt(thirdX2, thirdY2),
    ];
    final bestIntersection = intersections.reduce(math.max);

    var totalEnergy = 0.0;
    var totalCount = 0;
    for (var y = 1; y < h - 1; y++) {
      for (var x = 1; x < w - 1; x++) {
        final gx = luma[y][x + 1] - luma[y][x - 1];
        final gy = luma[y + 1][x] - luma[y - 1][x];
        totalEnergy += math.sqrt((gx * gx + gy * gy).toDouble());
        totalCount++;
      }
    }
    final avgEnergy = totalCount == 0 ? 0 : totalEnergy / totalCount;
    if (avgEnergy <= 0.001) return 55;

    final ratio = bestIntersection / avgEnergy;
    // ratio ~1 (no concentration) → ~50; ratio ~3+ (strong subject placement
    // near an intersection) → ~95.
    final score = 35 + (ratio * 20);
    return score.clamp(1, 100).round();
  }
}
