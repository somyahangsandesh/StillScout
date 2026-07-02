import 'package:flutter/foundation.dart';

import '../data/models/frame_score_metadata.dart';
import 'vision/vision_cascade_orchestrator.dart';
import 'vision/vision_scoring_client.dart';

export 'vision/vision_cascade_orchestrator.dart' show VisionCascadeOrchestrator;

/// Public façade used by [FrameScoringService].
///
/// Delegates to [VisionCascadeOrchestrator]:
///
///   **P0** Supabase Edge Function proxy (keys server-side, daily device quota)
///   → **fallback** Groq → Gemini → Grok → OpenAI (local keys + device quota)
///   → null (caller uses ML Kit + heuristic)
class StillScoutVisionClient {
  StillScoutVisionClient._();

  static final VisionCascadeOrchestrator _orchestrator =
      VisionCascadeOrchestrator();

  /// Score one 512px base64 JPEG frame via the provider cascade.
  /// Returns null when all configured providers are exhausted — the caller
  /// should fall back to on-device ML Kit + heuristic scoring.
  static Future<FrameScoreMetadata?> scoreFrame({
    required String base64Jpeg,
  }) =>
      _orchestrator.scoreFrame(base64Jpeg: base64Jpeg);

  /// Whether at least one provider is currently available (configured + not
  /// rate-limited). Use this to decide whether to attempt the LLM phase at
  /// all — if false, skip straight to heuristic to save time.
  static Future<bool> hasAvailableProvider() =>
      _orchestrator.hasAvailableProvider();

  /// Debug string showing every provider's current state.
  static String get providerStatusSummary => _orchestrator.statusSummary;

  /// Test-only: reset the session-disabled circuit breaker on the OpenAI
  /// provider (keeps existing test signatures working).
  @visibleForTesting
  static void resetSessionDisabledForTests() => _orchestrator.resetForTests();

  /// Test-only: exercise the same JSON parsing path used by [scoreFrame].
  @visibleForTesting
  static FrameScoreMetadata? parseResponseForTests(String raw) =>
      parseVisionResponse(raw);
}
