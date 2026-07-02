import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stillscout/stillscout/domain/stillscout_online_status.dart';
import 'package:stillscout/stillscout/services/stillscout_connectivity.dart';

void main() {
  group('StillScoutConnectivity', () {
    test('isOnline is false when radio reports none', () async {
      final service = StillScoutConnectivity(
        connectivityChecker: () async => [ConnectivityResult.none],
        reachabilityProbe: () async => true,
      );
      expect(await service.isOnline, isFalse);
    });

    test('isOnline is false when radio is up but reachability fails', () async {
      final service = StillScoutConnectivity(
        connectivityChecker: () async => [ConnectivityResult.wifi],
        reachabilityProbe: () async => false,
      );
      expect(await service.isOnline, isFalse);
    });

    test('isOnline is true when radio is up and reachability succeeds', () async {
      final service = StillScoutConnectivity(
        connectivityChecker: () async => [ConnectivityResult.mobile],
        reachabilityProbe: () async => true,
      );
      expect(await service.isOnline, isTrue);
    });

    test('watchStatus yields checking then resolved snapshot', () async {
      final service = StillScoutConnectivity(
        connectivityChecker: () async => [ConnectivityResult.wifi],
        reachabilityProbe: () async => true,
      );

      final snapshots = await service.watchStatus().take(2).toList();
      expect(snapshots[0].status, OnlineStatus.checking);
      expect(snapshots[1].status, OnlineStatus.online);
    });
  });
}
