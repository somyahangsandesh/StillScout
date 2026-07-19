import '../../data/models/frame_score_metadata.dart';
import '../stillscout_cloud_quota_tracker.dart';
import '../stillscout_diagnostics_log.dart';
import 'providers/gemini_vision_client.dart';
import 'providers/supabase_vision_client.dart';
import 'vision_scoring_client.dart';

/// Gemini Flash cloud scoring for AI Pro.
///
/// Production path (release builds):
/// 1. Supabase Edge Function `vision-score` — batch + single, server-side keys.
/// 2. Direct [GeminiVisionClient] only when client keys are allowed (debug).
///
/// Free users never reach this path.
class VisionCascadeOrchestrator {
  VisionCascadeOrchestrator()
      : _supabaseClient = SupabaseVisionClient(),
        _geminiClient = GeminiVisionClient();

  VisionCascadeOrchestrator.withProviders({
    required VisionScoringClient supabaseClient,
    required VisionScoringClient geminiClient,
  })  : _supabaseClient = supabaseClient,
        _geminiClient = geminiClient;

  final VisionScoringClient _supabaseClient;
  final VisionScoringClient _geminiClient;
  final Map<String, _ProviderState> _states = {};

  static const Duration _rateLimitCooldown = Duration(minutes: 5);

  _ProviderState _stateFor(VisionScoringClient p) =>
      _states[p.name] ??= _ProviderState();

  /// Score [base64Jpegs] in one call — Supabase proxy first (release-safe),
  /// then direct Gemini when a debug client key is available.
  Future<VisionBatchResult> batchScoreFrames({
    required List<String> base64Jpegs,
    required int pickCount,
    StillScoutVideoContext videoContext = StillScoutVideoContext.auto,
  }) async {
    // ── Supabase batch (production) ───────────────────────────────────────
    if (_supabaseClient.isConfigured) {
      final state = _stateFor(_supabaseClient);
      if (!state.isPermanentlyDisabled && !state.isRateLimited) {
        StillScoutDiagnosticsLog.log(
          'Gemini',
          'Trying Supabase batch (${base64Jpegs.length} frames)…',
        );
        final result = await _supabaseClient.batchScoreFrames(
          base64Jpegs: base64Jpegs,
          pickCount: pickCount,
          videoContext: videoContext,
        );

        switch (result) {
          case VisionBatchSuccess():
            StillScoutDiagnosticsLog.log('Gemini', 'Supabase batch succeeded.');
            return result;
          case VisionBatchRateLimit():
            // Short cooldown — a 24h lockout bricks a demo device after one 429.
            state.markRateLimited(const Duration(minutes: 5));
            StillScoutDiagnosticsLog.log('Gemini', 'Supabase batch quota reached.');
          case VisionBatchAuthError():
            state.markPermanentlyDisabled();
            StillScoutDiagnosticsLog.log('Gemini', 'Supabase batch auth error.');
          case VisionBatchFailure(:final reason):
            StillScoutDiagnosticsLog.log('Gemini', 'Supabase batch failed ($reason).');
        }
      }
    }

    // ── Direct Gemini (debug / ALLOW_DIRECT_AI_KEYS only) ─────────────────
    if (!_geminiClient.isConfigured) {
      StillScoutDiagnosticsLog.log(
        'Gemini',
        'Batch unavailable — no Supabase or direct key.',
      );
      return const VisionBatchFailure('not configured');
    }

    final remaining = await StillScoutCloudQuotaTracker.remainingToday();
    if (remaining < pickCount) {
      StillScoutDiagnosticsLog.log(
        'Gemini',
        'Device quota insufficient ($remaining < $pickCount).',
      );
      return const VisionBatchFailure('quota exhausted');
    }

    final geminiState = _stateFor(_geminiClient);
    if (geminiState.isPermanentlyDisabled) {
      return const VisionBatchFailure('permanently disabled');
    }
    if (geminiState.isRateLimited) {
      return const VisionBatchFailure('rate limited');
    }

    StillScoutDiagnosticsLog.log(
      'Gemini',
      'Direct batch scoring ${base64Jpegs.length} frames…',
    );
    final result = await _geminiClient.batchScoreFrames(
      base64Jpegs: base64Jpegs,
      pickCount: pickCount,
      videoContext: videoContext,
    );

    switch (result) {
      case VisionBatchSuccess():
        for (var i = 0; i < pickCount; i++) {
          await StillScoutCloudQuotaTracker.tryConsumeFrame();
        }
        StillScoutDiagnosticsLog.log('Gemini', 'Direct batch succeeded.');
        return result;
      case VisionBatchRateLimit():
        geminiState.markRateLimited(_rateLimitCooldown);
        return result;
      case VisionBatchAuthError():
        geminiState.markPermanentlyDisabled();
        return result;
      case VisionBatchFailure():
        return result;
    }
  }

  Future<FrameScoreMetadata?> scoreFrame({
    required String base64Jpeg,
    StillScoutVideoContext videoContext = StillScoutVideoContext.auto,
  }) async {
    if (_supabaseClient.isConfigured) {
      final state = _stateFor(_supabaseClient);
      if (!state.isPermanentlyDisabled && !state.isRateLimited) {
        StillScoutDiagnosticsLog.log('Gemini', 'Trying Supabase Gemini proxy…');
        final result = await _supabaseClient.scoreFrame(
          base64Jpeg: base64Jpeg,
          videoContext: videoContext,
        );

        switch (result) {
          case VisionScoringSuccess(:final metadata):
            StillScoutDiagnosticsLog.log('Gemini', 'Supabase proxy scored successfully.');
            return metadata;
          case VisionScoringRateLimit():
            state.markRateLimited(const Duration(minutes: 5));
            StillScoutDiagnosticsLog.log('Gemini', 'Supabase daily quota reached.');
          case VisionScoringAuthError():
            state.markPermanentlyDisabled();
            StillScoutDiagnosticsLog.log('Gemini', 'Supabase auth error.');
          case VisionScoringFailure(:final reason):
            StillScoutDiagnosticsLog.log('Gemini', 'Supabase unavailable ($reason).');
        }
      }
    }

    if (!_geminiClient.isConfigured) {
      StillScoutDiagnosticsLog.log('Gemini', 'Not configured — on-device fallback.');
      return null;
    }

    if (!await StillScoutCloudQuotaTracker.hasRemaining()) {
      StillScoutDiagnosticsLog.log('Gemini', 'Local device quota exhausted.');
      return null;
    }

    final state = _stateFor(_geminiClient);
    if (state.isPermanentlyDisabled) return null;
    if (state.isRateLimited) {
      StillScoutDiagnosticsLog.log(
        'Gemini',
        'Still rate-limited (${state.rateLimitedFor.inSeconds}s remaining).',
      );
      return null;
    }

    StillScoutDiagnosticsLog.log('Gemini', 'Trying direct Gemini…');
    final result = await _geminiClient.scoreFrame(
      base64Jpeg: base64Jpeg,
      videoContext: videoContext,
    );

    switch (result) {
      case VisionScoringSuccess(:final metadata):
        await StillScoutCloudQuotaTracker.tryConsumeFrame();
        StillScoutDiagnosticsLog.log('Gemini', 'Direct Gemini scored successfully.');
        return metadata;
      case VisionScoringRateLimit():
        state.markRateLimited(_rateLimitCooldown);
        return null;
      case VisionScoringAuthError():
        state.markPermanentlyDisabled();
        return null;
      case VisionScoringFailure(:final reason):
        StillScoutDiagnosticsLog.log('Gemini', 'Failed ($reason).');
        return null;
    }
  }

  /// True when batch scoring can run: Supabase proxy configured, or a direct
  /// Gemini key is available with local quota remaining.
  Future<bool> hasAvailableProvider() async {
    if (_supabaseClient.isConfigured) {
      final s = _states[_supabaseClient.name];
      if (s == null || (!s.isPermanentlyDisabled && !s.isRateLimited)) {
        return true;
      }
    }

    if (!_geminiClient.isConfigured) return false;
    if (!await StillScoutCloudQuotaTracker.hasRemaining()) return false;
    final s = _states[_geminiClient.name];
    if (s == null) return true;
    return !s.isPermanentlyDisabled && !s.isRateLimited;
  }

  String get statusSummary {
    final parts = <String>[];
    if (_supabaseClient.isConfigured) {
      final s = _states[_supabaseClient.name];
      if (s == null) {
        parts.add('Supabase Gemini: ready');
      } else if (s.isPermanentlyDisabled) {
        parts.add('Supabase Gemini: disabled');
      } else if (s.isRateLimited) {
        parts.add('Supabase Gemini: quota reached');
      } else {
        parts.add('Supabase Gemini: ready');
      }
    } else {
      parts.add('Supabase Gemini: not configured');
    }

    if (_geminiClient.isConfigured) {
      final s = _states[_geminiClient.name];
      if (s == null) {
        parts.add('Direct Gemini: ready (debug)');
      } else if (s.isPermanentlyDisabled) {
        parts.add('Direct Gemini: disabled');
      } else if (s.isRateLimited) {
        parts.add('Direct Gemini: rate-limited');
      } else {
        parts.add('Direct Gemini: ready (debug)');
      }
    } else {
      parts.add('Direct Gemini: not configured');
    }

    return parts.join(' · ');
  }

  void resetForTests() {
    _states.clear();
    _supabaseClient.resetForTests();
    _geminiClient.resetForTests();
  }
}

class _ProviderState {
  bool isPermanentlyDisabled = false;
  DateTime? _rateLimitedUntil;

  bool get isRateLimited =>
      _rateLimitedUntil != null && DateTime.now().isBefore(_rateLimitedUntil!);

  Duration get rateLimitedFor {
    if (_rateLimitedUntil == null) return Duration.zero;
    final remaining = _rateLimitedUntil!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void markRateLimited(Duration cooldown) {
    _rateLimitedUntil = DateTime.now().add(cooldown);
  }

  void markPermanentlyDisabled() => isPermanentlyDisabled = true;
}
