import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/stillscout_theme.dart';

enum StillScoutGalleryView { ranked, timeline }

/// Toggle between score-ranked and chronological gallery layouts.
class StillScoutViewToggle extends StatelessWidget {
  const StillScoutViewToggle({
    super.key,
    required this.current,
    required this.onChanged,
    this.timelineLocked = false,
  });

  final StillScoutGalleryView current;
  final ValueChanged<StillScoutGalleryView> onChanged;
  final bool timelineLocked;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: current == StillScoutGalleryView.ranked
          ? 'View mode: Ranked. Switch to Timeline.'
          : 'View mode: Timeline. Switch to Ranked.',
      button: true,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        height: StillScoutSpacing.l + StillScoutSpacing.s + 4,
        decoration: BoxDecoration(
          color: StillScoutColors.slate,
          borderRadius: StillScoutRadius.chip,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: _Tab(
                icon: Icons.auto_awesome,
                label: 'Ranked',
                selected: current == StillScoutGalleryView.ranked,
                onTap: () {
                  if (current != StillScoutGalleryView.ranked) {
                    HapticFeedback.selectionClick();
                    onChanged(StillScoutGalleryView.ranked);
                  }
                },
              ),
            ),
            Flexible(
              child: _Tab(
                icon: timelineLocked
                    ? Icons.lock_outline
                    : Icons.view_timeline_outlined,
                label: timelineLocked ? 'Timeline · Pro' : 'Timeline',
                selected: current == StillScoutGalleryView.timeline,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(StillScoutGalleryView.timeline);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: StillScoutSpacing.s + 2,
          vertical: StillScoutSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: selected ? StillScoutColors.accent : Colors.transparent,
          borderRadius: StillScoutRadius.chip,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13,
              color:
                  selected ? StillScoutColors.voidBlack : StillScoutColors.silver,
            ),
            const SizedBox(width: StillScoutSpacing.xs),
            Flexible(
              child: Text(
                label,
                style: StillScoutTextStyles.label.copyWith(
                  color: selected
                      ? StillScoutColors.voidBlack
                      : StillScoutColors.silver,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
