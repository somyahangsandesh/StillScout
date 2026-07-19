import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stillscout/stillscout/presentation/providers/stillscout_quota_coordinator.dart';
import 'package:stillscout/stillscout/services/stillscout_scout_quota_tracker.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    _setupSecureStorageMock();
  });

  const coordinator = StillScoutQuotaCoordinator();

  setUp(() async {
    await StillScoutScoutQuotaTracker.resetForTests();
    await StillScoutAiProTrialTracker.resetForTests();
    await StillScoutFirstScoutTracker.resetForTests();
  });

  test('degraded trial scout does not consume scout credit or trial', () async {
    final usedBefore = await StillScoutScoutQuotaTracker.usedToday();

    await coordinator.recordScoutCompletion(
      isPro: false,
      trialActive: true,
      geminiReached: false,
      isFirstScout: true,
    );

    expect(await StillScoutScoutQuotaTracker.usedToday(), usedBefore);
    expect(StillScoutAiProTrialTracker.isTrialAvailable, isTrue);
    expect(StillScoutFirstScoutTracker.isFirstScout, isFalse);
  });

  test('successful trial scout consumes scout credit and trial', () async {
    await coordinator.recordScoutCompletion(
      isPro: false,
      trialActive: true,
      geminiReached: true,
      isFirstScout: true,
    );

    expect(await StillScoutScoutQuotaTracker.usedToday(), 1);
    expect(StillScoutAiProTrialTracker.isTrialAvailable, isFalse);
    expect(StillScoutFirstScoutTracker.isFirstScout, isFalse);
  });

  test('pro scouts skip quota bookkeeping', () async {
    await coordinator.recordScoutCompletion(
      isPro: true,
      trialActive: false,
      geminiReached: true,
      isFirstScout: false,
    );

    expect(await StillScoutScoutQuotaTracker.usedToday(), 0);
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
