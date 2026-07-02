import '../../domain/repositories/scoring_repository.dart';
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
    void Function(double progress)? onProgress,
    StillScoutCancelToken? cancelToken,
    bool requireCloudAi = false,
  }) {
    return _scoringService.scoreAndRankFrames(
      frames,
      videoPath: videoPath,
      scoreWeights: scoreWeights,
      onProgress: onProgress,
      cancelToken: cancelToken,
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
