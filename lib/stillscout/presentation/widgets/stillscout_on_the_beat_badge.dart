import 'package:flutter/material.dart';

import '../theme/stillscout_theme.dart';

/// Small badge for frames whose timestamp aligns with an audio energy peak.
class StillScoutOnTheBeatBadge extends StatelessWidget {
  const StillScoutOnTheBeatBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: StillScoutColors.accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(StillScoutRadius.pill),
        border: Border.all(
          color: StillScoutColors.accent.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.graphic_eq_rounded,
            size: compact ? 10 : 12,
            color: StillScoutColors.accent,
          ),
          const SizedBox(width: 4),
          Text(
            compact ? 'BEAT' : 'On the beat',
            style: StillScoutTextStyles.badge.copyWith(
              color: StillScoutColors.accent,
              fontSize: compact ? 9 : 10,
            ),
          ),
        ],
      ),
    );
  }
}
