import 'package:stillscout/config/stillscout_config.dart';
import 'package:stillscout/services/stillscout_purchase_service.dart';

import '../domain/stillscout_constants.dart';
import 'stillscout_scout_quota_tracker.dart';

export 'package:stillscout/services/stillscout_purchase_service.dart'
    show SubscriptionCheckResult, StillScoutIapInitStatus;

/// StillScout Pro detection — export limits are per-scout session in the
/// notifier ([StillScoutState.exportsUsedThisSession]), not lifetime prefs.
class StillScoutSubscriptionManager {
  StillScoutSubscriptionManager._();

  /// Preferred check — [SubscriptionCheckResult.checkFailed] means the store
  /// could not be queried (do not silently treat as Free forever).
  static Future<SubscriptionCheckResult> checkSubscription() =>
      StillScoutPurchaseService.checkProEntitlement();

  static Future<bool> isProUser() async {
    final result = await checkSubscription();
    return result.isPro;
  }

  static Future<String> tierLabel({
    required bool isPro,
    required int exportsUsedThisSession,
    int? scoutsRemainingToday,
  }) async {
    if (isPro) {
      return '${StillScoutConfig.aiProDisplayName} — '
          '${StillScoutConfig.geminiModelDisplayName} · Unlimited · 4K';
    }
    final scoutsLeft = scoutsRemainingToday ??
        await StillScoutScoutQuotaTracker.remainingToday(isPro: false);
    final exportRemaining =
        (StillScoutConstants.freeExportsPerScout - exportsUsedThisSession)
            .clamp(0, StillScoutConstants.freeExportsPerScout);
    return 'Free — on-device ML · $scoutsLeft scout${scoutsLeft == 1 ? '' : 's'} left today · '
        '$exportRemaining save${exportRemaining == 1 ? '' : 's'} this run';
  }
}
