import '../data/models/scored_frame.dart';
import 'stillscout_constants.dart';

/// Central gating rules for keeper visibility, timestamps, and exports.
///
/// Rank is the 0-based index in the score-sorted frame list (0 = best).
class StillScoutAccessPolicy {
  StillScoutAccessPolicy._();

  /// Maximum number of frames a user can view at this tier.
  ///
  /// [isFirstScout] gives new free users a bonus (8 instead of 5) as a
  /// "wow moment" so they feel StillScout's full value before converting.
  static int keeperLimit({required bool isPro, bool isFirstScout = false}) {
    if (isPro) return StillScoutConstants.proKeeperLimit;
    if (isFirstScout) {
      // Cap at proKeeperLimit so we never exceed Pro's visibility on first scout.
      return (StillScoutConstants.freeKeeperLimit +
              StillScoutConstants.firstScoutBonusKeepers)
          .clamp(0, StillScoutConstants.proKeeperLimit);
    }
    return StillScoutConstants.freeKeeperLimit;
  }

  static bool showTimestamp({required bool isPro}) => isPro;

  static bool canViewFrame({
    required int rank,
    required bool isPro,
    bool isFirstScout = false,
  }) =>
      rank >= 0 && rank < keeperLimit(isPro: isPro, isFirstScout: isFirstScout);

  static bool canExportFrame({
    required int rank,
    required bool isPro,
    bool isFirstScout = false,
  }) =>
      canViewFrame(rank: rank, isPro: isPro, isFirstScout: isFirstScout);

  static bool isLocked({
    required int rank,
    required bool isPro,
    bool isFirstScout = false,
  }) =>
      !canViewFrame(rank: rank, isPro: isPro, isFirstScout: isFirstScout);

  static String rankLabel(int rank) => 'Top Pick #${rank + 1}';

  static String frameFooterLabel({
    required int rank,
    required bool isPro,
    required String formattedTimestamp,
  }) {
    if (showTimestamp(isPro: isPro)) return formattedTimestamp;
    return rankLabel(rank);
  }

  static String semanticsLabel({
    required int rank,
    required bool isPro,
    required double score,
  }) {
    final scoreLabel = score >= 10.0 ? '10' : score.toStringAsFixed(1);
    if (showTimestamp(isPro: isPro)) {
      return 'Frame rank ${rank + 1}, score $scoreLabel';
    }
    return '${rankLabel(rank)}, score $scoreLabel';
  }

  static int lockedCount({
    required int totalFrames,
    required bool isPro,
    bool isFirstScout = false,
  }) {
    final limit = keeperLimit(isPro: isPro, isFirstScout: isFirstScout);
    if (totalFrames <= limit) return 0;
    return totalFrames - limit;
  }

  static int exportsRemainingThisScout({
    required bool isPro,
    required int exportsUsedThisSession,
  }) {
    if (isPro) return StillScoutConstants.unlimitedExportsSentinel;
    return (StillScoutConstants.freeExportsPerScout - exportsUsedThisSession)
        .clamp(0, StillScoutConstants.freeExportsPerScout);
  }

  static bool hasUnlimitedExports({required bool isPro}) => isPro;

  /// Clamps export counters for UI — never show the unlimited sentinel (999).
  static int displayExportsRemaining({required int exportsRemaining}) {
    if (exportsRemaining >= StillScoutConstants.unlimitedExportsSentinel) {
      return StillScoutConstants.freeExportsPerScout;
    }
    return exportsRemaining.clamp(0, StillScoutConstants.freeExportsPerScout);
  }

  static String exportsAllowanceLabel({
    required bool isPro,
    required int exportsUsedThisSession,
  }) {
    if (isPro) return 'Unlimited saves';
    final left = exportsRemainingThisScout(
      isPro: false,
      exportsUsedThisSession: exportsUsedThisSession,
    );
    if (left <= 0) return 'No saves left this scout';
    return '$left save${left == 1 ? '' : 's'} left this scout';
  }

  static bool canExportThisSession({
    required bool isPro,
    required int exportsUsedThisSession,
    int count = 1,
  }) {
    if (isPro) return true;
    return exportsRemainingThisScout(
          isPro: isPro,
          exportsUsedThisSession: exportsUsedThisSession,
        ) >=
        count;
  }

  /// Cloud Gemini analysis — paid AI Pro entitlement.
  static bool canUseCloudAi({required bool isPro}) => isPro;

  /// Whether the next scout will call Gemini (Pro, or unused free AI trial).
  /// Used for offline gates and preflight connectivity UI.
  static bool scoutRequiresNetwork({
    required bool isPro,
    bool isAiProTrialAvailable = false,
  }) =>
      isPro || isAiProTrialAvailable;

  /// AI Auto Polish — AI Pro only (not available on the free trial).
  /// Polish runs automatically on all top picks after each Pro scout, and is
  /// available as a per-frame toggle in the detail sheet.
  static bool canUseAiPolish({required bool isPro, bool isAiProTrial = false}) =>
      isPro;

  static String scoutsAllowanceLabel({
    required bool isPro,
    required int scoutsRemainingToday,
    bool isLoading = false,
    bool isAiProTrialAvailable = false,
  }) {
    if (isPro) return 'Unlimited AI Pro scouts';
    if (isLoading) return 'Checking daily allowance…';
    if (isAiProTrialAvailable) {
      return 'Free AI Trial ready · needs internet';
    }
    if (scoutsRemainingToday <= 0) return 'No free scouts left today';
    return '$scoutsRemainingToday free scout${scoutsRemainingToday == 1 ? '' : 's'} left today';
  }

  /// Ranks the user may browse in detail (gallery + swipe carousel).
  static List<int> browsableRanks({
    required int totalFrames,
    required bool isPro,
    bool isFirstScout = false,
  }) {
    return [
      for (var rank = 0; rank < totalFrames; rank++)
        if (canViewFrame(rank: rank, isPro: isPro, isFirstScout: isFirstScout))
          rank,
    ];
  }

  /// Hive snapshot — always stores full frame data; UI gates locked fields.
  static Map<String, dynamic> toPersistedJson({required ScoredFrame frame}) =>
      frame.toJson();

  static bool isPersistedLocked(Map<String, dynamic> json) =>
      json['persistedLocked'] == true;

  /// Rehydrate a history frame — masks scrub fields for locked free tiers.
  static ScoredFrame fromPersistedJson(
    Map<String, dynamic> json, {
    required bool isPro,
    required int rank,
  }) {
    final locked = !isPro && isLocked(rank: rank, isPro: false);
    if (locked) {
      json = Map<String, dynamic>.from(json)
        ..['timestampMs'] = 0
        ..['sourceVideoPath'] = '';
    }
    return ScoredFrame.fromJson(json);
  }
}
