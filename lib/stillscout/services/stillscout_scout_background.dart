import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen awake while scouting so iOS does not throttle the session.
class StillScoutScoutBackground {
  StillScoutScoutBackground._();

  /// Disable platform hooks in unit tests.
  @visibleForTesting
  static bool enabled = true;

  /// No-op on iOS — no foreground service needed (wakelock handles it).
  static void initialize() {}

  static Future<void> begin({required String statusMessage}) async {
    if (!enabled) return;
    await _safeWakelock(enable: true);
  }

  static Future<void> updateStatus(String statusMessage) async {}

  static Future<void> end() async {
    if (!enabled) return;
    await _safeWakelock(enable: false);
  }

  static Future<void> _safeWakelock({required bool enable}) async {
    if (kIsWeb) return;
    try {
      await (enable ? WakelockPlus.enable() : WakelockPlus.disable())
          .timeout(const Duration(milliseconds: 250));
    } catch (_) {}
  }
}
