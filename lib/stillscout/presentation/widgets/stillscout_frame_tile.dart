import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/frame_score_metadata.dart';
import '../../data/models/scored_frame.dart';
import '../../domain/stillscout_access_policy.dart';
import '../../domain/stillscout_constants.dart';
import '../theme/stillscout_theme.dart';
import 'stillscout_score_badge.dart';

class StillScoutFrameTile extends StatefulWidget {
  const StillScoutFrameTile({
    super.key,
    required this.scoredFrame,
    required this.onTap,
    this.onLongPress,
    this.onLockedTap,
    this.isSelecting = false,
    this.isSelected = false,
    this.rank = 0,
    this.isLocked = false,
    this.isPro = false,
    this.celebrateShimmer = false,
  });

  final ScoredFrame scoredFrame;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  /// Called when the user taps the "Unlock with Pro" button in the locked overlay.
  final VoidCallback? onLockedTap;
  final bool isSelecting;
  final bool isSelected;
  final int rank;
  final bool isLocked;
  final bool isPro;
  final bool celebrateShimmer;

  @override
  State<StillScoutFrameTile> createState() => _StillScoutFrameTileState();
}

class _StillScoutFrameTileState extends State<StillScoutFrameTile>
    with TickerProviderStateMixin {
  double _scale = 1;
  AnimationController? _shimmerCtrl;
  AnimationController? _revealGlowCtrl;
  Animation<double>? _revealGlow;

  @override
  void initState() {
    super.initState();
    if (widget.celebrateShimmer) {
      _shimmerCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600),
      )..forward();
    } else if (widget.scoredFrame.isTopScout && !widget.isLocked) {
      // A distinct, one-shot "reveal" flash for top-scout tiles that aren't
      // already covered by the rank-0 completion shimmer above — a quick
      // gold wash across the artwork rather than a border glow, so the two
      // effects never stack on the same tile.
      _revealGlowCtrl = AnimationController(
        vsync: this,
        duration: StillScoutMotion.slow,
      );
      _revealGlow = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: StillScoutMotion.emphasis)),
          weight: 35,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 65,
        ),
      ]).animate(_revealGlowCtrl!);
      _revealGlowCtrl!.forward();
    }
  }

  @override
  void dispose() {
    _shimmerCtrl?.dispose();
    _revealGlowCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = widget.scoredFrame;
    final isTop = frame.isTopScout && !widget.isLocked;
    final footer = StillScoutAccessPolicy.frameFooterLabel(
      rank: widget.rank,
      isPro: widget.isPro,
      formattedTimestamp: frame.frame.formattedTimestamp,
    );

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      onTap: () {
        if (widget.isLocked) {
          HapticFeedback.lightImpact();
        }
        widget.onTap();
      },
      onLongPress: widget.isLocked ? null : widget.onLongPress,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: _shimmerCtrl != null
            ? AnimatedBuilder(
                animation: _shimmerCtrl!,
                builder: (context, child) {
                  final glow = _shimmerCtrl!.value * 0.45;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: StillScoutColors.scoutGold
                              .withValues(alpha: glow),
                          blurRadius: 22,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: _buildTile(frame, isTop, footer),
              )
            : _buildTile(frame, isTop, footer),
      ),
    );
  }

  Widget _buildTile(ScoredFrame frame, bool isTop, String footer) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isSelected
              ? StillScoutColors.accent
              : (isTop
                  ? StillScoutColors.scoutGold
                  : (widget.isLocked
                      ? StillScoutColors.slateLight.withValues(alpha: 0.5)
                      : Colors.transparent)),
          width: widget.isSelected ? 2.5 : (isTop ? 2.5 : 1),
        ),
        boxShadow:
            isTop && !widget.isSelecting ? [StillScoutColors.goldGlow()] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isTop ? 14 : 16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImage(widget.isLocked),
            if (_revealGlow != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _revealGlow!,
                    builder: (context, _) {
                      final glow = _revealGlow!.value;
                      if (glow <= 0) return const SizedBox.shrink();
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            radius: 1.1,
                            colors: [
                              StillScoutColors.scoutGold
                                  .withValues(alpha: glow * 0.4),
                              StillScoutColors.scoutGold.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            if (!widget.isLocked)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  color: stillScoutScoreTierColor(frame.score),
                ),
              ),
            if (widget.isSelecting && !widget.isLocked)
              Container(
                color: widget.isSelected
                    ? StillScoutColors.accent.withValues(alpha: 0.18)
                    : StillScoutColors.voidBlack.withValues(alpha: 0.25),
              ),
            if (widget.isLocked)
              _LockedOverlay(
                score: frame.score,
                metadata: frame.metadata,
                onUnlock: widget.onLockedTap ?? widget.onTap,
              ),
            if (!widget.isLocked)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 28, 10, 10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xCC000000), Colors.transparent],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_hasSummary(frame.metadata)) ...[
                        Text(
                          frame.metadata.summary!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: StillScoutTextStyles.caption.copyWith(
                            color:
                                StillScoutColors.chalk.withValues(alpha: 0.82),
                            fontSize: 10.5,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              footer,
                              style: StillScoutTextStyles.caption.copyWith(
                                color: StillScoutColors.chalk,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StillScoutScoreBadge(
                            score: frame.score,
                            size: StillScoutScoreBadgeSize.small,
                            metadata: frame.metadata,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            if (!widget.isLocked && widget.rank < 3)
              Positioned(
                top: 10,
                left: 10,
                child: StillScoutDecorations.rankBadge(widget.rank),
              )
            else if (isTop && !widget.isSelecting && !widget.isLocked)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: StillScoutColors.scoutGold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('TOP SCOUT', style: StillScoutTextStyles.badge),
                ),
              ),
            if (!widget.isLocked)
              Positioned(
                top: 10,
                right: 10,
                child: _SourceChip(source: frame.metadata.source),
              ),
            if (widget.isSelecting && !widget.isLocked)
              Positioned(
                top: 10,
                right: 10,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isSelected
                        ? StillScoutColors.accent
                        : Colors.black.withValues(alpha: 0.4),
                    border: Border.all(
                      color: widget.isSelected
                          ? StillScoutColors.accent
                          : StillScoutColors.chalk.withValues(alpha: 0.7),
                      width: 1.5,
                    ),
                  ),
                  child: widget.isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: StillScoutColors.voidBlack,
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(bool locked) {
    final image = _FadeInFrameImage(
      filePath: widget.scoredFrame.frame.filePath,
      cacheWidth: locked ? StillScoutConstants.freePreviewMaxWidth : null,
    );
    if (!locked) return image;
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          StillScoutColors.voidBlack.withValues(alpha: 0.35),
          BlendMode.darken,
        ),
        child: image,
      ),
    );
  }
}

/// Aspirational lock overlay: shows the score prominently, a Gemini summary
/// snippet if available, and a gold "Unlock with Pro" CTA — turning a
/// frustrating wall into a desire-building moment.
class _LockedOverlay extends StatelessWidget {
  const _LockedOverlay({
    required this.score,
    required this.metadata,
    this.onUnlock,
  });

  final double score;
  final FrameScoreMetadata metadata;
  final VoidCallback? onUnlock;

  String? get _summarySnippet {
    final s = metadata.summary;
    if (s == null || s.trim().isEmpty) return null;
    // Take the first sentence or up to 60 chars.
    final trimmed = s.trim();
    final dot = trimmed.indexOf('. ');
    final snippet = dot > 0 && dot < 60 ? trimmed.substring(0, dot) : trimmed;
    return snippet.length > 60 ? '${snippet.substring(0, 60)}…' : snippet;
  }

  @override
  Widget build(BuildContext context) {
    final scoreLabel = score >= 10.0 ? '10' : score.toStringAsFixed(1);
    final snippet = _summarySnippet;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            StillScoutColors.voidBlack.withValues(alpha: 0.55),
            StillScoutColors.voidBlack.withValues(alpha: 0.75),
          ],
        ),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Large gold score badge.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: StillScoutColors.scoutGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: StillScoutColors.scoutGold.withValues(alpha: 0.65),
                width: 1.5,
              ),
            ),
            child: Text(
              scoreLabel,
              style: StillScoutTextStyles.numeric.copyWith(
                color: StillScoutColors.scoutGold,
                fontSize: 22,
              ),
            ),
          ),
          if (snippet != null) ...[
            const SizedBox(height: 6),
            Text(
              snippet,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: StillScoutTextStyles.caption.copyWith(
                color: StillScoutColors.chalk.withValues(alpha: 0.82),
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onUnlock,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: StillScoutColors.scoutGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: StillScoutColors.scoutGold.withValues(alpha: 0.55),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    size: 12,
                    color: StillScoutColors.scoutGold,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Unlock with Pro',
                    style: StillScoutTextStyles.caption.copyWith(
                      color: StillScoutColors.scoutGold,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.source});

  final ScoreSource source;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (source) {
      ScoreSource.llm => ('AI', StillScoutColors.accent),
      ScoreSource.hybrid => ('ML', StillScoutColors.success),
      ScoreSource.heuristic => ('Est.', StillScoutColors.silver),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: StillScoutColors.voidBlack.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: StillScoutTextStyles.badge.copyWith(
          color: color,
          fontSize: 9,
        ),
      ),
    );
  }
}

bool _hasSummary(FrameScoreMetadata metadata) {
  final summary = metadata.summary;
  return summary != null && summary.trim().isNotEmpty;
}

class _FadeInFrameImage extends StatelessWidget {
  const _FadeInFrameImage({
    required this.filePath,
    this.cacheWidth,
  });

  final String filePath;
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(filePath),
      key: ValueKey(filePath),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      cacheWidth: cacheWidth,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: frame == null
              ? Container(
                  key: const ValueKey('skeleton'),
                  color: StillScoutColors.filmGray,
                )
              : KeyedSubtree(key: const ValueKey('image'), child: child),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: StillScoutColors.filmGray,
        alignment: Alignment.center,
        child: const Icon(
          Icons.broken_image_outlined,
          color: StillScoutColors.silver,
        ),
      ),
    );
  }
}
