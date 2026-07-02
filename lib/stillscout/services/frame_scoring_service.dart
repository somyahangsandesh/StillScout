import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../data/models/extracted_frame.dart';
import '../data/models/frame_score_metadata.dart';
import '../data/models/scored_frame.dart';
import '../domain/failures/stillscout_failure.dart';
import '../domain/stillscout_constants.dart';
import 'face_quality_detector.dart';
import 'frame_heuristic_scorer.dart';
import 'stillscout_cancel_token.dart';
import 'stillscout_cloud_quota_tracker.dart';
import 'stillscout_image_prep.dart';
import 'stillscout_score_cache.dart';
import 'stillscout_top_picks_selector.dart';
import 'stillscout_vision_client.dart';

/// Scores extracted frames and ranks them for the gallery.
///
/// Pipeline per batch:
/// 1. Look up each frame in the on-disk cache (keyed by sampled video hash +
///    timestamp) — re-opening a video you already scouted, or retrying a
///    batch that partially failed, never re-spends API calls.
/// 2. Run a fast on-device heuristic pre-pass on cache misses and **sort by
///    pre-score descending** so limited cloud-AI quota is spent on the frames
///    most likely to be keepers — not the first N chronological shots (which
///    are often intro blur / setup frames).
/// 3. For cache misses, score concurrently via [StillScoutVisionClient] when
///    a provider is available.
/// 4. When [requireCloudAi] is false, anything that fails falls back to the
///    pre-pass heuristic scores. Production scouts pass [requireCloudAi: true]
///    so offline / failed AI runs surface an error instead of silent estimates.
/// 4. For heuristic-scored frames, if a real [FaceQualityDetector] is
///    provided ([FaceQualityDetector.isRealDetector] == true), the open-eyes
///    axis is replaced with an ML Kit on-device measurement. This cannot run
///    inside a Dart isolate (platform channel constraint), so it executes on
///    the main isolate after the `compute()`-based heuristic pass completes.
///    Updated scores are written back to the cache.
/// 5. Frames are ranked by weighted total and the top picks are flagged
///    `isTopScout`.
class FrameScoringService {
  FrameScoringService({FaceQualityDetector? faceDetector})
      : _faceDetector = faceDetector ?? const NeutralFaceQualityDetector();

  final FaceQualityDetector _faceDetector;

  Future<List<ScoredFrame>> scoreAndRankFrames(
    List<ExtractedFrame> frames, {
    required String videoPath,
    Map<String, double>? scoreWeights,
    void Function(double progress)? onProgress,
    StillScoutCancelToken? cancelToken,
    bool requireCloudAi = false,
  }) async {
    if (frames.isEmpty) return [];

    final videoHash = await StillScoutScoreCache.videoHash(videoPath);
    final results = <String, FrameScoreMetadata>{};
    final pending = <ExtractedFrame>[];

    for (final frame in frames) {
      final cached = await StillScoutScoreCache.get(videoHash, frame.timestampMs);
      if (cached != null) {
        results[frame.id] = cached;
      } else {
        pending.add(frame);
      }
    }

    final total = pending.length;
    var processed = 0;
    void bump() {
      processed++;
      if (total > 0) onProgress?.call(processed / total);
    }

    if (total == 0) {
      onProgress?.call(1.0);
    } else {
      final needsHeuristic = <ExtractedFrame>[];

      // Fast pre-pass — used for AI prioritization and as the fallback score
      // so we never scan pixels twice for frames that miss cloud AI.
      cancelToken?.throwIfCancelled();
      final preScores = await compute(
        FrameHeuristicScorer.scoreFilesInIsolate,
        pending.map((f) => f.filePath).toList(growable: false),
      );
      pending.sort((a, b) {
        final scoreA = preScores[a.filePath]?.totalScore(scoreWeights) ?? 0;
        final scoreB = preScores[b.filePath]?.totalScore(scoreWeights) ?? 0;
        return scoreB.compareTo(scoreA);
      });

      // Run LLM phase if any provider has a configured key AND is not
      // currently rate-limited. This avoids burning time on image prep when
      // all providers are known to be exhausted for this session.
      final llmPhaseRan = await StillScoutVisionClient.hasAvailableProvider();

      var cloudSucceeded = 0;
      var cloudCap = 0;

      if (llmPhaseRan) {
        cancelToken?.throwIfCancelled();
        final quotaLeft = await StillScoutCloudQuotaTracker.remainingToday();
        cloudCap = math.min(
          StillScoutConstants.maxCloudFramesPerScout,
          math.min(quotaLeft, pending.length),
        );
        final cloudTargets = pending.take(cloudCap).toList(growable: false);
        if (cloudCap < pending.length) {
          needsHeuristic.addAll(pending.skip(cloudCap));
        }

        final payloads = await compute(
          StillScoutImagePrep.prepareUploadPayloads,
          cloudTargets.map((f) => f.filePath).toList(growable: false),
        );

        await _runWithConcurrency<ExtractedFrame>(
          cloudTargets,
          maxConcurrency: StillScoutConstants.maxConcurrentScoringRequests,
          cancelToken: cancelToken,
          action: (frame) async {
            final payload = payloads[frame.filePath];
            if (payload == null) {
              needsHeuristic.add(frame);
              bump();
              return;
            }
            final metadata = await StillScoutVisionClient.scoreFrame(base64Jpeg: payload);
            if (metadata != null) {
              cloudSucceeded++;
              results[frame.id] = metadata;
              await StillScoutScoreCache.put(videoHash, frame.timestampMs, metadata);
            } else {
              needsHeuristic.add(frame);
            }
            bump();
          },
        );
      } else {
        needsHeuristic.addAll(pending);
      }

      if (requireCloudAi) {
        if (pending.isNotEmpty && !llmPhaseRan) {
          final hasQuota = await StillScoutCloudQuotaTracker.hasRemaining();
          throw ScoringFailure(
            hasQuota
                ? 'AI scoring is unavailable — check your internet connection and try again.'
                : 'Daily AI scouting limit reached on this device. Try again tomorrow.',
          );
        }
        if (llmPhaseRan && cloudCap > 0 && cloudSucceeded == 0) {
          throw const ScoringFailure(
            'AI couldn\'t finish scoring your frames — check your connection and try again.',
          );
        }
      }

      if (needsHeuristic.isNotEmpty) {
        cancelToken?.throwIfCancelled();

        for (final frame in needsHeuristic) {
          final metadata = preScores[frame.filePath] ??
              FrameHeuristicScorer.scoreFile(frame.filePath);
          if (!llmPhaseRan) bump();
          results[frame.id] = metadata;
        }

        if (!_faceDetector.isRealDetector) {
          for (final frame in needsHeuristic) {
            final metadata = results[frame.id];
            if (metadata != null) {
              await StillScoutScoreCache.put(
                  videoHash, frame.timestampMs, metadata);
            }
          }
        }
      }
    }

    cancelToken?.throwIfCancelled();
    onProgress?.call(1.0);

    // ML Kit eyes on every frame when available — not just heuristic fallbacks.
    if (_faceDetector.isRealDetector) {
      cancelToken?.throwIfCancelled();
      await _runFaceDetectionPhase(
        frames,
        results,
        videoHash,
        cancelToken,
      );
    }

    final scored = frames
        .map((frame) {
          final metadata = results[frame.id] ??
              FrameHeuristicScorer.scoreFile(frame.filePath);
          return ScoredFrame(
            frame: frame,
            score: metadata.totalScore(scoreWeights),
            metadata: metadata,
          );
        })
        .toList(growable: false);

    scored.sort((a, b) => b.score.compareTo(a.score));
    if (scored.isEmpty) return scored;

    final topPicks = StillScoutTopPicksSelector.select(scored);
    final topPickIds = topPicks.map((f) => f.frame.id).toSet();
    return scored
        .map((item) => topPickIds.contains(item.frame.id)
            ? item.copyWith(isTopScout: true)
            : item)
        .toList(growable: false);
  }

  /// Runs ML Kit face detection on each heuristic frame and upgrades the
  /// open-eyes score in [results]. Frames where no face is detected keep their
  /// neutral baseline (68). Updated metadata is cached immediately.
  Future<void> _runFaceDetectionPhase(
    List<ExtractedFrame> frames,
    Map<String, FrameScoreMetadata> results,
    String videoHash,
    StillScoutCancelToken? cancelToken,
  ) async {
    // Face detection is fast on-device (~50-150 ms/frame) but sequential is
    // safest to avoid overwhelming the ML Kit native thread pool on older
    // devices. If profiling shows a bottleneck, raise this cap to 3-4.
    const maxConcurrent = 2;
    final queue = List<ExtractedFrame>.from(frames);

    Future<void> worker() async {
      while (queue.isNotEmpty) {
        cancelToken?.throwIfCancelled();
        final frame = queue.removeAt(0);
        final base = results[frame.id];
        if (base == null) continue;

        final eyeScore = await _faceDetector.detectOpenEyesScore(frame.filePath);

        // Only upgrade if ML Kit actually found a face; null means "no face"
        // (landscape shot, object video, etc.) — keep the neutral 68 in that
        // case so the heuristic axes still drive ranking.
        final upgraded = eyeScore != null
            ? base.copyWith(
                openEyesScore: eyeScore,
                source: ScoreSource.hybrid,
              )
            : base;

        results[frame.id] = upgraded;
        await StillScoutScoreCache.put(videoHash, frame.timestampMs, upgraded);
      }
    }

    final workerCount = maxConcurrent < frames.length ? maxConcurrent : frames.length;
    if (workerCount > 0) {
      await Future.wait(List.generate(workerCount, (_) => worker()));
    }
  }
}

/// Minimal bounded-concurrency runner — caps simultaneous network requests
/// without pulling in a dedicated pool/queue package for one use site.
Future<void> _runWithConcurrency<T>(
  List<T> items, {
  required int maxConcurrency,
  required Future<void> Function(T item) action,
  StillScoutCancelToken? cancelToken,
}) async {
  final queue = List<T>.from(items);
  final workerCount = maxConcurrency < queue.length ? maxConcurrency : queue.length;

  Future<void> worker() async {
    while (queue.isNotEmpty) {
      cancelToken?.throwIfCancelled();
      final item = queue.removeAt(0);
      await action(item);
    }
  }

  await Future.wait(List.generate(workerCount, (_) => worker()));
}
