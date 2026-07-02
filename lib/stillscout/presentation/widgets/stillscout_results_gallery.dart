import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/models/frame_score_metadata.dart';
import '../../data/models/scored_frame.dart';
import '../../domain/stillscout_access_policy.dart';
import '../theme/stillscout_theme.dart';
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
    this.selectedIds = const {},
    this.videoDurationMs,
    this.processingTimeMs,
    this.exportsUsedThisSession = 0,
    this.celebrateCompletion = false,
  });

  final List<ScoredFrame> frames;
  final List<ScoredFrame> topPicks;
  final void Function(ScoredFrame frame, int rank) onFrameTap;
  final void Function(ScoredFrame frame) onFrameLongPress;
  final VoidCallback onLockedFrameTap;
  final bool isPro;
  final Set<String> selectedIds;
  final int? videoDurationMs;
  final int? processingTimeMs;
  final int exportsUsedThisSession;
  final bool celebrateCompletion;

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
    );
    final aiScored = widget.frames
        .where((f) => f.metadata.source == ScoreSource.llm)
        .length;
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
              exportsUsedThisSession: widget.exportsUsedThisSession,
            ),
          ),
        if (!widget._isSelecting && widget.celebrateCompletion)
          SliverToBoxAdapter(
            child: StillScoutCompletionHero(
              topScore: widget.frames.isEmpty ? 0 : widget.frames.first.score,
              isPro: widget.isPro,
              exportsRemaining: exportsLeft,
              aiScoredCount: aiScored,
              totalFrames: widget.frames.length,
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
                if (StillScoutAccessPolicy.isLocked(rank: rank, isPro: widget.isPro)) {
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
                      heightFactor: staggerTall ? 1.08 : 0.94,
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
                          celebrateShimmer:
                              widget.celebrateCompletion && rank == 0 && !locked,
                          isSelecting: widget._isSelecting && !locked,
                          isSelected: widget.selectedIds.contains(frame.frame.id),
                          onTap: () {
                            if (locked) {
                              widget.onLockedFrameTap();
                            } else {
                              widget.onFrameTap(frame, rank);
                            }
                          },
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
