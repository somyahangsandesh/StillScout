import 'package:flutter/material.dart';

import '../theme/stillscout_theme.dart';

/// Shared metric cell used by frame detail and compare — keeps score UI
/// visually consistent across sheets.
class StillScoutScoreMetricCell extends StatelessWidget {
  const StillScoutScoreMetricCell({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final int value;
  final Widget? trailing;

  static Color colorFor(int value) {
    if (value >= 80) return StillScoutColors.scoutGold;
    if (value >= 60) return StillScoutColors.accent;
    return StillScoutColors.silver;
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(value);
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: StillScoutTextStyles.caption.copyWith(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing ??
            Text(
              '$value',
              style: StillScoutTextStyles.caption.copyWith(
                color: StillScoutColors.chalk,
                fontWeight: FontWeight.w700,
              ),
            ),
      ],
    );
  }
}

/// 2×2 compact breakdown for a single frame (detail sheet).
class StillScoutCompactScoreGrid extends StatelessWidget {
  const StillScoutCompactScoreGrid({
    super.key,
    required this.sharpness,
    required this.lighting,
    required this.openEyes,
    required this.composition,
  });

  final int sharpness;
  final int lighting;
  final int openEyes;
  final int composition;

  @override
  Widget build(BuildContext context) {
    final cells = [
      (Icons.blur_off_outlined, 'Sharp', sharpness),
      (Icons.wb_sunny_outlined, 'Light', lighting),
      (Icons.remove_red_eye_outlined, 'Eyes', openEyes),
      (Icons.crop_free_outlined, 'Comp', composition),
    ];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: StillScoutDecorations.surfaceCard(),
      child: Column(
        children: [
          for (var row = 0; row < 2; row++) ...[
            if (row > 0) const SizedBox(height: StillScoutSpacing.s),
            Row(
              children: [
                for (var col = 0; col < 2; col++) ...[
                  if (col > 0) const SizedBox(width: StillScoutSpacing.s),
                  Expanded(
                    child: StillScoutScoreMetricCell(
                      icon: cells[row * 2 + col].$1,
                      label: cells[row * 2 + col].$2,
                      value: cells[row * 2 + col].$3,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Head-to-head 2×2 breakdown (compare sheet) — same cells as detail, with
/// A · B values instead of linear bars.
class StillScoutCompareScoreGrid extends StatelessWidget {
  const StillScoutCompareScoreGrid({
    super.key,
    required this.sharpnessA,
    required this.sharpnessB,
    required this.lightingA,
    required this.lightingB,
    required this.openEyesA,
    required this.openEyesB,
    required this.compositionA,
    required this.compositionB,
    required this.overallA,
    required this.overallB,
  });

  final int sharpnessA;
  final int sharpnessB;
  final int lightingA;
  final int lightingB;
  final int openEyesA;
  final int openEyesB;
  final int compositionA;
  final int compositionB;
  final double overallA;
  final double overallB;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      (Icons.blur_off_outlined, 'Sharp', sharpnessA, sharpnessB),
      (Icons.wb_sunny_outlined, 'Light', lightingA, lightingB),
      (Icons.remove_red_eye_outlined, 'Eyes', openEyesA, openEyesB),
      (Icons.crop_free_outlined, 'Comp', compositionA, compositionB),
    ];

    return Container(
      padding: const EdgeInsets.all(StillScoutSpacing.m - 2),
      decoration: StillScoutDecorations.surfaceCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Score Breakdown', style: StillScoutTextStyles.subtitle),
          const SizedBox(height: StillScoutSpacing.m),
          for (var row = 0; row < 2; row++) ...[
            if (row > 0) const SizedBox(height: StillScoutSpacing.s),
            Row(
              children: [
                for (var col = 0; col < 2; col++) ...[
                  if (col > 0) const SizedBox(width: StillScoutSpacing.s),
                  Expanded(
                    child: _CompareMetricCell(
                      icon: metrics[row * 2 + col].$1,
                      label: metrics[row * 2 + col].$2,
                      valueA: metrics[row * 2 + col].$3,
                      valueB: metrics[row * 2 + col].$4,
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: StillScoutSpacing.m),
          const Divider(color: StillScoutColors.slate, height: 1),
          const SizedBox(height: StillScoutSpacing.m),
          Row(
            children: [
              Text('Overall', style: StillScoutTextStyles.caption),
              const Spacer(),
              _OverallPair(scoreA: overallA, scoreB: overallB),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompareMetricCell extends StatelessWidget {
  const _CompareMetricCell({
    required this.icon,
    required this.label,
    required this.valueA,
    required this.valueB,
  });

  final IconData icon;
  final String label;
  final int valueA;
  final int valueB;

  @override
  Widget build(BuildContext context) {
    final lead = valueA == valueB
        ? StillScoutColors.silver
        : valueA > valueB
            ? StillScoutScoreMetricCell.colorFor(valueA)
            : StillScoutScoreMetricCell.colorFor(valueB);
    return Row(
      children: [
        Icon(icon, size: 14, color: lead),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: StillScoutTextStyles.caption.copyWith(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '$valueA',
          style: StillScoutTextStyles.caption.copyWith(
            color: valueA >= valueB
                ? StillScoutColors.chalk
                : StillScoutColors.silver,
            fontWeight: valueA > valueB ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          ' · ',
          style: StillScoutTextStyles.caption.copyWith(
            color: StillScoutColors.silver.withValues(alpha: 0.6),
          ),
        ),
        Text(
          '$valueB',
          style: StillScoutTextStyles.caption.copyWith(
            color: valueB >= valueA
                ? StillScoutColors.chalk
                : StillScoutColors.silver,
            fontWeight: valueB > valueA ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _OverallPair extends StatelessWidget {
  const _OverallPair({required this.scoreA, required this.scoreB});

  final double scoreA;
  final double scoreB;

  String _fmt(double v) => v >= 10.0 ? '10' : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _fmt(scoreA),
          style: StillScoutTextStyles.subtitle.copyWith(
            fontSize: 17,
            color: scoreA >= scoreB
                ? StillScoutColors.scoutGold
                : StillScoutColors.silver,
          ),
        ),
        Text(
          ' · ',
          style: StillScoutTextStyles.caption.copyWith(
            color: StillScoutColors.silver.withValues(alpha: 0.6),
          ),
        ),
        Text(
          _fmt(scoreB),
          style: StillScoutTextStyles.subtitle.copyWith(
            fontSize: 17,
            color: scoreB >= scoreA
                ? StillScoutColors.scoutGold
                : StillScoutColors.silver,
          ),
        ),
      ],
    );
  }
}
