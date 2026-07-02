import '../../data/models/extracted_frame.dart';
import '../../services/video_frame_extractor.dart';
import '../../services/stillscout_cancel_token.dart';
import '../failures/stillscout_failure.dart';

/// Contract for all video-related operations in StillScout.
///
/// The concrete [VideoRepositoryImpl] wraps [VideoFrameExtractor] and
/// [StillScoutCacheJanitor]. Tests swap it for a fake, allowing the notifier
/// state machine to be unit-tested without touching the filesystem.
abstract interface class VideoRepository {
  /// Reads the duration of a video without fully extracting frames.
  /// Returns null if the duration cannot be determined.
  Future<Duration?> readDuration(String videoPath);

  /// Extracts frames, emitting [FrameExtractionProgress] updates and
  /// throwing a [StillScoutFailure] on any unrecoverable error.
  Future<List<ExtractedFrame>> extractFrames({
    required String videoPath,
    required String sessionId,
    int? trimStartMs,
    int? trimEndMs,
    int? knownDurationMs,
    void Function(FrameExtractionProgress)? onProgress,
    StillScoutCancelToken? cancelToken,
  });

  /// Trims [frames] to remove near-duplicate consecutive shots via
  /// perceptual hashing, then returns the de-duplicated list.
  Future<List<ExtractedFrame>> deduplicateFrames(
    List<ExtractedFrame> frames,
  );

  /// Releases cached frames from old sessions that exceed the LRU budget.
  Future<void> runCacheJanitor();
}
