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

    await tester.pump(const Duration(milliseconds: 4500));
  });
}
