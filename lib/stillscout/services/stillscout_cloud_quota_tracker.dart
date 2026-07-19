import 'package:shared_preferences/shared_preferences.dart';

import '../domain/stillscout_constants.dart';

/// Device-local guard for shared cloud AI keys.
///
/// This is not a replacement for a production backend proxy, but it prevents a
/// single install from exhausting the app-wide free-tier pool during shipathon
/// or early beta. Once the daily cap is reached, callers skip cloud providers
/// and fall back to on-device Apple Vision + heuristic scoring.
class StillScoutCloudQuotaTracker {
  StillScoutCloudQuotaTracker._();

  static String _todayUtcKey() {
    final now = DateTime.now().toUtc();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  static Future<int> remainingToday() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay(prefs);
    final used = prefs.getInt(StillScoutConstants.cloudQuotaCountKey) ?? 0;
    return (StillScoutConstants.maxCloudFramesPerDeviceDay - used).clamp(
      0,
      StillScoutConstants.maxCloudFramesPerDeviceDay,
    );
  }

  static Future<bool> hasRemaining() async => (await remainingToday()) > 0;

  /// Records one successful cloud frame score against the daily cap.
  static Future<bool> tryConsumeFrame() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay(prefs);
    final used = prefs.getInt(StillScoutConstants.cloudQuotaCountKey) ?? 0;
    if (used >= StillScoutConstants.maxCloudFramesPerDeviceDay) return false;
    await prefs.setInt(StillScoutConstants.cloudQuotaCountKey, used + 1);
    return true;
  }

  /// Returns a reserved slot when direct providers all fail after a success-path
  /// reservation — not needed when consuming only on success.
  static Future<void> releaseFrame() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay(prefs);
    final used = prefs.getInt(StillScoutConstants.cloudQuotaCountKey) ?? 0;
    if (used <= 0) return;
    await prefs.setInt(StillScoutConstants.cloudQuotaCountKey, used - 1);
  }

  static Future<void> resetForDebug() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      StillScoutConstants.cloudQuotaDateKey,
      _todayUtcKey(),
    );
    await prefs.setInt(StillScoutConstants.cloudQuotaCountKey, 0);
  }

  static Future<void> _resetIfNewDay(SharedPreferences prefs) async {
    final today = _todayUtcKey();
    final stored = prefs.getString(StillScoutConstants.cloudQuotaDateKey);
    if (stored == today) return;
    await prefs.setString(StillScoutConstants.cloudQuotaDateKey, today);
    await prefs.setInt(StillScoutConstants.cloudQuotaCountKey, 0);
  }
}
