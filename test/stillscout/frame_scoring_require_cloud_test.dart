import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stillscout/stillscout/data/models/extracted_frame.dart';
import 'package:stillscout/stillscout/data/models/frame_score_metadata.dart';
import 'package:stillscout/stillscout/services/frame_scoring_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late String framePath;
  late String videoPath;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('stillscout_cloud_test');
    Hive.init(tempDir.path);
    framePath = '${tempDir.path}/frame.jpg';
    videoPath = '${tempDir.path}/video.mp4';
    await File(framePath).writeAsBytes([0xFF, 0xD8, 0xFF, 0xD9]);
    await File(videoPath).writeAsBytes([0, 1, 2, 3]);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  // Graceful-degradation contract: when Gemini is unavailable the service
  // returns Vision/heuristic scores rather than crashing the scout.
  // This ensures AI Pro users always get results even with network issues.
  test(
    'gracefully falls back to Vision scores when cloud AI unavailable',
    () async {
      final frame = ExtractedFrame(
        id: 'f1',
        filePath: framePath,
        timestampMs: 100,
        width: 640,
        height: 480,
        sourceVideoPath: videoPath,
      );

      final service = FrameScoringService();

      final results = await service.scoreAndRankFrames(
        [frame],
        videoPath: videoPath,
        useCloudAi: true,
        requireCloudAi: false,
      );

      expect(results, hasLength(1));
      expect(
        results.first.metadata.source,
        isNot(ScoreSource.llm),
        reason: 'No Gemini key in tests — score must be on-device',
      );
    },
  );

  // W1.2 soft-degrade: requireCloudAi must no longer throw when Gemini is
  // unreachable — it should fall through to the Vision/heuristic preliminary
  // scores exactly like the optional-cloud path, so AI Pro scouts always
  // complete with a usable gallery.
  test(
    'requireCloudAi true soft-degrades to Vision scores when Gemini unavailable',
    () async {
      final frame = ExtractedFrame(
        id: 'f1',
        filePath: framePath,
        timestampMs: 100,
        width: 640,
        height: 480,
        sourceVideoPath: videoPath,
      );

      final service = FrameScoringService();

      final results = await service.scoreAndRankFrames(
        [frame],
        videoPath: videoPath,
        useCloudAi: true,
        requireCloudAi: true,
      );

      expect(results, hasLength(1));
      expect(
        results.first.metadata.source,
        isNot(ScoreSource.llm),
        reason: 'No Gemini key in tests — score must be on-device',
      );
    },
  );
}
