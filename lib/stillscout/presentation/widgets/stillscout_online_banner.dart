import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';

import '../../domain/stillscout_online_status.dart';
import '../theme/stillscout_theme.dart';

/// Persistent strip when AI Pro / trial scouting needs a network and it’s down.
///
/// Free on-device scouts do not need this banner — pass [needsNetwork] false.
///
/// Wraps in [AnimatedSwitcher] with a vertical slide so it appears/disappears
/// smoothly rather than popping in abruptly.
class StillScoutOnlineBanner extends StatelessWidget {
  const StillScoutOnlineBanner({
    super.key,
    required this.status,
    this.needsNetwork = false,
  });

  final OnlineStatus status;

  /// When false (default), the banner stays hidden — free scouts run offline.
  /// Set true for AI Pro or an active AI Pro trial that requires Gemini.
  final bool needsNetwork;

  @override
  Widget build(BuildContext context) {
    final show = needsNetwork && status != OnlineStatus.online;
    return AnimatedSwitcher(
      duration: StillScoutMotion.base,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return SizeTransition(
          sizeFactor: animation,
          alignment: Alignment.topCenter,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: show
          ? _BannerContent(key: ValueKey(status), status: status)
          : const SizedBox.shrink(key: ValueKey('hidden')),
    );
  }
}

class _BannerContent extends StatelessWidget {
  const _BannerContent({super.key, required this.status});
  final OnlineStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, message, color) = switch (status) {
      OnlineStatus.checking => (
          Icons.sync_rounded,
          'Checking connection for AI Pro scouting…',
          StillScoutColors.silver,
        ),
      OnlineStatus.offline => (
          Icons.wifi_off_rounded,
          'No internet — AI Pro scouting needs a connection.',
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
            if (status == OnlineStatus.offline) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => AppSettings.openAppSettings(),
                style: TextButton.styleFrom(
                  foregroundColor: StillScoutColors.accent,
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: StillScoutSpacing.s,
                  ),
                ),
                child: Text(
                  'Settings',
                  style: StillScoutTextStyles.caption.copyWith(
                    color: StillScoutColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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
          'Offline — AI Pro needs connection',
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
