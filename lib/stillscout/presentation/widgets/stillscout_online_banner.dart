import 'package:flutter/material.dart';

import '../../domain/stillscout_online_status.dart';
import '../theme/stillscout_theme.dart';

/// Persistent strip when AI scouting isn't available.
class StillScoutOnlineBanner extends StatelessWidget {
  const StillScoutOnlineBanner({
    super.key,
    required this.status,
  });

  final OnlineStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == OnlineStatus.online) return const SizedBox.shrink();

    final (icon, message, color) = switch (status) {
      OnlineStatus.checking => (
          Icons.sync_rounded,
          'Checking connection for AI scouting…',
          StillScoutColors.silver,
        ),
      OnlineStatus.offline => (
          Icons.wifi_off_rounded,
          'No internet — StillScout needs a connection for AI scouting.',
          StillScoutColors.danger,
        ),
      OnlineStatus.online => (Icons.cloud_done_rounded, '', StillScoutColors.success),
    };

    return Material(
      color: status == OnlineStatus.checking
          ? StillScoutColors.slate
          : const Color(0xFF3D1F1F),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: StillScoutSpacing.m,
          vertical: StillScoutSpacing.s,
        ),
        child: Row(
          children: [
            if (status == OnlineStatus.checking)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: StillScoutColors.accent.withValues(alpha: 0.8),
                ),
              )
            else
              Icon(icon, size: 18, color: color.withValues(alpha: 0.95)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: StillScoutTextStyles.caption.copyWith(
                  color: StillScoutColors.chalk.withValues(alpha: 0.92),
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact chip for empty / pre-flight screens explaining the online requirement.
class StillScoutOnlineRequirementChip extends StatelessWidget {
  const StillScoutOnlineRequirementChip({
    super.key,
    required this.status,
  });

  final OnlineStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (status) {
      OnlineStatus.checking => (
          StillScoutColors.silver,
          Icons.sync_rounded,
          'Checking connection…',
        ),
      OnlineStatus.online => (
          StillScoutColors.success,
          Icons.cloud_done_rounded,
          'Online — AI scouting ready',
        ),
      OnlineStatus.offline => (
          StillScoutColors.danger,
          Icons.wifi_off_rounded,
          'Offline — connect to scout',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: StillScoutSpacing.m,
        vertical: StillScoutSpacing.s,
      ),
      decoration: BoxDecoration(
        color: StillScoutColors.filmGray.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(StillScoutRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == OnlineStatus.checking)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                color: StillScoutColors.accent.withValues(alpha: 0.85),
              ),
            )
          else
            Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: StillScoutTextStyles.caption.copyWith(
              color: StillScoutColors.chalk.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
