import '../../domain/repositories/scoring_repository.dart';
import '../../domain/stillscout_constants.dart';
import '../../services/face_quality_detector.dart';
import '../../services/frame_scoring_service.dart';
import '../../services/stillscout_cancel_token.dart';
import '../../services/stillscout_top_picks_selector.dart';
import '../models/extracted_frame.dart';
import '../models/scored_frame.dart';

class ScoringRepositoryImpl implements ScoringRepository {
  ScoringRepositoryImpl({
    FrameScoringService? scoringService,
    FaceQualityDetector? faceDetector,
  }) : _scoringService = scoringService ??
            FrameScoringService(faceDetector: faceDetector);

  final FrameScoringService _scoringService;

  @override
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
  }) {
    return _scoringService.scoreAndRankFrames(
      frames,
      videoPath: videoPath,
      scoreWeights: scoreWeights,
      videoContext: videoContext,
      onProgress: onProgress,
      cancelToken: cancelToken,
      useCloudAi: useCloudAi,
      requireCloudAi: requireCloudAi,
    );
  }

  @override
  List<ScoredFrame> selectTopPicks(
    List<ScoredFrame> ranked, {
    int count = 3,
  }) {
    return StillScoutTopPicksSelector.select(ranked, count: count);
  }
}
