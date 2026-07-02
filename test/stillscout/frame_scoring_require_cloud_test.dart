import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stillscout/stillscout/data/models/extracted_frame.dart';
import 'package:stillscout/stillscout/domain/failures/stillscout_failure.dart';
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

  test('requireCloudAi fails instead of heuristic fallback when AI unavailable',
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

    await expectLater(
      service.scoreAndRankFrames(
        [frame],
        videoPath: videoPath,
        requireCloudAi: true,
      ),
      throwsA(isA<ScoringFailure>()),
    );
  });
}
