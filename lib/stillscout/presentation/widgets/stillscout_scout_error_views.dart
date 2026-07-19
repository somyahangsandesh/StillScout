import 'package:flutter/material.dart';

import '../theme/stillscout_theme.dart';
import 'stillscout_status_view.dart';

/// Full-screen error state shown when a scout fails.
///
/// Extracted from `StillScoutScreen` (W3.2) — behavior unchanged.
class StillScoutScoutErrorView extends StatelessWidget {
  const StillScoutScoutErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return StillScoutStatusView(
      icon: Icons.error_outline_rounded,
      iconColor: StillScoutColors.danger,
      title: 'Scout hit a snag',
      body: message,
      primaryLabel: 'Try again',
      primaryIcon: Icons.refresh_rounded,
      onPrimary: onRetry,
    );
  }
}

/// Full-screen cancelled state shown briefly after a scout is cancelled.
///
/// Extracted from `StillScoutScreen` (W3.2) — behavior unchanged.
class StillScoutScoutCancelledView extends StatelessWidget {
  const StillScoutScoutCancelledView({super.key, required this.onStartOver});

  final VoidCallback onStartOver;

  @override
  Widget build(BuildContext context) {
    return StillScoutStatusView(
      icon: Icons.cancel_outlined,
      iconColor: StillScoutColors.silver,
      title: 'Scout cancelled',
      body: 'No frames were saved. Pick a clip whenever you\'re ready.',
      primaryLabel: 'Start over',
      primaryIcon: Icons.movie_filter_outlined,
      onPrimary: onStartOver,
    );
  }
}
