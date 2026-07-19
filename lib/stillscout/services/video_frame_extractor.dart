import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

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
    var endMs = (trimEndMs ?? durationMs).clamp(startMs, durationMs);
    // Cap the scouted range at the 10-minute product limit. If the user
    // did not trim a longer source, stop at max so we still cover a full
    // allowed window instead of rejecting after pick.
    final maxEnd =
        startMs + StillScoutConstants.maxVideoDurationMs;
    if (endMs > maxEnd) endMs = maxEnd.clamp(startMs, durationMs);
    final effectiveDuration = endMs - startMs;
    if (effectiveDuration > StillScoutConstants.maxVideoDurationMs) {
      throw VideoFrameExtractorException(
        'That clip is longer than 10 minutes. Trim it to 10 minutes or less, then try again.',
        code: VideoFrameExtractorErrorCode.tooLong,
      );
    }

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
          var thumbPath = await _extractThumbnail(
            videoPath: videoPath,
            sessionDir: sessionDir.path,
            timestampMs: timestampMs,
          );

          // One retry — late seeks on long clips often succeed on the
          // second attempt after the demuxer has warmed up.
          if (thumbPath == null) {
            await Future<void>.delayed(const Duration(milliseconds: 40));
            thumbPath = await _extractThumbnail(
              videoPath: videoPath,
              sessionDir: sessionDir.path,
              timestampMs: timestampMs,
            );
          }

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

    // ── Burst detection — supplement high-motion windows ──────────────────
    // Consecutive frames whose JPEG file-size ratio deviates significantly
    // indicate a rapid scene change or motion spike (complex textures compress
    // larger; heavy blur compresses smaller). Extract an additional frame at
    // the midpoint of each detected motion window so the scorer has a better
    // chance of capturing the peak of the action.
    cancelToken?.throwIfCancelled();
    final burstTimestamps = await _detectBurstTimestamps(frames);

    if (burstTimestamps.isNotEmpty) {
      onProgress?.call(
        FrameExtractionProgress(
          phase: 'Sharpening burst frames…',
          progress: 1.0,
          framesExtracted: frames.length,
          totalFrames: frames.length + burstTimestamps.length,
          extractedFrames: List.unmodifiable(frames),
        ),
      );

      for (final ts in burstTimestamps) {
        cancelToken?.throwIfCancelled();
        final thumbPath = await _extractThumbnail(
          videoPath: videoPath,
          sessionDir: sessionDir.path,
          timestampMs: ts,
        );
        if (thumbPath != null) {
          frames.add(
            ExtractedFrame(
              id: _uuid.v4(),
              filePath: thumbPath,
              timestampMs: ts,
              width: StillScoutConstants.maxFrameWidth,
              height: _estimatedHeight,
              sourceVideoPath: videoPath,
            ),
          );
        }
      }

      frames.sort((a, b) => a.timestampMs.compareTo(b.timestampMs));
    }

    onProgress?.call(
      FrameExtractionProgress(
        phase: 'Frames ready',
        progress: 1.0,
        framesExtracted: frames.length,
        totalFrames: frames.length,
        extractedFrames: List.unmodifiable(frames),
      ),
    );

    return frames;
  }

  /// Detects motion-spike windows in [frames] using JPEG file-size as a proxy
  /// for visual complexity.  Returns a list of midpoint timestamps to extract.
  ///
  /// JPEG file size correlates well with spatial frequency: sharp, complex
  /// frames (motion, detail) compress large; blurry or static frames compress
  /// small.  A large ratio change between neighbours implies a scene change or
  /// motion burst.
  Future<List<int>> _detectBurstTimestamps(List<ExtractedFrame> frames) async {
    if (frames.length < 2) return [];

    final sizes = <int>[];
    for (final f in frames) {
      try {
        sizes.add(await File(f.filePath).length());
      } catch (_) {
        sizes.add(0);
      }
    }

    // Compute mean and stddev of relative size changes between consecutive frames.
    final ratios = <double>[];
    for (var i = 0; i < sizes.length - 1; i++) {
      final a = sizes[i];
      final b = sizes[i + 1];
      if (a <= 0 || b <= 0) {
        ratios.add(0);
        continue;
      }
      ratios.add((b / a - 1.0).abs());
    }

    if (ratios.isEmpty) return [];

    final mean = ratios.reduce((a, b) => a + b) / ratios.length;
    final variance =
        ratios.map((r) => (r - mean) * (r - mean)).reduce((a, b) => a + b) /
            ratios.length;
    final stddev = math.sqrt(variance);
    // Threshold: mean + 1.5σ. Floor at 0.25 to ignore trivially small deltas.
    final threshold = math.max(mean + 1.5 * stddev, 0.25);

    final burstMidpoints = <int>[];
    for (var i = 0; i < ratios.length; i++) {
      if (ratios[i] > threshold && ratios[i] > 0.25) {
        // Only add a midpoint if the gap between frames is large enough
        // to be worth an extra sample.
        final gap =
            frames[i + 1].timestampMs - frames[i].timestampMs;
        if (gap >= StillScoutConstants.frameIntervalMs * 0.6) {
          final mid =
              frames[i].timestampMs + gap ~/ 2;
          burstMidpoints.add(mid);
        }
      }
    }

    // De-duplicate and cap at 20% of original frame count to avoid flooding.
    final cap = (frames.length * 0.2).ceil().clamp(0, 12);
    return burstMidpoints.toSet().take(cap).toList();
  }

  Future<String?> _extractThumbnail({
    required String videoPath,
    required String sessionDir,
    required int timestampMs,
  }) {
    // Pass the FULL target path including extension. The iOS plugin (0.5.x)
    // generates the filename from the VIDEO NAME when given a bare directory,
    // so every frame from the same video collides at "sessionDir/videoname.jpg".
    // Providing a path that already has a .jpg extension bypasses that logic
    // and writes directly to the unique per-timestamp path we supply.
    final framePath =
        '$sessionDir/frame_${timestampMs.toString().padLeft(10, '0')}.jpg';
    return VideoThumbnail.thumbnailFile(
      video: videoPath,
      thumbnailPath: framePath,
      timeMs: timestampMs,
      imageFormat: ImageFormat.JPEG,
      quality: StillScoutConstants.jpegQuality,
      maxWidth: StillScoutConstants.maxFrameWidth,
    );
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
  tooLong,
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
