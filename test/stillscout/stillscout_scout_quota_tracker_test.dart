import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stillscout/stillscout/domain/stillscout_constants.dart';
import 'package:stillscout/stillscout/services/stillscout_scout_quota_tracker.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    _setupSecureStorageMock();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StillScoutScoutQuotaTracker.resetForTests();
  });

  test('free user starts with full daily allowance', () async {
    expect(
      await StillScoutScoutQuotaTracker.remainingToday(isPro: false),
      StillScoutConstants.freeScoutsPerDay,
    );
  });

  test('pro users have unlimited scouts', () async {
    expect(
      await StillScoutScoutQuotaTracker.remainingToday(isPro: true),
      StillScoutConstants.unlimitedScoutsSentinel,
    );
    expect(await StillScoutScoutQuotaTracker.canStartScout(isPro: true), isTrue);
  });

  test('completed scout decrements daily allowance', () async {
    await StillScoutScoutQuotaTracker.recordCompletedScout(isPro: false);
    expect(
      await StillScoutScoutQuotaTracker.remainingToday(isPro: false),
      StillScoutConstants.freeScoutsPerDay - 1,
    );
  });

  test('cannot start when daily allowance exhausted', () async {
    for (var i = 0; i < StillScoutConstants.freeScoutsPerDay; i++) {
      await StillScoutScoutQuotaTracker.recordCompletedScout(isPro: false);
    }
    expect(await StillScoutScoutQuotaTracker.canStartScout(isPro: false), isFalse);
    expect(await StillScoutScoutQuotaTracker.remainingToday(isPro: false), 0);
  });

  test('AI Pro trial is available once then permanently consumed', () async {
    await StillScoutAiProTrialTracker.resetForTests();
    expect(StillScoutAiProTrialTracker.isTrialAvailable, isTrue);
    await StillScoutAiProTrialTracker.consumeTrial();
    expect(StillScoutAiProTrialTracker.isTrialAvailable, isFalse);
    await StillScoutAiProTrialTracker.consumeTrial(); // idempotent
    expect(StillScoutAiProTrialTracker.isTrialAvailable, isFalse);
  });

  test('trial is unavailable until load completes (cold start)', () async {
    await StillScoutAiProTrialTracker.resetForTests();
    StillScoutAiProTrialTracker.markUnloadedForTests();
    expect(
      StillScoutAiProTrialTracker.isTrialAvailable,
      isFalse,
      reason: 'unloaded tracker must not optimistically grant a trial',
    );

    await StillScoutAiProTrialTracker.load();
    expect(StillScoutAiProTrialTracker.isTrialAvailable, isTrue);
  });

  test('load restores consumed trial from Keychain after unload', () async {
    await StillScoutAiProTrialTracker.resetForTests();
    await StillScoutAiProTrialTracker.consumeTrial();
    StillScoutAiProTrialTracker.markUnloadedForTests();
    expect(StillScoutAiProTrialTracker.isTrialAvailable, isFalse);

    await StillScoutAiProTrialTracker.load();
    expect(
      StillScoutAiProTrialTracker.isTrialAvailable,
      isFalse,
      reason: 'Keychain-consumed trial must stay consumed after reload',
    );
  });

  test('first-scout tracker flips only after markFirstScoutDone', () async {
    await StillScoutFirstScoutTracker.resetForTests();
    expect(StillScoutFirstScoutTracker.isFirstScout, isTrue);
    await StillScoutFirstScoutTracker.markFirstScoutDone();
    expect(StillScoutFirstScoutTracker.isFirstScout, isFalse);
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
