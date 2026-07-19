import 'extracted_frame.dart';
import 'frame_score_metadata.dart';

/// An extracted frame paired with its AI evaluation scores.
class ScoredFrame {
  const ScoredFrame({
    required this.frame,
    required this.score,
    required this.metadata,
    this.isTopScout = false,
    this.geminiPickRank,
  });

  final ExtractedFrame frame;

  /// 0.0–10.0 composite score with 1dp precision (e.g. 8.5, 6.3, 9.0).
  final double score;
  final FrameScoreMetadata metadata;
  final bool isTopScout;

  /// 0-based rank in Gemini's picks array (best-first). Null when not a
  /// Gemini pick — used to preserve carousel order over score sort.
  final int? geminiPickRank;

  ScoredFrame copyWith({
    ExtractedFrame? frame,
    double? score,
    FrameScoreMetadata? metadata,
    bool? isTopScout,
    int? geminiPickRank,
  }) {
    return ScoredFrame(
      frame: frame ?? this.frame,
      score: score ?? this.score,
      metadata: metadata ?? this.metadata,
      isTopScout: isTopScout ?? this.isTopScout,
      geminiPickRank: geminiPickRank ?? this.geminiPickRank,
    );
  }

  Map<String, dynamic> toJson() => {
        'frameId': frame.id,
        'filePath': frame.filePath,
        'timestampMs': frame.timestampMs,
        'width': frame.width,
        'height': frame.height,
        'sourceVideoPath': frame.sourceVideoPath,
        'score': score,
        'isTopScout': isTopScout,
        if (geminiPickRank != null) 'geminiPickRank': geminiPickRank,
        'metadata': metadata.toJson(),
      };

  /// Reads a persisted score — handles both the legacy 0-100 int format and
  /// the current 0.0-10.0 double format so History doesn't break on upgrade.
  static double _parseScore(Object? raw, FrameScoreMetadata metadata) {
    if (raw is double) {
      // Already 0-10 format — clamp and round to 1dp.
      return (raw.clamp(0.0, 10.0) * 10).round() / 10.0;
    }
    if (raw is int) {
      // Legacy 0-100 int → convert to 0-10 double.
      return raw > 10
          ? ((raw.clamp(0, 100) * 10).round() / 100.0)
          : raw.toDouble();
    }
    return metadata.totalScore();
  }

  factory ScoredFrame.fromJson(Map<String, dynamic> json) {
    final frame = ExtractedFrame(
      id: json['frameId'] as String? ?? '',
      filePath: json['filePath'] as String? ?? '',
      timestampMs: json['timestampMs'] as int? ?? 0,
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
      sourceVideoPath: json['sourceVideoPath'] as String? ?? '',
    );
    final metadata = json['metadata'] is Map
        ? FrameScoreMetadata.fromJson(
            Map<String, dynamic>.from(json['metadata'] as Map),
          )
        : const FrameScoreMetadata(
            blurScore: 50,
            lightingScore: 50,
            openEyesScore: 50,
            compositionScore: 50,
          );
    return ScoredFrame(
      frame: frame,
      score: _parseScore(json['score'], metadata),
      metadata: metadata,
      isTopScout: json['isTopScout'] as bool? ?? false,
      geminiPickRank: json['geminiPickRank'] as int?,
    );
  }
}
