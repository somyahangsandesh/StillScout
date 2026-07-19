import '../../services/stillscout_scout_quota_tracker.dart';

/// Encapsulates the trial/daily/first-scout bookkeeping that runs after a
/// scout completes. Extracted from [StillScoutNotifier] (W3.1) so the
/// notifier can stay focused on orchestration — behavior is unchanged.
class StillScoutQuotaCoordinator {
  const StillScoutQuotaCoordinator();

  /// Records the outcome of a just-completed scout against the free daily
  /// quota, the one-time AI Pro trial, and the first-scout bonus tracker.
  ///
  /// Callers are expected to only invoke this when the scout actually
  /// produced frames for a non-Pro user — see [StillScoutNotifier.processVideo].
  ///
  /// A scout is **credit-worthy** unless the user was on the one-time AI trial
  /// and Gemini never reached — they didn't get the trial experience, so they
  /// keep their free scout credit, trial token, and first-scout keeper bonus.
  ///
  /// - Skips [StillScoutScoutQuotaTracker.recordCompletedScout] when not
  ///   credit-worthy.
  /// - Consumes the AI Pro trial only when it was active AND Gemini actually
  ///   scored frames.
  /// - Marks the first-scout tracker done only for credit-worthy free scouts
  ///   (same fairness rule as the daily quota).
  Future<void> recordScoutCompletion({
    required bool isPro,
    required bool trialActive,
    required bool geminiReached,
    required bool isFirstScout,
  }) async {
    final creditWorthy = !(trialActive && !geminiReached);
    if (creditWorthy) {
      await StillScoutScoutQuotaTracker.recordCompletedScout(isPro: isPro);
    }
    if (trialActive && geminiReached) {
      await StillScoutAiProTrialTracker.consumeTrial();
    }
    if (!isPro && isFirstScout && creditWorthy) {
      await StillScoutFirstScoutTracker.markFirstScoutDone();
    }
  }
}
