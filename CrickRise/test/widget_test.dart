import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crickrise/app.dart';

void main() {
  testWidgets('Welcome screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: CrickRiseApp()),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Sunday'), findsWidgets);
  });
}
