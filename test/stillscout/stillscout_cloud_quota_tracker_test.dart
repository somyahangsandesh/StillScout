import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stillscout/stillscout/domain/stillscout_constants.dart';
import 'package:stillscout/stillscout/services/stillscout_cloud_quota_tracker.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    _setupSecureStorageMock();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StillScoutCloudQuotaTracker.resetForDebug();
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

  test('quota survives simulated app restart (Keychain-backed)', () async {
    // Consume a few frames, then simulate a fresh app process re-reading
    // state — SharedPreferences alone would still work here since we never
    // clear it, but this guards against regressing back to prefs-only
    // storage that a reinstall would wipe.
    await StillScoutCloudQuotaTracker.tryConsumeFrame();
    await StillScoutCloudQuotaTracker.tryConsumeFrame();
    SharedPreferences.setMockInitialValues({}); // prefs wiped, Keychain isn't
    expect(
      await StillScoutCloudQuotaTracker.remainingToday(),
      StillScoutConstants.maxCloudFramesPerDeviceDay - 2,
    );
  });
}

void _setupSecureStorageMock() {
  final store = <String, String>{};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (call) async {
      switch (call.method) {
        case 'write':
          store[call.arguments['key'] as String] =
              call.arguments['value'] as String? ?? '';
          return null;
        case 'read':
          return store[call.arguments['key'] as String];
        case 'delete':
          store.remove(call.arguments['key'] as String);
          return null;
        case 'readAll':
          return Map<String, String>.from(store);
        case 'deleteAll':
          store.clear();
          return null;
        case 'containsKey':
          return store.containsKey(call.arguments['key'] as String);
        default:
          return null;
      }
    },
  );
}
