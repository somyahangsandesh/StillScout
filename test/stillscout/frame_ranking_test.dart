import 'dart:io';

import 'package:stillscout/stillscout/data/models/extracted_frame.dart';
import 'package:stillscout/stillscout/services/frame_scoring_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('stillscout_ranking_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
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
        final value = isLight ? 245 : 10;
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

  group('FrameScoringService — ranking (heuristic fallback, no API key in tests)', () {
    test('ranks the sharpest, best-lit frame first and flags top picks as top scout', () async {
      final sharpFrame = ExtractedFrame(
        id: 'sharp',
        filePath: writeJpeg('sharp', checkerboard()),
        timestampMs: 500,
        width: 96,
        height: 96,
        sourceVideoPath: '${tempDir.path}/source.mp4',
      );
      final darkFrame = ExtractedFrame(
        id: 'dark',
        filePath: writeJpeg('dark', flat(8)),
        timestampMs: 1000,
        width: 96,
        height: 96,
        sourceVideoPath: '${tempDir.path}/source.mp4',
      );
      final blownOutFrame = ExtractedFrame(
        id: 'blown_out',
        filePath: writeJpeg('blown_out', flat(250)),
        timestampMs: 1500,
        width: 96,
        height: 96,
        sourceVideoPath: '${tempDir.path}/source.mp4',
      );

      final scored = await FrameScoringService().scoreAndRankFrames(
        [darkFrame, blownOutFrame, sharpFrame], // intentionally out of order
        videoPath: '${tempDir.path}/source.mp4',
      );

      expect(scored, hasLength(3));

      // Sorted descending by score.
      for (var i = 0; i < scored.length - 1; i++) {
        expect(scored[i].score, greaterThanOrEqualTo(scored[i + 1].score));
      }

      expect(scored.first.frame.id, 'sharp');
      expect(scored.where((s) => s.isTopScout).length, 3);
      expect(scored.first.isTopScout, isTrue);
    });

    test('returns an empty list for an empty input without touching the cache', () async {
      final scored = await FrameScoringService().scoreAndRankFrames(
        [],
        videoPath: '${tempDir.path}/source.mp4',
      );
      expect(scored, isEmpty);
    });

    test('reports progress reaching 1.0 by completion', () async {
      final frame = ExtractedFrame(
        id: 'only',
        filePath: writeJpeg('only', flat(135)),
        timestampMs: 0,
        width: 96,
        height: 96,
        sourceVideoPath: '${tempDir.path}/source.mp4',
      );

      final progressValues = <double>[];
      await FrameScoringService().scoreAndRankFrames(
        [frame],
        videoPath: '${tempDir.path}/source.mp4',
        onProgress: progressValues.add,
      );

      expect(progressValues, isNotEmpty);
      expect(progressValues.last, 1.0);
    });
  });
}
