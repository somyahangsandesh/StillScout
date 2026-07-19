import 'dart:ui';

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
    this.isAiProTrial = false,
    this.geminiReached = true,
    this.onRetryCloudAi,
  });

  final double topScore;
  final bool isPro;
  final int exportsRemaining;
  final int aiScoredCount;
  final int totalFrames;
  final bool isAiProTrial;

  /// False when this scout requested cloud AI but Gemini was unreachable and
  /// Vision-only scores were shown instead (soft-degrade, W1.2).
  final bool geminiReached;

  /// Called when the user taps "Retry with Gemini" on the degraded banner.
  /// Null hides the Retry CTA (e.g. while a retry is already in flight).
  final VoidCallback? onRetryCloudAi;

  @override
  State<StillScoutCompletionHero> createState() =>
      _StillScoutCompletionHeroState();
}

class _StillScoutCompletionHeroState extends State<StillScoutCompletionHero>
    with TickerProviderStateMixin {
  late final AnimationController _shimmer;
  late final AnimationController _idlePulse;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _idlePulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _shimmer.forward().then((_) {
      if (mounted) {
        _idlePulse.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _shimmer.dispose();
    _idlePulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final polishLabel = widget.isPro
        ? 'AI Pro · Deep analysis · Unlimited saves · 4K'
        : widget.isAiProTrial
            ? 'Free AI Trial complete · Upgrade to keep Gemini quality'
            : widget.exportsRemaining > 0
                ? '${widget.exportsRemaining}/${StillScoutConstants.freeExportsPerScout} saves left this scout'
                : 'All saves used — upgrade for unlimited';

    final showDegradedBanner =
        !widget.geminiReached && (widget.isPro || widget.isAiProTrial);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        StillScoutSpacing.m,
        StillScoutSpacing.s,
        StillScoutSpacing.m,
        StillScoutSpacing.m,
      ),
      child: ClipRRect(
        borderRadius: StillScoutRadius.card,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                children: [
                  _GoldPulseBadge(
                    score: widget.topScore,
                    shimmer: _shimmer,
                    pulse: _idlePulse,
                  ),
                  const SizedBox(width: StillScoutSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.isPro
                                  ? 'AI Pro scout complete'
                                  : widget.isAiProTrial
                                      ? 'AI Trial scout complete'
                                      : 'Scout complete',
                              style: StillScoutTextStyles.subtitle.copyWith(
                                color: StillScoutColors.scoutGold,
                              ),
                            ),
                            if (widget.isAiProTrial) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: StillScoutColors.scoutGold
                                      .withValues(alpha: 0.18),
                                  borderRadius:
                                      BorderRadius.circular(StillScoutRadius.pill),
                                  border: Border.all(
                                    color: StillScoutColors.scoutGold
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                child: Text(
                                  'TRIAL',
                                  style: StillScoutTextStyles.badge.copyWith(
                                    color: StillScoutColors.scoutGold,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ],
                          ],
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
                            widget.isPro || widget.isAiProTrial
                                ? '${widget.aiScoredCount} of ${widget.totalFrames} frames Gemini-scored'
                                : '${widget.totalFrames} frames ranked on-device · upgrade for Gemini',
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
                  if (showDegradedBanner) ...[
                    const SizedBox(height: StillScoutSpacing.s),
                    _DegradedGeminiBanner(onRetry: widget.onRetryCloudAi),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown on the completion hero when a Pro/trial scout requested Gemini but
/// fell back to on-device Vision scores (W1.2 soft-degrade). Offers a Retry
/// CTA that re-scores the already-extracted frames with Gemini (W2.4).
class _DegradedGeminiBanner extends StatelessWidget {
  const _DegradedGeminiBanner({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: StillScoutSpacing.s + 2,
        vertical: StillScoutSpacing.s,
      ),
      decoration: BoxDecoration(
        color: StillScoutColors.slate.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(StillScoutRadius.s),
        border: Border.all(
          color: StillScoutColors.silver.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 16,
            color: StillScoutColors.silver,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Gemini was unavailable — showing on-device picks',
              style: StillScoutTextStyles.caption.copyWith(
                color: StillScoutColors.chalk,
                fontSize: 11,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRetry,
              child: Text(
                'Retry',
                style: StillScoutTextStyles.caption.copyWith(
                  color: StillScoutColors.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GoldPulseBadge extends StatelessWidget {
  const _GoldPulseBadge({
    required this.score,
    required this.shimmer,
    required this.pulse,
  });

  final double score;
  final Animation<double> shimmer;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([shimmer, pulse]),
      builder: (context, child) {
        // During shimmer, glow sweeps 0.2 → 0.55.
        // After shimmer (pulse takes over), gently oscillates 0.2 ↔ 0.40.
        final shimmerDone = shimmer.status == AnimationStatus.completed;
        final glow = shimmerDone
            ? 0.20 + (pulse.value * 0.20)
            : 0.20 + (shimmer.value * 0.35);
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
        score >= 10.0 ? '10' : score.toStringAsFixed(1),
        style: StillScoutTextStyles.numeric.copyWith(fontSize: 20),
      ),
    );
  }
}
