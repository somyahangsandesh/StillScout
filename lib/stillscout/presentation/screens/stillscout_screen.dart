import 'dart:async';
import 'dart:io';

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
import '../widgets/stillscout_context_picker.dart';
import '../widgets/stillscout_empty_state.dart';
import '../widgets/stillscout_online_banner.dart';
import '../widgets/stillscout_crop_picker.dart';
import '../widgets/stillscout_frame_detail_sheet.dart';
import '../widgets/stillscout_paywall_sheet.dart';
import '../widgets/stillscout_processing_state.dart';
import '../widgets/stillscout_results_gallery.dart';
import '../widgets/stillscout_trim_scrubber.dart';
import 'stillscout_history_screen.dart';


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
  bool _wasBackgroundedDuringScout = false;
  int? _scoutsRemainingThisWeek;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTierLabel();
    _loadScoutQuota();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    final phase = ref.read(stillScoutProvider).phase;
    final isProcessing = phase == StillScoutPhase.extracting ||
        phase == StillScoutPhase.scoring;

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
      final message = Platform.isAndroid
          ? 'Still scouting in the background — check your notification.'
          : 'StillScout is still working — keep the app open for fastest results.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
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

  bool _isOnline() => ref.read(isOnlineProvider);

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
    final isPro = ref.read(stillScoutProvider).isPro;
    final remaining =
        await StillScoutScoutQuotaTracker.remainingThisWeek(isPro: isPro);
    if (mounted) setState(() => _scoutsRemainingThisWeek = remaining);
  }

  Future<void> _loadTierLabel() async {
    final state = ref.read(stillScoutProvider);
    final label = await StillScoutSubscriptionManager.tierLabel(
      isPro: state.isPro,
      exportsUsedThisSession: state.exportsUsedThisSession,
      scoutsRemainingThisWeek: _scoutsRemainingThisWeek,
    );
    if (mounted) setState(() => _tierLabel = label);
  }

  Future<void> _showPaywall({String? reason}) async {
    final state = ref.read(stillScoutProvider);
    if (state.isPro) return;
    await StillScoutPaywallSheet.show(
      context,
      exportsRemaining: StillScoutAccessPolicy.exportsRemainingThisScout(
        isPro: false,
        exportsUsedThisSession: state.exportsUsedThisSession,
      ),
      reason: reason,
      onPurchased: () async {
        await ref.read(stillScoutProvider.notifier).refreshSubscriptionState();
        await _loadScoutQuota();
        await _loadTierLabel();
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
        unawaited(_loadTierLabel());
      }
      if (next.phase != StillScoutPhase.complete) {
        setState(() => _celebrateCompletion = false);
      }
    });

    // Compare action: if exactly 2 selected frames, show compare icon.
    final canCompare = _selectedIds.length == 2 &&
        state.phase == StillScoutPhase.complete;

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
            const StillScoutLogo(size: 28, animateGlow: true, glowStrength: 0.22),
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
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: StillScoutColors.vignette),
        child: SafeArea(
          child: Column(
            children: [
              StillScoutOnlineBanner(status: onlineStatus),
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
          return _PreFlightCard(
            key: const ValueKey('preflight'),
            state: state,
            onlineStatus: onlineStatus,
            scoutsRemainingThisWeek: _scoutsRemainingThisWeek,
            onStartScout: () {
              if (onlineStatus != OnlineStatus.online) {
                _showOfflineSnack();
                return;
              }
              if (!state.isPro && (_scoutsRemainingThisWeek ?? 0) <= 0) {
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
            onContextChanged: (ctx) => ref
                .read(stillScoutProvider.notifier)
                .setVideoContext(ctx),
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
          exportsUsedThisSession: state.exportsUsedThisSession,
          celebrateCompletion: _celebrateCompletion,
          onLockedFrameTap: () => _showPaywall(
            reason:
                'Unlock all top picks, exact timecodes, and native 4K exports.',
          ),
          onFrameTap: (frame, rank) {
            if (_selectedIds.isNotEmpty) {
              if (!StillScoutAccessPolicy.isLocked(rank: rank, isPro: state.isPro)) {
                _toggleSelection(frame);
              }
              return;
            }
            _onFrameTap(frame, state.isPro, state.frames, rank);
          },
          onFrameLongPress: (frame) {
            final rank = state.frames.indexWhere((f) => f.frame.id == frame.frame.id);
            if (StillScoutAccessPolicy.isLocked(rank: rank, isPro: state.isPro)) {
              return;
            }
            _toggleSelection(frame);
          },
        );

      case StillScoutPhase.error:
        return _ErrorState(
          key: const ValueKey('error'),
          message: state.errorMessage ?? 'Unknown error',
          onRetry: () => ref.read(stillScoutProvider.notifier).reset(),
        );

      case StillScoutPhase.cancelled:
        return _CancelledState(
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
    if (!_isOnline()) {
      _showOfflineSnack();
      return;
    }
    await ref.read(stillScoutProvider.notifier).onVideoPicked(path);
    await _loadTierLabel();
  }

  Future<void> _onFrameTap(
    ScoredFrame frame,
    bool isPro,
    List<ScoredFrame> allFrames,
    int rank,
  ) async {
    if (StillScoutAccessPolicy.isLocked(rank: rank, isPro: isPro)) {
      await _showPaywall(
        reason: 'See full detail on all ${StillScoutAccessPolicy.keeperLimit(isPro: isPro)}+ ranked picks with Pro.',
      );
      return;
    }
    await StillScoutFrameDetailSheet.show(
      context,
      frame: frame,
      tierLabel: _tierLabel,
      isPro: isPro,
      rank: rank,
      allFrames: allFrames,
      initialIndex: rank,
      onExportPressed: _handleExport,
    );
  }

  void _openCompare(StillScoutState state) {
    final selected = state.frames
        .where((f) => _selectedIds.contains(f.frame.id))
        .toList();
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
    bool applyPolish = true,
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
          reason: 'You\'ve used all ${StillScoutConstants.freeExportsPerScout} polished saves for this scout.',
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
        ref.read(stillScoutProvider.notifier).consumeSessionExports(1);
      }
      HapticFeedback.mediumImpact();
    }

    await _loadTierLabel();
    if (!mounted) return;
    _showExportFeedback(result, isPro: state.isPro);
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
    final frames = state.frames
        .where((f) => _selectedIds.contains(f.frame.id))
        .where((f) {
          final rank = state.frames.indexWhere((x) => x.frame.id == f.frame.id);
          return StillScoutAccessPolicy.canExportFrame(rank: rank, isPro: state.isPro);
        })
        .toList();
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
      );
      if (!mounted) return;
      if (summary.hasAnySuccess) {
        if (!state.isPro) {
          ref
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
      if (result.isSuccess && !state.isPro) {
        ref.read(stillScoutProvider.notifier).consumeSessionExports(frames.length);
      }
      setState(() {
        _batchExportBusy = false;
        _selectedIds.clear();
      });
      await _loadTierLabel();
      _showExportFeedback(result, isPro: state.isPro, batchCount: frames.length);
    }
  }

  void _showExportFeedback(ExportResult result,
      {required bool isPro, int? batchCount}) {
    switch (result.outcome) {
      case ExportOutcome.success:
        _showSnack(
          batchCount != null
              ? 'Shared $batchCount frames.'
              : isPro
                  ? (result.nativeResUsed
                      ? 'Exported at native resolution.'
                      : 'Exported — original video unavailable, used preview quality.')
                  : 'Exported. ${_tierLabel.split('—').lastOrNull?.trim() ?? ''}',
        );
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

// ── Pre-flight card ────────────────────────────────────────────────────────────

class _PreFlightCard extends StatefulWidget {
  const _PreFlightCard({
    super.key,
    required this.state,
    required this.onlineStatus,
    this.scoutsRemainingThisWeek,
    required this.onStartScout,
    required this.onTrimChanged,
    required this.onContextChanged,
    required this.onPickDifferent,
  });

  final StillScoutState state;
  final OnlineStatus onlineStatus;
  final int? scoutsRemainingThisWeek;
  final VoidCallback onStartScout;
  final void Function(int start, int end) onTrimChanged;
  final ValueChanged<StillScoutVideoContext> onContextChanged;
  final VoidCallback onPickDifferent;

  @override
  State<_PreFlightCard> createState() => _PreFlightCardState();
}

class _PreFlightCardState extends State<_PreFlightCard> {
  bool _showTrim = false;

  @override
  Widget build(BuildContext context) {
    final durationMs = widget.state.videoDurationMs ?? 0;
    final scoutsLeft = widget.scoutsRemainingThisWeek;
    final quotaLoading = !widget.state.isPro && scoutsLeft == null;
    final quotaOk =
        widget.state.isPro || (scoutsLeft != null && scoutsLeft > 0);
    final canScout = widget.onlineStatus == OnlineStatus.online &&
        (widget.state.isPro || (scoutsLeft != null && scoutsLeft > 0));
    final scoutLabel = StillScoutAccessPolicy.scoutsAllowanceLabel(
      isPro: widget.state.isPro,
      scoutsRemainingThisWeek: scoutsLeft ?? 0,
      isLoading: quotaLoading,
    );
    final ctaLabel = switch (widget.onlineStatus) {
      OnlineStatus.checking => 'Checking connection…',
      OnlineStatus.offline => 'Connect to start',
      OnlineStatus.online => quotaLoading
          ? 'Loading allowance…'
          : (quotaOk ? 'Start Scout' : 'No scouts left this week'),
    };

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: StillScoutSpacing.m),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: StillScoutSpacing.xl),
            const Icon(
              Icons.check_circle_rounded,
              color: StillScoutColors.success,
              size: 40,
            ),
            const SizedBox(height: StillScoutSpacing.m),
            Text('Video ready', style: StillScoutTextStyles.title),
            const SizedBox(height: StillScoutSpacing.xs),
            Text(
              'Review the estimate and trim the clip if you like, then start scouting.',
              style: StillScoutTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: StillScoutSpacing.m),
            StillScoutOnlineRequirementChip(status: widget.onlineStatus),
            if (!widget.state.isPro) ...[
              const SizedBox(height: StillScoutSpacing.s),
              Text(
                scoutLabel,
                style: StillScoutTextStyles.caption.copyWith(
                  color: quotaLoading
                      ? StillScoutColors.silver
                      : quotaOk
                          ? StillScoutColors.accent
                          : StillScoutColors.danger,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Exports are clean — upgrade for unlimited scouts and 4K.',
                style: StillScoutTextStyles.caption.copyWith(
                  color: StillScoutColors.silver.withValues(alpha: 0.75),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: StillScoutSpacing.l),

            // Pre-flight estimate
            StillScoutPreFlightEstimate(
              estimatedFrames: widget.state.estimatedFrameCount,
              durationMs: durationMs,
            ),

            const SizedBox(height: StillScoutSpacing.m),

            Text(
              "What's this video?",
              style: StillScoutTextStyles.caption.copyWith(
                color: StillScoutColors.silver,
              ),
            ),
            const SizedBox(height: StillScoutSpacing.s),
            StillScoutContextPicker(
              selected: widget.state.videoContext,
              onChanged: widget.onContextChanged,
            ),

            const SizedBox(height: StillScoutSpacing.m),

            // Trim toggle
            if (durationMs > 5000) // only show trim for clips > 5s
              _TrimToggle(
                expanded: _showTrim,
                onToggle: () => setState(() => _showTrim = !_showTrim),
              ),

            if (_showTrim && durationMs > 5000) ...[
              const SizedBox(height: StillScoutSpacing.m),
              StillScoutTrimScrubber(
                durationMs: durationMs,
                initialStartMs: widget.state.trimStartMs,
                initialEndMs: widget.state.trimEndMs,
                onTrimChanged: widget.onTrimChanged,
              ),
            ],

            const SizedBox(height: StillScoutSpacing.xl),

            // CTA
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Semantics(
                label: 'Start scouting frames',
                button: true,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: canScout
                        ? StillScoutColors.accent
                        : StillScoutColors.slate,
                    foregroundColor: StillScoutColors.voidBlack,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(StillScoutRadius.m),
                    ),
                  ),
                  icon: Icon(
                    canScout ? Icons.search_rounded : Icons.wifi_off_rounded,
                    size: 20,
                  ),
                  label: Text(
                    ctaLabel,
                    style: StillScoutTextStyles.subtitle.copyWith(
                      color: StillScoutColors.voidBlack,
                    ),
                  ),
                  onPressed: canScout ? widget.onStartScout : null,
                ),
              ),
            ),

            const SizedBox(height: StillScoutSpacing.m),

            TextButton(
              onPressed: widget.onPickDifferent,
              child: Text(
                'Pick a different video',
                style: StillScoutTextStyles.caption.copyWith(
                  color: StillScoutColors.silver,
                ),
              ),
            ),

            const SizedBox(height: StillScoutSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _TrimToggle extends StatelessWidget {
  const _TrimToggle({required this.expanded, required this.onToggle});

  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: StillScoutSpacing.m,
          vertical: StillScoutSpacing.s,
        ),
        decoration: BoxDecoration(
          color: StillScoutColors.filmGray,
          borderRadius: BorderRadius.circular(StillScoutRadius.s),
          border: Border.all(
            color: expanded
                ? StillScoutColors.accent.withValues(alpha: 0.5)
                : StillScoutColors.silver.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.content_cut_rounded,
              size: 16,
              color:
                  expanded ? StillScoutColors.accent : StillScoutColors.silver,
            ),
            const SizedBox(width: StillScoutSpacing.s),
            Text(
              expanded ? 'Hide trim' : 'Trim clip before scouting',
              style: StillScoutTextStyles.caption.copyWith(
                color:
                    expanded ? StillScoutColors.accent : StillScoutColors.chalk,
              ),
            ),
            const Spacer(),
            Icon(
              expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 18,
              color: StillScoutColors.silver,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error / Cancelled states ───────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(StillScoutSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: StillScoutColors.danger, size: 48),
            const SizedBox(height: StillScoutSpacing.m),
            Text(message,
                style: StillScoutTextStyles.body, textAlign: TextAlign.center),
            const SizedBox(height: StillScoutSpacing.l),
            Semantics(
              label: 'Try again',
              button: true,
              child: OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: StillScoutColors.chalk,
                  side: const BorderSide(color: StillScoutColors.accent),
                  minimumSize: const Size(0, 48),
                ),
                child: const Text('Try again'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CancelledState extends StatelessWidget {
  const _CancelledState({super.key, required this.onStartOver});

  final VoidCallback onStartOver;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(StillScoutSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cancel_outlined,
                color: StillScoutColors.silver, size: 48),
            const SizedBox(height: StillScoutSpacing.m),
            Text('Scout cancelled', style: StillScoutTextStyles.title),
            const SizedBox(height: StillScoutSpacing.s),
            Text(
              'No frames were saved. Pick a clip whenever you\'re ready.',
              style: StillScoutTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: StillScoutSpacing.l),
            Semantics(
              label: 'Start over',
              button: true,
              child: OutlinedButton(
                onPressed: onStartOver,
                style: OutlinedButton.styleFrom(
                  foregroundColor: StillScoutColors.chalk,
                  side: const BorderSide(color: StillScoutColors.accent),
                  minimumSize: const Size(0, 48),
                ),
                child: const Text('Start over'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

