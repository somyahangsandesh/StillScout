import 'package:stillscout/config/stillscout_config.dart';
import 'package:stillscout/services/stillscout_purchase_service.dart';

import '../domain/stillscout_constants.dart';
import 'stillscout_scout_quota_tracker.dart';

/// StillScout Pro detection — export limits are per-scout session in the
/// notifier ([StillScoutState.exportsUsedThisSession]), not lifetime prefs.
class StillScoutSubscriptionManager {
  StillScoutSubscriptionManager._();

  static Future<bool> isProUser() async {
    return StillScoutPurchaseService.hasEntitlement(StillScoutConfig.rcEntitlementPro);
  }

  static Future<String> tierLabel({
    required bool isPro,
    required int exportsUsedThisSession,
    int? scoutsRemainingThisWeek,
  }) async {
    if (isPro) return 'Pro — Unlimited scouts · Native 4K';
    final scoutsLeft = scoutsRemainingThisWeek ??
        await StillScoutScoutQuotaTracker.remainingThisWeek(isPro: false);
    final exportRemaining =
        (StillScoutConstants.freeExportsPerScout - exportsUsedThisSession)
            .clamp(0, StillScoutConstants.freeExportsPerScout);
    return 'Free — $scoutsLeft scout${scoutsLeft == 1 ? '' : 's'} left this week · '
        '$exportRemaining export${exportRemaining == 1 ? '' : 's'} this run';
  }
}
