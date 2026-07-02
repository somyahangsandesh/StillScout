import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../domain/stillscout_online_status.dart';

/// Network + reachability checks for StillScout's online-only AI flows.
///
/// [Connectivity] alone only reports radio state (Wi‑Fi/cellular). We also
/// probe a lightweight HTTP endpoint so captive portals / dead Wi‑Fi don't
/// pass as "online".
class StillScoutConnectivity {
  StillScoutConnectivity({
    Connectivity? connectivity,
    Dio? dio,
    Future<bool> Function()? reachabilityProbe,
    Future<List<ConnectivityResult>> Function()? connectivityChecker,
  })  : _connectivity = connectivity ?? Connectivity(),
        _dio = dio ?? Dio(),
        _reachabilityProbe = reachabilityProbe,
        _connectivityChecker = connectivityChecker;

  final Connectivity _connectivity;
  final Dio _dio;
  final Future<bool> Function()? _reachabilityProbe;
  final Future<List<ConnectivityResult>> Function()? _connectivityChecker;

  static const _reachabilityUrl = 'https://clients3.google.com/generate_204';

  Future<bool> get isOnline async =>
      (await _resolveStatus()) == OnlineStatus.online;

  Stream<StillScoutOnlineSnapshot> watchStatus() async* {
    yield const StillScoutOnlineSnapshot(OnlineStatus.checking);
    yield StillScoutOnlineSnapshot(await _resolveStatus());

    await for (final _ in _connectivity.onConnectivityChanged) {
      yield const StillScoutOnlineSnapshot(OnlineStatus.checking);
      yield StillScoutOnlineSnapshot(await _resolveStatus());
    }
  }

  Future<OnlineStatus> _resolveStatus() async {
    final checker = _connectivityChecker;
    final results = checker != null
        ? await checker()
        : await _connectivity.checkConnectivity();
    if (!_hasNetwork(results)) return OnlineStatus.offline;
    if (await _probeReachability()) return OnlineStatus.online;
    return OnlineStatus.offline;
  }

  bool _hasNetwork(List<ConnectivityResult> results) {
    return !results.contains(ConnectivityResult.none);
  }

  Future<bool> _probeReachability() async {
    final probe = _reachabilityProbe;
    if (probe != null) return probe();
    try {
      final response = await _dio.head(
        _reachabilityUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 4),
          sendTimeout: const Duration(seconds: 4),
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
