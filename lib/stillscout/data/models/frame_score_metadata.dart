/// Where a frame's score came from — surfaced in the UI so creators know
/// whether they're looking at a real AI judgment or an offline estimate.
enum ScoreSource {
  /// Scored by Gemini Flash (AI Pro cloud path).
  llm,

  /// Scored on-device via pixel heuristics (no network, or LLM unavailable).
  heuristic,

  /// Pixel heuristics combined with Apple Vision face detection for the
  /// open-eyes axis. Fully offline.
  hybrid;

  String get label => switch (this) {
        ScoreSource.llm => 'Gemini AI',
        ScoreSource.heuristic => 'On-device',
        ScoreSource.hybrid => 'Apple Vision',
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

  /// Weighted aggregate used for ranking — returns a 0.0–10.0 score with
  /// 1-decimal-place precision (e.g. 8.5, 6.3, 9.0).
  ///
  /// Sub-scores (blur/lighting/eyes/composition) remain on the 0–100 int
  /// scale internally; the total is divided by 10 on the way out so the
  /// displayed number is intuitive ("9.5 out of 10").
  double totalScore([Map<String, double>? weights]) {
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
    // Round to 1 decimal place on the 0–10 scale.
    final raw = weighted.clamp(0.0, 100.0);
    return (raw * 10).round() / 100.0; // e.g. 85.4 → 854 → 854/100 = 8.5
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
