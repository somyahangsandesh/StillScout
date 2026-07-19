import 'dart:ui';

import 'package:flutter/material.dart';

import '../../domain/stillscout_constants.dart';
import '../providers/stillscout_notifier.dart';
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
    this.cloudScoringOutcome = CloudScoringOutcome.notApplicable,
    this.onRetryCloudAi,
    this.onUpgradeAiPro,
  });

  final double topScore;
  final bool isPro;
  final int exportsRemaining;
  final int aiScoredCount;
  final int totalFrames;
  final bool isAiProTrial;

  /// Distinguishes full Gemini success from soft-degrade vs daily quota.
  final CloudScoringOutcome cloudScoringOutcome;

  /// Called when the user taps "Retry with Gemini" on the degraded banner.
  /// Null hides the Retry CTA (e.g. while a retry is already in flight).
  final VoidCallback? onRetryCloudAi;

  /// Optional upgrade path when daily AI quota is exhausted (free/trial).
  final VoidCallback? onUpgradeAiPro;

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

  bool get _usedCloudAi =>
      widget.isPro ||
      widget.isAiProTrial ||
      widget.cloudScoringOutcome != CloudScoringOutcome.notApplicable;

  @override
  Widget build(BuildContext context) {
    final polishLabel = widget.isPro
        ? 'AI Pro · Deep analysis · Unlimited saves · 4K'
        : widget.isAiProTrial
            ? 'Free AI Trial complete · Upgrade to keep Gemini quality'
            : widget.exportsRemaining > 0
                ? '${widget.exportsRemaining}/${StillScoutConstants.freeExportsPerScout} saves left this scout'
                : 'All saves used — upgrade for unlimited';

    final outcome = widget.cloudScoringOutcome;
    final showOutcomeBanner = _usedCloudAi &&
        (outcome == CloudScoringOutcome.degraded ||
            outcome == CloudScoringOutcome.quotaExceeded);

    final title = widget.isPro
        ? 'AI Pro scout complete'
        : widget.isAiProTrial
            ? 'AI Trial scout complete'
            : 'Scout complete';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        StillScoutSpacing.m,
        StillScoutSpacing.s,
        StillScoutSpacing.m,
        StillScoutSpacing.s,
      ),
      child: Semantics(
        label:
            '$title. Top score ${widget.topScore >= 10.0 ? '10' : widget.topScore.toStringAsFixed(1)}. $polishLabel',
        child: ClipRRect(
          borderRadius: StillScoutRadius.card,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: AnimatedBuilder(
              animation: _shimmer,
              builder: (context, child) {
                final animT =
                    StillScoutMotion.entrance.transform(_shimmer.value);
                return DecoratedBox(
                  decoration: StillScoutDecorations.glassCard(
                    borderColor: Color.lerp(
                      StillScoutColors.scoutGold.withValues(alpha: 0.40),
                      StillScoutColors.accent.withValues(alpha: 0.55),
                      animT,
                    ),
                    borderWidth: 1.5,
                  ),
                  child: child,
                );
              },
              child: Padding(
                padding: StillScoutSpacing.cardPadding,
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
                                  Flexible(
                                    child: Text(
                                      title,
                                      style: StillScoutTextStyles.subtitle
                                          .copyWith(
                                        color: StillScoutColors.scoutGold,
                                      ),
                                    ),
                                  ),
                                  if (widget.isAiProTrial) ...[
                                    const SizedBox(width: StillScoutSpacing.s),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: StillScoutColors.scoutGold
                                            .withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(
                                            StillScoutRadius.pill),
                                        border: Border.all(
                                          color: StillScoutColors.scoutGold
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                      child: Text(
                                        'TRIAL',
                                        style: StillScoutTextStyles.badge
                                            .copyWith(
                                          color: StillScoutColors.scoutGold,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: StillScoutSpacing.xs),
                              Text(
                                polishLabel,
                                style: StillScoutTextStyles.caption.copyWith(
                                  color: StillScoutColors.chalk,
                                ),
                              ),
                              if (widget.totalFrames > 0) ...[
                                const SizedBox(height: StillScoutSpacing.xs),
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
                      ],
                    ),
                    if (showOutcomeBanner) ...[
                      const SizedBox(height: StillScoutSpacing.m),
                      if (outcome == CloudScoringOutcome.quotaExceeded)
                        _QuotaExceededBanner(
                          isPro: widget.isPro,
                          onUpgrade:
                              widget.isPro ? null : widget.onUpgradeAiPro,
                        )
                      else
                        _DegradedGeminiBanner(onRetry: widget.onRetryCloudAi),
                    ],
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

/// Soft-degrade: Gemini failed but quota remains — Retry is appropriate.
class _DegradedGeminiBanner extends StatelessWidget {
  const _DegradedGeminiBanner({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return _OutcomeBanner(
      icon: Icons.cloud_off_rounded,
      accent: StillScoutColors.silver,
      message: 'Gemini was unavailable — showing on-device picks',
      actionLabel: onRetry == null ? null : 'Retry',
      onAction: onRetry,
      semanticsLabel: onRetry == null
          ? 'Gemini was unavailable. Showing on-device picks.'
          : 'Gemini was unavailable. Showing on-device picks. Double tap to retry.',
    );
  }
}

/// Daily / server AI quota hit — never offer Retry; upgrade or wait.
class _QuotaExceededBanner extends StatelessWidget {
  const _QuotaExceededBanner({
    required this.isPro,
    this.onUpgrade,
  });

  final bool isPro;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    final message = isPro
        ? 'Daily AI quota reached — showing on-device picks. Try again tomorrow.'
        : 'Daily AI quota reached — showing on-device picks. Upgrade for priority access.';
    return _OutcomeBanner(
      icon: Icons.hourglass_top_rounded,
      accent: StillScoutColors.scoutGold,
      message: message,
      actionLabel: (!isPro && onUpgrade != null) ? 'Upgrade' : null,
      onAction: onUpgrade,
      semanticsLabel: (!isPro && onUpgrade != null)
          ? '$message Double tap to upgrade.'
          : message,
    );
  }
}

class _OutcomeBanner extends StatelessWidget {
  const _OutcomeBanner({
    required this.icon,
    required this.accent,
    required this.message,
    required this.semanticsLabel,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color accent;
  final String message;
  final String semanticsLabel;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      button: onAction != null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: StillScoutSpacing.s + 2,
          vertical: StillScoutSpacing.s,
        ),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(StillScoutRadius.s),
          border: Border.all(
            color: accent.withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: StillScoutTextStyles.caption.copyWith(
                  color: StillScoutColors.chalk,
                  fontSize: 11,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onAction,
                  borderRadius: BorderRadius.circular(StillScoutRadius.pill),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Text(
                      actionLabel!,
                      style: StillScoutTextStyles.caption.copyWith(
                        color: StillScoutColors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
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
