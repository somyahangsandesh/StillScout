import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Persistent anonymous device identifier.
///
/// Generated once on first launch and stored in SharedPreferences.
/// Used by the Supabase Edge Function for per-device daily quota tracking.
/// Does NOT identify the user — it is a random UUID, not tied to any account.
class StillScoutDeviceId {
  StillScoutDeviceId._();

  static const _kPrefsKey = 'stillscout_device_id';
  static const _uuid = Uuid();

  static String? _cached;

  /// Returns the device ID, generating and persisting it on first call.
  static Future<String> get() async {
    if (_cached != null) return _cached!;

    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_kPrefsKey);
    if (id == null || id.isEmpty) {
      id = _uuid.v4();
      await prefs.setString(_kPrefsKey, id);
    }
    _cached = id;
    return id;
  }

  /// Resets the cached ID — used in tests only.
  static void resetForTests() => _cached = null;
}
