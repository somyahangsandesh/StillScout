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
  /// - Skips [StillScoutScoutQuotaTracker.recordCompletedScout] when the
  ///   trial was active but Gemini never reached — the user didn't get the
  ///   trial experience, so they shouldn't lose a free scout credit.
  /// - Consumes the AI Pro trial only when it was active AND Gemini actually
  ///   scored frames.
  /// - Marks the first-scout tracker done whenever this was the first scout,
  ///   independent of trial/Gemini state.
  Future<void> recordScoutCompletion({
    required bool isPro,
    required bool trialActive,
    required bool geminiReached,
    required bool isFirstScout,
  }) async {
    if (!(trialActive && !geminiReached)) {
      await StillScoutScoutQuotaTracker.recordCompletedScout(isPro: isPro);
    }
    if (trialActive && geminiReached) {
      await StillScoutAiProTrialTracker.consumeTrial();
    }
    if (isFirstScout) {
      await StillScoutFirstScoutTracker.markFirstScoutDone();
    }
  }
}
