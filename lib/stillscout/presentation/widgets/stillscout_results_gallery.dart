import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../data/models/frame_score_metadata.dart';
import '../../data/models/scored_frame.dart';
import '../../domain/stillscout_access_policy.dart';
import '../../domain/stillscout_constants.dart';
import '../theme/stillscout_theme.dart';
import 'stillscout_ai_pro_upgrade.dart';
import 'stillscout_coach_mark.dart';
import 'stillscout_completion_hero.dart';
import 'stillscout_frame_tile.dart';
import 'stillscout_session_header.dart';
import 'stillscout_top_picks_carousel.dart';
import 'stillscout_view_toggle.dart';

class StillScoutResultsGallery extends StatefulWidget {
  const StillScoutResultsGallery({
    super.key,
    required this.frames,
    required this.topPicks,
    required this.onFrameTap,
    required this.onFrameLongPress,
    required this.onLockedFrameTap,
    required this.isPro,
    this.isAiProTrial = false,
    this.isFirstScout = false,
    this.showContextChipsCoachMark = false,
    this.onContextChipsCoachMarkDismissed,
    this.selectedIds = const {},
    this.videoDurationMs,
    this.processingTimeMs,
    this.exportsUsedThisSession = 0,
    this.celebrateCompletion = false,
    this.geminiReached = true,
    this.onRetryCloudAi,
    this.onUpgradeAiPro,
    this.videoContext = StillScoutVideoContext.auto,
    this.onContextChanged,
    this.onPolishTopPicks,
    this.isPolishing = false,
    this.polishedPaths = const {},
  });

  final List<ScoredFrame> frames;
  final List<ScoredFrame> topPicks;
  final void Function(ScoredFrame frame, int rank) onFrameTap;
  final void Function(ScoredFrame frame) onFrameLongPress;
  final VoidCallback onLockedFrameTap;
  final bool isPro;
  final bool isAiProTrial;
  final bool isFirstScout;
  final bool showContextChipsCoachMark;
  final VoidCallback? onContextChipsCoachMarkDismissed;
  final Set<String> selectedIds;
  final int? videoDurationMs;
  final int? processingTimeMs;
  final int exportsUsedThisSession;
  final bool celebrateCompletion;

  /// False when the last scout requested Gemini but fell back to Vision-only
  /// scores (soft-degrade). Drives the completion hero's degraded banner.
  final bool geminiReached;

  /// Called when the user taps "Retry" on the degraded banner. Null hides
  /// the Retry CTA.
  final VoidCallback? onRetryCloudAi;
  final VoidCallback? onUpgradeAiPro;

  /// Current context — shown in the results context chips for re-ranking.
  final StillScoutVideoContext videoContext;

  /// Called when user taps a context chip in the results view.
  final ValueChanged<StillScoutVideoContext>? onContextChanged;

  /// Called when user taps "Polish Best Frames". Async — shows spinner.
  final Future<void> Function()? onPolishTopPicks;

  /// True while polish is running — disables the button and shows a spinner.
  final bool isPolishing;

  /// Map of frameId → polished file path, pre-computed by the screen.
  final Map<String, String> polishedPaths;

  bool get _isSelecting => selectedIds.isNotEmpty;

  @override
  State<StillScoutResultsGallery> createState() =>
      _StillScoutResultsGalleryState();
}

class _StillScoutResultsGalleryState extends State<StillScoutResultsGallery> {
  StillScoutGalleryView _view = StillScoutGalleryView.ranked;

  int _rankOf(ScoredFrame frame) =>
      widget.frames.indexWhere((f) => f.frame.id == frame.frame.id);

  List<ScoredFrame> get _displayFrames {
    if (_view == StillScoutGalleryView.timeline) {
      final copy = List<ScoredFrame>.of(widget.frames);
      copy.sort((a, b) => a.frame.timestampMs.compareTo(b.frame.timestampMs));
      return copy;
    }
    return widget.frames;
  }

  void _onViewChanged(StillScoutGalleryView view) {
    if (view == StillScoutGalleryView.timeline && !widget.isPro) {
      widget.onLockedFrameTap();
      return;
    }
    setState(() => _view = view);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 700 ? 3 : 2;
    final frames = _displayFrames;
    final lockedCount = StillScoutAccessPolicy.lockedCount(
      totalFrames: widget.frames.length,
      isPro: widget.isPro,
      isFirstScout: widget.isFirstScout,
    );
    final aiScored =
        widget.frames.where((f) => f.metadata.source == ScoreSource.llm).length;
    final exportsLeft = StillScoutAccessPolicy.exportsRemainingThisScout(
      isPro: widget.isPro,
      exportsUsedThisSession: widget.exportsUsedThisSession,
    );

    return CustomScrollView(
      slivers: [
        if (!widget._isSelecting)
          SliverToBoxAdapter(
            child: StillScoutSessionHeader(
              frames: widget.frames,
              videoDurationMs: widget.videoDurationMs,
              processingTimeMs: widget.processingTimeMs,
              isPro: widget.isPro,
              isAiProTrial: widget.isAiProTrial,
              isFirstScout: widget.isFirstScout,
              exportsUsedThisSession: widget.exportsUsedThisSession,
            ),
          ),
        if (!widget._isSelecting && widget.celebrateCompletion)
          SliverToBoxAdapter(
            child: StillScoutCompletionHero(
              topScore: widget.frames.isEmpty ? 0.0 : widget.frames.first.score,
              isPro: widget.isPro,
              isAiProTrial: widget.isAiProTrial,
              exportsRemaining: exportsLeft,
              aiScoredCount: aiScored,
              totalFrames: widget.frames.length,
              geminiReached: widget.geminiReached,
              onRetryCloudAi: widget.onRetryCloudAi,
            ),
          ),
        // Post-trial conversion: strike while Gemini quality is fresh.
        if (!widget._isSelecting &&
            widget.isAiProTrial &&
            !widget.isPro &&
            widget.onUpgradeAiPro != null)
          SliverToBoxAdapter(
            child: StillScoutAiProUpgradeCard(
              afterTrial: true,
              onUpgrade: widget.onUpgradeAiPro!,
            ),
          ),
        if (!widget._isSelecting && widget.onContextChanged != null)
          SliverToBoxAdapter(
            child: StillScoutCoachMark(
              message: 'Tap to re-rank by video type',
              visible: widget.showContextChipsCoachMark,
              onDismiss: widget.onContextChipsCoachMarkDismissed ?? () {},
              preferBelow: true,
              child: _ContextChipRow(
                current: widget.videoContext,
                onChanged: widget.onContextChanged!,
              ),
            ),
          ),
        if (!widget._isSelecting &&
            _view == StillScoutGalleryView.ranked &&
            widget.topPicks.isNotEmpty)
          SliverToBoxAdapter(
            child: StillScoutTopPicksCarousel(
              frames: widget.topPicks,
              isPro: widget.isPro,
              rankFor: _rankOf,
              onFrameTap: (frame) {
                final rank = _rankOf(frame);
                if (StillScoutAccessPolicy.isLocked(
                    rank: rank,
                    isPro: widget.isPro,
                    isFirstScout: widget.isFirstScout)) {
                  widget.onLockedFrameTap();
                  return;
                }
                widget.onFrameTap(frame, rank);
              },
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            StillScoutSpacing.m,
            StillScoutSpacing.m,
            StillScoutSpacing.m,
            StillScoutSpacing.xs,
          ),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Text(
                  widget._isSelecting ? 'Select frames' : 'All Frames',
                  style: StillScoutTextStyles.subtitle,
                ),
                const Spacer(),
                if (widget._isSelecting)
                  Text(
                    '${widget.selectedIds.length} selected',
                    style: StillScoutTextStyles.caption.copyWith(
                      color: StillScoutColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  StillScoutViewToggle(
                    current: _view,
                    onChanged: _onViewChanged,
                    timelineLocked: !widget.isPro,
                  ),
              ],
            ),
          ),
        ),
        if (lockedCount > 0 && !widget._isSelecting)
          SliverToBoxAdapter(
            child: _UnlockBanner(
              lockedCount: lockedCount,
              exportsLeft: exportsLeft,
              isPro: widget.isPro,
              onTap: widget.onLockedFrameTap,
            ),
          )
        else if (!widget.isPro && exportsLeft == 0 && !widget._isSelecting)
          SliverToBoxAdapter(
            child: _UnlockBanner(
              lockedCount: 0,
              exportsLeft: exportsLeft,
              isPro: widget.isPro,
              onTap: widget.onLockedFrameTap,
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            StillScoutSpacing.s + 4,
            0,
            StillScoutSpacing.s + 4,
            120,
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: StillScoutSpacing.s + 4,
              crossAxisSpacing: StillScoutSpacing.s + 4,
              childAspectRatio: 0.72,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final frame = frames[index];
                final rank = _rankOf(frame);
                final locked = StillScoutAccessPolicy.isLocked(
                  rank: rank,
                  isPro: widget.isPro,
                  isFirstScout: widget.isFirstScout,
                );
                final staggerTall = index % 3 == 1;
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(
                    milliseconds: 320 + (index * 40).clamp(0, 400),
                  ),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, (1 - value) * 18),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: Align(
                    alignment: staggerTall
                        ? Alignment.topCenter
                        : Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: staggerTall ? 1.0 : 0.94,
                      child: Semantics(
                        label: StillScoutAccessPolicy.semanticsLabel(
                          rank: rank,
                          isPro: widget.isPro,
                          score: frame.score,
                        ),
                        button: true,
                        child: StillScoutFrameTile(
                          scoredFrame: frame,
                          rank: rank,
                          isLocked: locked,
                          isPro: widget.isPro,
                          celebrateShimmer: widget.celebrateCompletion &&
                              rank == 0 &&
                              !locked,
                          isSelecting: widget._isSelecting && !locked,
                          isSelected:
                              widget.selectedIds.contains(frame.frame.id),
                          onTap: () {
                            if (locked) {
                              widget.onLockedFrameTap();
                            } else {
                              widget.onFrameTap(frame, rank);
                            }
                          },
                          onLockedTap: locked
                              ? widget.onLockedFrameTap
                              : null,
                          onLongPress: locked
                              ? null
                              : () => widget.onFrameLongPress(frame),
                        ),
                      ),
                    ),
                  ),
                );
              },
              childCount: frames.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _UnlockBanner extends StatelessWidget {
  const _UnlockBanner({
    required this.lockedCount,
    required this.exportsLeft,
    required this.isPro,
    required this.onTap,
  });

  final int lockedCount;
  final int exportsLeft;
  final bool isPro;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final limit = StillScoutAccessPolicy.keeperLimit(isPro: isPro);
    final message = () {
      if (lockedCount > 0) {
        return 'Unlock $lockedCount more picks · You have $limit free keepers';
      }
      if (!isPro && exportsLeft == 0) {
        return 'Free exports used this scout — upgrade for unlimited scouts & 4K';
      }
      return 'Unlock more picks and exports with StillScout Pro';
    }();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        StillScoutSpacing.m,
        0,
        StillScoutSpacing.m,
        StillScoutSpacing.s,
      ),
      child: ClipRRect(
        borderRadius: StillScoutRadius.card,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: StillScoutRadius.card,
              child: Ink(
                decoration: StillScoutDecorations.glassCard(
                  borderColor: StillScoutColors.accent.withValues(alpha: 0.35),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: StillScoutSpacing.m,
                  vertical: StillScoutSpacing.s + 2,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_open_rounded,
                      color: StillScoutColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: StillScoutTextStyles.caption.copyWith(
                          color: StillScoutColors.chalk,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: StillScoutColors.silver,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StillScoutFramePreview extends StatelessWidget {
  const StillScoutFramePreview({super.key, required this.framePath});

  final String framePath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(StillScoutRadius.l),
      child: Image.file(
        File(framePath),
        fit: BoxFit.cover,
        width: double.infinity,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Context chip row — lets users re-rank results by scene type.
// ---------------------------------------------------------------------------

class _ContextChipRow extends StatelessWidget {
  const _ContextChipRow({
    required this.current,
    required this.onChanged,
  });

  final StillScoutVideoContext current;
  final ValueChanged<StillScoutVideoContext> onChanged;

  static const List<StillScoutVideoContext> _contexts = [
    StillScoutVideoContext.auto,
    StillScoutVideoContext.portrait,
    StillScoutVideoContext.action,
    StillScoutVideoContext.landscape,
    StillScoutVideoContext.event,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        StillScoutSpacing.m,
        0,
        StillScoutSpacing.m,
        StillScoutSpacing.s,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scene Type',
            style: StillScoutTextStyles.caption.copyWith(
              color: StillScoutColors.silver,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _contexts
                  .map((ctx) => _ContextChip(
                        context: ctx,
                        selected: ctx == current,
                        onTap: () => onChanged(ctx),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextChip extends StatelessWidget {
  const _ContextChip({
    required this.context,
    required this.selected,
    required this.onTap,
  });

  final StillScoutVideoContext context;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext ctx) {
    const accent = StillScoutColors.accent;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selected
                ? accent.withValues(alpha: 0.18)
                : StillScoutColors.slateLight.withValues(alpha: 0.35),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.75)
                  : StillScoutColors.silver.withValues(alpha: 0.18),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                context.icon,
                size: 14,
                color: selected ? accent : StillScoutColors.silver,
              ),
              const SizedBox(width: 6),
              Text(
                context.label,
                style: StillScoutTextStyles.caption.copyWith(
                  color: selected ? StillScoutColors.chalk : StillScoutColors.silver,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
