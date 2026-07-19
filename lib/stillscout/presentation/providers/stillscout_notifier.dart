import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:stillscout/services/stillscout_purchase_service.dart';

import '../../data/models/extracted_frame.dart';
import '../../data/models/frame_score_metadata.dart';
import '../../data/models/scored_frame.dart';
import '../../domain/failures/stillscout_failure.dart';
import '../../domain/repositories/scoring_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/repositories/video_repository.dart';
import '../../domain/stillscout_access_policy.dart';
import '../../domain/stillscout_constants.dart';
import '../../services/stillscout_auto_polish.dart';
import '../../services/stillscout_cancel_token.dart';
import '../../services/stillscout_cloud_quota_tracker.dart';
import '../../services/stillscout_connectivity.dart';
import '../../services/stillscout_scout_background.dart';
import '../../services/stillscout_scout_quota_tracker.dart';
import '../../services/stillscout_subscription_manager.dart';
import '../../services/stillscout_top_picks_selector.dart';
import 'stillscout_connectivity_provider.dart';
import 'stillscout_quota_coordinator.dart';
import 'stillscout_repository_providers.dart';
import 'stillscout_session_writer.dart';

enum StillScoutPhase { idle, extracting, scoring, complete, error, cancelled }

/// Outcome of the cloud (Gemini) scoring attempt for the last completed scout.
///
/// - [notApplicable]: free, on-device-only scout — cloud AI was never used.
/// - [full]: cloud AI was used and Gemini scored the frames successfully.
/// - [degraded]: cloud AI was requested but Gemini was unreachable/failed —
///   Vision/heuristic scores were shown instead (soft-degrade, W1.2).
/// - [quotaExceeded]: cloud AI was requested but the shared device-side daily
///   cloud quota was exhausted, so Gemini was never attempted.
enum CloudScoringOutcome { notApplicable, full, degraded, quotaExceeded }

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
    this.framesExtracted = 0,
    this.totalFrames = 0,
    this.errorMessage,
    this.exportsUsedThisSession = 0,
    this.isPro = false,
    this.subscriptionCheckFailed = false,
    this.isAiProTrial = false,
    this.isFirstScout = false,
    this.geminiReachedOnLastScout = true,
    this.cloudScoringOutcome = CloudScoringOutcome.notApplicable,
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

  /// Count of frames extracted so far during the extraction phase.
  final int framesExtracted;

  /// Total frames expected for this extraction pass, once known.
  final int totalFrames;

  final String? errorMessage;
  final int exportsUsedThisSession;
  final bool isPro;

  /// True when the last store entitlement check failed (network / IAP init).
  /// UI should offer retry — do not treat as permanent Free.
  final bool subscriptionCheckFailed;

  /// True while this specific scout is running (or just completed) using the
  /// one-time complimentary AI Pro trial. Used to show a "Trial" badge on
  /// the processing screen and the completion hero.
  final bool isAiProTrial;

  /// True when this is the user's first-ever completed scout. Gives free users
  /// a first-scout keeper bonus (8 visible frames instead of 5) so they experience the
  /// app at its best before being asked to upgrade.
  final bool isFirstScout;

  /// True when the last completed AI Pro scout successfully reached Gemini.
  /// False means Gemini was unavailable and Vision-only scores were shown.
  /// Only meaningful when [phase] == [StillScoutPhase.complete] and [isPro].
  final bool geminiReachedOnLastScout;

  /// Cloud (Gemini) scoring outcome for the last completed scout. Drives the
  /// degraded banner + Retry CTA on the completion hero.
  final CloudScoringOutcome cloudScoringOutcome;

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
    int? framesExtracted,
    int? totalFrames,
    String? errorMessage,
    int? exportsUsedThisSession,
    bool? isPro,
    bool? subscriptionCheckFailed,
    bool? isAiProTrial,
    bool? isFirstScout,
    bool? geminiReachedOnLastScout,
    CloudScoringOutcome? cloudScoringOutcome,
    String? sessionId,
    int? processingTimeMs,
    StillScoutVideoContext? videoContext,
    bool clearError = false,
    bool clearVideo = false,
    bool clearTrim = false,
    bool clearSession = false,
    bool clearLiveFrames = false,
    bool clearDuration = false,
  }) {
    return StillScoutState(
      phase: phase ?? this.phase,
      progress: progress ?? this.progress,
      statusMessage: statusMessage ?? this.statusMessage,
      videoPath: clearVideo ? null : (videoPath ?? this.videoPath),
      videoDurationMs: clearVideo || clearDuration
          ? null
          : (videoDurationMs ?? this.videoDurationMs),
      trimStartMs: clearTrim ? null : (trimStartMs ?? this.trimStartMs),
      trimEndMs: clearTrim ? null : (trimEndMs ?? this.trimEndMs),
      frames: frames ?? this.frames,
      topPicks: topPicks ?? this.topPicks,
      liveFrames: clearLiveFrames ? const [] : (liveFrames ?? this.liveFrames),
      framesExtracted:
          clearLiveFrames ? 0 : (framesExtracted ?? this.framesExtracted),
      totalFrames: clearLiveFrames ? 0 : (totalFrames ?? this.totalFrames),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      exportsUsedThisSession:
          exportsUsedThisSession ?? this.exportsUsedThisSession,
      isPro: isPro ?? this.isPro,
      subscriptionCheckFailed:
          subscriptionCheckFailed ?? this.subscriptionCheckFailed,
      isAiProTrial: isAiProTrial ?? this.isAiProTrial,
      isFirstScout: isFirstScout ?? this.isFirstScout,
      geminiReachedOnLastScout:
          geminiReachedOnLastScout ?? this.geminiReachedOnLastScout,
      cloudScoringOutcome: cloudScoringOutcome ?? this.cloudScoringOutcome,
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
        _sessionWriter = StillScoutSessionWriter(sessionRepository),
        super(const StillScoutState()) {
    _init();
  }

  Future<void> _init() async {
    await Future.wait([
      StillScoutFirstScoutTracker.load(),
      StillScoutAiProTrialTracker.load(),
      StillScoutScoutQuotaTracker.load(),
    ]);
    await _refreshSubscriptionState();
    if (mounted) {
      state = state.copyWith(
        isFirstScout: StillScoutFirstScoutTracker.isFirstScout,
      );
    }
  }

  final VideoRepository _videoRepo;
  final ScoringRepository _scoringRepo;
  final SessionRepository _sessionRepo;
  final StillScoutConnectivity _connectivity;
  final StillScoutSessionWriter _sessionWriter;
  final StillScoutQuotaCoordinator _quotaCoordinator =
      const StillScoutQuotaCoordinator();
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
    final result = await StillScoutSubscriptionManager.checkSubscription();
    if (mounted) {
      state = state.copyWith(
        isPro: result.isPro,
        subscriptionCheckFailed: result.checkFailed,
      );
    }
  }

  /// Apply purchase/restore [hasPro] immediately — avoids a failed refresh
  /// leaving the user on Free after a successful store transaction.
  void onPurchaseCompleted({required bool hasPro}) {
    if (!mounted) return;
    state = state.copyWith(
      isPro: hasPro,
      subscriptionCheckFailed: false,
    );
  }

  /// Records gallery export(s) against this scout session for free users
  /// and persists the counter so History can't reset the cap.
  Future<void> consumeSessionExports(int count) async {
    if (state.isPro || count <= 0) return;
    if (!StillScoutAccessPolicy.canExportThisSession(
      isPro: false,
      exportsUsedThisSession: state.exportsUsedThisSession,
      count: count,
    )) {
      return;
    }
    final next = state.exportsUsedThisSession + count;
    state = state.copyWith(exportsUsedThisSession: next);
    await _persistExportsUsed(next);
  }

  Future<void> _persistExportsUsed(int exportsUsed) async {
    final sessionId = state.sessionId;
    if (sessionId == null) return;
    try {
      final existing = await _sessionRepo.getSession(sessionId);
      if (existing == null) return;
      await _sessionRepo.saveSession(
        existing.copyWith(exportsUsed: exportsUsed),
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[StillScout] Export quota persist failed: $e\n$st');
      }
    }
  }

  /// Called after the user picks a video. Reads duration for the pre-flight
  /// estimate immediately, before the user taps "Start Scout."
  Future<void> onVideoPicked(String videoPath) async {
    final duration = await _videoRepo.readDuration(videoPath);
    if (!mounted) return;
    final durationMs = duration?.inMilliseconds;
    if (durationMs == null || durationMs <= 0) {
      state = state.copyWith(
        clearVideo: true,
        clearTrim: true,
        phase: StillScoutPhase.error,
        errorMessage: const VideoUnreadableFailure().displayMessage,
      );
      return;
    }
    if (durationMs > StillScoutConstants.maxVideoDurationMs) {
      // Keep the pick, but clamp the default scout range to the 10-minute
      // product limit so we extract across a full allowed window.
      state = state.copyWith(
        videoPath: videoPath,
        videoDurationMs: durationMs,
        trimStartMs: 0,
        trimEndMs: StillScoutConstants.maxVideoDurationMs,
        phase: StillScoutPhase.idle,
        clearError: true,
      );
      return;
    }
    state = state.copyWith(
      videoPath: videoPath,
      videoDurationMs: durationMs,
      clearTrim: true,
      clearDuration: false,
      phase: StillScoutPhase.idle,
      clearError: true,
    );
  }

  void setTrimRange(int startMs, int endMs) {
    state = state.copyWith(trimStartMs: startMs, trimEndMs: endMs);
  }

  void setVideoContext(StillScoutVideoContext context) {
    if (state.phase == StillScoutPhase.complete && state.frames.isNotEmpty) {
      _rerankWithContext(context);
    } else {
      state = state.copyWith(videoContext: context);
    }
  }

  /// Re-ranks already-scored frames using [newContext]'s score weights without
  /// re-extracting anything. Instant — pure in-memory sort on existing metadata.
  ///
  /// Gemini's explicit top-scout selections ([ScoredFrame.isTopScout]) are
  /// preserved: only their numeric score changes, never their "was hand-picked
  /// by Gemini" status. This prevents context weight tweaks from demoting frames
  /// that Gemini judged best in a comparative review.
  void _rerankWithContext(StillScoutVideoContext newContext) {
    final weights = newContext.scoreWeights;
    final reranked = state.frames
        .map((f) => f.copyWith(score: f.metadata.totalScore(weights)))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    // Keep Gemini-picked frames in topPicks; for non-AI scouts re-derive.
    final hasGeminiPicks = reranked.any((f) => f.isTopScout);
    final topPicks = hasGeminiPicks
        ? StillScoutTopPicksSelector.geminiOrderedTopPicks(reranked)
        : _scoringRepo.selectTopPicks(reranked);

    state = state.copyWith(
      frames: reranked,
      topPicks: topPicks,
      videoContext: newContext,
    );
  }

  /// Analyses scored frames to infer the best-fit video context.
  /// Only overrides [auto] — portrait/landscape/action selected before
  /// scouting are always honoured.
  ///
  /// Thresholds tuned for Vision's improved (0–100) score range:
  ///   – eyeScore 60+ reliably indicates a detected, open-eyed face.
  ///   – compositionScore 65+ signals clean, well-lit scenic framing.
  ///   – High blur variance + low mean blur = fast-moving subjects.
  StillScoutVideoContext _autoDetectContext(List<ScoredFrame> scored) {
    if (scored.isEmpty) return StillScoutVideoContext.auto;
    // Sample a representative cross-section: top-half of scored frames.
    final sample = scored.take(scored.length.clamp(1, 30)).toList();
    final n = sample.length;

    final meanEyes = sample
            .map((f) => f.metadata.openEyesScore.toDouble())
            .reduce((a, b) => a + b) /
        n;
    final meanComposition = sample
            .map((f) => f.metadata.compositionScore.toDouble())
            .reduce((a, b) => a + b) /
        n;
    final blurValues =
        sample.map((f) => f.metadata.blurScore.toDouble()).toList();
    final meanBlur = blurValues.reduce((a, b) => a + b) / n;
    final blurVariance = blurValues
            .map((b) => (b - meanBlur) * (b - meanBlur))
            .reduce((a, b) => a + b) /
        n;

    // --- Portrait: strong face signal across the sample ---
    // With improved Vision (multi-face + EAR sigmoid), scores above 60
    // reliably mean open-eyed, well-posed faces were detected.
    if (meanEyes > 60) return StillScoutVideoContext.portrait;

    // --- Landscape: good composition + no dominant faces ---
    // Saliency boost means high compositionScore now genuinely indicates a
    // clear subject (scenery, architecture, etc.).
    if (meanComposition > 65 && meanEyes < 45) {
      return StillScoutVideoContext.landscape;
    }

    // --- Action: blur variance signals mixed-motion footage ---
    // Some frames very sharp (stationary subject), others blurry (motion) —
    // high variance is a reliable action/sport indicator.
    if (blurVariance > 320 && meanBlur < 68) {
      return StillScoutVideoContext.action;
    }

    return StillScoutVideoContext.auto;
  }

  Future<void> processVideo(String videoPath) async {
    _abortingForOffline = false;
    await _refreshSubscriptionState();
    if (!mounted) return;

    // Always reset the trial badge first so non-trial scouts never show it.
    if (mounted) state = state.copyWith(isAiProTrial: false);

    // AI Pro trial: give brand-new free users one complimentary Gemini scout.
    final trialActive =
        !state.isPro && StillScoutAiProTrialTracker.isTrialAvailable;
    final useCloudAi =
        StillScoutAccessPolicy.canUseCloudAi(isPro: state.isPro) || trialActive;

    // Flag trial on state so UI can show the "AI Trial" badge.
    if (trialActive && mounted) {
      state = state.copyWith(isAiProTrial: true);
    }

    // Free scouts are on-device only — no network required.
    // AI Pro (and trial) needs connectivity for Gemini Flash.
    if (useCloudAi && !await _connectivity.isOnline) {
      if (mounted) {
        state = state.copyWith(
          phase: StillScoutPhase.error,
          errorMessage: const OfflineFailure().displayMessage,
          isAiProTrial: false, // clear badge — scout never started
        );
      }
      return;
    }

    if (!await StillScoutScoutQuotaTracker.canStartScout(isPro: state.isPro)) {
      if (mounted) {
        state = state.copyWith(
          phase: StillScoutPhase.error,
          errorMessage: const ScoutQuotaExhaustedFailure().displayMessage,
          isAiProTrial: false, // clear badge — scout never started
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
          // Only abort for offline when cloud AI is in use — free on-device
          // scouts work without a network connection.
          if (useCloudAi) unawaited(_guardOnlineDuringScout(cancelToken));
          state = state.copyWith(
            progress: 0.02 + snapshot.progress * 0.53,
            statusMessage: snapshot.statusMessage,
            liveFrames: snapshot.extractedFrames,
            framesExtracted: snapshot.framesExtracted,
            totalFrames: snapshot.totalFrames,
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
      if (useCloudAi) await _ensureOnline();

      final scoringMessage = useCloudAi
          ? 'Gemini is analysing up to 48 frames in one pass…'
          : 'On-device Vision is ranking your frames…';

      state = state.copyWith(
        phase: StillScoutPhase.scoring,
        progress: 0.60,
        statusMessage: scoringMessage,
      );
      await StillScoutScoutBackground.updateStatus(scoringMessage);

      final scored = await _scoringRepo.scoreAndRankFrames(
        extracted,
        videoPath: videoPath,
        scoreWeights: weights,
        videoContext: state.videoContext,
        cancelToken: cancelToken,
        useCloudAi: useCloudAi,
        requireCloudAi: useCloudAi,
        onProgress: (p) {
          if (!mounted) return;
          _throwIfCancelled(cancelToken);
          // W2.5: once frames are extracted, prefer a graceful Vision-only
          // degrade over cancelling — do NOT abort for offline during
          // scoring. The scoring service already soft-degrades to
          // Vision/heuristic scores when Gemini is unreachable (W1.2).
          state = state.copyWith(
            progress: 0.60 + p * 0.40,
            statusMessage: scoringMessage,
          );
        },
      );

      if (!mounted) return;
      _throwIfCancelled(cancelToken);

      // Auto-detect the best context from the scored frames, but only when
      // the user left the picker on "Auto" — an explicit choice is honoured.
      var finalFrames = scored;
      var finalContext = state.videoContext;
      if (finalContext == StillScoutVideoContext.auto) {
        final detected = _autoDetectContext(scored);
        if (detected != StillScoutVideoContext.auto) {
          final detectedWeights = detected.scoreWeights;
          finalFrames = scored
              .map(
                (f) => f.copyWith(score: f.metadata.totalScore(detectedWeights)),
              )
              .toList()
            ..sort((a, b) => b.score.compareTo(a.score));
          finalContext = detected;
        }
      }

      // Cap the gallery to the top [maxGalleryFrames] frames by score so the
      // UI stays clean regardless of video length. Frames are already sorted
      // descending by score, so a simple sublist is sufficient.
      // Guarantee that every isTopScout frame is retained even if it would
      // otherwise fall outside the cap (rare but possible on Vision-only scouts
      // where Gemini picks arrived from a previous cached result).
      if (finalFrames.length > StillScoutConstants.maxGalleryFrames) {
        final topN = finalFrames.sublist(0, StillScoutConstants.maxGalleryFrames);
        final alreadyIncludedIds = topN.map((f) => f.frame.id).toSet();
        final missedTopScouts = finalFrames
            .skip(StillScoutConstants.maxGalleryFrames)
            .where((f) => f.isTopScout && !alreadyIncludedIds.contains(f.frame.id))
            .toList(growable: false);
        // Re-sort so the gallery is always in descending score order even after
        // we re-insert Gemini-picked frames that were beyond the cap boundary.
        final combined = [...topN, ...missedTopScouts]
          ..sort((a, b) => b.score.compareTo(a.score));
        finalFrames = combined;
      }

      // Prefer Gemini's explicit picks for the carousel, in Gemini's
      // best-first order (geminiPickRank). Fall back to score-based diversity.
      final geminiPicks =
          StillScoutTopPicksSelector.geminiOrderedTopPicks(finalFrames);
      final topPicks = geminiPicks.isNotEmpty
          ? geminiPicks
          : _scoringRepo.selectTopPicks(finalFrames);
      final processingTimeMs =
          DateTime.now().difference(startTime).inMilliseconds;

      await _refreshSubscriptionState();

      if (!mounted) return;

      // Reliable Gemini detection: llm source is set only when the batch
      // succeeded (Vision-only frames always carry heuristic or hybrid).
      final geminiReached = !useCloudAi ||
          finalFrames.any((f) => f.metadata.source == ScoreSource.llm);

      final cloudScoringOutcome = await _resolveCloudScoringOutcome(
        useCloudAi: useCloudAi,
        geminiReached: geminiReached,
      );

      // If every frame was hard-rejected, transition to error with a clear
      // message rather than completing with an empty gallery.
      if (finalFrames.isEmpty) {
        state = state.copyWith(
          phase: StillScoutPhase.error,
          errorMessage:
              'No usable frames found — the video may be too blurry or underexposed. '
              'Try a brighter or steadier clip.',
        );
        return;
      }

      state = state.copyWith(
        phase: StillScoutPhase.complete,
        progress: 1,
        statusMessage: 'Scout complete',
        frames: finalFrames,
        topPicks: topPicks,
        processingTimeMs: processingTimeMs,
        videoContext: finalContext,
        geminiReachedOnLastScout: geminiReached,
        cloudScoringOutcome: cloudScoringOutcome,
      );

      await _sessionWriter.persistSession(
        sessionId: sessionId,
        videoPath: videoPath,
        scored: finalFrames,
        topPicks: topPicks,
        processingTimeMs: processingTimeMs,
        videoDurationMs: state.videoDurationMs,
        exportsUsedThisSession: state.exportsUsedThisSession,
      );

      if (!state.isPro && scored.isNotEmpty) {
        // Credit rule: don't burn a free scout credit when the user was on
        // the one-time AI trial and Gemini never actually ran — they didn't
        // get the trial experience, so they should get another free attempt.
        // Consume the AI Pro trial only when Gemini actually ran and scored
        // frames — if it fell back to Vision-only, the user didn't experience
        // the trial and should get another chance when online.
        // Persist the first-scout marker to disk but do NOT flip isFirstScout
        // in the live state — the gallery must keep showing the bonus keeper
        // count while the user is browsing results. isFirstScout is cleared on
        // the next reset() / new scout so subsequent runs have the normal limit.
        await _quotaCoordinator.recordScoutCompletion(
          isPro: state.isPro,
          trialActive: trialActive,
          geminiReached: geminiReached,
          isFirstScout: StillScoutFirstScoutTracker.isFirstScout,
        );
      }

      // For Pro users, immediately pre-polish every top pick in the background
      // so the polish toggle in the detail sheet is an instant cache hit —
      // no waiting. Runs frame-by-frame to stay off the main thread.
      if (state.isPro && topPicks.isNotEmpty) {
        unawaited(_prePolishTopPicks(topPicks));
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

  /// Resolves the [CloudScoringOutcome] for the scout that just finished.
  Future<CloudScoringOutcome> _resolveCloudScoringOutcome({
    required bool useCloudAi,
    required bool geminiReached,
  }) async {
    if (!useCloudAi) return CloudScoringOutcome.notApplicable;
    if (geminiReached) return CloudScoringOutcome.full;
    final hasQuota = await StillScoutCloudQuotaTracker.hasRemaining();
    return hasQuota
        ? CloudScoringOutcome.degraded
        : CloudScoringOutcome.quotaExceeded;
  }

  /// W2.4 — Re-scores already-extracted frames with Gemini, without
  /// re-running extraction. Used by the completion hero's Retry CTA when a
  /// scout degraded to Vision-only scoring ([CloudScoringOutcome.degraded]).
  Future<void> rescoreWithCloudAi() async {
    if (!mounted || state.phase != StillScoutPhase.complete) return;
    final videoPath = state.videoPath;
    final sessionId = state.sessionId;
    if (videoPath == null || state.frames.isEmpty) return;
    if (!await _connectivity.isOnline) return;

    final previousFrames = state.frames;
    final previousTopPicks = state.topPicks;
    final previousOutcome = state.cloudScoringOutcome;
    final previousProcessingTimeMs = state.processingTimeMs;

    final cancelToken = StillScoutCancelToken();
    _cancelToken = cancelToken;
    final startTime = DateTime.now();
    final weights = state.videoContext.scoreWeights;
    final extractedFrames =
        state.frames.map((f) => f.frame).toList(growable: false);

    state = state.copyWith(
      phase: StillScoutPhase.scoring,
      progress: 0.60,
      statusMessage: 'Retrying with Gemini…',
      clearError: true,
    );

    try {
      final scored = await _scoringRepo.scoreAndRankFrames(
        extractedFrames,
        videoPath: videoPath,
        scoreWeights: weights,
        videoContext: state.videoContext,
        cancelToken: cancelToken,
        useCloudAi: true,
        requireCloudAi: true,
        onProgress: (p) {
          if (!mounted) return;
          _throwIfCancelled(cancelToken);
          state = state.copyWith(progress: 0.60 + p * 0.40);
        },
      );

      if (!mounted) return;
      _throwIfCancelled(cancelToken);

      var finalFrames = scored;
      if (finalFrames.length > StillScoutConstants.maxGalleryFrames) {
        final topN =
            finalFrames.sublist(0, StillScoutConstants.maxGalleryFrames);
        final alreadyIncludedIds = topN.map((f) => f.frame.id).toSet();
        final missedTopScouts = finalFrames
            .skip(StillScoutConstants.maxGalleryFrames)
            .where((f) =>
                f.isTopScout && !alreadyIncludedIds.contains(f.frame.id))
            .toList(growable: false);
        final combined = [...topN, ...missedTopScouts]
          ..sort((a, b) => b.score.compareTo(a.score));
        finalFrames = combined;
      }

      final geminiPicks =
          StillScoutTopPicksSelector.geminiOrderedTopPicks(finalFrames);
      final topPicks = geminiPicks.isNotEmpty
          ? geminiPicks
          : _scoringRepo.selectTopPicks(finalFrames);

      final geminiReached =
          finalFrames.any((f) => f.metadata.source == ScoreSource.llm);
      final outcome = await _resolveCloudScoringOutcome(
        useCloudAi: true,
        geminiReached: geminiReached,
      );
      final processingTimeMs =
          previousProcessingTimeMs ?? DateTime.now().difference(startTime).inMilliseconds;

      state = state.copyWith(
        phase: StillScoutPhase.complete,
        progress: 1,
        statusMessage: 'Scout complete',
        frames: finalFrames,
        topPicks: topPicks,
        geminiReachedOnLastScout: geminiReached,
        cloudScoringOutcome: outcome,
      );

      if (sessionId != null) {
        await _sessionWriter.persistSession(
          sessionId: sessionId,
          videoPath: videoPath,
          scored: finalFrames,
          topPicks: topPicks,
          processingTimeMs: processingTimeMs,
          videoDurationMs: state.videoDurationMs,
          exportsUsedThisSession: state.exportsUsedThisSession,
        );
      }

      if (state.isPro && topPicks.isNotEmpty && geminiReached) {
        unawaited(_prePolishTopPicks(topPicks));
      }
    } on StillScoutFailure {
      if (mounted) {
        state = state.copyWith(
          phase: StillScoutPhase.complete,
          frames: previousFrames,
          topPicks: previousTopPicks,
          cloudScoringOutcome: previousOutcome,
        );
      }
    } catch (_) {
      if (mounted) {
        state = state.copyWith(
          phase: StillScoutPhase.complete,
          frames: previousFrames,
          topPicks: previousTopPicks,
          cloudScoringOutcome: previousOutcome,
        );
      }
    } finally {
      if (identical(_cancelToken, cancelToken)) _cancelToken = null;
    }
  }

  void cancelProcessing() => _cancelToken?.cancel();

  /// Called when connectivity drops mid-scout.
  /// Only aborts AI Pro scouts — free on-device scouts run entirely offline
  /// and must never be cancelled by a connectivity change.
  ///
  /// W2.5: once extraction has finished and scoring is underway, prefer a
  /// graceful Vision-only degrade over cancelling — the frames are already
  /// extracted, so losing the scout entirely would be wasteful when the
  /// scoring service can fall back to on-device scores instead.
  void abortForOffline() {
    if (!state.isBusy) return;
    if (state.phase == StillScoutPhase.scoring) return;
    // Abort when either Pro or an active AI trial is using cloud AI.
    final needsCloud = StillScoutAccessPolicy.canUseCloudAi(isPro: state.isPro)
        || state.isAiProTrial;
    if (!needsCloud) return;
    _abortingForOffline = true;
    _cancelToken?.cancel();
  }

  /// Exposes the session repository for the History screen to consume.
  SessionRepository getSessionRepository() => _sessionRepo;

  void reset() {
    _cancelToken?.cancel();
    _cancelToken = null;
    // Re-read isFirstScout from the tracker so subsequent scouts correctly
    // reflect the persisted state (tracker was marked done after the first
    // scout completed, so next scout gets isFirstScout: false).
    state = StillScoutState(
      isPro: state.isPro,
      isFirstScout: StillScoutFirstScoutTracker.isFirstScout,
    );
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
      // Re-read from tracker so the bonus doesn't carry forward.
      isFirstScout: StillScoutFirstScoutTracker.isFirstScout,
      isAiProTrial: false,
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

  /// Settings / paywall retry after store-unavailable or checkFailed.
  Future<void> retrySubscriptionCheck() async {
    await StillScoutPurchaseService.retryInitialize();
    await _refreshSubscriptionState();
  }

  /// Pre-polishes every top-pick frame in the background immediately after a
  /// Pro scout completes. Runs sequentially to avoid memory spikes.
  /// Results land in [StillScoutAutoPolish]'s in-memory cache so the detail
  /// sheet's polish toggle is an instant cache hit — no waiting for the user.
  Future<void> _prePolishTopPicks(List<ScoredFrame> topPicks) async {
    for (final sf in topPicks) {
      if (!mounted) return;
      try {
        await StillScoutAutoPolish.polishToCache(sf.frame.filePath);
      } catch (_) {
        // Best-effort: detail sheet will polish on-demand if this fails.
      }
    }
  }
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
