import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stillscout/stillscout/domain/stillscout_constants.dart';
import 'package:stillscout/stillscout/services/stillscout_scout_quota_tracker.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StillScoutScoutQuotaTracker.resetForTests();
  });

  test('free user starts with full weekly allowance', () async {
    expect(
      await StillScoutScoutQuotaTracker.remainingThisWeek(isPro: false),
      StillScoutConstants.freeScoutsPerWeek,
    );
  });

  test('pro users have unlimited scouts', () async {
    expect(
      await StillScoutScoutQuotaTracker.remainingThisWeek(isPro: true),
      StillScoutConstants.unlimitedScoutsSentinel,
    );
    expect(await StillScoutScoutQuotaTracker.canStartScout(isPro: true), isTrue);
  });

  test('completed scout decrements weekly allowance', () async {
    await StillScoutScoutQuotaTracker.recordCompletedScout(isPro: false);
    expect(
      await StillScoutScoutQuotaTracker.remainingThisWeek(isPro: false),
      StillScoutConstants.freeScoutsPerWeek - 1,
    );
  });

  test('cannot start when weekly allowance exhausted', () async {
    for (var i = 0; i < StillScoutConstants.freeScoutsPerWeek; i++) {
      await StillScoutScoutQuotaTracker.recordCompletedScout(isPro: false);
    }
    expect(await StillScoutScoutQuotaTracker.canStartScout(isPro: false), isFalse);
    expect(await StillScoutScoutQuotaTracker.remainingThisWeek(isPro: false), 0);
  });
}
