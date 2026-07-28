import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/stillscout_constants.dart';

// Shared Keychain storage — survives app delete + reinstall on iOS, matching
// the scout/trial trackers so the cloud AI fair-use cap can't be farmed by
// deleting and reinstalling the app.
const _keychain = FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
    synchronizable: false,
  ),
);

/// Device-local guard for the direct-Gemini **debug fallback** path only
/// (used when a client-side Gemini key is present, e.g. `ALLOW_DIRECT_AI_KEYS`
/// debug builds). It never gates the production Supabase `vision-score`
/// proxy — that path's real, server-verified caps (free/trial vs.
/// webhook-verified Pro) live entirely server-side in
/// `supabase/functions/vision-score/lib.ts`. Once this local cap is reached,
/// direct-Gemini callers skip cloud providers and fall back to on-device
/// Apple Vision + heuristic scoring.
///
/// Stored in the iOS Keychain (not SharedPreferences) so the counter is
/// resilient to app delete + reinstall.
class StillScoutCloudQuotaTracker {
  StillScoutCloudQuotaTracker._();

  static const _keychainDayKey = 'stillscout_cloud_quota_day_v2';
  static const _keychainCountKey = 'stillscout_cloud_quota_count_v2';

  static String _todayUtcKey() {
    final now = DateTime.now().toUtc();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  /// Ensures Keychain holds today's counter; migrates legacy prefs once.
  static Future<({String day, int count})> _loadState() async {
    final today = _todayUtcKey();
    try {
      final storedDay = await _keychain.read(key: _keychainDayKey);
      final storedCountRaw = await _keychain.read(key: _keychainCountKey);

      if (storedDay != null) {
        if (storedDay == today) {
          final count = int.tryParse(storedCountRaw ?? '0') ?? 0;
          return (day: today, count: count);
        }
        // New UTC day — reset counter.
        await _keychain.write(key: _keychainDayKey, value: today);
        await _keychain.write(key: _keychainCountKey, value: '0');
        return (day: today, count: 0);
      }

      // Migrate from legacy SharedPreferences on first run after upgrade.
      final prefs = await SharedPreferences.getInstance();
      final legacyDay = prefs.getString(StillScoutConstants.cloudQuotaDateKey);
      final legacyCount =
          prefs.getInt(StillScoutConstants.cloudQuotaCountKey) ?? 0;
      final count = (legacyDay == today) ? legacyCount : 0;
      await _keychain.write(key: _keychainDayKey, value: today);
      await _keychain.write(key: _keychainCountKey, value: '$count');
      await prefs.remove(StillScoutConstants.cloudQuotaDateKey);
      await prefs.remove(StillScoutConstants.cloudQuotaCountKey);
      return (day: today, count: count);
    } catch (_) {
      // Keychain unavailable — fall back to prefs for this session only.
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(StillScoutConstants.cloudQuotaDateKey);
      if (stored != today) {
        await prefs.setString(StillScoutConstants.cloudQuotaDateKey, today);
        await prefs.setInt(StillScoutConstants.cloudQuotaCountKey, 0);
        return (day: today, count: 0);
      }
      return (
        day: today,
        count: prefs.getInt(StillScoutConstants.cloudQuotaCountKey) ?? 0,
      );
    }
  }

  static Future<void> _writeCount(int count) async {
    final today = _todayUtcKey();
    try {
      await _keychain.write(key: _keychainDayKey, value: today);
      await _keychain.write(key: _keychainCountKey, value: '$count');
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StillScoutConstants.cloudQuotaDateKey, today);
      await prefs.setInt(StillScoutConstants.cloudQuotaCountKey, count);
    }
  }

  static Future<int> remainingToday() async {
    final state = await _loadState();
    return (StillScoutConstants.maxCloudFramesPerDeviceDay - state.count)
        .clamp(0, StillScoutConstants.maxCloudFramesPerDeviceDay);
  }

  static Future<bool> hasRemaining() async => (await remainingToday()) > 0;

  /// Records one successful cloud frame score against the daily cap.
  static Future<bool> tryConsumeFrame() async {
    final state = await _loadState();
    if (state.count >= StillScoutConstants.maxCloudFramesPerDeviceDay) {
      return false;
    }
    await _writeCount(state.count + 1);
    return true;
  }

  /// Returns a reserved slot when direct providers all fail after a success-path
  /// reservation — not needed when consuming only on success.
  static Future<void> releaseFrame() async {
    final state = await _loadState();
    if (state.count <= 0) return;
    await _writeCount(state.count - 1);
  }

  static Future<void> resetForDebug() async {
    final today = _todayUtcKey();
    try {
      await _keychain.write(key: _keychainDayKey, value: today);
      await _keychain.write(key: _keychainCountKey, value: '0');
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StillScoutConstants.cloudQuotaDateKey, today);
    await prefs.setInt(StillScoutConstants.cloudQuotaCountKey, 0);
  }
}
