import 'package:flutter/material.dart';

import '../theme/stillscout_theme.dart';

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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(StillScoutSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: StillScoutColors.danger, size: 48),
            const SizedBox(height: StillScoutSpacing.m),
            Text(message,
                style: StillScoutTextStyles.body, textAlign: TextAlign.center),
            const SizedBox(height: StillScoutSpacing.l),
            Semantics(
              label: 'Try again',
              button: true,
              child: OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: StillScoutColors.chalk,
                  side: const BorderSide(color: StillScoutColors.accent),
                  minimumSize: const Size(0, 48),
                ),
                child: const Text('Try again'),
              ),
            ),
          ],
        ),
      ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(StillScoutSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cancel_outlined,
                color: StillScoutColors.silver, size: 48),
            const SizedBox(height: StillScoutSpacing.m),
            Text('Scout cancelled', style: StillScoutTextStyles.title),
            const SizedBox(height: StillScoutSpacing.s),
            Text(
              'No frames were saved. Pick a clip whenever you\'re ready.',
              style: StillScoutTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: StillScoutSpacing.l),
            Semantics(
              label: 'Start over',
              button: true,
              child: OutlinedButton(
                onPressed: onStartOver,
                style: OutlinedButton.styleFrom(
                  foregroundColor: StillScoutColors.chalk,
                  side: const BorderSide(color: StillScoutColors.accent),
                  minimumSize: const Size(0, 48),
                ),
                child: const Text('Start over'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
