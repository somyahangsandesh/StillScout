import '../../data/models/extracted_frame.dart';
import '../../data/models/scored_frame.dart';
import '../../services/stillscout_cancel_token.dart';

/// Contract for frame scoring and ranking.
abstract interface class ScoringRepository {
  /// Scores [frames] via cloud AI when [requireCloudAi] is true (production
  /// scouts). Heuristic fallback is only used when [requireCloudAi] is false
  /// (tests / legacy paths).
  Future<List<ScoredFrame>> scoreAndRankFrames(
    List<ExtractedFrame> frames, {
    required String videoPath,
    Map<String, double>? scoreWeights,
    void Function(double progress)? onProgress,
    StillScoutCancelToken? cancelToken,
    bool requireCloudAi = false,
  });

  /// Selects up to [count] top picks with diversity enforcement:
  /// no two picks can be temporally or perceptually "near-duplicate."
  List<ScoredFrame> selectTopPicks(List<ScoredFrame> ranked, {int count = 3});
}
