import 'package:stillscout/stillscout/data/models/frame_score_metadata.dart';
import 'package:stillscout/stillscout/services/stillscout_vision_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StillScoutVisionClient response parsing', () {
    test('parses clean JSON into a FrameScoreMetadata with source=llm', () {
      const raw = '{"blur_score":92,"lighting_score":81,'
          '"open_eyes_score":75,"composition_score":88,'
          '"summary":"Sharp subject, soft window light, strong framing."}';

      final metadata = StillScoutVisionClient.parseResponseForTests(raw);

      expect(metadata, isNotNull);
      expect(metadata!.blurScore, 92);
      expect(metadata.lightingScore, 81);
      expect(metadata.openEyesScore, 75);
      expect(metadata.compositionScore, 88);
      expect(metadata.summary, contains('Sharp subject'));
      expect(metadata.source, ScoreSource.llm);
    });

    test('recovers JSON embedded in extra prose/markdown fences', () {
      const raw = '''
Sure, here is the score:
```json
{"blur_score": 60, "lighting_score": 70, "open_eyes_score": 65, "composition_score": 55, "summary": "Decent but a bit flat."}
```
Let me know if you need anything else!
''';

      final metadata = StillScoutVisionClient.parseResponseForTests(raw);

      expect(metadata, isNotNull);
      expect(metadata!.blurScore, 60);
      expect(metadata.compositionScore, 55);
    });

    test('clamps out-of-schema values instead of throwing', () {
      const raw = '{"blur_score":150,"lighting_score":-5,'
          '"open_eyes_score":40,"composition_score":40}';

      final metadata = StillScoutVisionClient.parseResponseForTests(raw);

      expect(metadata, isNotNull);
      expect(metadata!.blurScore, 100);
      expect(metadata.lightingScore, 1);
    });

    test('returns null for unparseable garbage instead of throwing', () {
      const raw = 'I cannot help with that request.';

      final metadata = StillScoutVisionClient.parseResponseForTests(raw);

      expect(metadata, isNull);
    });

    test('returns null for valid JSON missing the schema entirely', () {
      const raw = '{"unrelated_field": true}';

      // Missing fields fall back to a neutral default rather than null —
      // the caller treats any non-null metadata as a usable score.
      final metadata = StillScoutVisionClient.parseResponseForTests(raw);

      expect(metadata, isNotNull);
      expect(metadata!.blurScore, 50);
    });
  });
}
