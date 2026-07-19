import 'package:flutter/material.dart';

import '../../data/models/frame_score_metadata.dart';
import '../theme/stillscout_theme.dart';

/// Returns the accent colour for a score on the 0–10 scale.
Color stillScoutScoreTierColor(double score) {
  if (score >= 8.0) return StillScoutColors.success;
  if (score >= 6.0) return StillScoutColors.accent;
  if (score >= 4.0) return StillScoutColors.silver;
  return StillScoutColors.danger;
}

enum StillScoutScoreBadgeSize { small, medium, large }

/// Radial score indicator — a color-coded progress ring with the numeric
/// score in the centre.  Score is on the 0–10 scale (e.g. 8.5, 9.0, 10).
///
/// Pass [metadata] to enable a tap-to-expand breakdown sheet showing the
/// four sub-scores (Sharpness, Lighting, Expression, Composition).
class StillScoutScoreBadge extends StatelessWidget {
  const StillScoutScoreBadge({
    super.key,
    required this.score,
    this.size = StillScoutScoreBadgeSize.medium,
    this.metadata,
  });

  final double score;
  final StillScoutScoreBadgeSize size;

  /// When provided, tapping the badge shows a score-breakdown bottom sheet.
  final FrameScoreMetadata? metadata;

  double get _diameter => switch (size) {
        StillScoutScoreBadgeSize.small  => 36,
        StillScoutScoreBadgeSize.medium => 50,
        StillScoutScoreBadgeSize.large  => 70,
      };

  double get _fontSize => switch (size) {
        StillScoutScoreBadgeSize.small  => 11,
        StillScoutScoreBadgeSize.medium => 14,
        StillScoutScoreBadgeSize.large  => 20,
      };

  double get _strokeWidth => switch (size) {
        StillScoutScoreBadgeSize.small  => 2.5,
        StillScoutScoreBadgeSize.medium => 3.0,
        StillScoutScoreBadgeSize.large  => 4.0,
      };

  String get _label {
    if (score >= 10.0) return '10';
    return score.toStringAsFixed(1);
  }

  void _showBreakdown(BuildContext context) {
    final m = metadata;
    if (m == null) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScoreBreakdownSheet(score: score, metadata: m),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clamped = score.clamp(0.0, 10.0);
    final color = stillScoutScoreTierColor(clamped);
    final hasTap = metadata != null;

    final badge = Semantics(
      label: hasTap
          ? 'Score $_label out of 10, tap for breakdown'
          : 'Score $_label out of 10',
      button: hasTap,
      excludeSemantics: true,
      child: SizedBox(
        width: _diameter,
        height: _diameter,
        child: Stack(
          alignment: Alignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: StillScoutColors.voidBlack.withValues(alpha: 0.62),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(_strokeWidth / 2),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: clamped / 10.0),
                duration: StillScoutMotion.slow,
                curve: StillScoutMotion.entrance,
                builder: (context, value, _) => CircularProgressIndicator(
                  value: value,
                  strokeWidth: _strokeWidth,
                  backgroundColor: color.withValues(alpha: 0.18),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
            Text(
              _label,
              style: StillScoutTextStyles.badge.copyWith(
                color: color,
                fontSize: _fontSize,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );

    if (!hasTap) return badge;
    return GestureDetector(
      onTap: () => _showBreakdown(context),
      child: badge,
    );
  }
}

// ── Score breakdown sheet ─────────────────────────────────────────────────────

class _ScoreBreakdownSheet extends StatelessWidget {
  const _ScoreBreakdownSheet({
    required this.score,
    required this.metadata,
  });

  final double score;
  final FrameScoreMetadata metadata;

  static const _rows = [
    (Icons.blur_circular_rounded,   'Sharpness',   'blurScore'),
    (Icons.wb_sunny_rounded,        'Lighting',    'lightingScore'),
    (Icons.face_retouching_natural_rounded, 'Expression', 'openEyesScore'),
    (Icons.crop_free_rounded,       'Composition', 'compositionScore'),
  ];

  int _subScore(String key) => switch (key) {
        'blurScore'        => metadata.blurScore,
        'lightingScore'    => metadata.lightingScore,
        'openEyesScore'    => metadata.openEyesScore,
        'compositionScore' => metadata.compositionScore,
        _                  => 50,
      };

  @override
  Widget build(BuildContext context) {
    final label = score >= 10.0 ? '10' : score.toStringAsFixed(1);
    final color = stillScoutScoreTierColor(score);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: StillScoutColors.voidBlack,
      borderRadius: StillScoutRadius.sheet,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          StillScoutSpacing.l,
          StillScoutSpacing.m,
          StillScoutSpacing.l,
          StillScoutSpacing.l + bottomInset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: StillScoutColors.silver.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: StillScoutSpacing.l),
            // Header
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.12),
                    border: Border.all(
                      color: color.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: StillScoutTextStyles.numeric.copyWith(
                      fontSize: 20,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: StillScoutSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Score breakdown',
                        style: StillScoutTextStyles.title.copyWith(
                          color: StillScoutColors.chalk,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Scored via ${metadata.source.label}',
                        style: StillScoutTextStyles.caption.copyWith(
                          color: StillScoutColors.silver,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: StillScoutSpacing.l),
            // Sub-score rows
            ..._rows.map((row) {
              final sub = _subScore(row.$3);
              final subColor = stillScoutScoreTierColor(sub / 10.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: StillScoutSpacing.m),
                child: Row(
                  children: [
                    Icon(row.$1, size: 18, color: subColor),
                    const SizedBox(width: StillScoutSpacing.m),
                    SizedBox(
                      width: 90,
                      child: Text(
                        row.$2,
                        style: StillScoutTextStyles.body.copyWith(
                          color: StillScoutColors.chalk,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: sub / 100.0),
                          duration: StillScoutMotion.slow,
                          curve: StillScoutMotion.entrance,
                          builder: (_, v, __) => LinearProgressIndicator(
                            value: v,
                            minHeight: 6,
                            backgroundColor:
                                subColor.withValues(alpha: 0.15),
                            valueColor:
                                AlwaysStoppedAnimation(subColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: StillScoutSpacing.s),
                    SizedBox(
                      width: 32,
                      child: Text(
                        (sub / 10.0).toStringAsFixed(1),
                        textAlign: TextAlign.right,
                        style: StillScoutTextStyles.badge.copyWith(
                          color: subColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            // Summary if available
            if (metadata.summary != null) ...[
              const SizedBox(height: StillScoutSpacing.s),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(StillScoutSpacing.m),
                decoration: BoxDecoration(
                  color: StillScoutColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(StillScoutRadius.m),
                  border: Border.all(
                    color: StillScoutColors.accent.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: StillScoutColors.accent,
                    ),
                    const SizedBox(width: StillScoutSpacing.s),
                    Expanded(
                      child: Text(
                        metadata.summary!,
                        style: StillScoutTextStyles.caption.copyWith(
                          color: StillScoutColors.chalk,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
