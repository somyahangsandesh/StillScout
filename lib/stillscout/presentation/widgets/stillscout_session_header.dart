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
          margin: const EdgeInsets.fromLTRB(
            StillScoutSpacing.m,
            StillScoutSpacing.s,
            StillScoutSpacing.m,
            0,
          ),
          padding: StillScoutSpacing.cardPadding,
          borderColor: StillScoutColors.scoutGold.withValues(alpha: 0.25),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 340;
                  return Wrap(
                    alignment: WrapAlignment.spaceAround,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing:
                        compact ? StillScoutSpacing.s : StillScoutSpacing.m,
                    runSpacing: StillScoutSpacing.s,
                    children: [
                      _Stat(
                        icon: Icons.auto_awesome,
                        value: _topScore >= 10.0 ? '10' : _topScore.toStringAsFixed(1),
                        label: 'Top Score',
                        accent: true,
                        compact: compact,
                      ),
                      _Stat(
                        icon: Icons.grid_view_rounded,
                        value: '$total',
                        label: 'Frames',
                        compact: compact,
                      ),
                      if (videoDurationMs != null)
                        _Stat(
                          icon: Icons.timer_outlined,
                          value: _formatDuration(videoDurationMs!),
                          label: 'Clip',
                          compact: compact,
                        ),
                      if (processingTimeMs != null)
                        _Stat(
                          icon: Icons.bolt_rounded,
                          value:
                              '${(processingTimeMs! / 1000).toStringAsFixed(1)}s',
                          label: 'Processed',
                          compact: compact,
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: StillScoutSpacing.m),
              _ScoreHistogram(
                frames: frames,
                keeperLimit: keeperLimit,
              ),
              const SizedBox(height: StillScoutSpacing.s),
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
            padding: const EdgeInsets.fromLTRB(
              StillScoutSpacing.m,
              StillScoutSpacing.s,
              StillScoutSpacing.m,
              0,
            ),
            child: Text(
              !(isPro || isAiProTrial)
                  ? 'On-device Apple Vision scores · Unlock AI Pro for Gemini judgment'
                  : (aiCount == 0
                      ? 'Gemini was unavailable — scores are on-device estimates. '
                          'Re-scout when online for Gemini judgments.'
                      : '$aiCount of $total frames Gemini-scored · '
                          '${total - aiCount} on-device estimates'),
              style: StillScoutTextStyles.caption.copyWith(
                color: StillScoutColors.silver.withValues(alpha: 0.85),
              ),
              textAlign: TextAlign.center,
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
          Icon(icon, size: 14, color: color.withValues(alpha: 0.8)),
          const SizedBox(height: StillScoutSpacing.xs / 2),
          Text(
            value,
            style: StillScoutTextStyles.subtitle.copyWith(
              color: color,
              fontSize: compact ? 16 : 18,
            ),
          ),
          Text(label, style: StillScoutTextStyles.caption),
        ],
      ),
    );
  }
}

/// Mini bar chart showing how many frames scored in each tier.
///
/// 5 buckets: 0–3 (dim), 3–5 (warm), 5–7 (yellow), 7–9 (green), 9–10 (gold).
/// Bars beyond [keeperLimit] are rendered at 35% opacity to visualise the
/// locked value without obscuring the unlocked portion.
class _ScoreHistogram extends StatelessWidget {
  const _ScoreHistogram({
    required this.frames,
    required this.keeperLimit,
  });

  final List<ScoredFrame> frames;
  final int keeperLimit;

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

    // Total per bucket.
    for (final f in frames) {
      counts[_bucket(f.score)]++;
    }

    // Unlocked per bucket: the top keeperLimit frames by score.
    final sorted = List<ScoredFrame>.of(frames)
      ..sort((a, b) => b.score.compareTo(a.score));
    for (var i = 0; i < math.min(keeperLimit, sorted.length); i++) {
      unlockedCounts[_bucket(sorted[i].score)]++;
    }

    final maxCount = counts.reduce(math.max).clamp(1, 999);

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
  });

  final int count;
  final int unlockedCount;
  final int maxCount;
  final Color color;
  final String label;

  static const double _maxBarH = 42;
  static const double _minBarH = 3;

  @override
  Widget build(BuildContext context) {
    final fraction = count / maxCount;
    final barH = (_minBarH + fraction * (_maxBarH - _minBarH))
        .clamp(_minBarH, _maxBarH);
    final lockedCount = (count - unlockedCount).clamp(0, count);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count > 0 ? '$count' : '',
          style: StillScoutTextStyles.caption.copyWith(
            fontSize: 9,
            color: color.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 2),
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
