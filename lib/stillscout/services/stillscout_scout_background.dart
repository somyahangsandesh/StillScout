import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps scouting alive while the user switches apps (Android) or locks the screen.
class StillScoutScoutBackground {
  StillScoutScoutBackground._();

  static bool _initialized = false;

  /// Disable platform hooks in unit tests.
  @visibleForTesting
  static bool enabled = true;

  /// Call once during app bootstrap (Android foreground-task channel setup).
  static void initialize() {
    if (_initialized || !Platform.isAndroid) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'stillscout_scout',
        channelName: 'StillScout scouting',
        channelDescription:
            'Shown while StillScout extracts and scores your video.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    _initialized = true;
  }

  static Future<void> begin({required String statusMessage}) async {
    if (!enabled) return;
    if (Platform.isAndroid && _initialized) {
      try {
        await _ensureNotificationPermission();
        if (await FlutterForegroundTask.isRunningService) {
          await FlutterForegroundTask.updateService(
            notificationTitle: 'StillScout is scouting',
            notificationText: statusMessage,
          );
        } else {
          await FlutterForegroundTask.startService(
            serviceId: 256,
            serviceTypes: const [ForegroundServiceTypes.dataSync],
            notificationTitle: 'StillScout is scouting',
            notificationText: statusMessage,
          );
        }
      } catch (_) {
        // Foreground service unavailable (tests, permission denied, etc.).
      }
    }
    await _safeWakelock(enable: true);
  }

  static Future<void> updateStatus(String statusMessage) async {
    if (!enabled) return;
    if (!Platform.isAndroid || !_initialized) return;
    try {
      if (!await FlutterForegroundTask.isRunningService) return;
      await FlutterForegroundTask.updateService(
        notificationText: statusMessage,
      );
    } catch (_) {}
  }

  static Future<void> end() async {
    if (!enabled) return;
    await _safeWakelock(enable: false);
    if (!Platform.isAndroid || !_initialized) return;
    try {
      if (!await FlutterForegroundTask.isRunningService) return;
      await FlutterForegroundTask.stopService();
    } catch (_) {}
  }

  static Future<void> _safeWakelock({required bool enable}) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    try {
      await (enable ? WakelockPlus.enable() : WakelockPlus.disable())
          .timeout(const Duration(milliseconds: 250));
    } catch (_) {
      // No-op in unit tests or when the platform channel is unavailable.
    }
  }

  static Future<void> _ensureNotificationPermission() async {
    final permission = await FlutterForegroundTask.checkNotificationPermission();
    if (permission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }
}
