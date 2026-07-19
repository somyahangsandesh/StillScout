import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

import '../../domain/failures/stillscout_failure.dart';
import '../../domain/repositories/video_repository.dart';
import '../../services/stillscout_cache_janitor.dart';
import '../../services/stillscout_cancel_token.dart';
import '../../services/stillscout_frame_dedup.dart';
import '../../services/video_frame_extractor.dart';
import '../models/extracted_frame.dart';

class VideoRepositoryImpl implements VideoRepository {
  VideoRepositoryImpl({VideoFrameExtractor? extractor})
      : _extractor = extractor ?? VideoFrameExtractor();

  final VideoFrameExtractor _extractor;

  @override
  Future<Duration?> readDuration(String videoPath) async {
    final controller = VideoPlayerController.file(File(videoPath));
    try {
      await controller.initialize().timeout(const Duration(seconds: 15));
      return controller.value.duration;
    } catch (_) {
      return null;
    } finally {
      await controller.dispose();
    }
  }

  @override
  Future<List<ExtractedFrame>> extractFrames({
    required String videoPath,
    required String sessionId,
    int? trimStartMs,
    int? trimEndMs,
    int? knownDurationMs,
    void Function(FrameExtractionProgress)? onProgress,
    StillScoutCancelToken? cancelToken,
  }) async {
    try {
      final sessionDir = await StillScoutCacheJanitor.sessionDir(sessionId);
      return await _extractor.extractFrames(
        videoPath: videoPath,
        trimStartMs: trimStartMs,
        trimEndMs: trimEndMs,
        knownDurationMs: knownDurationMs,
        outputDirectory: sessionDir.path,
        onProgress: onProgress,
        cancelToken: cancelToken,
      );
    } on StillScoutCancelledException {
      throw const CancelledFailure();
    } on CancelledFailure {
      // Progress callbacks may throw CancelledFailure — keep it typed.
      rethrow;
    } on StillScoutFailure {
      rethrow;
    } on VideoFrameExtractorException catch (e) {
      throw _mapExtractorException(e);
    } catch (e) {
      throw UnknownFailure(e);
    }
  }

  StillScoutFailure _mapExtractorException(VideoFrameExtractorException e) {
    switch (e.code) {
      case VideoFrameExtractorErrorCode.notFound:
        return const VideoNotFoundFailure();
      case VideoFrameExtractorErrorCode.tooShort:
        return const VideoTooShortFailure();
      case VideoFrameExtractorErrorCode.tooLong:
        return const VideoTooLongFailure();
      case VideoFrameExtractorErrorCode.timeout:
        return const VideoReadTimeoutFailure();
      case VideoFrameExtractorErrorCode.unreadable:
        return const VideoUnreadableFailure();
      case VideoFrameExtractorErrorCode.memoryPressure:
        return const MemoryPressureFailure();
      case VideoFrameExtractorErrorCode.extractionGeneric:
        return ExtractionFailure(e.message);
    }
  }

  @override
  Future<List<ExtractedFrame>> deduplicateFrames(
    List<ExtractedFrame> frames,
  ) async {
    if (frames.length <= 1) return frames;
    return compute(StillScoutFrameDedup.deduplicate, frames);
  }

  @override
  Future<void> runCacheJanitor() async {
    // Session ID list is handled by the caller / DI layer so the janitor
    // doesn't open Hive itself. We expose the raw eviction entry-point here.
    await StillScoutCacheJanitor.evict(activeSessions: const []);
  }
}
