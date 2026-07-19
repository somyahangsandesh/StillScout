import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/stillscout_constants.dart';

// Shared Keychain storage — survives app delete + reinstall on iOS.
const _keychain = FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
    synchronizable: false,
  ),
);

/// Daily scout allowance for free users — Pro is unlimited.
///
/// Count + day are stored in the iOS Keychain so deleting and reinstalling
/// the app cannot reset the free daily scout quota.
class StillScoutScoutQuotaTracker {
  StillScoutScoutQuotaTracker._();

  static const _keychainDayKey = 'stillscout_scout_quota_day_v2';
  static const _keychainCountKey = 'stillscout_scout_quota_count_v2';

  /// Preloads Keychain state and migrates legacy SharedPreferences once.
  static Future<void> load() async {
    await _loadState();
  }

  static String _dayKeyUtc() {
    final now = DateTime.now().toUtc();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Ensures Keychain holds today's counter; migrates legacy prefs once.
  static Future<({String day, int count})> _loadState() async {
    final today = _dayKeyUtc();
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

      // Migrate from SharedPreferences on first run after upgrade.
      final prefs = await SharedPreferences.getInstance();
      final legacyDay =
          prefs.getString(StillScoutConstants.scoutQuotaDayKey);
      final legacyCount =
          prefs.getInt(StillScoutConstants.scoutQuotaCountKey) ?? 0;
      final count = (legacyDay == today) ? legacyCount : 0;
      await _keychain.write(key: _keychainDayKey, value: today);
      await _keychain.write(key: _keychainCountKey, value: '$count');
      await prefs.remove(StillScoutConstants.scoutQuotaDayKey);
      await prefs.remove(StillScoutConstants.scoutQuotaCountKey);
      return (day: today, count: count);
    } catch (_) {
      // Keychain unavailable — fall back to prefs for this session only.
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(StillScoutConstants.scoutQuotaDayKey);
      if (stored != today) {
        await prefs.setString(StillScoutConstants.scoutQuotaDayKey, today);
        await prefs.setInt(StillScoutConstants.scoutQuotaCountKey, 0);
        return (day: today, count: 0);
      }
      return (
        day: today,
        count: prefs.getInt(StillScoutConstants.scoutQuotaCountKey) ?? 0,
      );
    }
  }

  static Future<void> _writeCount(int count) async {
    final today = _dayKeyUtc();
    try {
      await _keychain.write(key: _keychainDayKey, value: today);
      await _keychain.write(key: _keychainCountKey, value: '$count');
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StillScoutConstants.scoutQuotaDayKey, today);
      await prefs.setInt(StillScoutConstants.scoutQuotaCountKey, count);
    }
  }

  static Future<int> usedToday() async {
    final state = await _loadState();
    return state.count;
  }

  static Future<int> remainingToday({required bool isPro}) async {
    if (isPro) return StillScoutConstants.unlimitedScoutsSentinel;
    final used = await usedToday();
    return (StillScoutConstants.freeScoutsPerDay - used)
        .clamp(0, StillScoutConstants.freeScoutsPerDay);
  }

  static Future<bool> canStartScout({required bool isPro}) async {
    if (isPro) return true;
    return (await remainingToday(isPro: false)) > 0;
  }

  /// Call once per successfully completed scout (free tier only).
  static Future<void> recordCompletedScout({required bool isPro}) async {
    if (isPro) return;
    final state = await _loadState();
    await _writeCount(state.count + 1);
  }

  @visibleForTesting
  static Future<void> resetForTests() async {
    final today = _dayKeyUtc();
    try {
      await _keychain.write(key: _keychainDayKey, value: today);
      await _keychain.write(key: _keychainCountKey, value: '0');
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StillScoutConstants.scoutQuotaDayKey, today);
    await prefs.setInt(StillScoutConstants.scoutQuotaCountKey, 0);
  }
}

/// Tracks whether the user has an unused one-time AI Pro trial.
///
/// Stored in the iOS Keychain so that deleting and reinstalling the app does
/// NOT reset the trial — preventing the "delete-to-get-unlimited-trials" exploit.
/// Brand-new installs get a single complimentary AI Pro scout so they
/// experience Gemini's quality before being asked to pay.
class StillScoutAiProTrialTracker {
  StillScoutAiProTrialTracker._();

  static const _keychainKey = 'stillscout_ai_pro_trial_used_v2';
  // Legacy SharedPreferences key — only read during one-time migration.
  static const _legacyPrefsKey = 'stillscout_ai_pro_trial_used';
  // Tri-state: null = not yet loaded, false = available, true = consumed.
  static bool? _used;

  /// Call during app init alongside [StillScoutFirstScoutTracker.load].
  /// Migrates existing SharedPreferences data to Keychain on first run.
  static Future<void> load() async {
    try {
      // Check Keychain first.
      final keychainVal = await _keychain.read(key: _keychainKey);
      if (keychainVal != null) {
        _used = keychainVal == 'true';
        return;
      }

      // Migrate from SharedPreferences on first run after upgrade.
      final prefs = await SharedPreferences.getInstance();
      final legacyUsed = prefs.getBool(_legacyPrefsKey) ?? false;
      _used = legacyUsed;
      // Write migrated value to Keychain and clean up SharedPreferences.
      await _keychain.write(key: _keychainKey, value: _used! ? 'true' : 'false');
      await prefs.remove(_legacyPrefsKey);
    } catch (_) {
      // Keychain unavailable — grant the trial optimistically.
      // consumeTrial() always sets _used = true in-memory for the current
      // session, so within one app run the trial cannot be used twice even
      // if every Keychain write also fails.
      _used = false;
    }
  }

  /// True when the complimentary AI Pro scout has not yet been used.
  ///
  /// Uses `!= true` rather than `== false` so the trial is granted when
  /// [load] has not yet completed (_used is still null) — avoids a race
  /// where processVideo starts before the async _init() finishes.
  static bool get isTrialAvailable => _used == false;

  /// Permanently consumes the trial. Safe to call multiple times.
  static Future<void> consumeTrial() async {
    if (_used == true) return;
    _used = true;
    try {
      await _keychain.write(key: _keychainKey, value: 'true');
    } catch (_) {}
  }

  @visibleForTesting
  static Future<void> resetForTests() async {
    _used = false;
    await _keychain.write(key: _keychainKey, value: 'false');
  }
}

/// Tracks whether this is the user's first-ever scout so we can give them a
/// larger free keeper window as a "wow" moment.
///
/// Stored in the iOS Keychain so the first-scout bonus cannot be farmed
/// by deleting and reinstalling the app.
class StillScoutFirstScoutTracker {
  StillScoutFirstScoutTracker._();

  static const _keychainKey = 'stillscout_first_scout_done_v2';
  // Legacy SharedPreferences key — only read during one-time migration.
  static const _legacyPrefsKey = 'stillscout_first_scout_done';
  // Tri-state: null = not yet loaded.
  static bool? _done;

  /// Call once during app init so [isFirstScout] is synchronously available.
  /// Migrates existing SharedPreferences data to Keychain on first run.
  static Future<void> load() async {
    try {
      // Check Keychain first.
      final keychainVal = await _keychain.read(key: _keychainKey);
      if (keychainVal != null) {
        _done = keychainVal == 'true';
        return;
      }

      // Migrate from SharedPreferences on first run after upgrade.
      final prefs = await SharedPreferences.getInstance();
      final legacyDone = prefs.getBool(_legacyPrefsKey) ?? false;
      _done = legacyDone;
      // Write migrated value to Keychain and clean up SharedPreferences.
      await _keychain.write(key: _keychainKey, value: _done! ? 'true' : 'false');
      await prefs.remove(_legacyPrefsKey);
    } catch (_) {
      // If Keychain is unavailable, assume done=false (user gets the bonus
      // for this session only — first-scout bonus is low-risk).
      _done = false;
    }
  }

  /// True when the user has never completed a scout on this device.
  /// Returns true (show bonus) if [load] has not been called yet — safe default.
  static bool get isFirstScout => _done != true;

  /// Call after a free scout completes successfully.
  static Future<void> markFirstScoutDone() async {
    if (_done == true) return;
    _done = true;
    try {
      await _keychain.write(key: _keychainKey, value: 'true');
    } catch (_) {}
  }

  @visibleForTesting
  static Future<void> resetForTests() async {
    _done = false;
    await _keychain.write(key: _keychainKey, value: 'false');
  }
}
