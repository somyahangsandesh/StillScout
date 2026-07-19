import 'package:flutter/material.dart';

import 'package:stillscout/config/stillscout_config.dart';

import '../../domain/stillscout_constants.dart';
import '../theme/stillscout_theme.dart';
import 'stillscout_buttons.dart';
import 'stillscout_glass_surface.dart';

/// Compact badge for AI Pro entitlement.
class StillScoutAiProBadge extends StatelessWidget {
  const StillScoutAiProBadge({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            StillScoutColors.scoutGold.withValues(alpha: 0.95),
            StillScoutColors.accent.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: compact ? 11 : 13,
            color: StillScoutColors.voidBlack,
          ),
          SizedBox(width: compact ? 3 : 4),
          Text(
            StillScoutConfig.aiProDisplayName,
            style: StillScoutTextStyles.badge.copyWith(
              color: StillScoutColors.voidBlack,
              fontSize: compact ? 9 : 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Post-free-scout / post-trial upgrade surface.
class StillScoutAiProUpgradeCard extends StatelessWidget {
  const StillScoutAiProUpgradeCard({
    super.key,
    required this.onUpgrade,
    this.afterTrial = false,
  });

  final VoidCallback onUpgrade;

  /// When true, copy assumes the user just experienced a successful Gemini trial.
  final bool afterTrial;

  @override
  Widget build(BuildContext context) {
    return StillScoutGlassSurface(
      margin: const EdgeInsets.fromLTRB(
        StillScoutSpacing.m,
        StillScoutSpacing.s,
        StillScoutSpacing.m,
        StillScoutSpacing.s,
      ),
      padding: const EdgeInsets.all(StillScoutSpacing.m),
      borderColor: StillScoutColors.scoutGold.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const StillScoutAiProBadge(),
              const Spacer(),
              Icon(
                Icons.bolt_rounded,
                color: StillScoutColors.scoutGold.withValues(alpha: 0.9),
              ),
            ],
          ),
          const SizedBox(height: StillScoutSpacing.s),
          Text(
            afterTrial
                ? 'You just used ${StillScoutConfig.geminiModelDisplayName} — like that quality?'
                : 'AI finds your best moment and turns it into a professional photo.',
            style: StillScoutTextStyles.subtitle.copyWith(
              color: StillScoutColors.chalk,
              height: 1.25,
            ),
          ),
          const SizedBox(height: StillScoutSpacing.xs),
          Text(
            afterTrial
                ? 'Keep ${StillScoutConfig.geminiModelDisplayName} judgment on every scout, unlock all ${StillScoutConstants.proKeeperLimit} keepers, '
                    'AI Auto Polish, and unlimited scouts with '
                    '${StillScoutConfig.aiProDisplayName}.'
                : 'Upgrade for ${StillScoutConfig.geminiModelDisplayName} judgment, photo quality scores with '
                    'reasons, and AI Auto Polish with before/after.',
            style: StillScoutTextStyles.caption.copyWith(
              color: StillScoutColors.silver,
            ),
          ),
          const SizedBox(height: StillScoutSpacing.m),
          SizedBox(
            width: double.infinity,
            child: StillScoutPrimaryButton(
              label: afterTrial
                  ? 'Keep ${StillScoutConfig.aiProDisplayName}'
                  : 'Unlock ${StillScoutConfig.aiProDisplayName}',
              icon: Icons.auto_awesome,
              onPressed: onUpgrade,
            ),
          ),
        ],
      ),
    );
  }
}
