import 'dart:async';

import 'package:flutter/services.dart';
import 'package:stillscout/stillscout/data/models/extracted_frame.dart';
import 'package:stillscout/stillscout/data/models/frame_score_metadata.dart';
import 'package:stillscout/stillscout/data/models/scored_frame.dart';
import 'package:stillscout/stillscout/data/models/stillscout_session.dart';
import 'package:stillscout/stillscout/domain/failures/stillscout_failure.dart';
import 'package:stillscout/stillscout/domain/stillscout_constants.dart';
import 'package:stillscout/stillscout/domain/repositories/scoring_repository.dart';
import 'package:stillscout/stillscout/domain/repositories/session_repository.dart';
import 'package:stillscout/stillscout/domain/repositories/video_repository.dart';
import 'package:stillscout/stillscout/presentation/providers/stillscout_connectivity_provider.dart';
import 'package:stillscout/stillscout/presentation/providers/stillscout_notifier.dart';
import 'package:stillscout/stillscout/presentation/providers/stillscout_repository_providers.dart';
import 'package:stillscout/stillscout/domain/stillscout_online_status.dart';
import 'package:stillscout/stillscout/services/stillscout_connectivity.dart';
import 'package:stillscout/stillscout/services/stillscout_scout_background.dart';
import 'package:stillscout/stillscout/services/stillscout_cancel_token.dart';
import 'package:stillscout/stillscout/services/stillscout_scout_quota_tracker.dart';
import 'package:stillscout/stillscout/services/video_frame_extractor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── fakes ────────────────────────────────────────────────────────────────────

const _mockFrame = ExtractedFrame(
  id: 'frame1',
  filePath: '/fake/frame1.jpg',
  timestampMs: 500,
  width: 1280,
  height: 720,
  sourceVideoPath: '/fake/video.mp4',
);

const _mockScored = ScoredFrame(
  frame: _mockFrame,
  score: 8.5,
  metadata: FrameScoreMetadata(
    blurScore: 80,
    lightingScore: 85,
    openEyesScore: 90,
    compositionScore: 85,
  ),
  isTopScout: true,
);

class FakeVideoRepository implements VideoRepository {
  StillScoutFailure? throwFailure;
  final List<ExtractedFrame> frames;
  int extractCallCount = 0;

  FakeVideoRepository({this.throwFailure, List<ExtractedFrame>? frames})
      : frames = frames ?? [_mockFrame];

  @override
  Future<Duration?> readDuration(String videoPath) async =>
      const Duration(seconds: 5);

  @override
  Future<List<ExtractedFrame>> extractFrames({
    required String videoPath,
    required String sessionId,
    int? trimStartMs,
    int? trimEndMs,
    int? knownDurationMs,
    void Function(FrameExtractionProgress p)? onProgress,
    StillScoutCancelToken? cancelToken,
  }) async {
    extractCallCount++;
    if (throwFailure != null) throw throwFailure!;
    return frames;
  }

  @override
  Future<List<ExtractedFrame>> deduplicateFrames(
      List<ExtractedFrame> frames) async =>
      frames;

  @override
  Future<void> runCacheJanitor() async {}
}

class FakeScoringRepository implements ScoringRepository {
  final List<ScoredFrame> results;

  /// When set, scoreAndRankFrames suspends until this completes — lets tests
  /// deterministically observe the "scoring" phase before it resolves.
  final Future<void>? blockUntil;

  FakeScoringRepository({List<ScoredFrame>? results, this.blockUntil})
      : results = results ?? [_mockScored];

  @override
  Future<List<ScoredFrame>> scoreAndRankFrames(
    List<ExtractedFrame> frames, {
    required String videoPath,
    Map<String, double>? scoreWeights,
    StillScoutVideoContext videoContext = StillScoutVideoContext.auto,
    void Function(double)? onProgress,
    StillScoutCancelToken? cancelToken,
    bool useCloudAi = false,
    bool requireCloudAi = false,
  }) async {
    if (blockUntil != null) await blockUntil;
    onProgress?.call(1.0);
    return results;
  }

  @override
  List<ScoredFrame> selectTopPicks(List<ScoredFrame> ranked, {int count = 3}) =>
      ranked.take(count).toList();
}

class FakeSessionRepository implements SessionRepository {
  final _sessions = <String, StillScoutSession>{};

  @override
  Future<List<StillScoutSession>> getSessions() async =>
      _sessions.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<void> saveSession(StillScoutSession session) async =>
      _sessions[session.id] = session;

  @override
  Future<StillScoutSession?> getSession(String id) async => _sessions[id];

  @override
  Future<void> deleteSession(String id) async => _sessions.remove(id);

  @override
  Future<void> evictOldSessions() async {}
}

class FakeStillScoutConnectivity extends StillScoutConnectivity {
  FakeStillScoutConnectivity({this.alwaysOnline = true})
      : super(reachabilityProbe: () async => alwaysOnline);

  final bool alwaysOnline;

  @override
  Future<bool> get isOnline async => alwaysOnline;

  @override
  Stream<StillScoutOnlineSnapshot> watchStatus() async* {
    yield StillScoutOnlineSnapshot(
      alwaysOnline ? OnlineStatus.online : OnlineStatus.offline,
    );
  }
}

// ── helpers ──────────────────────────────────────────────────────────────────

ProviderContainer _makeContainer({
  VideoRepository? videoRepo,
  ScoringRepository? scoringRepo,
  SessionRepository? sessionRepo,
  StillScoutConnectivity? connectivity,
}) {
  return ProviderContainer(
    overrides: [
      videoRepositoryProvider
          .overrideWithValue(videoRepo ?? FakeVideoRepository()),
      scoringRepositoryProvider
          .overrideWithValue(scoringRepo ?? FakeScoringRepository()),
      sessionRepositoryProvider
          .overrideWithValue(sessionRepo ?? FakeSessionRepository()),
      stillScoutConnectivityProvider.overrideWithValue(
        connectivity ?? FakeStillScoutConnectivity(),
      ),
    ],
  );
}

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    StillScoutScoutBackground.enabled = false;
    // StillScoutSubscriptionManager reads SharedPreferences.
    SharedPreferences.setMockInitialValues({});
    // flutter_secure_storage uses a MethodChannel — stub it with an in-memory
    // store so Keychain-backed trackers work in unit tests.
    _setupSecureStorageMock();
  });

  group('StillScoutNotifier', () {
    setUp(() async {
      await StillScoutScoutQuotaTracker.resetForTests();
      // Consume the AI Pro trial so offline tests are not affected by it.
      await StillScoutAiProTrialTracker.consumeTrial();
    });

    test('initial state is idle with empty frames', () {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final state = container.read(stillScoutProvider);
      expect(state.phase, StillScoutPhase.idle);
      expect(state.frames, isEmpty);
    });

    test('processVideo succeeds offline for free on-device scouts', () async {
      final container = _makeContainer(
        connectivity: FakeStillScoutConnectivity(alwaysOnline: false),
      );
      addTearDown(container.dispose);

      await container
          .read(stillScoutProvider.notifier)
          .processVideo('/fake/video.mp4');

      final state = container.read(stillScoutProvider);
      expect(state.phase, StillScoutPhase.complete);
      expect(state.frames, isNotEmpty);
    });

    test('processVideo transitions idle → extracting → scoring → complete', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final phases = <StillScoutPhase>[];
      container.listen(
        stillScoutProvider.select((s) => s.phase),
        (_, next) => phases.add(next),
        fireImmediately: true,
      );

      await container
          .read(stillScoutProvider.notifier)
          .processVideo('/fake/video.mp4');

      expect(phases, containsAllInOrder([
        StillScoutPhase.idle,
        StillScoutPhase.extracting,
        StillScoutPhase.scoring,
        StillScoutPhase.complete,
      ]));
    });

    test('processVideo results in non-empty frames on success', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container
          .read(stillScoutProvider.notifier)
          .processVideo('/fake/video.mp4');

      final state = container.read(stillScoutProvider);
      expect(state.phase, StillScoutPhase.complete);
      expect(state.frames, isNotEmpty);
    });

    test('extraction failure maps to StillScoutPhase.error', () async {
      final container = _makeContainer(
        videoRepo: FakeVideoRepository(
          throwFailure: const VideoTooShortFailure(),
        ),
      );
      addTearDown(container.dispose);

      await container
          .read(stillScoutProvider.notifier)
          .processVideo('/fake/video.mp4');

      final state = container.read(stillScoutProvider);
      expect(state.phase, StillScoutPhase.error);
      expect(state.errorMessage, contains('too short'));
    });

    test('cancelProcessing moves to cancelled phase', () async {
      // Use a video repo that never resolves (simulate slow extraction).
      final neverCompletes = _NeverExtractingVideoRepo();
      final container = _makeContainer(videoRepo: neverCompletes);
      addTearDown(container.dispose);

      final notifier = container.read(stillScoutProvider.notifier);

      // Start processing without awaiting.
      final future = notifier.processVideo('/fake/video.mp4');
      // Wait until the cancel token is wired up.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      notifier.cancelProcessing();
      await future;

      final state = container.read(stillScoutProvider);
      expect(state.phase, StillScoutPhase.cancelled);
    });

    test('reset returns to idle state', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container
          .read(stillScoutProvider.notifier)
          .processVideo('/fake/video.mp4');

      container.read(stillScoutProvider.notifier).reset();

      final state = container.read(stillScoutProvider);
      expect(state.phase, StillScoutPhase.idle);
      expect(state.frames, isEmpty);
    });

    test('processVideo fails when daily scout quota exhausted', () async {
      for (var i = 0; i < StillScoutConstants.freeScoutsPerDay; i++) {
        await StillScoutScoutQuotaTracker.recordCompletedScout(isPro: false);
      }

      final container = _makeContainer();
      addTearDown(container.dispose);

      await container
          .read(stillScoutProvider.notifier)
          .processVideo('/fake/video.mp4');

      final state = container.read(stillScoutProvider);
      expect(state.phase, StillScoutPhase.error);
      expect(
        state.errorMessage,
        const ScoutQuotaExhaustedFailure().displayMessage,
      );
    });

    test('session is persisted after successful processing', () async {
      final fakeSessionRepo = FakeSessionRepository();
      final container = _makeContainer(sessionRepo: fakeSessionRepo);
      addTearDown(container.dispose);

      await container
          .read(stillScoutProvider.notifier)
          .processVideo('/fake/video.mp4');

      final sessions = await fakeSessionRepo.getSessions();
      expect(sessions, hasLength(1));
      expect(sessions.first.frameCount, greaterThan(0));
    });

    test('onVideoPicked sets videoPath and videoDurationMs without processing', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container
          .read(stillScoutProvider.notifier)
          .onVideoPicked('/fake/video.mp4');

      final state = container.read(stillScoutProvider);
      expect(state.phase, StillScoutPhase.idle);
      expect(state.videoPath, '/fake/video.mp4');
      expect(state.videoDurationMs, isNotNull);
    });

    test('free scout sets cloudScoringOutcome to notApplicable', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container
          .read(stillScoutProvider.notifier)
          .processVideo('/fake/video.mp4');

      final state = container.read(stillScoutProvider);
      expect(state.phase, StillScoutPhase.complete);
      expect(state.cloudScoringOutcome, CloudScoringOutcome.notApplicable);
    });

    test(
      'trial scout that never reaches Gemini does not consume a free scout '
      'credit, trial token, or first-scout bonus',
      () async {
        // Make the AI trial available (group setUp consumes it by default).
        await StillScoutAiProTrialTracker.resetForTests();
        await StillScoutFirstScoutTracker.resetForTests();
        addTearDown(StillScoutAiProTrialTracker.consumeTrial);
        addTearDown(StillScoutFirstScoutTracker.markFirstScoutDone);

        final container = _makeContainer();
        addTearDown(container.dispose);

        final usedBefore = await StillScoutScoutQuotaTracker.usedToday();

        await container
            .read(stillScoutProvider.notifier)
            .processVideo('/fake/video.mp4');

        final state = container.read(stillScoutProvider);
        expect(state.phase, StillScoutPhase.complete);
        // FakeScoringRepository returns heuristic-source frames — Gemini
        // never "reached" even though the trial requested cloud AI.
        expect(state.geminiReachedOnLastScout, isFalse);
        expect(state.cloudScoringOutcome, CloudScoringOutcome.degraded);

        final usedAfter = await StillScoutScoutQuotaTracker.usedToday();
        expect(
          usedAfter,
          usedBefore,
          reason: 'a degraded trial scout must not burn a free scout credit',
        );
        expect(
          StillScoutAiProTrialTracker.isTrialAvailable,
          isTrue,
          reason: 'the trial was never actually experienced, so it should '
              'still be available',
        );
        expect(
          StillScoutFirstScoutTracker.isFirstScout,
          isTrue,
          reason: 'failed trial must preserve the first-scout keeper bonus',
        );
      },
    );

    test(
      'rescoreWithCloudAi re-scores existing frames without re-extracting',
      () async {
        await StillScoutAiProTrialTracker.resetForTests();
        addTearDown(StillScoutAiProTrialTracker.consumeTrial);

        final videoRepo = FakeVideoRepository();
        final container = _makeContainer(videoRepo: videoRepo);
        addTearDown(container.dispose);

        await container
            .read(stillScoutProvider.notifier)
            .processVideo('/fake/video.mp4');

        var state = container.read(stillScoutProvider);
        expect(state.cloudScoringOutcome, CloudScoringOutcome.degraded);
        expect(videoRepo.extractCallCount, 1);

        await container.read(stillScoutProvider.notifier).rescoreWithCloudAi();

        expect(
          videoRepo.extractCallCount,
          1,
          reason: 'rescoreWithCloudAi must not re-run extraction',
        );
        state = container.read(stillScoutProvider);
        expect(state.phase, StillScoutPhase.complete);
        expect(state.frames, isNotEmpty);
      },
    );

    test(
      'abortForOffline does not cancel a scout that is already scoring',
      () async {
        final gate = Completer<void>();
        final container = _makeContainer(
          scoringRepo: FakeScoringRepository(blockUntil: gate.future),
        );
        addTearDown(container.dispose);

        final notifier = container.read(stillScoutProvider.notifier);
        final future = notifier.processVideo('/fake/video.mp4');

        // Wait until the scout reaches the scoring phase.
        while (container.read(stillScoutProvider).phase !=
            StillScoutPhase.scoring) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }

        // Simulate connectivity dropping mid-scout — should not cancel once
        // scoring has begun (W2.5: soft-degrade over hard cancel).
        notifier.abortForOffline();
        gate.complete();
        await future;

        final state = container.read(stillScoutProvider);
        expect(state.phase, isNot(StillScoutPhase.cancelled));
      },
    );
  });
}

// ── secure storage mock ───────────────────────────────────────────────────────

/// Stubs the flutter_secure_storage MethodChannel with an in-memory map so
/// Keychain-backed trackers work correctly in unit tests.
void _setupSecureStorageMock() {
  final store = <String, String>{};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (call) async {
      switch (call.method) {
        case 'write':
          store[call.arguments['key'] as String] =
              call.arguments['value'] as String? ?? '';
          return null;
        case 'read':
          return store[call.arguments['key'] as String];
        case 'delete':
          store.remove(call.arguments['key'] as String);
          return null;
        case 'readAll':
          return Map<String, String>.from(store);
        case 'deleteAll':
          store.clear();
          return null;
        case 'containsKey':
          return store.containsKey(call.arguments['key'] as String);
        default:
          return null;
      }
    },
  );
}

// ── test doubles ──────────────────────────────────────────────────────────────

/// Video repo that blocks extraction until cancelled.
class _NeverExtractingVideoRepo implements VideoRepository {
  @override
  Future<Duration?> readDuration(String videoPath) async =>
      const Duration(seconds: 5);

  @override
  Future<List<ExtractedFrame>> extractFrames({
    required String videoPath,
    required String sessionId,
    int? trimStartMs,
    int? trimEndMs,
    int? knownDurationMs,
    void Function(FrameExtractionProgress p)? onProgress,
    StillScoutCancelToken? cancelToken,
  }) async {
    // Poll for cancellation every 10ms.
    while (true) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      if (cancelToken?.isCancelled ?? false) {
        throw const CancelledFailure();
      }
    }
  }

  @override
  Future<List<ExtractedFrame>> deduplicateFrames(
          List<ExtractedFrame> frames) async =>
      frames;

  @override
  Future<void> runCacheJanitor() async {}
}
