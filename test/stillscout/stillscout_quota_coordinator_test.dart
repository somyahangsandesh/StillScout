import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stillscout/stillscout/presentation/providers/stillscout_quota_coordinator.dart';
import 'package:stillscout/stillscout/services/stillscout_scout_quota_tracker.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    _setupSecureStorageMock();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StillScoutScoutQuotaTracker.resetForTests();
    await StillScoutAiProTrialTracker.resetForTests();
    await StillScoutFirstScoutTracker.resetForTests();
  });

  const coordinator = StillScoutQuotaCoordinator();

  test('successful Vision scout burns daily credit and first-scout bonus',
      () async {
    await coordinator.recordScoutCompletion(
      isPro: false,
      trialActive: false,
      geminiReached: false,
      isFirstScout: true,
    );

    expect(await StillScoutScoutQuotaTracker.usedToday(), 1);
    expect(StillScoutFirstScoutTracker.isFirstScout, isFalse);
    expect(StillScoutAiProTrialTracker.isTrialAvailable, isTrue);
  });

  test('successful AI trial consumes trial and burns daily credit', () async {
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

  test(
    'degraded AI trial does not burn daily credit, trial, or first-scout bonus',
    () async {
      await coordinator.recordScoutCompletion(
        isPro: false,
        trialActive: true,
        geminiReached: false,
        isFirstScout: true,
      );

      expect(
        await StillScoutScoutQuotaTracker.usedToday(),
        0,
        reason: 'failed trial must not burn a free scout credit',
      );
      expect(
        StillScoutAiProTrialTracker.isTrialAvailable,
        isTrue,
        reason: 'user never experienced Gemini — trial remains',
      );
      expect(
        StillScoutFirstScoutTracker.isFirstScout,
        isTrue,
        reason: 'failed trial must not consume the first-scout keeper bonus',
      );
    },
  );

  test('Pro completion does not touch free-tier trackers', () async {
    await coordinator.recordScoutCompletion(
      isPro: true,
      trialActive: false,
      geminiReached: true,
      isFirstScout: true,
    );

    expect(await StillScoutScoutQuotaTracker.usedToday(), 0);
    expect(StillScoutAiProTrialTracker.isTrialAvailable, isTrue);
    expect(StillScoutFirstScoutTracker.isFirstScout, isTrue);
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
