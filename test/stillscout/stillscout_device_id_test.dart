import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stillscout/stillscout/services/stillscout_device_id.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    _setupSecureStorageMock();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StillScoutDeviceId.resetForTests();
  });

  test('generates and persists a UUID on first call', () async {
    final id = await StillScoutDeviceId.get();
    expect(id, matches(RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    )));

    final again = await StillScoutDeviceId.get();
    expect(again, id);
  });

  test('migrates legacy SharedPreferences device id to Keychain', () async {
    const legacyId = '550e8400-e29b-41d4-a716-446655440000';
    await StillScoutDeviceId.resetForTests();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('stillscout_device_id', legacyId);

    final id = await StillScoutDeviceId.get();
    expect(id, legacyId);

    expect(prefs.getString('stillscout_device_id'), isNull);
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
