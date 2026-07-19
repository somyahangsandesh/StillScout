import 'package:flutter_test/flutter_test.dart';
import 'package:stillscout/stillscout/data/models/extracted_frame.dart';
import 'package:stillscout/stillscout/data/models/frame_score_metadata.dart';
import 'package:stillscout/stillscout/data/models/scored_frame.dart';
import 'package:stillscout/stillscout/domain/stillscout_constants.dart';
import 'package:stillscout/stillscout/services/stillscout_gallery_cap.dart';

ScoredFrame _frame({
  required String id,
  required double score,
  bool isTopScout = false,
}) {
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

  test('prefers all isTopScout frames over higher-scoring fillers', () {
    // 5 Gemini picks with modest scores + many higher-scoring non-picks.
    final frames = <ScoredFrame>[
      for (var i = 0; i < 5; i++)
        _frame(id: 'top$i', score: 5.0 + i * 0.1, isTopScout: true),
      for (var i = 0; i < 40; i++)
        _frame(id: 'fill$i', score: 9.0 - i * 0.01, isTopScout: false),
    ];

    final capped = StillScoutGalleryCap.cap(frames, max: 20);
    expect(capped.length, 20);
    for (var i = 0; i < 5; i++) {
      expect(
        capped.any((f) => f.frame.id == 'top$i'),
        isTrue,
        reason: 'Gemini top$i must survive the ≤20 gallery cap',
      );
    }
  });

  test('when more than max top scouts, keeps highest-scoring tops', () {
    final frames = [
      for (var i = 0; i < 25; i++)
        _frame(id: 't$i', score: i.toDouble(), isTopScout: true),
    ];
    final capped = StillScoutGalleryCap.cap(frames, max: 20);
    expect(capped.length, 20);
    expect(capped.every((f) => f.isTopScout), isTrue);
    expect(capped.first.score, 24);
    expect(capped.last.score, 5);
    expect(capped.any((f) => f.frame.id == 't0'), isFalse);
  });

  test('under-cap input is sorted by score descending', () {
    final frames = [
      _frame(id: 'a', score: 3),
      _frame(id: 'b', score: 9, isTopScout: true),
      _frame(id: 'c', score: 6),
    ];
    final capped = StillScoutGalleryCap.cap(frames, max: 20);
    expect(capped.map((f) => f.frame.id).toList(), ['b', 'c', 'a']);
  });
}
