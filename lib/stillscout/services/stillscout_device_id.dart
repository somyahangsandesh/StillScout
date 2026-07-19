import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const _keychain = FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
    synchronizable: false,
  ),
);

/// Persistent anonymous device identifier.
class StillScoutDeviceId {
  StillScoutDeviceId._();

  static const _keychainKey = 'stillscout_device_id_v2';
  static const _legacyPrefsKey = 'stillscout_device_id';
  static const _uuid = Uuid();

  static String? _cached;
  static Future<String>? _inflight;

  static Future<String> get() async {
    if (_cached != null) return _cached!;
    return _inflight ??= _loadOrCreate().whenComplete(() {
      _inflight = null;
    });
  }

  static Future<String> _loadOrCreate() async {
    if (_cached != null) return _cached!;

    try {
      final stored = await _keychain.read(key: _keychainKey);
      if (stored != null && stored.isNotEmpty) {
        _cached = stored;
        return stored;
      }

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

  @visibleForTesting
  static Future<void> resetForTests() async {
    _cached = null;
    _inflight = null;
    try {
      await _keychain.delete(key: _keychainKey);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyPrefsKey);
  }
}
