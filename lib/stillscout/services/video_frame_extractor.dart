import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../data/models/extracted_frame.dart';
import '../domain/stillscout_constants.dart';
import 'stillscout_cancel_token.dart';

/// Progress snapshot emitted while frames are being extracted.
class FrameExtractionProgress {
  const FrameExtractionProgress({
    required this.phase,
    required this.progress,
    required this.framesExtracted,
    required this.totalFrames,
    this.extractedFrames = const [],
  });

  final String phase;
  final double progress;
  final int framesExtracted;
  final int totalFrames;

  /// Frames extracted so far — grows during extraction for the live strip.
  final List<ExtractedFrame> extractedFrames;

  String get statusMessage => phase;
}

/// Native-backed video frame extractor.
class VideoFrameExtractor {
  VideoFrameExtractor({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  static const _estimatedHeight = 720;

  Future<List<ExtractedFrame>> extractFrames({
    required String videoPath,
    int? trimStartMs,
    int? trimEndMs,
    int? knownDurationMs,
    String? outputDirectory,
    void Function(FrameExtractionProgress progress)? onProgress,
    StillScoutCancelToken? cancelToken,
  }) async {
    final file = File(videoPath);
    if (!await file.exists()) {
      throw VideoFrameExtractorException(
        'Video file not found.',
        code: VideoFrameExtractorErrorCode.notFound,
      );
    }

    onProgress?.call(
      const FrameExtractionProgress(
        phase: 'Analyzing video…',
        progress: 0.02,
        framesExtracted: 0,
        totalFrames: 0,
      ),
    );

    final durationMs =
        knownDurationMs ?? await _readDurationMs(videoPath);
    if (durationMs <= 0) {
      throw VideoFrameExtractorException(
        'Could not read this video. Try a different file or format.',
        code: VideoFrameExtractorErrorCode.unreadable,
      );
    }
    if (durationMs < StillScoutConstants.minVideoDurationMs) {
      throw VideoFrameExtractorException(
        'That clip is too short to scout — try something at least half a second long.',
        code: VideoFrameExtractorErrorCode.tooShort,
      );
    }

    cancelToken?.throwIfCancelled();

    final startMs = (trimStartMs ?? 0).clamp(0, durationMs);
    final endMs = (trimEndMs ?? durationMs).clamp(startMs, durationMs);
    final effectiveDuration = endMs - startMs;

    final timestamps = _buildTimestamps(effectiveDuration, offsetMs: startMs);
    if (timestamps.isEmpty) {
      throw VideoFrameExtractorException(
        'No frames could be sampled from this video.',
        code: VideoFrameExtractorErrorCode.unreadable,
      );
    }

    final sessionDir = outputDirectory != null
        ? Directory(outputDirectory)
        : await _createSessionDir();
    if (!await sessionDir.exists()) {
      await sessionDir.create(recursive: true);
    }
    if (outputDirectory == null) {
      await _cleanupStaleSessions(sessionDir.parent);
    }

    final frames = <ExtractedFrame>[];
    var failedCount = 0;
    var completed = 0;
    final total = timestamps.length;
    final queue = List<int>.from(timestamps);
    final concurrency = StillScoutConstants.maxConcurrentThumbnailExtractions
        .clamp(1, total);

    Future<void> worker() async {
      while (queue.isNotEmpty) {
        cancelToken?.throwIfCancelled();
        final timestampMs = queue.removeAt(0);
        try {
          final thumbPath = await VideoThumbnail.thumbnailFile(
            video: videoPath,
            thumbnailPath: sessionDir.path,
            timeMs: timestampMs,
            imageFormat: ImageFormat.JPEG,
            quality: StillScoutConstants.jpegQuality,
            maxWidth: StillScoutConstants.maxFrameWidth,
          );

          if (thumbPath == null) {
            failedCount++;
          } else {
            frames.add(
              ExtractedFrame(
                id: _uuid.v4(),
                filePath: thumbPath,
                timestampMs: timestampMs,
                width: StillScoutConstants.maxFrameWidth,
                height: _estimatedHeight,
                sourceVideoPath: videoPath,
              ),
            );
          }
        } catch (_) {
          failedCount++;
        }

        completed++;
        onProgress?.call(
          FrameExtractionProgress(
            phase: 'Scouting frames…',
            progress: completed / total,
            framesExtracted: frames.length,
            totalFrames: total,
            extractedFrames: List.unmodifiable(frames),
          ),
        );
      }
    }

    await Future.wait(List.generate(concurrency, (_) => worker()));

    final failureRatio = total == 0 ? 0.0 : failedCount / total;
    if (frames.isEmpty) {
      throw VideoFrameExtractorException(
        'No frames could be extracted from this video. It may be corrupted or use an unsupported codec.',
        code: VideoFrameExtractorErrorCode.extractionGeneric,
      );
    }
    if (failureRatio > StillScoutConstants.maxFrameFailureRatio) {
      throw VideoFrameExtractorException(
        'Too many frames failed to decode (device may be low on memory). Try a shorter clip.',
        code: VideoFrameExtractorErrorCode.memoryPressure,
      );
    }

    frames.sort((a, b) => a.timestampMs.compareTo(b.timestampMs));

    onProgress?.call(
      FrameExtractionProgress(
        phase: 'Frames ready',
        progress: 1.0,
        framesExtracted: frames.length,
        totalFrames: total,
        extractedFrames: List.unmodifiable(frames),
      ),
    );

    return frames;
  }

  Future<int> _readDurationMs(String videoPath) async {
    final controller = VideoPlayerController.file(File(videoPath));
    try {
      await controller.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw VideoFrameExtractorException(
          'Timed out reading this video — it may be corrupted.',
          code: VideoFrameExtractorErrorCode.timeout,
        ),
      );
      return controller.value.duration.inMilliseconds;
    } on VideoFrameExtractorException {
      rethrow;
    } catch (_) {
      return 0;
    } finally {
      await controller.dispose();
    }
  }

  List<int> _buildTimestamps(int durationMs, {int offsetMs = 0}) {
    var intervalMs = StillScoutConstants.frameIntervalMs;
    final naiveCount = (durationMs / intervalMs).ceil();
    if (naiveCount > StillScoutConstants.maxFramesPerVideo) {
      intervalMs = (durationMs / StillScoutConstants.maxFramesPerVideo).ceil();
    }

    final timestamps = <int>[];
    for (var t = 0; t < durationMs; t += intervalMs) {
      timestamps.add(t + offsetMs);
    }
    final last = offsetMs + durationMs - 1;
    if (last > offsetMs && (timestamps.isEmpty || timestamps.last < last - 100)) {
      timestamps.add(last);
    }
    return timestamps;
  }

  Future<Directory> _createSessionDir() async {
    final tempDir = await getTemporaryDirectory();
    final sessionDir = Directory(
      '${tempDir.path}/stillscout/${DateTime.now().millisecondsSinceEpoch}',
    );
    await sessionDir.create(recursive: true);
    return sessionDir;
  }

  Future<void> _cleanupStaleSessions(Directory stillScoutRoot) async {
    try {
      if (!await stillScoutRoot.exists()) return;
      final cutoff = DateTime.now().subtract(const Duration(hours: 1));
      final entries = stillScoutRoot.listSync();
      for (final entry in entries) {
        if (entry is! Directory) continue;
        final stat = await entry.stat();
        if (stat.modified.isBefore(cutoff)) {
          await entry.delete(recursive: true);
        }
      }
    } catch (_) {}
  }
}

/// Stable, locale-independent error classification for [VideoFrameExtractorException].
///
/// Callers should switch on [code] rather than pattern-matching [message],
/// since the message text is user-facing copy and may change independently.
enum VideoFrameExtractorErrorCode {
  notFound,
  tooShort,
  timeout,
  unreadable,
  memoryPressure,
  extractionGeneric,
}

class VideoFrameExtractorException implements Exception {
  VideoFrameExtractorException(
    this.message, {
    this.code = VideoFrameExtractorErrorCode.extractionGeneric,
  });

  final String message;
  final VideoFrameExtractorErrorCode code;

  @override
  String toString() => message;
}
