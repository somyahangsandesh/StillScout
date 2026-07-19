import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/scored_frame.dart';
import '../../data/models/stillscout_session.dart';
import '../../domain/failures/stillscout_failure.dart';
import '../../domain/stillscout_access_policy.dart';
import '../../domain/stillscout_constants.dart';
import '../../services/stillscout_export_service.dart';
import '../../services/stillscout_scout_quota_tracker.dart';
import '../../services/stillscout_subscription_manager.dart';
import '../providers/stillscout_connectivity_provider.dart';
import '../providers/stillscout_notifier.dart';
import '../providers/stillscout_repository_providers.dart';
import '../theme/stillscout_theme.dart';
import '../widgets/stillscout_crop_picker.dart';
import '../widgets/stillscout_frame_detail_sheet.dart';
import '../widgets/stillscout_paywall_sheet.dart';
import '../widgets/stillscout_results_gallery.dart';

class StillScoutSessionDetailScreen extends ConsumerStatefulWidget {
  const StillScoutSessionDetailScreen({
    super.key,
    required this.session,
  });

  final StillScoutSession session;

  @override
  ConsumerState<StillScoutSessionDetailScreen> createState() =>
      _StillScoutSessionDetailScreenState();
}

class _StillScoutSessionDetailScreenState
    extends ConsumerState<StillScoutSessionDetailScreen> {
  String _tierLabel = '';
  late StillScoutSession _session;
  late int _exportsUsedThisView;
  // Cached so repeated _loadTierLabel calls don't fire extra SharedPreferences reads.
  int? _cachedScoutsRemaining;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _exportsUsedThisView = widget.session.exportsUsed;
    _loadTierLabel();
  }

  Future<void> _loadTierLabel() async {
    final isPro = ref.read(stillScoutProvider).isPro;
    // Read quota from SharedPreferences only once per screen visit.
    _cachedScoutsRemaining ??= await StillScoutScoutQuotaTracker.remainingToday(
      isPro: isPro,
    );
    final label = await StillScoutSubscriptionManager.tierLabel(
      isPro: isPro,
      exportsUsedThisSession: _exportsUsedThisView,
      scoutsRemainingToday: _cachedScoutsRemaining,
    );
    if (mounted) setState(() => _tierLabel = label);
  }

  List<ScoredFrame> get _frames {
    final isPro = ref.read(stillScoutProvider).isPro;
    return _session.topFrameSnapshots
        .asMap()
        .entries
        .map(
          (e) => StillScoutAccessPolicy.fromPersistedJson(
            Map<String, dynamic>.from(e.value),
            isPro: isPro,
            rank: e.key,
            isFirstScout: _session.usedFirstScoutBonus,
          ),
        )
        .toList(growable: false);
  }

  List<ScoredFrame> get _topPicks {
    final byId = {for (final f in _frames) f.frame.id: f};
    if (_session.topPickFrameIds.isNotEmpty) {
      return [
        for (final id in _session.topPickFrameIds)
          if (byId.containsKey(id)) byId[id]!,
      ];
    }
    return _frames.where((f) => f.isTopScout).take(3).toList(growable: false);
  }

  Future<void> _showPaywall({String? reason}) async {
    final isPro = ref.read(stillScoutProvider).isPro;
    if (isPro) return;
    // Compute locked counts for personalised paywall hook.
    final lockedCount = StillScoutAccessPolicy.lockedCount(
      totalFrames: _frames.length,
      isPro: false,
      isFirstScout: _session.usedFirstScoutBonus,
    );
    final lockedFrames = _frames.length > lockedCount
        ? _frames.skip(_frames.length - lockedCount)
        : <ScoredFrame>[];
    final bestLockedScore = lockedFrames.isEmpty
        ? null
        : lockedFrames.map((f) => f.score).reduce((a, b) => a > b ? a : b);
    await StillScoutPaywallSheet.show(
      context,
      exportsRemaining: StillScoutAccessPolicy.exportsRemainingThisScout(
        isPro: false,
        exportsUsedThisSession: _exportsUsedThisView,
      ),
      reason: reason,
      lockedCount: lockedCount > 0 ? lockedCount : null,
      bestLockedScore: bestLockedScore,
      onPurchased: () async {
        await ref.read(stillScoutProvider.notifier).refreshSubscriptionState();
        await _loadTierLabel();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Refresh tier label and unlock state whenever the subscription changes
    // (e.g. user upgrades via paywall while the detail screen is open).
    ref.listen(stillScoutProvider.select((s) => s.isPro), (_, __) {
      unawaited(_loadTierLabel());
    });

    final frames = _frames;
    final state = ref.watch(stillScoutProvider);
    final topPicks = _topPicks;

    return Scaffold(
      backgroundColor: StillScoutColors.voidBlack,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: StillScoutColors.chalk),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _formatDate(_session.createdAt),
          style: StillScoutTextStyles.title,
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: StillScoutColors.silver),
            color: StillScoutColors.slate,
            onSelected: (value) {
              if (value == 'rescout') _rescoutVideo();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'rescout',
                child: Text(
                  'Scout this video again',
                  style: StillScoutTextStyles.body.copyWith(
                    color: StillScoutColors.chalk,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: StillScoutColors.vignette),
        child: SafeArea(
          child: frames.isEmpty
              ? _UnavailableFrames(onScoutAgain: _rescoutVideo)
              : StillScoutResultsGallery(
                  frames: frames,
                  topPicks: topPicks,
                  videoDurationMs: _session.videoDurationMs,
                  processingTimeMs: _session.processingTimeMs,
                  isPro: state.isPro,
                  isFirstScout: _session.usedFirstScoutBonus,
                  exportsUsedThisSession: _exportsUsedThisView,
                  onUpgradeAiPro: () => _showPaywall(
                    reason:
                        'AI finds your best moment and turns it into a professional photo.',
                  ),
                  onLockedFrameTap: () => _showPaywall(
                    reason:
                        'Unlock Gemini judgment, ${StillScoutConstants.proKeeperLimit} keepers, and native 4K.',
                  ),
                  onFrameTap: (frame, rank) {
                    if (StillScoutAccessPolicy.isLocked(
                      rank: rank,
                      isPro: state.isPro,
                      isFirstScout: _session.usedFirstScoutBonus,
                    )) {
                      _showPaywall(
                        reason:
                            'Unlock Gemini judgment, ${StillScoutConstants.proKeeperLimit} keepers, and native 4K.',
                      );
                    } else {
                      _onFrameTap(frame, state.isPro, frames, rank);
                    }
                  },
                  onFrameLongPress: (_) {},
                ),
        ),
      ),
    );
  }

  Future<void> _onFrameTap(
    ScoredFrame frame,
    bool isPro,
    List<ScoredFrame> allFrames,
    int rank,
  ) async {
    if (StillScoutAccessPolicy.isLocked(
      rank: rank,
      isPro: isPro,
      isFirstScout: _session.usedFirstScoutBonus,
    )) {
      await _showPaywall();
      return;
    }
    await StillScoutFrameDetailSheet.show(
      context,
      frame: frame,
      tierLabel: _tierLabel,
      isPro: isPro,
      isFirstScout: _session.usedFirstScoutBonus,
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

  Future<void> _handleExport(
    ScoredFrame frame,
    StillScoutExportAction action, {
    required StillScoutCropRatio cropRatio,
    bool applyPolish = false,
    String? precomputedPolishPath,
  }) async {
    final isPro = ref.read(stillScoutProvider).isPro;
    final faceDetector = ref.read(faceDetectorProvider);

    // Past-scout exports are tracked on the session row (not the live notifier).
    var reserved = false;
    if (!isPro) {
      if (!StillScoutAccessPolicy.canExportThisSession(
        isPro: false,
        exportsUsedThisSession: _exportsUsedThisView,
      )) {
        if (!mounted) return;
        await _showPaywall(
          reason:
              'You\'ve used all ${StillScoutConstants.freeExportsPerScout} saves for this past scout.',
        );
        return;
      }
      final next = _exportsUsedThisView + 1;
      setState(() => _exportsUsedThisView = next);
      final reservedSession = _session.copyWith(exportsUsed: next);
      await ref.read(sessionRepositoryProvider).saveSession(reservedSession);
      if (mounted) setState(() => _session = reservedSession);
      reserved = true;
    }
    if (!mounted) {
      if (reserved) {
        final next = (_exportsUsedThisView - 1).clamp(0, 1 << 30);
        _exportsUsedThisView = next;
        final refunded = _session.copyWith(exportsUsed: next);
        await ref.read(sessionRepositoryProvider).saveSession(refunded);
        _session = refunded;
      }
      return;
    }

    final shareOrigin = _shareOriginRect();
    final result = action == StillScoutExportAction.saveToGallery
        ? await StillScoutExportService.saveToGallery(
            frame,
            isPro: isPro,
            cropRatio: cropRatio,
            applyPolish: applyPolish,
            faceDetector: faceDetector,
            precomputedPolishPath: precomputedPolishPath,
            permissionContext: context,
          )
        : await StillScoutExportService.share(
            frame,
            isPro: isPro,
            cropRatio: cropRatio,
            applyPolish: applyPolish,
            faceDetector: faceDetector,
            precomputedPolishPath: precomputedPolishPath,
            shareOrigin: shareOrigin,
          );

    if (!result.isSuccess && reserved) {
      final next = (_exportsUsedThisView - 1).clamp(0, 1 << 30);
      setState(() => _exportsUsedThisView = next);
      final refunded = _session.copyWith(exportsUsed: next);
      await ref.read(sessionRepositoryProvider).saveSession(refunded);
      if (mounted) setState(() => _session = refunded);
    }

    await _loadTierLabel();
    if (!mounted) return;

    if (result.isSuccess) {
      final base = action == StillScoutExportAction.saveToGallery
          ? 'Saved to your photo library.'
          : 'Shared successfully.';
      final message = isPro && !result.nativeResUsed
          ? '$base Original video unavailable — used preview quality.'
          : base;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: StillScoutColors.slate,
          content: Text(message),
        ),
      );
    } else if (result.outcome != ExportOutcome.cancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: StillScoutColors.slate,
          content: Text(result.message ?? 'Export failed.'),
        ),
      );
    }
  }

  Rect _shareOriginRect() {
    final size = MediaQuery.sizeOf(context);
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height - 80),
      width: 1,
      height: 1,
    );
  }

  Future<void> _rescoutVideo() async {
    final isPro = ref.read(stillScoutProvider).isPro;
    // Only block offline when the user actually needs cloud AI (Pro or trial).
    // Free on-device scouts run fine without connectivity.
    final needsOnline =
        StillScoutAccessPolicy.canUseCloudAi(isPro: isPro) ||
        StillScoutAiProTrialTracker.isTrialAvailable;
    if (needsOnline && !ref.read(isOnlineProvider)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: StillScoutColors.slate,
          content: Text(const OfflineFailure().displayMessage),
        ),
      );
      return;
    }
    if (!isPro &&
        !await StillScoutScoutQuotaTracker.canStartScout(isPro: false)) {
      if (!mounted) return;
      await _showPaywall(
        reason: const ScoutQuotaExhaustedFailure().displayMessage,
      );
      return;
    }

    final path = _session.videoPath;
    final exists = path.isNotEmpty && File(path).existsSync();
    if (!exists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: StillScoutColors.slate,
          content: Text(
            'Original video no longer available. Pick a new video.',
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    final notifier = ref.read(stillScoutProvider.notifier);
    await notifier.onVideoPicked(path);
    // Start scouting immediately — "Scout again" should not stop at pre-flight.
    if (!mounted) return;
    final state = ref.read(stillScoutProvider);
    if (state.videoPath != null && state.phase == StillScoutPhase.idle) {
      await notifier.processVideo(state.videoPath!);
    }
  }

  static String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}

class _UnavailableFrames extends StatelessWidget {
  const _UnavailableFrames({required this.onScoutAgain});
  final VoidCallback onScoutAgain;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(StillScoutSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 56,
              color: StillScoutColors.silver.withValues(alpha: 0.45),
            ),
            const SizedBox(height: StillScoutSpacing.m),
            Text(
              'Frames unavailable',
              style: StillScoutTextStyles.subtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: StillScoutSpacing.s),
            Text(
              'Cached frames from this session have been cleared. '
              'Re-scout the original video to regenerate them.',
              style: StillScoutTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: StillScoutSpacing.l),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onScoutAgain,
                icon: const Icon(Icons.search_rounded),
                label: const Text('Scout this video again'),
                style: FilledButton.styleFrom(
                  backgroundColor: StillScoutColors.accent,
                  foregroundColor: StillScoutColors.voidBlack,
                  minimumSize: const Size(0, 52),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
