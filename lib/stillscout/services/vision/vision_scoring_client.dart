import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/frame_score_metadata.dart';
import '../../domain/stillscout_constants.dart';

// ── Shared Dio instance ────────────────────────────────────────────────────

/// All vision providers share one Dio client — one connection pool, one set
/// of timeout settings, no per-provider overhead.
final sharedVisionDio = Dio(
  BaseOptions(
    connectTimeout: StillScoutConstants.scoringConnectTimeout,
    receiveTimeout: StillScoutConstants.scoringReceiveTimeout,
  ),
);

// ── System prompt ──────────────────────────────────────────────────────────

/// Identical prompt sent to every provider — consistent scoring schema
/// regardless of which AI handles the request.
const kVisionSystemPrompt = '''
You are a meticulous photo scout helping a short-form video creator pick the
single best still frame to export from their footage. You will see ONE frame.
Score it honestly and independently on four axes, each an integer 1-100
(100 = excellent, 1 = unusable):

- blur_score: sharpness/focus of the main subject. Motion blur or soft focus = low.
- lighting_score: exposure quality — penalize both underexposed (too dark) and
  blown-out highlights. Even, flattering light = high.
- open_eyes_score: if a face is visible, how open/alert/flattering the eyes and
  expression are (closed eyes, mid-blink, awkward expression = low). If no
  face is visible, judge general subject clarity and energy instead.
- composition_score: framing quality — rule of thirds, headroom, leading lines,
  background clutter, subject placement.

Respond with ONLY compact JSON, no markdown, no prose, matching exactly:
{"blur_score":<int>,"lighting_score":<int>,"open_eyes_score":<int>,"composition_score":<int>,"summary":"<one short clause, max 14 words, on why this frame stands out or falls short>"}
''';

// ── Result types ───────────────────────────────────────────────────────────

sealed class VisionScoringResult {
  const VisionScoringResult();
}

class VisionScoringSuccess extends VisionScoringResult {
  VisionScoringSuccess(this.metadata);
  final FrameScoreMetadata metadata;
}

/// Provider responded with HTTP 429 — back off and try the next provider.
class VisionScoringRateLimit extends VisionScoringResult {
  const VisionScoringRateLimit();
}

/// Provider responded with HTTP 401/403 — key is wrong; disable for session.
class VisionScoringAuthError extends VisionScoringResult {
  const VisionScoringAuthError();
}

/// Any other failure (network, timeout, bad parse, 5xx) — try next provider.
class VisionScoringFailure extends VisionScoringResult {
  const VisionScoringFailure([this.reason]);
  final String? reason;
}

// ── Abstract interface ─────────────────────────────────────────────────────

abstract interface class VisionScoringClient {
  /// Human-readable name used in debug logs (e.g. 'Groq', 'Gemini').
  String get name;

  /// Whether the provider has a valid API key configured.
  bool get isConfigured;

  /// Score one 512px base64-encoded JPEG frame.
  ///
  /// Returns a [VisionScoringResult]:
  /// - [VisionScoringSuccess] — score is ready.
  /// - [VisionScoringRateLimit] — hit quota; cascade to next provider.
  /// - [VisionScoringAuthError] — bad key; disable for session.
  /// - [VisionScoringFailure] — any other error; cascade to next provider.
  Future<VisionScoringResult> scoreFrame({required String base64Jpeg});

  /// Reset session-level circuit breakers (test hook — named clearly, no
  /// annotation needed since it's already an interface method).
  void resetForTests();
}

// ── Shared response parser ─────────────────────────────────────────────────

/// Parses a raw JSON string from any provider into [FrameScoreMetadata].
///
/// All providers use the same [kVisionSystemPrompt] and are expected to return
/// the same JSON schema. This single parser is shared so a bug fix applies
/// everywhere at once.
FrameScoreMetadata? parseVisionResponse(String raw) {
  Map<String, dynamic>? json;
  try {
    json = jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {
    final match = RegExp(r'\{[\s\S]*\}').firstMatch(raw);
    if (match == null) return null;
    try {
      json = jsonDecode(match.group(0)!) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  try {
    return FrameScoreMetadata.fromJson({
      'blurScore': json['blur_score'],
      'lightingScore': json['lighting_score'],
      'openEyesScore': json['open_eyes_score'],
      'compositionScore': json['composition_score'],
      'summary': json['summary'] is String ? json['summary'] : null,
      'source': ScoreSource.llm.name,
    });
  } catch (e) {
    debugPrint('[VisionParser] Field mapping failed: $e  raw: $raw');
    return null;
  }
}

// ── DioException → VisionScoringResult helper ─────────────────────────────

VisionScoringResult dioExceptionToResult(DioException e, String providerName) {
  final status = e.response?.statusCode;
  if (status == 401 || status == 403) {
    debugPrint('[$providerName] Auth error ($status) — disabling for session.');
    return const VisionScoringAuthError();
  }
  if (status == 429) {
    debugPrint('[$providerName] Rate-limited (429) — cascading to next provider.');
    return const VisionScoringRateLimit();
  }
  debugPrint('[$providerName] Request failed (status=$status): ${e.message}');
  return VisionScoringFailure('status=$status');
}
