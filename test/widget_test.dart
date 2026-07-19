import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stillscout/app.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _setupSecureStorageMock();
  });

  testWidgets('StillScoutApp smoke test', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: StillScoutApp()));

    // At 500ms the splash animation is mid-run and the STILLSCOUT wordmark is visible.
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('STILLSCOUT'), findsWidgets);

    // Complete the splash animation (1200ms total), the 280ms boot delay,
    // and the route transition (420ms) so no one-shot timers remain pending.
    await tester.pump(const Duration(milliseconds: 800)); // → 1300ms
    await tester.pump(const Duration(milliseconds: 500)); // → 1800ms (past delay)
    await tester.pump(const Duration(milliseconds: 600)); // → 2400ms (route done)
    await tester.pump(const Duration(milliseconds: 600)); // → 3000ms (step anims done)
  });
}
