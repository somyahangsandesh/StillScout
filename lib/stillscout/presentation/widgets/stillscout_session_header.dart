import 'package:flutter/material.dart';

import '../../data/models/frame_score_metadata.dart';
import '../../data/models/scored_frame.dart';
import '../../domain/stillscout_access_policy.dart';
import '../../domain/stillscout_constants.dart';
import '../theme/stillscout_theme.dart';

class StillScoutSessionHeader extends StatelessWidget {
  const StillScoutSessionHeader({
    super.key,
    required this.frames,
    this.videoDurationMs,
    this.processingTimeMs,
    this.isPro = false,
    this.exportsUsedThisSession = 0,
  });

  final List<ScoredFrame> frames;
  final int? videoDurationMs;
  final int? processingTimeMs;
  final bool isPro;
  final int exportsUsedThisSession;

  int get _topScore => frames.isEmpty ? 0 : frames.first.score;

  int get _aiScoredCount =>
      frames.where((f) => f.metadata.source == ScoreSource.llm).length;

  @override
  Widget build(BuildContext context) {
    final aiCount = _aiScoredCount;
    final total = frames.length;
    final showProvenance = total > 0 && aiCount < total;
    final keeperLimit = StillScoutAccessPolicy.keeperLimit(isPro: isPro);
    final unlocked = total.clamp(0, keeperLimit);
    final exportsLeft = StillScoutAccessPolicy.exportsRemainingThisScout(
      isPro: isPro,
      exportsUsedThisSession: exportsUsedThisSession,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(
            StillScoutSpacing.m,
            StillScoutSpacing.s,
            StillScoutSpacing.m,
            0,
          ),
          padding: StillScoutSpacing.cardPadding,
          decoration: StillScoutDecorations.glassCard(
            borderColor: StillScoutColors.scoutGold.withValues(alpha: 0.25),
          ),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 340;
                  return Wrap(
                    alignment: WrapAlignment.spaceAround,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: compact ? StillScoutSpacing.s : StillScoutSpacing.m,
                    runSpacing: StillScoutSpacing.s,
                    children: [
                      _Stat(
                        icon: Icons.auto_awesome,
                        value: '$_topScore',
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
                        ? 'Unlimited polished saves'
                        : '$exportsLeft/${StillScoutConstants.freeExportsPerScout} polished saves left',
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
              aiCount == 0
                  ? 'Cloud AI was unavailable — scores are on-device estimates. '
                      'Re-scout when online for AI judgments.'
                  : '$aiCount of $total frames AI-scored · '
                      '${total - aiCount} on-device estimates',
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
