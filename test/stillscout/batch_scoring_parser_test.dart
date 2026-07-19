import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stillscout/stillscout/services/stillscout_diagnostics_log.dart';
import 'package:stillscout/stillscout/services/stillscout_vision_client.dart';
import 'package:stillscout/stillscout/services/vision/vision_scoring_client.dart';

void main() {
  group('parseBatchScoringResponse', () {
    const complete = '''
{"scores":[
{"i":0,"b":80,"l":70,"e":90,"c":75,"n":"good"},
{"i":1,"b":60,"l":65,"e":70,"c":72,"n":"ok"}
],"picks":[0,1],"note":"best first"}
''';

    test('accepts complete scores for expectedFrameCount', () {
      final result = StillScoutVisionClient.parseBatchResponseForTests(
        complete,
        expectedFrameCount: 2,
      );
      expect(result, isNotNull);
      expect(result!.scores.length, 2);
      expect(result.picks, [0, 1]);
    });

    test('rejects sparse scores when expectedFrameCount is set', () {
      final sparse = StillScoutVisionClient.parseBatchResponseForTests(
        '{"scores":[{"i":0,"b":80,"l":70,"e":90,"c":75,"n":"only one"}],'
        '"picks":[0],"note":"sparse"}',
        expectedFrameCount: 5,
      );
      expect(sparse, isNull);
    });

    test('rejects missing frame indices when expectedFrameCount is set', () {
      final missingIndex = StillScoutVisionClient.parseBatchResponseForTests(
        '{"scores":[{"i":0,"b":80,"l":70,"e":90,"c":75,"n":"a"},'
        '{"i":2,"b":60,"l":65,"e":70,"c":72,"n":"c"}],'
        '"picks":[0,2],"note":"gap"}',
        expectedFrameCount: 3,
      );
      expect(missingIndex, isNull);
    });

    test('rejects empty scores or picks', () {
      expect(
        StillScoutVisionClient.parseBatchResponseForTests(
          '{"scores":[],"picks":[0]}',
        ),
        isNull,
      );
      expect(
        StillScoutVisionClient.parseBatchResponseForTests(
          '{"scores":[{"i":0,"b":1,"l":1,"e":1,"c":1}],"picks":[]}',
        ),
        isNull,
      );
    });

    test('recovers JSON embedded in markdown fences', () {
      const fenced = '''
Here is the batch result:
```json
{"scores":[{"i":0,"b":80,"l":70,"e":90,"c":75,"n":"a"},{"i":1,"b":60,"l":65,"e":70,"c":72,"n":"b"}],"picks":[0,1],"note":"ok"}
```
''';
      final result = StillScoutVisionClient.parseBatchResponseForTests(
        fenced,
        expectedFrameCount: 2,
      );
      expect(result, isNotNull);
      expect(result!.scores.length, 2);
      expect(result.picks, [0, 1]);
    });

    test('clamps out-of-range score axes to 1–100', () {
      final result = StillScoutVisionClient.parseBatchResponseForTests(
        '{"scores":[{"i":0,"b":200,"l":-5,"e":0,"c":150,"n":"x"}],'
        '"picks":[0],"note":"clamp"}',
      );
      expect(result, isNotNull);
      final s = result!.scores[0]!;
      expect(s.blurScore, 100);
      expect(s.lightingScore, 1);
      expect(s.openEyesScore, 1);
      expect(s.compositionScore, 100);
    });

    test('accepts out-of-range pick indices (caller validates)', () {
      final result = StillScoutVisionClient.parseBatchResponseForTests(
        '{"scores":[{"i":0,"b":80,"l":70,"e":90,"c":75,"n":"a"},'
        '{"i":1,"b":60,"l":65,"e":70,"c":72,"n":"b"}],'
        '"picks":[99,0],"note":"oob"}',
        expectedFrameCount: 2,
      );
      expect(result, isNotNull);
      expect(result!.picks, [99, 0]);
    });
  });

  group('StillScoutDiagnosticsLog', () {
    tearDown(StillScoutDiagnosticsLog.clear);

    test('dump redacts absolute paths to basenames', () {
      StillScoutDiagnosticsLog.log(
        'Test',
        'Failed to read /Users/alice/stillscout/secret/video.mp4',
      );
      final dump = StillScoutDiagnosticsLog.dump();
      expect(dump, isNot(contains('/Users/alice')));
      expect(dump, contains('video.mp4'));
    });
  });

  group('VisionCascadeOrchestrator', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
    });
    test('uses Supabase batch when configured and succeeds', () async {
      final supabase = _MockVisionClient(
        name: 'Supabase',
        configured: true,
        batchResult: const VisionBatchSuccess(
          scores: {
            0: VisionBatchFrameScore(
              index: 0,
              blurScore: 80,
              lightingScore: 70,
              openEyesScore: 90,
              compositionScore: 75,
            ),
          },
          picks: [0],
        ),
      );
      final gemini = _MockVisionClient(name: 'Gemini', configured: true);

      final orchestrator = VisionCascadeOrchestrator.withProviders(
        supabaseClient: supabase,
        geminiClient: gemini,
      );

      final result = await orchestrator.batchScoreFrames(
        base64Jpegs: ['jpeg1'],
        pickCount: 1,
      );

      expect(result, isA<VisionBatchSuccess>());
      expect(supabase.batchCalls, 1);
      expect(gemini.batchCalls, 0);
    });

    test('falls back to direct Gemini when Supabase batch fails', () async {
      final supabase = _MockVisionClient(
        name: 'Supabase',
        configured: true,
        batchResult: const VisionBatchFailure('network'),
      );
      final gemini = _MockVisionClient(
        name: 'Gemini',
        configured: true,
        batchResult: const VisionBatchSuccess(
          scores: {
            0: VisionBatchFrameScore(
              index: 0,
              blurScore: 70,
              lightingScore: 70,
              openEyesScore: 70,
              compositionScore: 70,
            ),
          },
          picks: [0],
        ),
      );

      final orchestrator = VisionCascadeOrchestrator.withProviders(
        supabaseClient: supabase,
        geminiClient: gemini,
      );

      final result = await orchestrator.batchScoreFrames(
        base64Jpegs: ['jpeg1'],
        pickCount: 1,
      );

      expect(result, isA<VisionBatchSuccess>());
      expect(supabase.batchCalls, 1);
      expect(gemini.batchCalls, 1);
    });

    test('returns failure when no provider is configured', () async {
      final orchestrator = VisionCascadeOrchestrator.withProviders(
        supabaseClient: _MockVisionClient(name: 'Supabase', configured: false),
        geminiClient: _MockVisionClient(name: 'Gemini', configured: false),
      );

      final result = await orchestrator.batchScoreFrames(
        base64Jpegs: ['jpeg1'],
        pickCount: 1,
      );

      expect(result, isA<VisionBatchFailure>());
    });

    test('sets lastBatchQuotaExceeded on Supabase rate limit', () async {
      final supabase = _MockVisionClient(
        name: 'Supabase',
        configured: true,
        batchResult: const VisionBatchRateLimit(),
      );

      final orchestrator = VisionCascadeOrchestrator.withProviders(
        supabaseClient: supabase,
        geminiClient: _MockVisionClient(name: 'Gemini', configured: false),
      );

      final result = await orchestrator.batchScoreFrames(
        base64Jpegs: ['jpeg1'],
        pickCount: 1,
      );

      expect(result, isA<VisionBatchFailure>());
      expect(orchestrator.lastBatchQuotaExceeded, isTrue);
    });

    test('clears lastBatchQuotaExceeded on successful batch', () async {
      final orchestrator = VisionCascadeOrchestrator.withProviders(
        supabaseClient: _MockVisionClient(
          name: 'Supabase',
          configured: true,
          batchResult: const VisionBatchSuccess(
            scores: {
              0: VisionBatchFrameScore(
                index: 0,
                blurScore: 80,
                lightingScore: 70,
                openEyesScore: 90,
                compositionScore: 75,
              ),
            },
            picks: [0],
          ),
        ),
        geminiClient: _MockVisionClient(name: 'Gemini', configured: false),
      );

      orchestrator.lastBatchQuotaExceeded = true;
      await orchestrator.batchScoreFrames(
        base64Jpegs: ['jpeg1'],
        pickCount: 1,
      );

      expect(orchestrator.lastBatchQuotaExceeded, isFalse);
    });
  });
}

class _MockVisionClient implements VisionScoringClient {
  _MockVisionClient({
    required this.name,
    required bool configured,
    this.batchResult = const VisionBatchFailure('mock'),
  }) : isConfigured = configured;

  @override
  final String name;

  @override
  final bool isConfigured;

  final VisionBatchResult batchResult;

  int batchCalls = 0;
  int scoreCalls = 0;

  @override
  Future<VisionBatchResult> batchScoreFrames({
    required List<String> base64Jpegs,
    required int pickCount,
    StillScoutVideoContext videoContext = StillScoutVideoContext.auto,
  }) async {
    batchCalls++;
    return batchResult;
  }

  @override
  Future<VisionScoringResult> scoreFrame({
    required String base64Jpeg,
    StillScoutVideoContext videoContext = StillScoutVideoContext.auto,
  }) async {
    scoreCalls++;
    return const VisionScoringFailure('mock');
  }

  @override
  void resetForTests() {}
}
