/// Where a frame's score came from — surfaced in the UI so creators know
/// whether they're looking at a real AI judgment or an offline estimate.
enum ScoreSource {
  /// Scored by the multimodal vision LLM (gpt-4o-mini).
  llm,

  /// Scored on-device via pixel heuristics (no network, or LLM unavailable).
  heuristic,

  /// Pixel heuristics (blur/lighting/composition) combined with ML Kit
  /// on-device face detection for the open-eyes axis. Best-of-both-worlds:
  /// fully offline, real face intelligence.
  hybrid;

  String get label => switch (this) {
        ScoreSource.llm => 'AI Scored',
        ScoreSource.heuristic => 'Estimated · Offline',
        ScoreSource.hybrid => 'On-device ML',
      };

  static ScoreSource fromName(String? name) {
    return ScoreSource.values.firstWhere(
      (s) => s.name == name,
      orElse: () => ScoreSource.heuristic,
    );
  }
}

/// Granular AI scoring breakdown for a single extracted frame.
class FrameScoreMetadata {
  const FrameScoreMetadata({
    required this.blurScore,
    required this.lightingScore,
    required this.openEyesScore,
    required this.compositionScore,
    this.summary,
    this.source = ScoreSource.heuristic,
  });

  final int blurScore;
  final int lightingScore;
  final int openEyesScore;
  final int compositionScore;

  /// One-line "why this scored the way it did" — written by the vision LLM.
  /// Null for heuristic scores, since there's no model reasoning to show.
  final String? summary;

  final ScoreSource source;

  /// Weighted aggregate used for ranking (open eyes/expression matters most
  /// for "is this the keeper frame", composition next, then technicals).
  int totalScore([Map<String, double>? weights]) {
    final w = weights ??
        const {
          'blur': 0.25,
          'lighting': 0.25,
          'eyes': 0.30,
          'composition': 0.20,
        };
    final weighted = (blurScore * (w['blur'] ?? 0.25)) +
        (lightingScore * (w['lighting'] ?? 0.25)) +
        (openEyesScore * (w['eyes'] ?? 0.30)) +
        (compositionScore * (w['composition'] ?? 0.20));
    return weighted.round().clamp(1, 100);
  }

  FrameScoreMetadata copyWith({
    int? blurScore,
    int? lightingScore,
    int? openEyesScore,
    int? compositionScore,
    String? summary,
    ScoreSource? source,
  }) {
    return FrameScoreMetadata(
      blurScore: blurScore ?? this.blurScore,
      lightingScore: lightingScore ?? this.lightingScore,
      openEyesScore: openEyesScore ?? this.openEyesScore,
      compositionScore: compositionScore ?? this.compositionScore,
      summary: summary ?? this.summary,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toJson() => {
        'blurScore': blurScore,
        'lightingScore': lightingScore,
        'openEyesScore': openEyesScore,
        'compositionScore': compositionScore,
        'totalScore': totalScore(),
        'summary': summary,
        'source': source.name,
      };

  factory FrameScoreMetadata.fromJson(Map<String, dynamic> json) {
    return FrameScoreMetadata(
      blurScore: _clampedInt(json['blurScore']),
      lightingScore: _clampedInt(json['lightingScore']),
      openEyesScore: _clampedInt(json['openEyesScore']),
      compositionScore: _clampedInt(json['compositionScore']),
      summary: json['summary'] as String?,
      source: ScoreSource.fromName(json['source'] as String?),
    );
  }

  static int _clampedInt(Object? value, {int fallback = 50}) {
    if (value is int) return value.clamp(1, 100).toInt();
    if (value is num) return value.round().clamp(1, 100).toInt();
    if (value is String) {
      final parsed = int.tryParse(value) ?? double.tryParse(value)?.round();
      if (parsed != null) return parsed.clamp(1, 100).toInt();
    }
    return fallback;
  }
}
