import 'dart:io';

import 'package:stillscout/stillscout/data/models/frame_score_metadata.dart';
import 'package:stillscout/stillscout/services/frame_heuristic_scorer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('stillscout_heuristic_test');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  String writeJpeg(String name, img.Image image) {
    final path = '${tempDir.path}/$name.jpg';
    File(path).writeAsBytesSync(img.encodeJpg(image, quality: 90));
    return path;
  }

  img.Image checkerboard({int size = 96, int cell = 6}) {
    final image = img.Image(width: size, height: size);
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final isLight = ((x ~/ cell) + (y ~/ cell)) % 2 == 0;
        final value = isLight ? 250 : 5;
        image.setPixelRgb(x, y, value, value, value);
      }
    }
    return image;
  }

  img.Image flat(int gray, {int size = 96}) {
    final image = img.Image(width: size, height: size);
    img.fill(image, color: img.ColorRgb8(gray, gray, gray));
    return image;
  }

  group('FrameHeuristicScorer', () {
    test('scores a high-contrast checkerboard as sharper than a flat image', () {
      final sharpPath = writeJpeg('sharp', checkerboard());
      final flatPath = writeJpeg('flat', flat(128));

      final sharp = FrameHeuristicScorer.scoreFile(sharpPath);
      final blurry = FrameHeuristicScorer.scoreFile(flatPath);

      expect(sharp.blurScore, greaterThan(blurry.blurScore));
      expect(sharp.source, ScoreSource.heuristic);
    });

    test('penalizes underexposed and overexposed frames vs. mid-gray', () {
      final darkPath = writeJpeg('dark', flat(8));
      final brightPath = writeJpeg('bright', flat(248));
      final midPath = writeJpeg('mid', flat(135));

      final dark = FrameHeuristicScorer.scoreFile(darkPath);
      final bright = FrameHeuristicScorer.scoreFile(brightPath);
      final mid = FrameHeuristicScorer.scoreFile(midPath);

      expect(mid.lightingScore, greaterThan(dark.lightingScore));
      expect(mid.lightingScore, greaterThan(bright.lightingScore));
    });

    test('always returns scores within 1-100 and a neutral open-eyes baseline', () {
      final path = writeJpeg('checker', checkerboard());
      final result = FrameHeuristicScorer.scoreFile(path);

      for (final value in [
        result.blurScore,
        result.lightingScore,
        result.openEyesScore,
        result.compositionScore,
      ]) {
        expect(value, inInclusiveRange(1, 100));
      }
      // No on-device face/eye model — heuristic scorer is honest about this
      // and returns the same neutral baseline rather than fabricating signal.
      expect(result.openEyesScore, 68);
    });

    test('gracefully falls back for a missing or corrupt file', () {
      final result = FrameHeuristicScorer.scoreFile('${tempDir.path}/does_not_exist.jpg');
      expect(result.blurScore, 50);
      expect(result.source, ScoreSource.heuristic);
    });

    test('scoreFilesInIsolate scores a batch keyed by file path', () {
      final pathA = writeJpeg('a', checkerboard());
      final pathB = writeJpeg('b', flat(135));

      final results = FrameHeuristicScorer.scoreFilesInIsolate([pathA, pathB]);

      expect(results.keys, containsAll([pathA, pathB]));
      expect(results[pathA]!.source, ScoreSource.heuristic);
    });
  });
}
