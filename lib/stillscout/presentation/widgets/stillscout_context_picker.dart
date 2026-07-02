import 'package:flutter/material.dart';

import '../../domain/stillscout_constants.dart';
import '../theme/stillscout_theme.dart';

class StillScoutContextPicker extends StatelessWidget {
  const StillScoutContextPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final StillScoutVideoContext selected;
  final ValueChanged<StillScoutVideoContext> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: StillScoutVideoContext.values.map((ctx) {
          final isSelected = ctx == selected;
          return Padding(
            padding: const EdgeInsets.only(right: StillScoutSpacing.s),
            child: GestureDetector(
              onTap: () => onChanged(ctx),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: StillScoutSpacing.m,
                  vertical: StillScoutSpacing.s,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? StillScoutColors.accent.withValues(alpha: 0.2)
                      : StillScoutColors.slate,
                  borderRadius: BorderRadius.circular(StillScoutRadius.pill),
                  border: Border.all(
                    color: isSelected
                        ? StillScoutColors.accent
                        : StillScoutColors.silver.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      ctx.icon,
                      size: 14,
                      color: isSelected
                          ? StillScoutColors.accent
                          : StillScoutColors.silver,
                    ),
                    const SizedBox(width: StillScoutSpacing.xs),
                    Text(
                      ctx.label,
                      style: StillScoutTextStyles.caption.copyWith(
                        color: isSelected
                            ? StillScoutColors.chalk
                            : StillScoutColors.silver,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
