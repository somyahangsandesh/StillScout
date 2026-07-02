import 'package:flutter/foundation.dart';

import '../../data/models/frame_score_metadata.dart';
import '../stillscout_cloud_quota_tracker.dart';
import 'providers/gemini_vision_client.dart';
import 'providers/groq_vision_client.dart';
import 'providers/grok_vision_client.dart';
import 'providers/openai_vision_client.dart';
import 'providers/supabase_vision_client.dart';
import 'vision_scoring_client.dart';

/// Two-tier cascade architecture:
///
/// ── Tier 1: Supabase Edge Function (Priority 0) ──────────────────────────
///   Keys live as Supabase Secrets — NEVER in the app binary.
///   The edge function runs its own Groq → Gemini → Grok → OpenAI cascade
///   server-side and enforces its own per-device daily quota (see Supabase
///   `vision-score` deployment). Direct-provider fallback uses the app-local
///   guard [StillScoutConstants.maxCloudFramesPerDeviceDay] (40 frames/day).
///   This is the production path for all users.
///
/// ── Tier 2: Direct API clients (fallback only) ────────────────────────────
///   Used when the Supabase proxy is unavailable (cold start timeout, network,
///   misconfigured). Keys come from secrets.local.dart (gitignored).
///   A device-local daily quota guard protects shared key budgets.
///   Priority order: Groq → Gemini → Grok → OpenAI
///
/// ── Tier 3: On-device fallback (caller's responsibility) ─────────────────
///   When scoreFrame() returns null, the caller uses ML Kit + heuristic.
class VisionCascadeOrchestrator {
  VisionCascadeOrchestrator()
      : _supabaseClient = SupabaseVisionClient(),
        _directProviders = [
          GroqVisionClient(),
          GeminiVisionClient(),
          GrokVisionClient(),
          OpenAiVisionClient(),
        ];

  /// Exposed for tests — inject fakes.
  VisionCascadeOrchestrator.withProviders({
    required VisionScoringClient supabaseClient,
    required List<VisionScoringClient> directProviders,
  })  : _supabaseClient = supabaseClient,
        _directProviders = directProviders;

  final VisionScoringClient _supabaseClient;
  final List<VisionScoringClient> _directProviders;
  final Map<String, _ProviderState> _states = {};

  static const Duration _rateLimitCooldown = Duration(minutes: 5);

  _ProviderState _stateFor(VisionScoringClient p) =>
      _states[p.name] ??= _ProviderState();

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Score one frame — tries Supabase proxy first, then direct providers.
  ///
  /// Returns null when all configured providers have been exhausted;
  /// callers should fall back to on-device ML Kit + heuristic.
  Future<FrameScoreMetadata?> scoreFrame({required String base64Jpeg}) async {
    // ── Tier 1: Supabase proxy ────────────────────────────────────────────
    if (_supabaseClient.isConfigured) {
      final state = _stateFor(_supabaseClient);

      if (!state.isPermanentlyDisabled && !state.isRateLimited) {
        debugPrint('[Cascade] Trying Supabase proxy…');
        final result = await _supabaseClient.scoreFrame(base64Jpeg: base64Jpeg);

        switch (result) {
          case VisionScoringSuccess(:final metadata):
            debugPrint('[Cascade] Supabase scored successfully.');
            return metadata;

          case VisionScoringRateLimit():
            // Device hit the server-side daily cap.
            // Mark as rate-limited and fall through to direct providers so the
            // user still gets some AI scoring via local keys today.
            state.markRateLimited(const Duration(hours: 24));
            debugPrint(
              '[Cascade] Supabase daily quota reached — '
              'falling through to direct providers.',
            );

          case VisionScoringAuthError():
            state.markPermanentlyDisabled();
            debugPrint(
              '[Cascade] Supabase auth error — '
              'disabled for session. Check anon key + function deployment.',
            );

          case VisionScoringFailure(:final reason):
            debugPrint('[Cascade] Supabase unavailable ($reason) — trying direct providers.');
        }
      }
    }

    // ── Tier 2: Direct API providers (with local quota guard) ─────────────
    final hasDirectProviders =
        _directProviders.any((p) => p.isConfigured);

    if (!hasDirectProviders) {
      debugPrint('[Cascade] No direct providers configured — ML Kit fallback.');
      return null;
    }

    if (!await StillScoutCloudQuotaTracker.hasRemaining()) {
      debugPrint(
        '[Cascade] Local device quota exhausted — '
        'using on-device ML Kit fallback.',
      );
      return null;
    }

    for (final provider in _directProviders) {
      if (!provider.isConfigured) continue;

      final state = _stateFor(provider);
      if (state.isPermanentlyDisabled) continue;
      if (state.isRateLimited) {
        debugPrint(
          '[Cascade] ${provider.name} still rate-limited '
          '(${state.rateLimitedFor.inSeconds}s remaining) — skipping.',
        );
        continue;
      }

      debugPrint('[Cascade] Trying ${provider.name}…');
      final result = await provider.scoreFrame(base64Jpeg: base64Jpeg);

      switch (result) {
        case VisionScoringSuccess(:final metadata):
          await StillScoutCloudQuotaTracker.tryConsumeFrame();
          debugPrint('[Cascade] ${provider.name} scored successfully.');
          return metadata;

        case VisionScoringRateLimit():
          state.markRateLimited(_rateLimitCooldown);
          debugPrint(
            '[Cascade] ${provider.name} rate-limited — '
            'cooling down for ${_rateLimitCooldown.inMinutes} min.',
          );
          continue;

        case VisionScoringAuthError():
          state.markPermanentlyDisabled();
          debugPrint(
            '[Cascade] ${provider.name} auth error — '
            'disabled for this session.',
          );
          continue;

        case VisionScoringFailure(:final reason):
          debugPrint('[Cascade] ${provider.name} failed ($reason) — trying next.');
          continue;
      }
    }

    debugPrint('[Cascade] All providers exhausted — ML Kit fallback.');
    return null;
  }

  /// Whether at least one provider is available and the device has quota left.
  Future<bool> hasAvailableProvider() async {
    // Supabase proxy — no local quota consumed, just check if it's usable
    if (_supabaseClient.isConfigured) {
      final s = _states[_supabaseClient.name];
      if (s == null || (!s.isPermanentlyDisabled && !s.isRateLimited)) {
        return true;
      }
    }

    // Direct providers — check local quota + provider health
    if (!await StillScoutCloudQuotaTracker.hasRemaining()) return false;
    return _directProviders.any((p) {
      if (!p.isConfigured) return false;
      final s = _states[p.name];
      if (s == null) return true;
      return !s.isPermanentlyDisabled && !s.isRateLimited;
    });
  }

  /// Human-readable status — useful for a debug overlay.
  String get statusSummary {
    final parts = <String>[];

    // Supabase proxy
    if (_supabaseClient.isConfigured) {
      final s = _states[_supabaseClient.name];
      if (s == null) {
        parts.add('Supabase: ready (P0)');
      } else if (s.isPermanentlyDisabled) {
        parts.add('Supabase: disabled (bad key)');
      } else if (s.isRateLimited) {
        parts.add('Supabase: daily quota reached');
      } else {
        parts.add('Supabase: ready (P0)');
      }
    } else {
      parts.add('Supabase: not configured');
    }

    // Direct providers
    for (final p in _directProviders) {
      if (!p.isConfigured) {
        parts.add('${p.name}: not configured');
        continue;
      }
      final s = _states[p.name];
      if (s == null) {
        parts.add('${p.name}: ready (fallback)');
      } else if (s.isPermanentlyDisabled) {
        parts.add('${p.name}: disabled (bad key)');
      } else if (s.isRateLimited) {
        parts.add('${p.name}: rate-limited ${s.rateLimitedFor.inSeconds}s');
      } else {
        parts.add('${p.name}: ready (fallback)');
      }
    }

    return parts.join(' | ');
  }

  /// Reset all providers — test hook.
  void resetForTests() {
    _states.clear();
    _supabaseClient.resetForTests();
    for (final p in _directProviders) {
      p.resetForTests();
    }
  }
}

// ── Per-provider rate-limit state ──────────────────────────────────────────

class _ProviderState {
  DateTime? _rateLimitedUntil;
  bool _permanentlyDisabled = false;

  bool get isPermanentlyDisabled => _permanentlyDisabled;

  bool get isRateLimited {
    if (_rateLimitedUntil == null) return false;
    return DateTime.now().isBefore(_rateLimitedUntil!);
  }

  Duration get rateLimitedFor {
    if (_rateLimitedUntil == null) return Duration.zero;
    final remaining = _rateLimitedUntil!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void markRateLimited(Duration cooldown) {
    _rateLimitedUntil = DateTime.now().add(cooldown);
  }

  void markPermanentlyDisabled() => _permanentlyDisabled = true;
}
