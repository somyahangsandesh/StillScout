import 'extracted_frame.dart';
import 'frame_score_metadata.dart';

/// An extracted frame paired with its AI evaluation scores.
class ScoredFrame {
  const ScoredFrame({
    required this.frame,
    required this.score,
    required this.metadata,
    this.isTopScout = false,
  });

  final ExtractedFrame frame;
  final int score;
  final FrameScoreMetadata metadata;
  final bool isTopScout;

  ScoredFrame copyWith({
    ExtractedFrame? frame,
    int? score,
    FrameScoreMetadata? metadata,
    bool? isTopScout,
  }) {
    return ScoredFrame(
      frame: frame ?? this.frame,
      score: score ?? this.score,
      metadata: metadata ?? this.metadata,
      isTopScout: isTopScout ?? this.isTopScout,
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
        'metadata': metadata.toJson(),
      };

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
      score: json['score'] as int? ?? metadata.totalScore(),
      metadata: metadata,
      isTopScout: json['isTopScout'] as bool? ?? false,
    );
  }
}
