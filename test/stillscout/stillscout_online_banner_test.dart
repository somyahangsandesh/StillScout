import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stillscout/stillscout/domain/stillscout_online_status.dart';
import 'package:stillscout/stillscout/presentation/widgets/stillscout_online_banner.dart';

void main() {
  testWidgets('online banner hidden when online', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StillScoutOnlineBanner(status: OnlineStatus.online),
        ),
      ),
    );
    expect(find.textContaining('internet'), findsNothing);
  });

  testWidgets('offline banner shows disconnect message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StillScoutOnlineBanner(status: OnlineStatus.offline),
        ),
      ),
    );
    expect(find.textContaining('No internet'), findsOneWidget);
  });

  testWidgets('checking chip shows spinner label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StillScoutOnlineRequirementChip(status: OnlineStatus.checking),
        ),
      ),
    );
    expect(find.text('Checking connection…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
