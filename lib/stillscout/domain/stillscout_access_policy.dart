import '../data/models/scored_frame.dart';
import 'stillscout_constants.dart';

/// Central gating rules for keeper visibility, timestamps, and exports.
///
/// Rank is the 0-based index in the score-sorted frame list (0 = best).
class StillScoutAccessPolicy {
  StillScoutAccessPolicy._();

  static int keeperLimit({required bool isPro}) =>
      isPro ? StillScoutConstants.proKeeperLimit : StillScoutConstants.freeKeeperLimit;

  static bool showTimestamp({required bool isPro}) => isPro;

  static bool canViewFrame({required int rank, required bool isPro}) =>
      rank >= 0 && rank < keeperLimit(isPro: isPro);

  static bool canExportFrame({required int rank, required bool isPro}) =>
      canViewFrame(rank: rank, isPro: isPro);

  static bool isLocked({required int rank, required bool isPro}) =>
      !canViewFrame(rank: rank, isPro: isPro);

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
    required int score,
  }) {
    if (showTimestamp(isPro: isPro)) {
      return 'Frame rank ${rank + 1}, score $score';
    }
    return '${rankLabel(rank)}, score $score';
  }

  static int lockedCount({required int totalFrames, required bool isPro}) {
    final limit = keeperLimit(isPro: isPro);
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
    if (isPro) return 'Unlimited polished saves';
    final left = exportsRemainingThisScout(
      isPro: false,
      exportsUsedThisSession: exportsUsedThisSession,
    );
    if (left <= 0) return 'No polished saves left this scout';
    return '$left polished save${left == 1 ? '' : 's'} left this scout';
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

  static String scoutsAllowanceLabel({
    required bool isPro,
    required int scoutsRemainingThisWeek,
    bool isLoading = false,
  }) {
    if (isPro) return 'Unlimited scouts';
    if (isLoading) return 'Checking weekly allowance…';
    if (scoutsRemainingThisWeek <= 0) return 'No scouts left this week';
    return '$scoutsRemainingThisWeek free scout${scoutsRemainingThisWeek == 1 ? '' : 's'} left this week';
  }

  /// Ranks the user may browse in detail (gallery + swipe carousel).
  static List<int> browsableRanks({
    required int totalFrames,
    required bool isPro,
  }) {
    return [
      for (var rank = 0; rank < totalFrames; rank++)
        if (canViewFrame(rank: rank, isPro: isPro)) rank,
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
