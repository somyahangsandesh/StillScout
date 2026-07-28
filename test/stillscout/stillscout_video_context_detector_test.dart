import 'package:flutter_test/flutter_test.dart';
import 'package:stillscout/stillscout/domain/stillscout_constants.dart';
import 'package:stillscout/stillscout/services/stillscout_video_context_detector.dart';

void main() {
  group('StillScoutVideoContextDetector', () {
    test('detects portrait from high open-eyes scores', () {
      final sample = List.generate(
        20,
        (_) => (openEyesScore: 72, compositionScore: 55, blurScore: 70),
      );
      expect(
        StillScoutVideoContextDetector.detectFromAxisScores(sample),
        StillScoutVideoContext.portrait,
      );
    });

    test('detects landscape from high composition and low eyes', () {
      final sample = List.generate(
        20,
        (_) => (openEyesScore: 30, compositionScore: 72, blurScore: 75),
      );
      expect(
        StillScoutVideoContextDetector.detectFromAxisScores(sample),
        StillScoutVideoContext.landscape,
      );
    });

    test('detects action from high blur variance and moderate mean blur', () {
      final sample = [
        (openEyesScore: 40, compositionScore: 50, blurScore: 90),
        (openEyesScore: 42, compositionScore: 48, blurScore: 35),
        (openEyesScore: 38, compositionScore: 52, blurScore: 88),
        (openEyesScore: 41, compositionScore: 49, blurScore: 30),
        (openEyesScore: 39, compositionScore: 51, blurScore: 85),
        (openEyesScore: 43, compositionScore: 47, blurScore: 32),
      ];
      expect(
        StillScoutVideoContextDetector.detectFromAxisScores(sample),
        StillScoutVideoContext.action,
      );
    });

    test('returns auto when signals are ambiguous', () {
      final sample = List.generate(
        10,
        (_) => (openEyesScore: 50, compositionScore: 50, blurScore: 70),
      );
      expect(
        StillScoutVideoContextDetector.detectFromAxisScores(sample),
        StillScoutVideoContext.auto,
      );
    });
  });
}
