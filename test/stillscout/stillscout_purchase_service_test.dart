import 'package:flutter_test/flutter_test.dart';
import 'package:stillscout/services/stillscout_purchase_service.dart';

void main() {
  group('StillScoutPurchaseService.getAppUserId', () {
    test('returns null when RevenueCat has never been configured', () async {
      // No secrets.local.dart public SDK key in the test environment, so
      // Purchases.configure() is never called — getAppUserId() must return
      // null rather than throwing, so callers fall back to the free/trial
      // cap instead of sending a bogus app_user_id to vision-score.
      final appUserId = await StillScoutPurchaseService.getAppUserId();
      expect(appUserId, isNull);
    });
  });
}
