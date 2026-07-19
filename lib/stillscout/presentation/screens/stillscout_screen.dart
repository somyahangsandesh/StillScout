import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/scored_frame.dart';
import '../../domain/failures/stillscout_failure.dart';
import '../../domain/stillscout_access_policy.dart';
import '../../domain/stillscout_constants.dart';
import '../../domain/stillscout_online_status.dart';
import '../../services/stillscout_export_service.dart';
import '../../services/stillscout_scout_quota_tracker.dart';
import '../../services/stillscout_subscription_manager.dart';
import '../providers/stillscout_notifier.dart';
import '../providers/stillscout_connectivity_provider.dart';
import '../providers/stillscout_repository_providers.dart';
import '../theme/stillscout_theme.dart';
import '../widgets/stillscout_logo.dart';
import '../widgets/stillscout_batch_export_bar.dart';
import '../widgets/stillscout_compare_sheet.dart';
import '../widgets/stillscout_empty_state.dart';
import '../widgets/stillscout_online_banner.dart';
import '../widgets/stillscout_crop_picker.dart';
import '../widgets/stillscout_frame_detail_sheet.dart';
import '../widgets/stillscout_paywall_sheet.dart';
import '../widgets/stillscout_coach_mark.dart';
import '../widgets/stillscout_preflight_card.dart';
import '../widgets/stillscout_processing_state.dart';
import '../widgets/stillscout_results_gallery.dart';
import '../widgets/stillscout_scout_error_views.dart';
import 'stillscout_history_screen.dart';
import 'stillscout_settings_screen.dart';

class StillScoutScreen extends ConsumerStatefulWidget {
  const StillScoutScreen({super.key});

  @override
  ConsumerState<StillScoutScreen> createState() => _StillScoutScreenState();
}

class _StillScoutScreenState extends ConsumerState<StillScoutScreen>
    with WidgetsBindingObserver {
  String _tierLabel = '';
  final Set<String> _selectedIds = {};
  bool _batchExportBusy = false;
  bool _celebrateCompletion = false;
  bool _showContextChipsMark = false;
  final _coachMarkTracker = StillScoutCoachMarkTracker();
  Timer? _cancelledResetTimer;
  bool _wasBackgroundedDuringScout = false;
  // Optimistic default so the Start Scout button is never permanently
  // disabled by a slow or failing SharedPreferences read.
  int? _scoutsRemainingToday = StillScoutConstants.freeScoutsPerDay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTierLabel();
    _loadScoutQuota();
  }

  @override
  void dispose() {
    _cancelledResetTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    final phase = ref.read(stillScoutProvider).phase;
    final isProcessing =
        phase == StillScoutPhase.extracting || phase == StillScoutPhase.scoring;

    if (!isProcessing) {
      _wasBackgroundedDuringScout = false;
      return;
    }

    if (lifecycleState == AppLifecycleState.paused) {
      _wasBackgroundedDuringScout = true;
    } else if (lifecycleState == AppLifecycleState.resumed &&
        _wasBackgroundedDuringScout &&
        mounted) {
      _wasBackgroundedDuringScout = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'StillScout is still working — keep the app open for fastest results.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: StillScoutColors.slate,
        ),
      );
    }
  }

  void _showOfflineSnack() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(const OfflineFailure().displayMessage),
        behavior: SnackBarBehavior.floating,
        backgroundColor: StillScoutColors.slate,
      ),
    );
  }

  Widget? _buildBackLeading(StillScoutState state) {
    switch (state.phase) {
      case StillScoutPhase.idle:
        if (state.videoPath == null) return null;
        return IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: StillScoutColors.chalk, size: 20),
          onPressed: () {
            ref.read(stillScoutProvider.notifier).clearVideoSelection();
            unawaited(_loadTierLabel());
          },
        );
      case StillScoutPhase.extracting:
      case StillScoutPhase.scoring:
        return IconButton(
          tooltip: 'Cancel scout',
          icon: const Icon(Icons.close_rounded, color: StillScoutColors.chalk),
          onPressed: () =>
              ref.read(stillScoutProvider.notifier).cancelProcessing(),
        );
      case StillScoutPhase.complete:
        return IconButton(
          tooltip: 'Back to video',
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: StillScoutColors.chalk, size: 20),
          onPressed: () {
            ref.read(stillScoutProvider.notifier).returnToPreFlight();
            setState(() => _selectedIds.clear());
            unawaited(_loadTierLabel());
          },
        );
      case StillScoutPhase.error:
      case StillScoutPhase.cancelled:
        return IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: StillScoutColors.chalk, size: 20),
          onPressed: () => ref.read(stillScoutProvider.notifier).reset(),
        );
    }
  }

  Future<void> _loadScoutQuota() async {
    try {
      final isPro = ref.read(stillScoutProvider).isPro;
      final remaining =
          await StillScoutScoutQuotaTracker.remainingToday(isPro: isPro);
      if (mounted) setState(() => _scoutsRemainingToday = remaining);
    } catch (_) {
      // On any failure keep the optimistic default so the button stays usable.
      if (mounted) {
        setState(
          () => _scoutsRemainingToday = StillScoutConstants.freeScoutsPerDay,
        );
      }
    }
  }

  Future<void> _maybeShowCoachMarks() async {
    // Show the context-chips coach mark first (700 ms delay so completion
    // hero animation has time to land before we throw an overlay on top).
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final showChips = await _coachMarkTracker
        .shouldShow(StillScoutCoachMarkKeys.contextChips);
    if (showChips && mounted) {
      setState(() => _showContextChipsMark = true);
      await _coachMarkTracker
          .markShown(StillScoutCoachMarkKeys.contextChips);
    }
  }

  Future<void> _loadTierLabel() async {
    final state = ref.read(stillScoutProvider);
    final label = await StillScoutSubscriptionManager.tierLabel(
      isPro: state.isPro,
      exportsUsedThisSession: state.exportsUsedThisSession,
      scoutsRemainingToday: _scoutsRemainingToday,
    );
    if (mounted) setState(() => _tierLabel = label);
  }

  Future<void> _showPaywall({String? reason}) async {
    final state = ref.read(stillScoutProvider);
    if (state.isPro) return;
    // Compute locked stats from the current session for the personalised hook.
    final lockedCount = StillScoutAccessPolicy.lockedCount(
      totalFrames: state.frames.length,
      isPro: false,
      isFirstScout: state.isFirstScout,
    );
    final lockedFrames = state.frames.length > lockedCount
        ? state.frames.skip(state.frames.length - lockedCount)
        : <ScoredFrame>[];
    final bestLockedScore = lockedFrames.isEmpty
        ? null
        : lockedFrames
            .map((f) => f.score)
            .reduce((a, b) => a > b ? a : b);

    await StillScoutPaywallSheet.show(
      context,
      exportsRemaining: StillScoutAccessPolicy.exportsRemainingThisScout(
        isPro: false,
        exportsUsedThisSession: state.exportsUsedThisSession,
      ),
      reason: reason,
      lockedCount: lockedCount > 0 ? lockedCount : null,
      bestLockedScore: bestLockedScore,
      onPurchased: () async {
        await ref.read(stillScoutProvider.notifier).refreshSubscriptionState();
        await _loadScoutQuota();
        await _loadTierLabel();
        if (!mounted) return;
        // Auto-start the scout so user doesn't need to tap Start Scout again
        // after upgrading from the pre-flight paywall.
        final s = ref.read(stillScoutProvider);
        if (s.phase == StillScoutPhase.idle && s.videoPath != null) {
          ref.read(stillScoutProvider.notifier).processVideo(s.videoPath!);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stillScoutProvider);
    final onlineStatus = ref.watch(onlineStatusProvider).valueOrNull?.status ??
        OnlineStatus.checking;

    ref.listen(onlineStatusProvider, (previous, next) {
      final wasOnline = previous?.valueOrNull?.isOnline ?? false;
      final nowOnline = next.valueOrNull?.isOnline ?? false;
      if (wasOnline && !nowOnline) {
        // Only abort if the active scout actually uses cloud AI.
        // Free on-device scouts run entirely offline — aborting them here
        // would cancel a perfectly valid scout for no reason.
        // AI trial scouts also use cloud AI even though isPro is false.
        ref.read(stillScoutProvider.notifier).abortForOffline();
      }
    });

    ref.listen(stillScoutProvider.select((s) => s.isPro), (previous, next) {
      if (previous != next) {
        unawaited(_loadScoutQuota());
        unawaited(_loadTierLabel());
      }
    });

    ref.listen(stillScoutProvider, (previous, next) {
      if (next.phase != StillScoutPhase.complete && _selectedIds.isNotEmpty) {
        setState(() => _selectedIds.clear());
      }
      // Success haptic when Top Scout is revealed.
      if (previous?.phase != StillScoutPhase.complete &&
          next.phase == StillScoutPhase.complete &&
          next.frames.isNotEmpty) {
        HapticFeedback.heavyImpact();
                setState(() => _celebrateCompletion = true);
                unawaited(_loadScoutQuota());
                unawaited(_maybeShowCoachMarks());
        unawaited(_loadTierLabel());
        // Warn AI Pro and trial users when Gemini fell back to Vision scores.
        if ((next.isPro || next.isAiProTrial) && !next.geminiReachedOnLastScout) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: StillScoutColors.slate,
                duration: Duration(seconds: 5),
                content: Text(
                  'Gemini was unreachable — showing on-device estimates. '
                  'Reconnect and re-scout for AI results.',
                ),
              ),
            );
          });
        }
        // Soft conversion: do not auto-open the paywall after trial —
        // the upgrade card in results is enough (avoids interrupting the wow).
      }
      if (next.phase != StillScoutPhase.complete) {
        setState(() => _celebrateCompletion = false);
      }
      // When cancelled, briefly show the cancelled state then return to
      // pre-flight — gives users a moment to see the feedback before the
      // screen resets, while preserving their video selection.
      if (previous?.phase != StillScoutPhase.cancelled &&
          next.phase == StillScoutPhase.cancelled) {
        _cancelledResetTimer?.cancel();
        _cancelledResetTimer = Timer(const Duration(milliseconds: 1200), () {
          if (mounted) {
            ref.read(stillScoutProvider.notifier).returnToPreFlight();
          }
        });
      }
      // Cancel the delayed reset if the user takes a new action themselves.
      if (previous?.phase == StillScoutPhase.cancelled &&
          next.phase != StillScoutPhase.cancelled) {
        _cancelledResetTimer?.cancel();
        _cancelledResetTimer = null;
      }
    });

    // Compare action: if exactly 2 selected frames, show compare icon.
    final canCompare =
        _selectedIds.length == 2 && state.phase == StillScoutPhase.complete;

    return Scaffold(
      backgroundColor: StillScoutColors.voidBlack,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: _buildBackLeading(state),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const StillScoutLogo(
                size: 28, animateGlow: true, glowStrength: 0.22),
            const SizedBox(width: 10),
            Text(
              'STILLSCOUT',
              style: StillScoutTextStyles.display.copyWith(
                fontSize: 22,
                letterSpacing: 2.4,
              ),
            ),
          ],
        ),
        actions: [
          if (canCompare)
            Semantics(
              label: 'Compare 2 selected frames',
              button: true,
              child: IconButton(
                tooltip: 'Compare',
                onPressed: () => _openCompare(state),
                icon: const Icon(Icons.compare, color: StillScoutColors.accent),
              ),
            ),
          if (state.phase == StillScoutPhase.complete)
            Semantics(
              label: 'Start over',
              button: true,
              child: IconButton(
                tooltip: 'Start over',
                onPressed: () {
                  ref.read(stillScoutProvider.notifier).reset();
                  setState(() => _selectedIds.clear());
                  unawaited(_loadScoutQuota());
                  unawaited(_loadTierLabel());
                },
                icon: const Icon(Icons.refresh_rounded,
                    color: StillScoutColors.chalk),
              ),
            ),
          Semantics(
            label: 'View past scouts',
            button: true,
            child: IconButton(
              tooltip: 'History',
              onPressed: () {
                final sessionRepo = ref
                    .read(stillScoutProvider.notifier)
                    .getSessionRepository();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StillScoutHistoryScreen(
                      sessionRepository: sessionRepo,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.history_rounded,
                  color: StillScoutColors.silver),
            ),
          ),
          Semantics(
            label: 'Settings',
            button: true,
            child: IconButton(
              tooltip: 'Settings',
              onPressed: () => StillScoutSettingsScreen.open(context),
              icon: const Icon(Icons.settings_outlined,
                  color: StillScoutColors.silver),
            ),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: StillScoutColors.vignette),
        child: SafeArea(
          child: Column(
            children: [
              StillScoutOnlineBanner(
                status: onlineStatus,
                needsNetwork: state.isPro || state.isAiProTrial,
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _buildBody(state, onlineStatus),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          _selectedIds.isEmpty || state.phase != StillScoutPhase.complete
              ? null
              : StillScoutBatchExportBar(
                  selectedCount: _selectedIds.length,
                  isPro: state.isPro,
                  isBusy: _batchExportBusy,
                  onClear: () => setState(() => _selectedIds.clear()),
                  onSaveToGallery: () => _handleBatchExport(
                    state,
                    StillScoutExportAction.saveToGallery,
                  ),
                  onShare: () => _handleBatchExport(
                    state,
                    StillScoutExportAction.share,
                  ),
                ),
    );
  }

  Widget _buildBody(StillScoutState state, OnlineStatus onlineStatus) {
    switch (state.phase) {
      case StillScoutPhase.idle:
        // After a video is picked but before processing starts, show
        // the pre-flight card (estimate + optional trim).
        if (state.videoPath != null && state.videoDurationMs != null) {
          return StillScoutPreFlightCard(
            key: const ValueKey('preflight'),
            state: state,
            onlineStatus: onlineStatus,
            scoutsRemainingToday: _scoutsRemainingToday,
            onStartScout: () {
              final needsCloud = StillScoutAccessPolicy.scoutRequiresNetwork(
                isPro: state.isPro,
                isAiProTrialAvailable:
                    StillScoutAiProTrialTracker.isTrialAvailable,
              );
              if (needsCloud && onlineStatus != OnlineStatus.online) {
                _showOfflineSnack();
                return;
              }
              // Only gate on quota when we have a confirmed value of 0.
              // While still loading (null) or optimistic default, let the
              // notifier handle the server-side guard so the button is never
              // permanently stuck disabled.
              if (!state.isPro &&
                  _scoutsRemainingToday != null &&
                  _scoutsRemainingToday! <= 0) {
                _showPaywall(
                  reason: const ScoutQuotaExhaustedFailure().displayMessage,
                );
                return;
              }
              ref
                  .read(stillScoutProvider.notifier)
                  .processVideo(state.videoPath!);
            },
            onTrimChanged: (start, end) =>
                ref.read(stillScoutProvider.notifier).setTrimRange(start, end),
            onContextChanged: (ctx) =>
                ref.read(stillScoutProvider.notifier).setVideoContext(ctx),
            onPickDifferent: () =>
                ref.read(stillScoutProvider.notifier).reset(),
          );
        }
        return StillScoutEmptyState(
          key: const ValueKey('empty'),
          isEnabled: true,
          onlineStatus: onlineStatus,
          onVideoSelected: _onVideoSelected,
        );

      case StillScoutPhase.extracting:
      case StillScoutPhase.scoring:
        return StillScoutProcessingState(
          key: const ValueKey('processing'),
          phase: state.phase,
          progress: state.progress,
          message: state.statusMessage,
          liveFrames: state.liveFrames,
          framesExtracted: state.framesExtracted,
          totalFrames: state.totalFrames,
          isAiProTrial: state.isAiProTrial,
          isPro: state.isPro,
          onCancel: () =>
              ref.read(stillScoutProvider.notifier).cancelProcessing(),
        );

      case StillScoutPhase.complete:
        return StillScoutResultsGallery(
          key: const ValueKey('gallery'),
          frames: state.frames,
          topPicks: state.topPicks,
          selectedIds: _selectedIds,
          videoDurationMs: state.videoDurationMs,
          processingTimeMs: state.processingTimeMs,
          isPro: state.isPro,
          isAiProTrial: state.isAiProTrial,
          isFirstScout: state.isFirstScout,
          exportsUsedThisSession: state.exportsUsedThisSession,
          showContextChipsCoachMark: _showContextChipsMark,
          onContextChipsCoachMarkDismissed: () {
            setState(() => _showContextChipsMark = false);
          },
          celebrateCompletion: _celebrateCompletion,
          geminiReached: state.geminiReachedOnLastScout,
          onRetryCloudAi: () =>
              ref.read(stillScoutProvider.notifier).rescoreWithCloudAi(),
          onUpgradeAiPro: () => _showPaywall(
            reason: state.isAiProTrial
                ? 'You just used Gemini. Keep AI Pro for unlimited scouts, '
                    '20 keepers, and Auto Polish.'
                : 'AI finds your best moment and turns it into a professional photo.',
          ),
          onLockedFrameTap: () => _showPaywall(
            reason:
                'Unlock Gemini judgment, 20 keepers, timecodes, and native 4K.',
          ),
          onFrameTap: (frame, rank) {
            if (_selectedIds.isNotEmpty) {
              if (!StillScoutAccessPolicy.isLocked(
                  rank: rank,
                  isPro: state.isPro,
                  isFirstScout: state.isFirstScout)) {
                _toggleSelection(frame);
              }
              return;
            }
            _onFrameTap(frame, state.isPro, state.frames, rank);
          },
          onFrameLongPress: (frame) {
            final rank =
                state.frames.indexWhere((f) => f.frame.id == frame.frame.id);
            if (StillScoutAccessPolicy.isLocked(
                rank: rank,
                isPro: state.isPro,
                isFirstScout: state.isFirstScout)) {
              return;
            }
            _toggleSelection(frame);
          },
          videoContext: state.videoContext,
          onContextChanged: (ctx) =>
              ref.read(stillScoutProvider.notifier).setVideoContext(ctx),
        );

      case StillScoutPhase.error:
        return StillScoutScoutErrorView(
          key: const ValueKey('error'),
          message: state.errorMessage ?? 'Unknown error',
          // Use returnToPreFlight so the picked video is preserved.
          onRetry: state.videoPath != null
              ? () => ref.read(stillScoutProvider.notifier).returnToPreFlight()
              : () => ref.read(stillScoutProvider.notifier).reset(),
        );

      case StillScoutPhase.cancelled:
        return StillScoutScoutCancelledView(
          key: const ValueKey('cancelled'),
          onStartOver: () => ref.read(stillScoutProvider.notifier).reset(),
        );
    }
  }

  void _toggleSelection(ScoredFrame frame) {
    HapticFeedback.selectionClick();
    setState(() {
      final id = frame.frame.id;
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  /// Picks up the video path and reads duration for the pre-flight card
  /// *before* starting extraction.
  Future<void> _onVideoSelected(String path) async {
    // Free on-device scouts can pick offline; AI Pro needs network later.
    await ref.read(stillScoutProvider.notifier).onVideoPicked(path);
    await _loadTierLabel();
    if (!mounted) return;
    final durationMs = ref.read(stillScoutProvider).videoDurationMs;
    if (durationMs != null &&
        durationMs > StillScoutConstants.maxVideoDurationMs) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: StillScoutColors.slate,
          duration: Duration(seconds: 6),
          content: Text(
            'This clip is longer than 10 minutes — scouting is limited to the '
            'first 10 minutes. Open Trim below to choose a different range.',
          ),
        ),
      );
    }
  }

  Future<void> _onFrameTap(
    ScoredFrame frame,
    bool isPro,
    List<ScoredFrame> allFrames,
    int rank,
  ) async {
    final scoutState = ref.read(stillScoutProvider);
    final isFirstScout = scoutState.isFirstScout;
    if (StillScoutAccessPolicy.isLocked(
        rank: rank, isPro: isPro, isFirstScout: isFirstScout)) {
      await _showPaywall(
        reason:
            'See full detail on all ${StillScoutAccessPolicy.keeperLimit(isPro: isPro, isFirstScout: isFirstScout)}+ ranked picks with Pro.',
      );
      return;
    }
    await StillScoutFrameDetailSheet.show(
      context,
      frame: frame,
      tierLabel: _tierLabel,
      isPro: isPro,
      isFirstScout: scoutState.isFirstScout,
      isAiProTrial: scoutState.isAiProTrial,
      rank: rank,
      allFrames: allFrames,
      initialIndex: rank,
      onExportPressed: _handleExport,
      onUnlockAiPro: () => _showPaywall(
        reason:
            'AI Auto Polish and Gemini Flash scoring unlock with AI Pro.',
      ),
    );
  }

  void _openCompare(StillScoutState state) {
    final selected =
        state.frames.where((f) => _selectedIds.contains(f.frame.id)).toList();
    if (selected.length != 2) return;
    StillScoutCompareSheet.show(
      context,
      frameA: selected[0],
      frameB: selected[1],
      isPro: state.isPro,
      rankA: state.frames.indexWhere((f) => f.frame.id == selected[0].frame.id),
      rankB: state.frames.indexWhere((f) => f.frame.id == selected[1].frame.id),
    );
  }

  Future<void> _handleExport(
    ScoredFrame frame,
    StillScoutExportAction action, {
    required StillScoutCropRatio cropRatio,
    bool applyPolish = false,
    String? precomputedPolishPath,
  }) async {
    final state = ref.read(stillScoutProvider);
    final faceDetector = ref.read(faceDetectorProvider);

    if (!state.isPro) {
      if (!StillScoutAccessPolicy.canExportThisSession(
        isPro: false,
        exportsUsedThisSession: state.exportsUsedThisSession,
      )) {
        if (!mounted) return;
        await _showPaywall(
          reason:
              'You\'ve used all ${StillScoutConstants.freeExportsPerScout} saves for this scout.',
        );
        return;
      }
    }

    final result = action == StillScoutExportAction.saveToGallery
        ? await StillScoutExportService.saveToGallery(
            frame,
            isPro: state.isPro,
            cropRatio: cropRatio,
            applyPolish: applyPolish,
            faceDetector: faceDetector,
            precomputedPolishPath: precomputedPolishPath,
            permissionContext: context,
          )
        : await StillScoutExportService.share(
            frame,
            isPro: state.isPro,
            cropRatio: cropRatio,
            applyPolish: applyPolish,
            faceDetector: faceDetector,
            precomputedPolishPath: precomputedPolishPath,
            shareOrigin: _shareOriginRect(context),
          );

    if (result.isSuccess) {
      if (!state.isPro) {
        await ref.read(stillScoutProvider.notifier).consumeSessionExports(1);
      }
      HapticFeedback.mediumImpact();
    }

    await _loadTierLabel();
    if (!mounted) return;
    _showExportFeedback(result, action: action, isPro: state.isPro);
  }

  Rect _shareOriginRect(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height - 80),
      width: 1,
      height: 1,
    );
  }

  Future<void> _handleBatchExport(
    StillScoutState state,
    StillScoutExportAction action,
  ) async {
    final frames =
        state.frames.where((f) => _selectedIds.contains(f.frame.id)).where((f) {
      final rank = state.frames.indexWhere((x) => x.frame.id == f.frame.id);
      return StillScoutAccessPolicy.canExportFrame(
          rank: rank,
          isPro: state.isPro,
          isFirstScout: state.isFirstScout);
    }).toList();
    if (frames.isEmpty) return;

    if (!state.isPro) {
      if (!StillScoutAccessPolicy.canExportThisSession(
        isPro: false,
        exportsUsedThisSession: state.exportsUsedThisSession,
        count: frames.length,
      )) {
        if (!mounted) return;
        await _showPaywall(
          reason: 'Batch export needs Pro or fewer frames selected.',
        );
        return;
      }
    }

    setState(() => _batchExportBusy = true);
    final faceDetector = ref.read(faceDetectorProvider);

    if (action == StillScoutExportAction.saveToGallery) {
      final summary = await StillScoutExportService.saveBatchToGallery(
        frames,
        isPro: state.isPro,
        faceDetector: faceDetector,
        permissionContext: context,
      );
      if (!mounted) return;
      if (summary.hasAnySuccess) {
        if (!state.isPro) {
          await ref
              .read(stillScoutProvider.notifier)
              .consumeSessionExports(summary.succeeded);
        }
        HapticFeedback.mediumImpact();
      }
      setState(() {
        _batchExportBusy = false;
        _selectedIds.clear();
      });
      await _loadTierLabel();
      _showSnack(
        summary.permissionDenied
            ? 'Photo library access is required to save exports.'
            : 'Saved ${summary.succeeded} of ${frames.length} frames to your camera roll.',
      );
    } else {
      final result = await StillScoutExportService.shareBatch(
        frames,
        isPro: state.isPro,
        faceDetector: faceDetector,
        shareOrigin: _shareOriginRect(context),
      );
      if (!mounted) return;
      if (result.isSuccess) {
        // Sharing counts against the free export quota the same as saving.
        if (!state.isPro) {
          await ref
              .read(stillScoutProvider.notifier)
              .consumeSessionExports(frames.length);
        }
        HapticFeedback.mediumImpact();
      }
      setState(() {
        _batchExportBusy = false;
        _selectedIds.clear();
      });
      await _loadTierLabel();
      _showExportFeedback(
        result,
        action: action,
        isPro: state.isPro,
        batchCount: frames.length,
      );
    }
  }

  void _showExportFeedback(
    ExportResult result, {
    required StillScoutExportAction action,
    required bool isPro,
    int? batchCount,
  }) {
    final isShare = action == StillScoutExportAction.share;
    switch (result.outcome) {
      case ExportOutcome.success:
        HapticFeedback.mediumImpact();
        String successMsg;
        if (batchCount != null) {
          successMsg = isShare
              ? 'Shared $batchCount photos.'
              : 'Saved $batchCount photos to your camera roll.';
        } else if (isShare) {
          successMsg = 'Share sheet opened.';
        } else if (isPro) {
          successMsg = result.nativeResUsed
              ? 'Saved at native resolution.'
              : 'Saved — the original source file was not found; saved at preview quality instead.';
        } else {
          // Celebrate the save; only mention quota when exhausted.
          final nowUsed = ref.read(stillScoutProvider).exportsUsedThisSession;
          final left = StillScoutAccessPolicy.exportsRemainingThisScout(
            isPro: false,
            exportsUsedThisSession: nowUsed,
          );
          successMsg = left <= 0
              ? 'Saved! No more free saves this scout — upgrade for unlimited.'
              : 'Saved to your camera roll!';
        }
        _showSnack(successMsg);
      case ExportOutcome.permissionDenied:
        _showSnack(result.message ?? 'Photo library access is required.');
      case ExportOutcome.failure:
        _showSnack(result.message ?? 'Export failed. Please try again.');
      case ExportOutcome.cancelled:
        break;
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: StillScoutColors.slate,
        content: Text(message),
      ),
    );
  }
}
