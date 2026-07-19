import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// Shared Keychain storage — survives app delete + reinstall on iOS.
const _keychain = FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
    synchronizable: false,
  ),
);

/// Persistent anonymous device identifier.
///
/// Generated once on first launch and stored in the iOS Keychain (migrated from
/// legacy SharedPreferences on upgrade). Used by the Supabase Edge Function for
/// per-device daily quota tracking. Does NOT identify the user — it is a random
/// UUID, not tied to any account.
class StillScoutDeviceId {
  StillScoutDeviceId._();

  static const _keychainKey = 'stillscout_device_id_v2';
  static const _legacyPrefsKey = 'stillscout_device_id';
  static const _uuid = Uuid();

  static String? _cached;

  /// Returns the device ID, generating and persisting it on first call.
  static Future<String> get() async {
    if (_cached != null) return _cached!;

    try {
      final stored = await _keychain.read(key: _keychainKey);
      if (stored != null && stored.isNotEmpty) {
        _cached = stored;
        return stored;
      }

      // Migrate from SharedPreferences on first run after upgrade.
      final prefs = await SharedPreferences.getInstance();
      var id = prefs.getString(_legacyPrefsKey);
      if (id == null || id.isEmpty) {
        id = _uuid.v4();
      }
      await _keychain.write(key: _keychainKey, value: id);
      await prefs.remove(_legacyPrefsKey);
      _cached = id;
      return id;
    } catch (_) {
      // Keychain unavailable — fall back to prefs for this session only.
      final prefs = await SharedPreferences.getInstance();
      var id = prefs.getString(_legacyPrefsKey);
      if (id == null || id.isEmpty) {
        id = _uuid.v4();
        await prefs.setString(_legacyPrefsKey, id);
      }
      _cached = id;
      return id;
    }
  }

  /// Resets cached state — used in tests only.
  @visibleForTesting
  static Future<void> resetForTests() async {
    _cached = null;
    try {
      await _keychain.delete(key: _keychainKey);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyPrefsKey);
  }
}
