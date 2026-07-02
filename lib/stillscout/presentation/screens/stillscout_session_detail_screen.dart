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

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _exportsUsedThisView = widget.session.exportsUsed;
    _loadTierLabel();
  }

  Future<void> _loadTierLabel() async {
    final isPro = ref.read(stillScoutProvider).isPro;
    final label = await StillScoutSubscriptionManager.tierLabel(
      isPro: isPro,
      exportsUsedThisSession: _exportsUsedThisView,
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
    await StillScoutPaywallSheet.show(
      context,
      exportsRemaining: StillScoutAccessPolicy.exportsRemainingThisScout(
        isPro: false,
        exportsUsedThisSession: _exportsUsedThisView,
      ),
      reason: reason,
      onPurchased: () async {
        await ref.read(stillScoutProvider.notifier).refreshSubscriptionState();
        await _loadTierLabel();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
          IconButton(
            tooltip: 'Start over',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.refresh_rounded, color: StillScoutColors.chalk),
          ),
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
              ? _UnavailableFrames()
              : StillScoutResultsGallery(
                  frames: frames,
                  topPicks: topPicks,
                  videoDurationMs: _session.videoDurationMs,
                  processingTimeMs: _session.processingTimeMs,
                  isPro: state.isPro,
                  exportsUsedThisSession: _exportsUsedThisView,
                  onLockedFrameTap: () => _showPaywall(
                    reason: 'Unlock all ranked picks from past scouts with Pro.',
                  ),
                  onFrameTap: (frame, rank) {
                    if (StillScoutAccessPolicy.isLocked(
                      rank: rank,
                      isPro: state.isPro,
                    )) {
                      _showPaywall(
                        reason:
                            'Unlock all ranked picks from past scouts with Pro.',
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
    if (StillScoutAccessPolicy.isLocked(rank: rank, isPro: isPro)) {
      await _showPaywall();
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

  Future<void> _handleExport(
    ScoredFrame frame,
    StillScoutExportAction action, {
    required StillScoutCropRatio cropRatio,
    bool applyPolish = true,
    String? precomputedPolishPath,
  }) async {
    final isPro = ref.read(stillScoutProvider).isPro;
    final faceDetector = ref.read(faceDetectorProvider);

    if (!isPro) {
      if (!StillScoutAccessPolicy.canExportThisSession(
        isPro: false,
        exportsUsedThisSession: _exportsUsedThisView,
      )) {
        if (!mounted) return;
        await _showPaywall(
          reason: 'You\'ve used all ${StillScoutConstants.freeExportsPerScout} polished saves for this past scout.',
        );
        return;
      }
    }

    final result = action == StillScoutExportAction.saveToGallery
        ? await StillScoutExportService.saveToGallery(
            frame,
            isPro: isPro,
            cropRatio: cropRatio,
            applyPolish: applyPolish,
            faceDetector: faceDetector,
            precomputedPolishPath: precomputedPolishPath,
          )
        : await StillScoutExportService.share(
            frame,
            isPro: isPro,
            cropRatio: cropRatio,
            applyPolish: applyPolish,
            faceDetector: faceDetector,
            precomputedPolishPath: precomputedPolishPath,
            shareOrigin: _shareOriginRect(),
          );

    if (result.isSuccess && !isPro) {
      setState(() => _exportsUsedThisView++);
      final updated = _session.copyWith(exportsUsed: _exportsUsedThisView);
      await ref.read(sessionRepositoryProvider).saveSession(updated);
      if (mounted) setState(() => _session = updated);
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
    if (!ref.read(isOnlineProvider)) {
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

    final isPro = ref.read(stillScoutProvider).isPro;
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
    await ref.read(stillScoutProvider.notifier).onVideoPicked(path);
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
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(StillScoutSpacing.xl),
        child: Text(
          'Frames from this session are no longer available. '
          'Re-scout the same video to regenerate them.',
          style: StillScoutTextStyles.body,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
