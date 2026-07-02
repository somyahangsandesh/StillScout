import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/frame_score_metadata.dart';
import '../../data/models/scored_frame.dart';
import '../../domain/stillscout_access_policy.dart';
import '../../domain/stillscout_constants.dart';
import '../theme/stillscout_theme.dart';

class StillScoutFrameTile extends StatefulWidget {
  const StillScoutFrameTile({
    super.key,
    required this.scoredFrame,
    required this.onTap,
    this.onLongPress,
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
    with SingleTickerProviderStateMixin {
  double _scale = 1;
  AnimationController? _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    if (widget.celebrateShimmer) {
      _shimmerCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600),
      )..forward();
    }
  }

  @override
  void dispose() {
    _shimmerCtrl?.dispose();
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
                          color: StillScoutColors.scoutGold.withValues(alpha: glow),
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
            boxShadow: isTop && !widget.isSelecting
                ? [StillScoutColors.goldGlow()]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isTop ? 14 : 16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildImage(widget.isLocked),
                if (!widget.isLocked)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 3,
                      color: _tierAccentColor(frame.score),
                    ),
                  ),
                if (widget.isSelecting && !widget.isLocked)
                  Container(
                    color: widget.isSelected
                        ? StillScoutColors.accent.withValues(alpha: 0.18)
                        : StillScoutColors.voidBlack.withValues(alpha: 0.25),
                  ),
                if (widget.isLocked) _LockedOverlay(score: frame.score),
                if (!widget.isLocked)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xCC000000), Colors.transparent],
                        ),
                      ),
                      child: Row(
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
                          _ScoreChip(score: frame.score),
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

class _LockedOverlay extends StatelessWidget {
  const _LockedOverlay({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: StillScoutColors.voidBlack.withValues(alpha: 0.45),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_rounded,
            color: StillScoutColors.accent.withValues(alpha: 0.9),
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            'Score $score',
            style: StillScoutTextStyles.caption.copyWith(
              color: StillScoutColors.chalk,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Upgrade to unlock',
            style: StillScoutTextStyles.caption.copyWith(
              color: StillScoutColors.silver,
              fontSize: 11,
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

Color _tierAccentColor(int score) {
  if (score >= 80) return StillScoutColors.success;
  if (score >= 60) return StillScoutColors.accent;
  if (score >= 40) return StillScoutColors.silver.withValues(alpha: 180 / 255);
  return StillScoutColors.danger.withValues(alpha: 130 / 255);
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
      fit: BoxFit.cover,
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

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: StillScoutColors.voidBlack.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: StillScoutColors.accent.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        '$score',
        style: StillScoutTextStyles.caption.copyWith(
          color: StillScoutColors.accent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
