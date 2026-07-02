import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stillscout/stillscout/domain/stillscout_constants.dart';
import 'package:stillscout/stillscout/services/stillscout_cloud_quota_tracker.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('fresh device has full daily cloud quota', () async {
    expect(
      await StillScoutCloudQuotaTracker.remainingToday(),
      StillScoutConstants.maxCloudFramesPerDeviceDay,
    );
  });

  test('tryConsumeFrame decrements remaining', () async {
    expect(await StillScoutCloudQuotaTracker.tryConsumeFrame(), isTrue);
    expect(
      await StillScoutCloudQuotaTracker.remainingToday(),
      StillScoutConstants.maxCloudFramesPerDeviceDay - 1,
    );
  });

  test('cannot consume beyond daily cap', () async {
    for (var i = 0; i < StillScoutConstants.maxCloudFramesPerDeviceDay; i++) {
      expect(await StillScoutCloudQuotaTracker.tryConsumeFrame(), isTrue);
    }
    expect(await StillScoutCloudQuotaTracker.tryConsumeFrame(), isFalse);
    expect(await StillScoutCloudQuotaTracker.remainingToday(), 0);
  });

  test('releaseFrame returns a consumed slot', () async {
    await StillScoutCloudQuotaTracker.tryConsumeFrame();
    await StillScoutCloudQuotaTracker.releaseFrame();
    expect(
      await StillScoutCloudQuotaTracker.remainingToday(),
      StillScoutConstants.maxCloudFramesPerDeviceDay,
    );
  });
}
