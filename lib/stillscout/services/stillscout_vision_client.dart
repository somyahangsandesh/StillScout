import 'package:flutter/foundation.dart';

import '../data/models/frame_score_metadata.dart';
import 'vision/vision_cascade_orchestrator.dart';
import 'vision/vision_scoring_client.dart';

export 'vision/vision_cascade_orchestrator.dart' show VisionCascadeOrchestrator;
export 'vision/vision_scoring_client.dart'
    show VisionBatchResult, VisionBatchSuccess, VisionBatchFailure,
         VisionBatchFrameScore, parseBatchScoringResponse;

/// Public façade used by [FrameScoringService].
///
/// AI Pro cloud path is **Gemini Flash only** (optional Supabase proxy that
/// must also call Gemini Flash). Free users never call this — they stay on
/// Apple Vision + heuristics.
class StillScoutVisionClient {
  StillScoutVisionClient._();

  static final VisionCascadeOrchestrator _orchestrator =
      VisionCascadeOrchestrator();

  /// Score up to [StillScoutConstants.maxGridFramesPerScout] frames in a
  /// single Gemini Flash (gemini-3.1-flash-lite) call. Returns per-frame
  /// scores + the [pickCount] best indices. Primary AI Pro scoring path.
  static Future<VisionBatchResult> batchScoreFrames({
    required List<String> base64Jpegs,
    required int pickCount,
    StillScoutVideoContext videoContext = StillScoutVideoContext.auto,
  }) =>
      _orchestrator.batchScoreFrames(
        base64Jpegs: base64Jpegs,
        pickCount: pickCount,
        videoContext: videoContext,
      );

  /// Score one 512px compressed JPEG via Gemini Flash (fallback / single
  /// frame re-score path — used when batch scoring fails).
  static Future<FrameScoreMetadata?> scoreFrame({
    required String base64Jpeg,
    StillScoutVideoContext videoContext = StillScoutVideoContext.auto,
  }) =>
      _orchestrator.scoreFrame(
        base64Jpeg: base64Jpeg,
        videoContext: videoContext,
      );

  /// Whether Gemini Flash (or its Supabase proxy) is available right now.
  static Future<bool> hasAvailableProvider() =>
      _orchestrator.hasAvailableProvider();

  static String get providerStatusSummary => _orchestrator.statusSummary;

  /// True when the last [batchScoreFrames] failed due to daily cloud quota.
  static bool get lastBatchQuotaExceeded =>
      _orchestrator.lastBatchQuotaExceeded;

  @visibleForTesting
  static void resetSessionDisabledForTests() => _orchestrator.resetForTests();

  /// Test hook — simulates a Supabase/direct 429 without running a batch.
  @visibleForTesting
  static void debugSetLastBatchQuotaExceeded(bool value) {
    _orchestrator.lastBatchQuotaExceeded = value;
  }

  @visibleForTesting
  static FrameScoreMetadata? parseResponseForTests(String raw) =>
      parseVisionResponse(raw);

  @visibleForTesting
  static VisionBatchSuccess? parseBatchResponseForTests(
    String raw, {
    int? expectedFrameCount,
  }) =>
      parseBatchScoringResponse(raw, expectedFrameCount: expectedFrameCount);
}
