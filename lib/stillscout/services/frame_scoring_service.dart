import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../data/models/extracted_frame.dart';
import '../data/models/frame_score_metadata.dart';
import '../data/models/scored_frame.dart';
import '../domain/stillscout_constants.dart';
import 'face_quality_detector.dart';
import 'frame_heuristic_scorer.dart';
import 'stillscout_cancel_token.dart';
import 'stillscout_diagnostics_log.dart';
import 'stillscout_image_prep.dart';
import 'stillscout_score_cache.dart';
import 'stillscout_top_picks_selector.dart';
import 'stillscout_vision_client.dart';
import 'vision/vision_scoring_client.dart';

/// Scores extracted frames and ranks them for the gallery.
///
/// Pipeline:
/// 1. Cache lookup → heuristic pre-pass → Vision face/expression (iOS).
/// 2. Free ([useCloudAi] false): commit on-device scores — never call Gemini.
/// 3. AI Pro ([useCloudAi] true): confidence gate, then send up to
///    [StillScoutConstants.maxCloudFramesPerScout] compressed frames to
///    Gemini Flash for final scores + summary.
/// 4. Rank and flag top picks.
class FrameScoringService {
  FrameScoringService({FaceQualityDetector? faceDetector})
      : _faceDetector = faceDetector ?? const NeutralFaceQualityDetector();

  final FaceQualityDetector _faceDetector;

  Future<List<ScoredFrame>> scoreAndRankFrames(
    List<ExtractedFrame> frames, {
    required String videoPath,
    Map<String, double>? scoreWeights,
    StillScoutVideoContext videoContext = StillScoutVideoContext.auto,
    void Function(double progress)? onProgress,
    StillScoutCancelToken? cancelToken,
    bool useCloudAi = false,
    @Deprecated('Soft-degrades to Vision scores when cloud is unavailable.')
    bool requireCloudAi = false,
  }) async {
    if (frames.isEmpty) return [];

    final videoHash = await StillScoutScoreCache.videoHash(videoPath);
    final results = <String, FrameScoreMetadata>{};
    final pending = <ExtractedFrame>[];
    // Frame IDs Gemini explicitly chose as best picks, in Gemini's order
    // (best-first). List preserves pick rank for the carousel.
    final geminiPickedIds = <String>[];

    for (final frame in frames) {
      final cached =
          await StillScoutScoreCache.get(videoHash, frame.timestampMs);
      if (cached != null) {
        // For AI Pro scouts, only accept Gemini-scored cache entries (llm).
        // Vision-only (heuristic / hybrid) cached scores are rejected so the
        // frame goes through Gemini on a re-scout of the same video.
        final acceptCache =
            !useCloudAi || cached.source == ScoreSource.llm;
        if (acceptCache) {
          results[frame.id] = cached;
        } else {
          pending.add(frame);
        }
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
      cancelToken?.throwIfCancelled();
      final preScores = await compute(
        FrameHeuristicScorer.scoreFilesInIsolate,
        pending.map((f) => f.filePath).toList(growable: false),
      );

      // Run Vision analysis for all pending frames (single channel call per
      // frame — cached inside VisionFaceQualityDetector so detectOpenEyesScore
      // and detectPrimaryFaceBounds never trigger a second round-trip).
      final visionAnalyses = <String, VisionFrameAnalysis?>{};
      if (_faceDetector.isRealDetector) {
        cancelToken?.throwIfCancelled();
        await _analyzeFramesWithVision(pending, visionAnalyses, cancelToken);
      }

      final preliminary = <String, FrameScoreMetadata>{};
      for (final frame in pending) {
        final base = preScores[frame.filePath] ??
            FrameHeuristicScorer.scoreFile(frame.filePath);
        final analysis = visionAnalyses[frame.filePath];

        if (analysis == null) {
          preliminary[frame.id] = base;
          continue;
        }

        // Sharpness: prefer face-crop Laplacian when a face is present.
        // Face-crop sharpness correctly ignores background bokeh (a good thing
        // in portrait photography), while global sharpness penalises it.
        final globalBlur =
            (analysis.nativeBlurScore * 100).round().clamp(1, 100);
        final faceBlur = analysis.faceSharpnessScore >= 0
            ? (analysis.faceSharpnessScore * 100).round().clamp(1, 100)
            : null;
        final nativeBlur = faceBlur != null
            // 70% face sharpness + 30% global: rewards bokeh portraits.
            ? ((faceBlur * 0.70) + (globalBlur * 0.30)).round().clamp(1, 100)
            : globalBlur;

        // Composition: blend saliency + rule-of-thirds scores.
        // Saliency = subject isolation; rule-of-thirds = placement quality.
        int compositionScore = base.compositionScore;
        final salInt = (analysis.saliencyScore * 100).round().clamp(1, 100);
        final rotInt = (analysis.ruleOfThirdsScore * 100).round().clamp(1, 100);
        // 55% heuristic + 25% saliency + 20% rule-of-thirds.
        compositionScore = ((compositionScore * 0.55) +
                (salInt * 0.25) +
                (rotInt * 0.20))
            .round()
            .clamp(1, 100);

        preliminary[frame.id] = base.copyWith(
          openEyesScore: analysis.eyeScore,
          blurScore: nativeBlur,
          compositionScore: compositionScore,
          source: ScoreSource.hybrid,
        );
      }

      // Sort pending by Vision score descending so the non-cloud path commits
      // the best frames first and the UI can display them in order.
      pending.sort((a, b) {
        final scoreA = preliminary[a.id]?.totalScore(scoreWeights) ?? 0;
        final scoreB = preliminary[b.id]?.totalScore(scoreWeights) ?? 0;
        return scoreB.compareTo(scoreA);
      });

      if (!useCloudAi) {
        for (final frame in pending) {
          final metadata = preliminary[frame.id]!;
          results[frame.id] = metadata;
          await StillScoutScoreCache.put(
            videoHash,
            frame.timestampMs,
            metadata,
          );
          bump();
        }
      } else {
        // ── AI Pro: 3-stage Gemini pipeline ────────────────────────────────
        //
        // Stage 1 — Vision trash filter (on-device, free)
        //   Eliminates only definitively unusable frames: extreme blur or
        //   total exposure failure. Vision makes NO aesthetic judgements here.
        //   Everything visually viable survives.
        //
        // Stage 2 — Temporal sampling → Gemini batch score (1 API call)
        //   Survivors are re-sorted chronologically, then divided into equal
        //   time buckets. The best-Vision-scored frame in each bucket is chosen
        //   so Gemini sees diverse moments with per-bucket quality. One Gemini
        //   call scores all chosen frames comparatively with a category-aware
        //   prompt and selects the top [maxCloudFramesPerScout] picks.
        //
        // Stage 3 — Fallback heuristic for un-scored frames
        //   Frames not included in the batch (outside buckets) or in
        //   hard-reject list get their Vision/heuristic preliminary score.
        //   If Gemini is unavailable, Vision scores are shown with no error.

        // Stage 1: separate hard-rejects from survivors.
        final survivors   = <ExtractedFrame>[];
        final hardRejects = <ExtractedFrame>[];
        for (final frame in pending) {
          final meta = preliminary[frame.id]!;
          // Hard-reject when EITHER blur OR lighting is below threshold —
          // an extremely blurry frame is unusable regardless of exposure, and
          // a completely dark frame is unusable regardless of sharpness.
          if (meta.blurScore    <= StillScoutConstants.visionRejectBlurThreshold ||
              meta.lightingScore <= StillScoutConstants.visionRejectLightingThreshold) {
            hardRejects.add(frame);
          } else {
            survivors.add(frame);
          }
        }

        // Commit hard-rejects with their Vision preliminary scores.
        for (final frame in hardRejects) {
          final metadata = preliminary[frame.id]!;
          results[frame.id] = metadata;
          await StillScoutScoreCache.put(videoHash, frame.timestampMs, metadata);
          bump();
        }

        // Stage 2: temporal-bucket sampling → Gemini batch call.
        var batchSucceeded = false;
        // Pre-detect context from Vision scores so Gemini receives the right
        // category-aware prompt even when the user left the picker on "Auto".
        var effectiveContext = videoContext;
        if (videoContext == StillScoutVideoContext.auto && survivors.isNotEmpty) {
          final sample = survivors.take(survivors.length.clamp(1, 30)).toList();
          final n = sample.length;
          final meanEyes = sample
                  .map((f) => preliminary[f.id]!.openEyesScore.toDouble())
                  .reduce((a, b) => a + b) /
              n;
          final meanComp = sample
                  .map((f) => preliminary[f.id]!.compositionScore.toDouble())
                  .reduce((a, b) => a + b) /
              n;
          if (meanEyes > 60) {
            effectiveContext = StillScoutVideoContext.portrait;
          } else if (meanComp > 65 && meanEyes < 45) {
            effectiveContext = StillScoutVideoContext.landscape;
          }
        }

        if (survivors.isNotEmpty &&
            await StillScoutVisionClient.hasAvailableProvider()) {
          cancelToken?.throwIfCancelled();

          // Re-sort survivors chronologically before temporal sampling.
          // (pending was pre-sorted by Vision score for the non-cloud path.)
          survivors.sort((a, b) => a.timestampMs.compareTo(b.timestampMs));

          // Build a temporally-diverse sample: divide survivors into
          // maxGridFramesPerScout equal time buckets and pick the best-Vision-
          // scored frame from each bucket so Gemini sees diverse moments.
          final batchTargets = _temporalSample(
            survivors,
            StillScoutConstants.maxGridFramesPerScout,
            preliminary,
          );

          // Prepare 384px thumbnails in an isolate.
          final gridPayloads = await compute(
            StillScoutImagePrep.prepareGridThumbnails,
            batchTargets.map((f) => f.filePath).toList(growable: false),
          );

          final orderedJpegs = <String>[];
          final orderedFrames = <ExtractedFrame>[];
          for (final frame in batchTargets) {
            final jpeg = gridPayloads[frame.filePath];
            if (jpeg != null) {
              orderedJpegs.add(jpeg);
              orderedFrames.add(frame);
            }
          }

          if (orderedJpegs.isNotEmpty) {
            final pickCount = math.min(
              StillScoutConstants.maxCloudFramesPerScout,
              orderedFrames.length,
            );

            // Simulate incremental progress while Gemini processes.
            // Real bump() calls resume once scored frames are committed.
            final progressAtBatchStart =
                total > 0 ? processed / total : 0.0;
            var simulatedP = progressAtBatchStart;
            final batchTick = Timer.periodic(
              const Duration(milliseconds: 400),
              (_) {
                final remaining = 0.88 - simulatedP;
                if (remaining <= 0) return;
                simulatedP += remaining * 0.12;
                onProgress?.call(simulatedP.clamp(progressAtBatchStart, 0.88));
              },
            );

            late final VisionBatchResult batchResult;
            try {
              batchResult = await StillScoutVisionClient.batchScoreFrames(
                base64Jpegs: orderedJpegs,
                pickCount: pickCount,
                videoContext: effectiveContext,
              );
            } finally {
              // Always cancel the timer, even when batchScoreFrames throws.
              batchTick.cancel();
            }

            if (batchResult is VisionBatchSuccess) {
              batchSucceeded = true;

              // Record Gemini's explicit top picks by frame ID (best-first).
              for (final pickIdx in batchResult.picks) {
                if (pickIdx >= 0 && pickIdx < orderedFrames.length) {
                  final id = orderedFrames[pickIdx].id;
                  if (!geminiPickedIds.contains(id)) {
                    geminiPickedIds.add(id);
                  }
                }
              }

              // Commit Gemini scores for every frame it scored.
              for (final entry in batchResult.scores.entries) {
                final idx = entry.key;
                if (idx < 0 || idx >= orderedFrames.length) continue;
                final frame    = orderedFrames[idx];
                final gs       = entry.value;
                final analysis = visionAnalyses[frame.filePath];

                // Blend Gemini's blur score with Vision's face-crop sharpness
                // when available — Vision's pixel-level measurement is more
                // accurate than Gemini's perceptual estimate from a thumbnail.
                final finalBlur = analysis == null
                    ? gs.blurScore
                    : analysis.faceSharpnessScore >= 0
                        ? ((analysis.faceSharpnessScore * 0.65 +
                                    analysis.nativeBlurScore * 0.20 +
                                    gs.blurScore / 100.0 * 0.15) *
                                100)
                            .round()
                            .clamp(1, 100)
                        : ((analysis.nativeBlurScore * 0.75 +
                                    gs.blurScore / 100.0 * 0.25) *
                                100)
                            .round()
                            .clamp(1, 100);

                // Blend Gemini's expression score with Vision's richer eye
                // measurement — Vision tracks faceCaptureQuality + pose.
                final finalEyes = analysis == null
                    ? gs.openEyesScore
                    : ((gs.openEyesScore * 0.60 + analysis.eyeScore * 0.40) / 1)
                        .round()
                        .clamp(1, 100);

                // Always use ScoreSource.llm for Gemini-scored frames,
                // even when Vision also contributed to blur/eye axes.
                // This makes "did Gemini run?" detectable via source alone.
                final finalMeta = FrameScoreMetadata(
                  blurScore:        finalBlur,
                  lightingScore:    gs.lightingScore,
                  openEyesScore:    finalEyes,
                  compositionScore: gs.compositionScore,
                  summary:          gs.summary,
                  source:           ScoreSource.llm,
                );
                results[frame.id] = finalMeta;
                await StillScoutScoreCache.put(
                  videoHash,
                  frame.timestampMs,
                  finalMeta,
                );
                bump();
              }

              // Commit preliminary Vision scores for batch frames Gemini
              // didn't explicitly score (sparse response edge case).
              for (final frame in orderedFrames) {
                if (!results.containsKey(frame.id)) {
                  final metadata = preliminary[frame.id]!;
                  results[frame.id] = metadata;
                  await StillScoutScoreCache.put(
                    videoHash,
                    frame.timestampMs,
                    metadata,
                  );
                  bump();
                }
              }
            }
          }

          // Commit preliminary scores for survivors not included in the batch.
          final batchIds = {for (final f in orderedFrames) f.id};
          for (final frame in survivors) {
            if (!batchIds.contains(frame.id) && !results.containsKey(frame.id)) {
              final metadata = preliminary[frame.id]!;
              results[frame.id] = metadata;
              await StillScoutScoreCache.put(videoHash, frame.timestampMs, metadata);
              bump();
            }
          }
        }

        if (!batchSucceeded) {
          // Soft-degrade: whether cloud AI was required or optional, Gemini
          // being unavailable never crashes the scout — commit each
          // survivor's Vision/heuristic preliminary score instead so the
          // user always gets a completed gallery (W1.2).
          StillScoutDiagnosticsLog.log(
            'Scoring',
            'Cloud batch unavailable — soft-degrading ${survivors.length} '
            'survivor(s) to Vision scores.',
          );
          for (final frame in survivors) {
            if (!results.containsKey(frame.id)) {
              final metadata = preliminary[frame.id]!;
              results[frame.id] = metadata;
              await StillScoutScoreCache.put(videoHash, frame.timestampMs, metadata);
              bump();
            }
          }
        }
      }
    }

    cancelToken?.throwIfCancelled();

    // ── Audio-sync boost ────────────────────────────────────────────────────
    // Frames that coincide with audio energy peaks (music beats / speech
    // onsets) tend to be more expressive and worthy of selection.  Boost
    // their composition score by up to 8 points — enough to break ties
    // without overriding genuine quality signals.
    Map<int, double> audioPeaks = {};
    final vd = _faceDetector;
    if (vd is VisionFaceQualityDetector) {
      try {
        audioPeaks = await vd.analyzeAudioPeaks(videoPath);
      } catch (_) {
        audioPeaks = {};
      }
    }

    // Signal 100% only after audio analysis is complete so the progress bar
    // reaches its final position at the same moment results appear.
    onProgress?.call(1.0);

    final scored = frames
        .map((frame) {
          var metadata = results[frame.id] ??
              FrameHeuristicScorer.scoreFile(frame.filePath);

          // Apply audio-sync boost when a peak falls within ±400 ms.
          if (audioPeaks.isNotEmpty) {
            final ts = frame.timestampMs;
            double bestPeakEnergy = 0;
            for (final entry in audioPeaks.entries) {
              if ((entry.key - ts).abs() <= 400) {
                bestPeakEnergy =
                    math.max(bestPeakEnergy, entry.value);
              }
            }
            if (bestPeakEnergy > 0) {
              final boost = (bestPeakEnergy * 8).round().clamp(1, 8);
              metadata = metadata.copyWith(
                compositionScore:
                    (metadata.compositionScore + boost).clamp(1, 100),
              );
            }
          }

          return ScoredFrame(
            frame: frame,
            score: metadata.totalScore(scoreWeights),
            metadata: metadata,
          );
        })
        .toList(growable: false);

    scored.sort((a, b) => b.score.compareTo(a.score));
    if (scored.isEmpty) return scored;

    // Determine top picks:
    // • AI Pro: Gemini explicitly chose [geminiPickedIds] — mark ALL of them as
    //   top scouts with geminiPickRank for carousel order.
    // • Free / Gemini unavailable: fall back to the score-based diversity selector.
    final Map<String, int> geminiRankById = {
      for (var i = 0; i < geminiPickedIds.length; i++) geminiPickedIds[i]: i,
    };
    final Set<String> topPickIds;
    if (geminiRankById.isNotEmpty) {
      topPickIds = geminiRankById.keys.toSet();
    } else {
      final fallback = StillScoutTopPicksSelector.select(scored);
      topPickIds = fallback.map((f) => f.frame.id).toSet();
    }

    return scored
        .map(
          (item) => topPickIds.contains(item.frame.id)
              ? item.copyWith(
                  isTopScout: true,
                  geminiPickRank: geminiRankById[item.frame.id],
                )
              : item,
        )
        .toList(growable: false);
  }

  /// Runs Vision on all [frames] concurrently (2 workers), storing full
  /// [VisionFrameAnalysis] results in [analyses]. The VisionFaceQualityDetector
  /// caches each result internally so follow-up calls (e.g. detectPrimaryFaceBounds
  /// during export) never fire a second channel round-trip.
  Future<void> _analyzeFramesWithVision(
    List<ExtractedFrame> frames,
    Map<String, VisionFrameAnalysis?> analyses,
    StillScoutCancelToken? cancelToken,
  ) async {
    // Cast once for Vision-specific cache clearing.
    final visionDetector =
        _faceDetector is VisionFaceQualityDetector ? _faceDetector : null;

    visionDetector?.clearCache();

    const maxConcurrent = 2;
    var nextIndex = 0;

    Future<void> worker() async {
      while (true) {
        cancelToken?.throwIfCancelled();
        final index = nextIndex;
        if (index >= frames.length) return;
        nextIndex = index + 1;
        final frame = frames[index];
        analyses[frame.filePath] =
            await _faceDetector.analyzeFrame(frame.filePath);
      }
    }

    final workerCount =
        maxConcurrent < frames.length ? maxConcurrent : frames.length;
    if (workerCount > 0) {
      await Future.wait(List.generate(workerCount, (_) => worker()));
    }
  }

  /// Selects up to [maxCount] frames from [chronologicalFrames] with even
  /// temporal spread. [chronologicalFrames] MUST be sorted by timestamp.
  ///
  /// Divides the timeline into [maxCount] equal buckets and picks the
  /// best-Vision-scored frame from each bucket, so Gemini sees the strongest
  /// candidate from every moment of the video — not just the frames Vision
  /// happened to rate highest overall.
  static List<ExtractedFrame> _temporalSample(
    List<ExtractedFrame> chronologicalFrames,
    int maxCount,
    Map<String, FrameScoreMetadata> preliminary,
  ) {
    if (chronologicalFrames.length <= maxCount) {
      return List.of(chronologicalFrames);
    }

    final bucketSize = chronologicalFrames.length / maxCount;
    final result = <ExtractedFrame>[];

    for (var b = 0; b < maxCount; b++) {
      // Use round-trip integer boundaries so adjacent buckets are strictly
      // non-overlapping: bucket b covers [b*size, (b+1)*size).
      final start = (b * bucketSize).round();
      final end = math.min(
        ((b + 1) * bucketSize).round(),
        chronologicalFrames.length,
      );
      if (start >= end) continue;
      final bucket = chronologicalFrames.sublist(start, end);
      // Pick the best-Vision-scored frame in this time window.
      final best = bucket.reduce((a, b) {
        final sa = preliminary[a.id]?.totalScore() ?? 0;
        final sb = preliminary[b.id]?.totalScore() ?? 0;
        return sa >= sb ? a : b;
      });
      result.add(best);
    }

    return result;
  }
}

