import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/frame_score_metadata.dart';
import '../../domain/stillscout_constants.dart';

export '../../domain/stillscout_constants.dart' show StillScoutVideoContext;

// ── Shared Dio instance ────────────────────────────────────────────────────

/// All vision providers share one Dio client — one connection pool, one set
/// of timeout settings, no per-provider overhead.
final sharedVisionDio = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
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

/// Extra instruction appended to [kVisionSystemPrompt] based on the creator's
/// declared shot intent. Without this, the model scores every frame with the
/// same generic rubric even though "portrait" and "landscape" clips should be
/// judged very differently (e.g. a landscape frame has no face, so
/// "open_eyes_score" needs a completely different meaning to be useful).
String contextInstructionFor(StillScoutVideoContext context) => switch (context) {
      StillScoutVideoContext.auto => '',
      StillScoutVideoContext.portrait =>
        '\n\nShot intent: PORTRAIT/SELFIE. A person\'s face is the primary '
            'subject and near-fills the frame. Weigh open_eyes_score heavily — '
            'judge open eyes, natural/flattering expression, and gaze — and '
            'penalize composition harder for awkward face cropping.',
      StillScoutVideoContext.action =>
        '\n\nShot intent: ACTION. The subject is moving fast (sports, pets, '
            'dance, etc). Prioritize blur_score above all — a frame that is '
            'razor-sharp but imperfectly composed beats a well-framed but '
            'motion-blurred one.',
      StillScoutVideoContext.landscape =>
        '\n\nShot intent: LANDSCAPE/SCENERY. No person is expected to be the '
            'subject. Score open_eyes_score based on overall scene sharpness, '
            'depth, and visual interest instead of faces. Weigh '
            'composition_score (framing, rule of thirds, horizon, leading '
            'lines) as the most important axis.',
      StillScoutVideoContext.event =>
        '\n\nShot intent: EVENT/GROUP. Multiple people may be visible. Judge '
            'open_eyes_score by the proportion of visible people with open '
            'eyes and genuine expressions, not just one face, and judge '
            'composition by how well the group and setting are framed '
            'together.',
    };

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

// ── Batch scoring types ────────────────────────────────────────────────────

/// One frame's score returned inside a [VisionBatchSuccess] response.
class VisionBatchFrameScore {
  const VisionBatchFrameScore({
    required this.index,
    required this.blurScore,
    required this.lightingScore,
    required this.openEyesScore,
    required this.compositionScore,
    this.summary,
  });

  /// 0-based index into the original frame list sent to [batchScoreFrames].
  final int index;
  final int blurScore;
  final int lightingScore;
  final int openEyesScore;
  final int compositionScore;
  final String? summary;
}

sealed class VisionBatchResult {
  const VisionBatchResult();
}

class VisionBatchSuccess extends VisionBatchResult {
  const VisionBatchSuccess({required this.scores, required this.picks});

  /// Individual scores for every frame in the batch (may be partial if the
  /// model skipped some). Keyed by the frame's 0-based index.
  final Map<int, VisionBatchFrameScore> scores;

  /// Ordered list of 0-based frame indices Gemini chose as the best picks,
  /// best first.
  final List<int> picks;
}

class VisionBatchRateLimit extends VisionBatchResult {
  const VisionBatchRateLimit();
}

class VisionBatchAuthError extends VisionBatchResult {
  const VisionBatchAuthError();
}

class VisionBatchFailure extends VisionBatchResult {
  const VisionBatchFailure([this.reason]);
  final String? reason;
}

// ── Batch scoring prompts ──────────────────────────────────────────────────

/// Builds the category-aware system prompt for the Gemini batch call.
/// Receives [frameCount] (total images sent) and [pickCount] (how many
/// to select as the best).
String batchScoringPromptFor(
  StillScoutVideoContext context,
  int frameCount,
  int pickCount,
) {
  final contextBlock = _batchContextInstructionFor(context);
  return '''You are an elite photo editor reviewing $frameCount frames from a single video. Frames are numbered 0 through ${frameCount - 1} and attached in order.

MANDATORY RULES — follow exactly or your output is invalid:
1. The "scores" array MUST contain exactly $frameCount objects — one per frame, indices 0 through ${frameCount - 1}. Never skip a frame.
2. The "picks" array MUST contain exactly $pickCount indices (the best $pickCount frames).
3. Output ONLY raw JSON — no markdown, no code fences, no extra text before or after.

PART 1 — Score EVERY frame (all $frameCount) on four axes (integers 1–100):
  • b (blur)       : sharpness of main subject. Bokeh background is fine. Penalise soft/motion-blurred subjects.
  • l (lighting)   : exposure quality — flattering even light = high. Penalise harsh shadows, blown highlights, muddy darks.
  • e (expression) : if faces visible — openness, naturalness, emotional authenticity. If no face — visual energy or mood.
  • c (composition): rule of thirds, subject placement, leading lines, negative space, visual balance.

PART 2 — Pick the $pickCount best frames.
$contextBlock

Photographer's mindset: compare frames against each other, not in isolation.
  • Genuine emotion beats technical perfection
  • Spread picks across different moments — no near-identical picks
  • Decisive moment: peak of action, height of expression, best light

JSON format (copy exactly, fill values):
{"scores":[{"i":0,"b":0,"l":0,"e":0,"c":0,"n":"note"},{"i":1,"b":0,"l":0,"e":0,"c":0,"n":"note"},...one object per frame up to i=${frameCount - 1}],"picks":[best,$pickCount,indices],"note":"≤20 word summary"}''';
}

String _batchContextInstructionFor(StillScoutVideoContext context) =>
    switch (context) {
      StillScoutVideoContext.auto =>
        'Shot type: AUTO — content may be anything.\n'
        'Weight all four axes equally. A breathtaking landscape beats a mediocre '
        'selfie. A genuine laugh slightly soft beats a sharp neutral stare. '
        'An empty scene with beautiful light beats a perfectly focused but '
        'emotionally flat frame. Judge purely on photographic impact.',

      StillScoutVideoContext.portrait =>
        'Shot type: PORTRAIT / SELFIE — a person\'s face is the subject.\n'
        'Priority order for picks:\n'
        '  1. EXPRESSION — genuine emotion, authentic smile, natural engagement '
        '(a real laugh beats a forced grin every time)\n'
        '  2. EYES — fully open, alert, looking with intention\n'
        '  3. FACE SHARPNESS — subject face must be sharp; background bokeh is desired\n'
        '  4. LIGHTING — flattering, no harsh under-eye or nose shadows\n'
        '  5. FRAMING — face fills the frame well, comfortable headroom\n'
        'Score expression_score on facial authenticity and eye openness.\n'
        'A slightly soft candid moment beats a tack-sharp posed expression every time.',

      StillScoutVideoContext.action =>
        'Shot type: ACTION — fast movement (sports, dance, pets, performance).\n'
        'Priority order for picks:\n'
        '  1. PEAK MOMENT — the apex: highest jump, ball contact, full extension, '
        'widest stride — the single frame that defines the motion\n'
        '  2. SUBJECT SHARPNESS — moving subject must be frozen; background blur is fine\n'
        '  3. ENERGY — spread limbs, intense expression, sense of speed or power\n'
        '  4. COMPOSITION — subject well-placed at the action peak\n'
        'Score expression_score on intensity and energy, not just facial expression.\n'
        'A slightly imperfect composition at the exact peak beats a perfect composition '
        'one frame before or after the decisive moment.',

      StillScoutVideoContext.landscape =>
        'Shot type: LANDSCAPE / SCENERY — no person is the primary subject.\n'
        'Priority order for picks:\n'
        '  1. LIGHT — golden-hour warmth, dramatic clouds, perfect exposure with '
        'shadow detail, colour richness\n'
        '  2. COMPOSITION — strong rule of thirds, leading lines, clear horizon, '
        'depth layers, visual anchors\n'
        '  3. OVERALL SHARPNESS — the entire scene should be in focus\n'
        '  4. MOOD — the frame should evoke a feeling through colour, scale, or atmosphere\n'
        'Score expression_score on overall scene sharpness and visual interest.\n'
        'Avoid flat grey skies, blown-out backgrounds, or cluttered mid-grounds.',

      StillScoutVideoContext.event =>
        'Shot type: EVENT / GROUP — multiple people expected.\n'
        'Priority order for picks:\n'
        '  1. COLLECTIVE ENERGY — the frame that captures group emotion: laughter, '
        'celebration, shared intensity, a communal reaction\n'
        '  2. OPEN EYES — the greatest proportion of visible people have open, engaged eyes\n'
        '  3. KEY SUBJECTS — speaker, couple, performer, or honouree is well-lit and prominent\n'
        '  4. SETTING — venue and atmosphere visible and flattering\n'
        '  5. SHARPNESS — group and key subjects sharp\n'
        'Score expression_score on the proportion of people with genuine, open expressions.\n'
        'The candid group laugh beats the stiff posed group shot.',
    };

// ── Batch response parser ──────────────────────────────────────────────────

/// Parses the JSON response from [batchScoringPromptFor] into a
/// [VisionBatchSuccess]. Returns null on any parse failure.
///
/// When [expectedFrameCount] is set, rejects sparse responses that score
/// fewer than that many frames (Gemini must score every batch frame).
VisionBatchSuccess? parseBatchScoringResponse(
  String raw, {
  int? expectedFrameCount,
}) {
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
    final scoresRaw = json['scores'] as List<dynamic>;
    final picksRaw  = json['picks']  as List<dynamic>;

    final scores = <int, VisionBatchFrameScore>{};
    for (final s in scoresRaw) {
      final m = s as Map<String, dynamic>;
      final i = (m['i'] as num).toInt();
      scores[i] = VisionBatchFrameScore(
        index:            i,
        blurScore:        (m['b'] as num).toInt().clamp(1, 100),
        lightingScore:    (m['l'] as num).toInt().clamp(1, 100),
        openEyesScore:    (m['e'] as num).toInt().clamp(1, 100),
        compositionScore: (m['c'] as num).toInt().clamp(1, 100),
        summary: m['n'] is String ? m['n'] as String : null,
      );
    }

    final picks = picksRaw.map((p) => (p as num).toInt()).toList();

    if (scores.isEmpty || picks.isEmpty) return null;
    if (expectedFrameCount != null && expectedFrameCount > 0) {
      if (scores.length < expectedFrameCount) {
        debugPrint(
          '[BatchParser] Incomplete scores: ${scores.length}/$expectedFrameCount',
        );
        return null;
      }
      for (var i = 0; i < expectedFrameCount; i++) {
        if (!scores.containsKey(i)) {
          debugPrint('[BatchParser] Missing score for frame index $i');
          return null;
        }
      }
    }
    return VisionBatchSuccess(scores: scores, picks: picks);
  } catch (e) {
    debugPrint('[BatchParser] Field mapping failed: $e  raw: $raw');
    return null;
  }
}

// ── Abstract interface ─────────────────────────────────────────────────────

abstract interface class VisionScoringClient {
  /// Human-readable name used in debug logs (e.g. 'Supabase', 'Gemini Flash').
  String get name;

  /// Whether the provider has a valid API key configured.
  bool get isConfigured;

  /// Score one 512px base64-encoded JPEG frame.
  ///
  /// [videoContext] is the creator-declared shot intent (auto/portrait/
  /// action/landscape/event) — providers append a context-specific
  /// instruction to the system prompt so e.g. "no face expected" landscape
  /// shots aren't judged by the same rubric as selfies.
  ///
  /// Returns a [VisionScoringResult]:
  /// - [VisionScoringSuccess] — score is ready.
  /// - [VisionScoringRateLimit] — hit quota; cascade to next provider.
  /// - [VisionScoringAuthError] — bad key; disable for session.
  /// - [VisionScoringFailure] — any other error; cascade to next provider.
  Future<VisionScoringResult> scoreFrame({
    required String base64Jpeg,
    StillScoutVideoContext videoContext = StillScoutVideoContext.auto,
  });

  /// Score [base64Jpegs] (all 384px thumbnails) in a single API call and
  /// return per-frame scores plus the [pickCount] best frame indices.
  ///
  /// Returns a [VisionBatchResult]:
  /// - [VisionBatchSuccess] — scores + picks are ready.
  /// - [VisionBatchRateLimit] — hit quota.
  /// - [VisionBatchAuthError] — bad key.
  /// - [VisionBatchFailure] — any other error.
  Future<VisionBatchResult> batchScoreFrames({
    required List<String> base64Jpegs,
    required int pickCount,
    StillScoutVideoContext videoContext = StillScoutVideoContext.auto,
  });

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
