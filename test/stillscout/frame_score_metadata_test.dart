import 'package:stillscout/stillscout/data/models/frame_score_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FrameScoreMetadata', () {
    test('totalScore applies the documented weights', () {
      const metadata = FrameScoreMetadata(
        blurScore: 80,
        lightingScore: 60,
        openEyesScore: 100,
        compositionScore: 40,
      );
      // 80*0.25 + 60*0.25 + 100*0.30 + 40*0.20 = 20 + 15 + 30 + 8 = 73
      expect(metadata.totalScore(), 73);
    });

    test('totalScore is clamped to 1-100', () {
      const high = FrameScoreMetadata(
        blurScore: 100,
        lightingScore: 100,
        openEyesScore: 100,
        compositionScore: 100,
      );
      expect(high.totalScore(), 100);

      const low = FrameScoreMetadata(
        blurScore: 1,
        lightingScore: 1,
        openEyesScore: 1,
        compositionScore: 1,
      );
      expect(low.totalScore(), 1);
    });

    test('fromJson round-trips toJson', () {
      const original = FrameScoreMetadata(
        blurScore: 72,
        lightingScore: 65,
        openEyesScore: 88,
        compositionScore: 59,
        summary: 'Crisp focus, slightly underexposed background.',
        source: ScoreSource.llm,
      );

      final restored = FrameScoreMetadata.fromJson(original.toJson());

      expect(restored.blurScore, original.blurScore);
      expect(restored.lightingScore, original.lightingScore);
      expect(restored.openEyesScore, original.openEyesScore);
      expect(restored.compositionScore, original.compositionScore);
      expect(restored.summary, original.summary);
      expect(restored.source, ScoreSource.llm);
    });

    test('fromJson clamps out-of-range and tolerates numeric strings', () {
      final metadata = FrameScoreMetadata.fromJson({
        'blurScore': 250, // way over 100
        'lightingScore': -40, // under 1
        'openEyesScore': '77', // numeric string from a sloppy LLM response
        'compositionScore': 12.6, // double from JSON
      });

      expect(metadata.blurScore, 100);
      expect(metadata.lightingScore, 1);
      expect(metadata.openEyesScore, 77);
      expect(metadata.compositionScore, 13);
    });

    test('fromJson falls back to a neutral default for missing/invalid fields', () {
      final metadata = FrameScoreMetadata.fromJson(<String, dynamic>{
        'blurScore': null,
        'lightingScore': 'not a number',
      });

      expect(metadata.blurScore, 50);
      expect(metadata.lightingScore, 50);
      expect(metadata.openEyesScore, 50);
      expect(metadata.compositionScore, 50);
    });

    test('fromJson defaults source to heuristic when absent or unknown', () {
      final missing = FrameScoreMetadata.fromJson({
        'blurScore': 50,
        'lightingScore': 50,
        'openEyesScore': 50,
        'compositionScore': 50,
      });
      expect(missing.source, ScoreSource.heuristic);

      final unknown = FrameScoreMetadata.fromJson({
        'blurScore': 50,
        'lightingScore': 50,
        'openEyesScore': 50,
        'compositionScore': 50,
        'source': 'totally_made_up',
      });
      expect(unknown.source, ScoreSource.heuristic);
    });

    test('ScoreSource labels are human-readable', () {
      expect(ScoreSource.llm.label, 'AI Scored');
      expect(ScoreSource.heuristic.label, 'Estimated · Offline');
    });
  });
}
