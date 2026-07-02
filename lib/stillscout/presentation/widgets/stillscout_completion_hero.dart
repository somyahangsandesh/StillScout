import 'package:flutter/material.dart';

import '../../domain/stillscout_constants.dart';
import '../theme/stillscout_theme.dart';

/// One-shot post-scout hero — celebrates the top pick and export allowance.
class StillScoutCompletionHero extends StatefulWidget {
  const StillScoutCompletionHero({
    super.key,
    required this.topScore,
    required this.isPro,
    required this.exportsRemaining,
    required this.aiScoredCount,
    required this.totalFrames,
  });

  final int topScore;
  final bool isPro;
  final int exportsRemaining;
  final int aiScoredCount;
  final int totalFrames;

  @override
  State<StillScoutCompletionHero> createState() =>
      _StillScoutCompletionHeroState();
}

class _StillScoutCompletionHeroState extends State<StillScoutCompletionHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final polishLabel = widget.isPro
        ? 'Unlimited polished saves · Native 4K ready'
        : '${widget.exportsRemaining}/${StillScoutConstants.freeExportsPerScout} Auto Polish exports ready';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        StillScoutSpacing.m,
        StillScoutSpacing.s,
        StillScoutSpacing.m,
        StillScoutSpacing.m,
      ),
      child: AnimatedBuilder(
        animation: _shimmer,
        builder: (context, child) {
          final t = Curves.easeOutCubic.transform(_shimmer.value);
          return DecoratedBox(
            decoration: StillScoutDecorations.glassCard(
              borderColor: Color.lerp(
                StillScoutColors.scoutGold.withValues(alpha: 0.35),
                StillScoutColors.accent.withValues(alpha: 0.55),
                t,
              ),
              borderWidth: 1.5,
            ),
            child: child,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(StillScoutSpacing.m),
          child: Row(
            children: [
              _GoldPulseBadge(score: widget.topScore, animation: _shimmer),
              const SizedBox(width: StillScoutSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scout complete',
                      style: StillScoutTextStyles.subtitle.copyWith(
                        color: StillScoutColors.scoutGold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      polishLabel,
                      style: StillScoutTextStyles.caption.copyWith(
                        color: StillScoutColors.chalk,
                      ),
                    ),
                    if (widget.totalFrames > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${widget.aiScoredCount} of ${widget.totalFrames} frames AI-scored',
                        style: StillScoutTextStyles.caption.copyWith(
                          color: StillScoutColors.silver,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.auto_fix_high_rounded,
                color: StillScoutColors.accent.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoldPulseBadge extends StatelessWidget {
  const _GoldPulseBadge({
    required this.score,
    required this.animation,
  });

  final int score;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final glow = 0.2 + (animation.value * 0.35);
        return Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: StillScoutColors.scoutGold.withValues(alpha: 0.15),
            border: Border.all(
              color: StillScoutColors.scoutGold.withValues(alpha: 0.7),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: StillScoutColors.scoutGold.withValues(alpha: glow),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: child,
        );
      },
      child: Text(
        '$score',
        style: StillScoutTextStyles.numeric.copyWith(fontSize: 22),
      ),
    );
  }
}
