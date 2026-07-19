import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/frame_score_metadata.dart';
import '../../data/models/scored_frame.dart';
import '../../domain/stillscout_access_policy.dart';
import '../../domain/stillscout_constants.dart';
import '../theme/stillscout_theme.dart';
import 'stillscout_glass_surface.dart';

class StillScoutSessionHeader extends StatelessWidget {
  const StillScoutSessionHeader({
    super.key,
    required this.frames,
    this.videoDurationMs,
    this.processingTimeMs,
    this.isPro = false,
    this.isAiProTrial = false,
    this.isFirstScout = false,
    this.exportsUsedThisSession = 0,
  });

  final List<ScoredFrame> frames;
  final int? videoDurationMs;
  final int? processingTimeMs;

  /// Real Pro entitlement — drives keeper/export chips.
  final bool isPro;

  /// One-time AI trial — only affects provenance copy, not entitlements.
  final bool isAiProTrial;
  final bool isFirstScout;
  final int exportsUsedThisSession;

  double get _topScore => frames.isEmpty ? 0.0 : frames.first.score;

  // Count only frames that Gemini scored — source is always llm for these.
  int get _aiScoredCount =>
      frames.where((f) => f.metadata.source == ScoreSource.llm).length;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Narrow or short phones: drop secondary stats + shrink/hide histogram.
    final compactWidth = size.width < 360;
    final shortPhone = size.height < 720;
    final dense = compactWidth || shortPhone;

    final aiCount = _aiScoredCount;
    final total = frames.length;
    final showProvenance = total > 0 && aiCount < total;
    final keeperLimit = StillScoutAccessPolicy.keeperLimit(
      isPro: isPro,
      isFirstScout: isFirstScout,
    );
    final unlocked = total.clamp(0, keeperLimit);
    final exportsLeft = StillScoutAccessPolicy.exportsRemainingThisScout(
      isPro: isPro,
      exportsUsedThisSession: exportsUsedThisSession,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StillScoutGlassSurface(
          margin: EdgeInsets.fromLTRB(
            StillScoutSpacing.m,
            dense ? StillScoutSpacing.xs : StillScoutSpacing.s,
            StillScoutSpacing.m,
            0,
          ),
          padding: EdgeInsets.all(dense ? StillScoutSpacing.s + 4 : StillScoutSpacing.m),
          borderColor: StillScoutColors.scoutGold.withValues(alpha: 0.25),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _Stat(
                      icon: Icons.auto_awesome,
                      value: _topScore >= 10.0
                          ? '10'
                          : _topScore.toStringAsFixed(1),
                      label: 'Top Score',
                      accent: true,
                      compact: dense,
                    ),
                  ),
                  Expanded(
                    child: _Stat(
                      icon: Icons.grid_view_rounded,
                      value: '$total',
                      label: 'Frames',
                      compact: dense,
                    ),
                  ),
                  if (!dense && videoDurationMs != null)
                    Expanded(
                      child: _Stat(
                        icon: Icons.timer_outlined,
                        value: _formatDuration(videoDurationMs!),
                        label: 'Clip',
                        compact: false,
                      ),
                    ),
                  if (!dense && processingTimeMs != null)
                    Expanded(
                      child: _Stat(
                        icon: Icons.bolt_rounded,
                        value:
                            '${(processingTimeMs! / 1000).toStringAsFixed(1)}s',
                        label: 'Processed',
                        compact: false,
                      ),
                    ),
                ],
              ),
              if (!shortPhone) ...[
                SizedBox(
                  height: dense ? StillScoutSpacing.s : StillScoutSpacing.m,
                ),
                _ScoreHistogram(
                  frames: frames,
                  keeperLimit: keeperLimit,
                  compact: dense,
                ),
              ],
              SizedBox(
                height: dense ? StillScoutSpacing.s : StillScoutSpacing.s + 2,
              ),
              if (dense)
                Text(
                  '$unlocked/$keeperLimit picks · ${isPro ? 'Unlimited saves' : '$exportsLeft/${StillScoutConstants.freeExportsPerScout} saves'}',
                  style: StillScoutTextStyles.caption.copyWith(
                    color: StillScoutColors.chalk.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              else
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: StillScoutSpacing.s,
                  runSpacing: StillScoutSpacing.s,
                  children: [
                    _UsageChip(
                      icon: Icons.lock_open_rounded,
                      label: '$unlocked/$keeperLimit picks unlocked',
                    ),
                    _UsageChip(
                      icon: Icons.auto_fix_high_rounded,
                      label: isPro
                          ? 'Unlimited saves'
                          : '$exportsLeft/${StillScoutConstants.freeExportsPerScout} saves left',
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (showProvenance)
          Padding(
            padding: EdgeInsets.fromLTRB(
              StillScoutSpacing.m,
              dense ? StillScoutSpacing.xs : StillScoutSpacing.s,
              StillScoutSpacing.m,
              0,
            ),
            child: Text(
              !(isPro || isAiProTrial)
                  ? 'On-device Vision · Upgrade for Gemini'
                  : (aiCount == 0
                      ? 'Gemini unavailable — on-device scores. Re-scout online for Gemini.'
                      : '$aiCount/$total Gemini · ${total - aiCount} on-device'),
              style: StillScoutTextStyles.caption.copyWith(
                color: StillScoutColors.silver.withValues(alpha: 0.85),
                fontSize: dense ? 11 : 12,
              ),
              textAlign: TextAlign.center,
              maxLines: dense ? 2 : 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  static String _formatDuration(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    final rem = s % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${rem}s';
  }
}

class _UsageChip extends StatelessWidget {
  const _UsageChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: StillScoutSpacing.s + 2,
        vertical: StillScoutSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: StillScoutColors.voidBlack.withValues(alpha: 0.35),
        borderRadius: StillScoutRadius.badge,
        border: Border.all(
          color: StillScoutColors.accent.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: StillScoutColors.accent),
          const SizedBox(width: StillScoutSpacing.xs + 2),
          Flexible(
            child: Text(
              label,
              style: StillScoutTextStyles.caption,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    this.accent = false,
    this.compact = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = accent ? StillScoutColors.scoutGold : StillScoutColors.chalk;
    return Semantics(
      label: '$label: $value',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: color.withValues(alpha: 0.8)),
          SizedBox(height: compact ? 2 : StillScoutSpacing.xs / 2),
          Text(
            value,
            style: StillScoutTextStyles.subtitle.copyWith(
              color: color,
              fontSize: compact ? 15 : 18,
            ),
          ),
          Text(
            label,
            style: StillScoutTextStyles.caption.copyWith(
              fontSize: compact ? 10 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mini bar chart showing how many frames scored in each tier.
class _ScoreHistogram extends StatelessWidget {
  const _ScoreHistogram({
    required this.frames,
    required this.keeperLimit,
    this.compact = false,
  });

  final List<ScoredFrame> frames;
  final int keeperLimit;
  final bool compact;

  static const _bucketRanges = [
    (min: 0.0, max: 3.0, label: '0–3'),
    (min: 3.0, max: 5.0, label: '3–5'),
    (min: 5.0, max: 7.0, label: '5–7'),
    (min: 7.0, max: 9.0, label: '7–9'),
    (min: 9.0, max: 10.01, label: '9–10'),
  ];

  static const _bucketColors = [
    Color(0xFF9E9E9E),
    Color(0xFFFF8A65),
    Color(0xFFFFD54F),
    Color(0xFF81C784),
    Color(0xFFFFD700),
  ];

  int _bucket(double score) {
    for (var b = 0; b < _bucketRanges.length; b++) {
      final r = _bucketRanges[b];
      if (score >= r.min && score < r.max) return b;
    }
    return _bucketRanges.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    if (frames.isEmpty) return const SizedBox.shrink();

    final counts = List<int>.filled(_bucketRanges.length, 0);
    final unlockedCounts = List<int>.filled(_bucketRanges.length, 0);

    for (final f in frames) {
      counts[_bucket(f.score)]++;
    }

    final sorted = List<ScoredFrame>.of(frames)
      ..sort((a, b) => b.score.compareTo(a.score));
    for (var i = 0; i < math.min(keeperLimit, sorted.length); i++) {
      unlockedCounts[_bucket(sorted[i].score)]++;
    }

    final maxCount = counts.reduce(math.max).clamp(1, 999);
    final maxBarH = compact ? 28.0 : 42.0;

    return Semantics(
      label: 'Score distribution histogram',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var b = 0; b < _bucketRanges.length; b++) ...[
            if (b > 0) const SizedBox(width: 4),
            Expanded(
              child: _HistogramBar(
                count: counts[b],
                unlockedCount: unlockedCounts[b],
                maxCount: maxCount,
                color: _bucketColors[b],
                label: _bucketRanges[b].label,
                maxBarH: maxBarH,
                showCountLabel: !compact,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistogramBar extends StatelessWidget {
  const _HistogramBar({
    required this.count,
    required this.unlockedCount,
    required this.maxCount,
    required this.color,
    required this.label,
    required this.maxBarH,
    this.showCountLabel = true,
  });

  final int count;
  final int unlockedCount;
  final int maxCount;
  final Color color;
  final String label;
  final double maxBarH;
  final bool showCountLabel;

  static const double _minBarH = 3;

  @override
  Widget build(BuildContext context) {
    final fraction = count / maxCount;
    final barH =
        (_minBarH + fraction * (maxBarH - _minBarH)).clamp(_minBarH, maxBarH);
    final lockedCount = (count - unlockedCount).clamp(0, count);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showCountLabel)
          Text(
            count > 0 ? '$count' : '',
            style: StillScoutTextStyles.caption.copyWith(
              fontSize: 9,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        if (showCountLabel) const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: barH,
            child: Column(
              children: [
                if (lockedCount > 0)
                  Flexible(
                    flex: lockedCount,
                    child: Container(
                      width: double.infinity,
                      color: color.withValues(alpha: 0.28),
                    ),
                  ),
                if (unlockedCount > 0)
                  Flexible(
                    flex: unlockedCount,
                    child: Container(
                      width: double.infinity,
                      color: color.withValues(alpha: 0.85),
                    ),
                  ),
                if (count == 0)
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      color: color.withValues(alpha: 0.10),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: StillScoutTextStyles.caption.copyWith(fontSize: 8),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
