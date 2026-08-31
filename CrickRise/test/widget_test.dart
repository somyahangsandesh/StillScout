import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crickrise/app.dart';

void main() {
  testWidgets('Splash screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: CrickRiseApp()),
    );
    await tester.pump();

    expect(find.text('CRICKRISE'), findsOneWidget);
    expect(find.textContaining('Warming'), findsOneWidget);

    // Drain splash timers so the test exits cleanly.
    await tester.pump(const Duration(seconds: 4));
  });
}
