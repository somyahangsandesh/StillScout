import 'package:flutter_test/flutter_test.dart';
import 'package:stillscout/config/stillscout_config.dart';
import 'package:stillscout/stillscout/domain/stillscout_constants.dart';
import 'package:stillscout/stillscout/services/stillscout_subscription_manager.dart';

void main() {
  group('StillScoutSubscriptionManager', () {
    test('tierLabel reflects per-scout export usage for free users', () async {
      final label = await StillScoutSubscriptionManager.tierLabel(
        isPro: false,
        exportsUsedThisSession: 1,
        scoutsRemainingToday: 2,
      );
      expect(label, contains('Free'));
      expect(label, contains('2 scouts left'));
      expect(label, contains('${StillScoutConstants.freeExportsPerScout - 1}'));
      expect(label, contains('this run'));
    });

    test('tierLabel shows Pro unlimited messaging with model display name',
        () async {
      final label = await StillScoutSubscriptionManager.tierLabel(
        isPro: true,
        exportsUsedThisSession: 0,
      );
      expect(label, contains('Pro'));
      expect(label, contains('Unlimited'));
      expect(label, contains(StillScoutConfig.geminiModelDisplayName));
      expect(label, isNot(contains('2.5')));
    });
  });
}
