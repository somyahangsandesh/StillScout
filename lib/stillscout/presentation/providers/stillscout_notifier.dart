import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/extracted_frame.dart';
import '../../data/models/scored_frame.dart';
import '../../data/models/stillscout_session.dart';
import '../../domain/failures/stillscout_failure.dart';
import '../../domain/repositories/scoring_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/repositories/video_repository.dart';
import '../../domain/stillscout_access_policy.dart';
import '../../domain/stillscout_constants.dart';
import '../../services/stillscout_cancel_token.dart';
import '../../services/stillscout_connectivity.dart';
import '../../services/stillscout_scout_background.dart';
import '../../services/stillscout_scout_quota_tracker.dart';
import '../../services/stillscout_subscription_manager.dart';
import 'stillscout_connectivity_provider.dart';
import 'stillscout_repository_providers.dart';

enum StillScoutPhase { idle, extracting, scoring, complete, error, cancelled }

class StillScoutState {
  const StillScoutState({
    this.phase = StillScoutPhase.idle,
    this.progress = 0,
    this.statusMessage = '',
    this.videoPath,
    this.videoDurationMs,
    this.trimStartMs,
    this.trimEndMs,
    this.frames = const [],
    this.topPicks = const [],
    this.liveFrames = const [],
    this.errorMessage,
    this.exportsUsedThisSession = 0,
    this.isPro = false,
    this.sessionId,
    this.processingTimeMs,
    this.videoContext = StillScoutVideoContext.auto,
  });

  final StillScoutPhase phase;
  final double progress;
  final String statusMessage;
  final String? videoPath;

  /// Duration read immediately after picking a video for the pre-flight
  /// estimate shown before extraction starts.
  final int? videoDurationMs;

  /// Trim range set by [StillScoutTrimScrubber]. Null = no trim applied.
  final int? trimStartMs;
  final int? trimEndMs;

  final List<ScoredFrame> frames;

  /// Diversity-aware subset of [frames] for the hero carousel.
  final List<ScoredFrame> topPicks;

  /// Frames extracted so far — powers the live filmstrip during extraction.
  final List<ExtractedFrame> liveFrames;

  final String? errorMessage;
  final int exportsUsedThisSession;
  final bool isPro;

  /// Stable ID for the current session — used as the key in Hive and as the
  /// name of the persistent frame cache directory.
  final String? sessionId;

  /// Wall-clock ms elapsed during extraction + scoring.
  final int? processingTimeMs;

  /// Creator-declared video intent for scoring weight overrides.
  final StillScoutVideoContext videoContext;

  bool get isBusy =>
      phase == StillScoutPhase.extracting || phase == StillScoutPhase.scoring;

  int get estimatedFrameCount {
    final durationMs = videoDurationMs ?? 0;
    final startMs = trimStartMs ?? 0;
    final endMs = trimEndMs ?? durationMs;
    final effective = (endMs - startMs).clamp(0, durationMs);
    if (effective == 0) return 0;
    const intervalMs = StillScoutConstants.frameIntervalMs;
    const maxFrames = StillScoutConstants.maxFramesPerVideo;
    final naive = (effective / intervalMs).ceil();
    return naive > maxFrames ? maxFrames : naive;
  }

  StillScoutState copyWith({
    StillScoutPhase? phase,
    double? progress,
    String? statusMessage,
    String? videoPath,
    int? videoDurationMs,
    int? trimStartMs,
    int? trimEndMs,
    List<ScoredFrame>? frames,
    List<ScoredFrame>? topPicks,
    List<ExtractedFrame>? liveFrames,
    String? errorMessage,
    int? exportsUsedThisSession,
    bool? isPro,
    String? sessionId,
    int? processingTimeMs,
    StillScoutVideoContext? videoContext,
    bool clearError = false,
    bool clearVideo = false,
    bool clearTrim = false,
    bool clearSession = false,
    bool clearLiveFrames = false,
  }) {
    return StillScoutState(
      phase: phase ?? this.phase,
      progress: progress ?? this.progress,
      statusMessage: statusMessage ?? this.statusMessage,
      videoPath: clearVideo ? null : (videoPath ?? this.videoPath),
      videoDurationMs: clearVideo ? null : (videoDurationMs ?? this.videoDurationMs),
      trimStartMs: clearTrim ? null : (trimStartMs ?? this.trimStartMs),
      trimEndMs: clearTrim ? null : (trimEndMs ?? this.trimEndMs),
      frames: frames ?? this.frames,
      topPicks: topPicks ?? this.topPicks,
      liveFrames: clearLiveFrames ? const [] : (liveFrames ?? this.liveFrames),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      exportsUsedThisSession:
          exportsUsedThisSession ?? this.exportsUsedThisSession,
      isPro: isPro ?? this.isPro,
      sessionId: clearSession ? null : (sessionId ?? this.sessionId),
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
      videoContext: videoContext ?? this.videoContext,
    );
  }
}

class StillScoutNotifier extends StateNotifier<StillScoutState> {
  StillScoutNotifier({
    required VideoRepository videoRepository,
    required ScoringRepository scoringRepository,
    required SessionRepository sessionRepository,
    StillScoutConnectivity? connectivity,
  })  : _videoRepo = videoRepository,
        _scoringRepo = scoringRepository,
        _sessionRepo = sessionRepository,
        _connectivity = connectivity ?? StillScoutConnectivity(),
        super(const StillScoutState()) {
    _refreshSubscriptionState();
  }

  final VideoRepository _videoRepo;
  final ScoringRepository _scoringRepo;
  final SessionRepository _sessionRepo;
  final StillScoutConnectivity _connectivity;
  StillScoutCancelToken? _cancelToken;
  bool _abortingForOffline = false;

  static const _uuid = Uuid();

  void _throwIfCancelled(StillScoutCancelToken token) {
    if (token.isCancelled) throw const CancelledFailure();
  }

  Future<void> _ensureOnline() async {
    if (!await _connectivity.isOnline) throw const OfflineFailure();
  }

  Future<void> _guardOnlineDuringScout(StillScoutCancelToken token) async {
    if (token.isCancelled || !mounted) return;
    if (!await _connectivity.isOnline) {
      _abortingForOffline = true;
      token.cancel();
    }
  }

  Future<void> _refreshSubscriptionState() async {
    final isPro = await StillScoutSubscriptionManager.isProUser();
    if (mounted) state = state.copyWith(isPro: isPro);
  }

  /// Records polished export(s) against this scout session for free users.
  void consumeSessionExports(int count) {
    if (state.isPro || count <= 0) return;
    if (!StillScoutAccessPolicy.canExportThisSession(
      isPro: false,
      exportsUsedThisSession: state.exportsUsedThisSession,
      count: count,
    )) {
      return;
    }
    state = state.copyWith(
      exportsUsedThisSession: state.exportsUsedThisSession + count,
    );
  }

  /// Called after the user picks a video. Reads duration for the pre-flight
  /// estimate immediately, before the user taps "Start Scout."
  Future<void> onVideoPicked(String videoPath) async {
    final duration = await _videoRepo.readDuration(videoPath);
    if (!mounted) return;
    state = state.copyWith(
      videoPath: videoPath,
      videoDurationMs: duration?.inMilliseconds,
      clearTrim: true,
      clearError: true,
    );
  }

  void setTrimRange(int startMs, int endMs) {
    state = state.copyWith(trimStartMs: startMs, trimEndMs: endMs);
  }

  void setVideoContext(StillScoutVideoContext context) {
    state = state.copyWith(videoContext: context);
  }

  Future<void> processVideo(String videoPath) async {
    _abortingForOffline = false;
    if (!await _connectivity.isOnline) {
      if (mounted) {
        state = state.copyWith(
          phase: StillScoutPhase.error,
          errorMessage: const OfflineFailure().displayMessage,
        );
      }
      return;
    }

    await _refreshSubscriptionState();
    if (!mounted) return;

    if (!await StillScoutScoutQuotaTracker.canStartScout(isPro: state.isPro)) {
      if (mounted) {
        state = state.copyWith(
          phase: StillScoutPhase.error,
          errorMessage: const ScoutQuotaExhaustedFailure().displayMessage,
        );
      }
      return;
    }

    final cancelToken = StillScoutCancelToken();
    _cancelToken = cancelToken;
    final sessionId = _uuid.v4();
    final startTime = DateTime.now();
    final weights = state.videoContext.scoreWeights;

    state = state.copyWith(
      phase: StillScoutPhase.extracting,
      progress: 0,
      statusMessage: 'Reading your clip…',
      videoPath: videoPath,
      frames: const [],
      topPicks: const [],
      liveFrames: const [],
      sessionId: sessionId,
      exportsUsedThisSession: 0,
      clearError: true,
      clearLiveFrames: true,
    );

    await StillScoutScoutBackground.begin(
      statusMessage: 'Extracting frames from your clip…',
    );

    try {
      var extracted = await _videoRepo.extractFrames(
        videoPath: videoPath,
        sessionId: sessionId,
        trimStartMs: state.trimStartMs,
        trimEndMs: state.trimEndMs,
        knownDurationMs: state.videoDurationMs,
        cancelToken: cancelToken,
        onProgress: (snapshot) {
          if (!mounted) return;
          _throwIfCancelled(cancelToken);
          unawaited(_guardOnlineDuringScout(cancelToken));
          state = state.copyWith(
            progress: 0.02 + snapshot.progress * 0.53,
            statusMessage: snapshot.statusMessage,
            liveFrames: snapshot.extractedFrames,
          );
          unawaited(
            StillScoutScoutBackground.updateStatus(snapshot.statusMessage),
          );
        },
      );

      if (!mounted) return;
      _throwIfCancelled(cancelToken);

      // De-duplicate before scoring to cut LLM spend on static footage.
      extracted = await _videoRepo.deduplicateFrames(extracted);

      if (!mounted) return;
      _throwIfCancelled(cancelToken);
      await _ensureOnline();

      state = state.copyWith(
        phase: StillScoutPhase.scoring,
        progress: 0.60,
        statusMessage: 'Asking the AI scout to judge each frame…',
      );
      await StillScoutScoutBackground.updateStatus(
        'AI is ranking your best frames…',
      );

      final scored = await _scoringRepo.scoreAndRankFrames(
        extracted,
        videoPath: videoPath,
        scoreWeights: weights,
        cancelToken: cancelToken,
        requireCloudAi: true,
        onProgress: (p) {
          if (!mounted) return;
          _throwIfCancelled(cancelToken);
          unawaited(_guardOnlineDuringScout(cancelToken));
          state = state.copyWith(
            progress: 0.60 + p * 0.40,
            statusMessage: 'Asking the AI scout to judge each frame…',
          );
        },
      );

      if (!mounted) return;
      _throwIfCancelled(cancelToken);

      final topPicks = _scoringRepo.selectTopPicks(scored);
      final processingTimeMs =
          DateTime.now().difference(startTime).inMilliseconds;

      await _refreshSubscriptionState();

      if (!mounted) return;

      state = state.copyWith(
        phase: StillScoutPhase.complete,
        progress: 1,
        statusMessage: 'Scout complete',
        frames: scored,
        topPicks: topPicks,
        processingTimeMs: processingTimeMs,
      );

      await _persistSession(
        sessionId: sessionId,
        videoPath: videoPath,
        scored: scored,
        topPicks: topPicks,
        processingTimeMs: processingTimeMs,
      );

      if (!state.isPro && scored.isNotEmpty) {
        await StillScoutScoutQuotaTracker.recordCompletedScout(
          isPro: state.isPro,
        );
      }
    } on CancelledFailure {
      if (mounted) {
        if (_abortingForOffline) {
          state = state.copyWith(
            phase: StillScoutPhase.error,
            errorMessage: const OfflineFailure().displayMessage,
          );
        } else {
          state = state.copyWith(
            phase: StillScoutPhase.cancelled,
            statusMessage: 'Scout cancelled',
          );
        }
      }
    } on StillScoutFailure catch (f) {
      if (mounted) {
        state = state.copyWith(
          phase: StillScoutPhase.error,
          errorMessage: f.displayMessage,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          phase: StillScoutPhase.error,
          errorMessage: UnknownFailure(e).displayMessage,
        );
      }
    } finally {
      _abortingForOffline = false;
      await StillScoutScoutBackground.end();
      if (identical(_cancelToken, cancelToken)) _cancelToken = null;
    }
  }

  Future<void> _persistSession({
    required String sessionId,
    required String videoPath,
    required List<ScoredFrame> scored,
    required List<ScoredFrame> topPicks,
    required int processingTimeMs,
  }) async {
    if (scored.isEmpty) return;
    final best = scored.first;
    try {
      // Persist full frame data; UI/access policy gates visibility at read time.
      final topSnapshots = scored
          .take(StillScoutConstants.maxFramesPerVideo)
          .map((frame) => StillScoutAccessPolicy.toPersistedJson(frame: frame))
          .toList(growable: false);
      final session = StillScoutSession(
        id: sessionId,
        videoPath: videoPath,
        createdAt: DateTime.now(),
        frameCount: scored.length,
        topScore: best.score,
        topFrameThumbPath: best.frame.filePath,
        videoDurationMs: state.videoDurationMs,
        processingTimeMs: processingTimeMs,
        topFrameSnapshots: topSnapshots,
        topPickFrameIds:
            topPicks.map((f) => f.frame.id).toList(growable: false),
      );
      await _sessionRepo.saveSession(session);
      await _sessionRepo.evictOldSessions();
    } catch (e, st) {
      // Session persistence is best-effort; never fail the UI over it.
      if (kDebugMode) {
        debugPrint('[StillScout] Session persist failed: $e\n$st');
      }
    }
  }

  void cancelProcessing() => _cancelToken?.cancel();

  /// Called when connectivity drops mid-scout — cancels work and surfaces offline error.
  void abortForOffline() {
    if (!state.isBusy) return;
    _abortingForOffline = true;
    _cancelToken?.cancel();
  }

  /// Exposes the session repository for the History screen to consume.
  SessionRepository getSessionRepository() => _sessionRepo;

  void reset() {
    _cancelToken?.cancel();
    _cancelToken = null;
    state = const StillScoutState();
    _refreshSubscriptionState();
  }

  /// Keeps the picked video but clears scout results (gallery → pre-flight).
  void returnToPreFlight() {
    _cancelToken?.cancel();
    _cancelToken = null;
    state = state.copyWith(
      phase: StillScoutPhase.idle,
      progress: 0,
      statusMessage: '',
      frames: const [],
      topPicks: const [],
      exportsUsedThisSession: 0,
      clearSession: true,
      processingTimeMs: null,
      clearError: true,
      clearLiveFrames: true,
    );
  }

  /// Clears the picked video and returns to the empty home state.
  void clearVideoSelection() {
    _cancelToken?.cancel();
    _cancelToken = null;
    state = state.copyWith(
      phase: StillScoutPhase.idle,
      progress: 0,
      statusMessage: '',
      clearVideo: true,
      clearTrim: true,
      frames: const [],
      topPicks: const [],
      exportsUsedThisSession: 0,
      clearSession: true,
      processingTimeMs: null,
      clearError: true,
      clearLiveFrames: true,
    );
  }

  Future<void> refreshSubscriptionState() => _refreshSubscriptionState();
}

final stillScoutProvider =
    StateNotifierProvider<StillScoutNotifier, StillScoutState>(
  (ref) => StillScoutNotifier(
    videoRepository: ref.watch(videoRepositoryProvider),
    scoringRepository: ref.watch(scoringRepositoryProvider),
    sessionRepository: ref.watch(sessionRepositoryProvider),
    connectivity: ref.watch(stillScoutConnectivityProvider),
  ),
);
