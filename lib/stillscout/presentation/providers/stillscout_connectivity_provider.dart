import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/stillscout_online_status.dart';
import '../../services/stillscout_connectivity.dart';

final stillScoutConnectivityProvider = Provider<StillScoutConnectivity>(
  (ref) => StillScoutConnectivity(),
);

final onlineStatusProvider = StreamProvider<StillScoutOnlineSnapshot>((ref) {
  return ref.watch(stillScoutConnectivityProvider).watchStatus();
});

/// Pessimistic online flag — false while checking or on error.
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(onlineStatusProvider).maybeWhen(
        data: (snapshot) => snapshot.isOnline,
        orElse: () => false,
      );
});
