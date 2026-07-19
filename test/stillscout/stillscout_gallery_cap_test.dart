import 'package:flutter_test/flutter_test.dart';
import 'package:stillscout/stillscout/data/models/extracted_frame.dart';
import 'package:stillscout/stillscout/data/models/frame_score_metadata.dart';
import 'package:stillscout/stillscout/data/models/scored_frame.dart';
import 'package:stillscout/stillscout/domain/stillscout_constants.dart';
import 'package:stillscout/stillscout/services/stillscout_gallery_cap.dart';

ScoredFrame _frame({required String id, required double score, bool isTopScout = false}) {
  return ScoredFrame(
    frame: ExtractedFrame(
      id: id,
      filePath: '/tmp/$id.jpg',
      timestampMs: id.hashCode.abs() % 100000,
      width: 100,
      height: 100,
      sourceVideoPath: '/tmp/v.mp4',
    ),
    score: score,
    metadata: const FrameScoreMetadata(
      blurScore: 50,
      lightingScore: 50,
      openEyesScore: 50,
      compositionScore: 50,
    ),
    isTopScout: isTopScout,
  );
}

void main() {
  test('does not exceed maxGalleryFrames and keeps Gemini pick', () {
    final frames = [
      for (var i = 0; i < 30; i++)
        _frame(id: 'f$i', score: 10.0 - i * 0.1, isTopScout: i == 25),
    ];
    final capped = StillScoutGalleryCap.cap(frames);
    expect(capped.length, StillScoutConstants.maxGalleryFrames);
    expect(capped.any((f) => f.frame.id == 'f25'), isTrue);
  });
}
