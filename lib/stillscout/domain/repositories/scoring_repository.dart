import '../../data/models/extracted_frame.dart';
import '../../data/models/scored_frame.dart';
import '../../services/stillscout_cancel_token.dart';
import '../stillscout_constants.dart';

/// Contract for frame scoring and ranking.
abstract interface class ScoringRepository {
  /// Scores [frames]. When [useCloudAi] is true (AI Pro), Vision-filtered
  /// candidates are sent to Gemini/cloud for final judgment + summary.
  /// Free users pass [useCloudAi]: false — Apple Vision + heuristics only, no
  /// network. [requireCloudAi] is retained for API compatibility; cloud
  /// failures soft-degrade to on-device Vision scores (W1.2).
  Future<List<ScoredFrame>> scoreAndRankFrames(
    List<ExtractedFrame> frames, {
    required String videoPath,
    Map<String, double>? scoreWeights,
    StillScoutVideoContext videoContext = StillScoutVideoContext.auto,
    void Function(double progress)? onProgress,
    StillScoutCancelToken? cancelToken,
    bool useCloudAi = false,
    @Deprecated('Soft-degrades to Vision scores when cloud is unavailable.')
    bool requireCloudAi = false,
  });

  /// Selects up to [count] top picks with diversity enforcement:
  /// no two picks can be temporally or perceptually "near-duplicate."
  List<ScoredFrame> selectTopPicks(List<ScoredFrame> ranked, {int count = 3});
}
