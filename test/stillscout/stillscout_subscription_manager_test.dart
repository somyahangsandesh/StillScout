import 'package:flutter_test/flutter_test.dart';
import 'package:stillscout/stillscout/domain/stillscout_constants.dart';
import 'package:stillscout/stillscout/services/stillscout_subscription_manager.dart';

void main() {
  group('StillScoutSubscriptionManager', () {
    test('tierLabel reflects per-scout export usage for free users', () async {
      final label = await StillScoutSubscriptionManager.tierLabel(
        isPro: false,
        exportsUsedThisSession: 1,
        scoutsRemainingThisWeek: 2,
      );
      expect(label, contains('Free'));
      expect(label, contains('2 scouts left'));
      expect(label, contains('${StillScoutConstants.freeExportsPerScout - 1}'));
      expect(label, contains('this run'));
    });

    test('tierLabel shows Pro unlimited messaging', () async {
      final label = await StillScoutSubscriptionManager.tierLabel(
        isPro: true,
        exportsUsedThisSession: 0,
      );
      expect(label, contains('Pro'));
      expect(label, contains('Unlimited scouts'));
    });
  });
}
