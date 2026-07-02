import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stillscout/stillscout/data/models/extracted_frame.dart';
import 'package:stillscout/stillscout/data/repositories/video_repository_impl.dart';
import 'package:stillscout/stillscout/domain/failures/stillscout_failure.dart';
import 'package:stillscout/stillscout/services/stillscout_cancel_token.dart';
import 'package:stillscout/stillscout/services/video_frame_extractor.dart';

/// Extractor stub that always fails with a given typed error, so we can
/// verify [VideoRepositoryImpl] maps [VideoFrameExtractorErrorCode] to the
/// correct [StillScoutFailure] subtype rather than pattern-matching message
/// text (which is fragile and locale-dependent).
class _ThrowingExtractor extends VideoFrameExtractor {
  _ThrowingExtractor(this._exception);

  final VideoFrameExtractorException _exception;

  @override
  Future<List<ExtractedFrame>> extractFrames({
    required String videoPath,
    int? trimStartMs,
    int? trimEndMs,
    int? knownDurationMs,
    String? outputDirectory,
    void Function(FrameExtractionProgress progress)? onProgress,
    StillScoutCancelToken? cancelToken,
  }) async {
    throw _exception;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;

  setUpAll(() async {
    tmpDir = await Directory.systemTemp.createTemp('video_repo_test_');
    // VideoRepositoryImpl.extractFrames resolves a session cache dir via
    // path_provider before delegating to the extractor — stub the channel
    // so that lookup succeeds in the test environment (no real platform).
    TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tmpDir.path,
    );
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    await tmpDir.delete(recursive: true);
  });

  Future<void> expectMapped(
    VideoFrameExtractorErrorCode code,
    Type expectedFailureType,
  ) async {
    final repo = VideoRepositoryImpl(
      extractor: _ThrowingExtractor(
        VideoFrameExtractorException('boom', code: code),
      ),
    );

    await expectLater(
      repo.extractFrames(videoPath: '/fake.mp4', sessionId: 's1'),
      throwsA(isA<StillScoutFailure>().having(
        (f) => f.runtimeType,
        'runtimeType',
        expectedFailureType,
      )),
    );
  }

  group('VideoRepositoryImpl error mapping', () {
    test('notFound maps to VideoNotFoundFailure', () {
      return expectMapped(
        VideoFrameExtractorErrorCode.notFound,
        VideoNotFoundFailure,
      );
    });

    test('tooShort maps to VideoTooShortFailure', () {
      return expectMapped(
        VideoFrameExtractorErrorCode.tooShort,
        VideoTooShortFailure,
      );
    });

    test('timeout maps to VideoReadTimeoutFailure', () {
      return expectMapped(
        VideoFrameExtractorErrorCode.timeout,
        VideoReadTimeoutFailure,
      );
    });

    test('unreadable maps to VideoUnreadableFailure', () {
      return expectMapped(
        VideoFrameExtractorErrorCode.unreadable,
        VideoUnreadableFailure,
      );
    });

    test('memoryPressure maps to MemoryPressureFailure', () {
      return expectMapped(
        VideoFrameExtractorErrorCode.memoryPressure,
        MemoryPressureFailure,
      );
    });

    test('extractionGeneric maps to ExtractionFailure carrying the message',
        () async {
      final repo = VideoRepositoryImpl(
        extractor: _ThrowingExtractor(
          VideoFrameExtractorException(
            'No frames could be extracted from this video.',
            code: VideoFrameExtractorErrorCode.extractionGeneric,
          ),
        ),
      );

      try {
        await repo.extractFrames(videoPath: '/fake.mp4', sessionId: 's1');
        fail('Expected a StillScoutFailure to be thrown');
      } on ExtractionFailure catch (f) {
        expect(f.reason, 'No frames could be extracted from this video.');
      }
    });
  });
}
