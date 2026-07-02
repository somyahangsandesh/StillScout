import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/stillscout_constants.dart';

/// Weekly scout allowance for free users — Pro is unlimited.
///
/// A "scout" is one full video → AI ranking run. Exports stay clean (no
/// watermark); this is the primary monetization lever alongside keeper limits.
class StillScoutScoutQuotaTracker {
  StillScoutScoutQuotaTracker._();

  static String _weekKeyUtc() {
    final now = DateTime.now().toUtc();
    final monday = DateTime.utc(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - DateTime.monday));
    return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
  }

  static Future<void> _resetIfNewWeek(SharedPreferences prefs) async {
    final week = _weekKeyUtc();
    final stored = prefs.getString(StillScoutConstants.scoutQuotaWeekKey);
    if (stored == week) return;
    await prefs.setString(StillScoutConstants.scoutQuotaWeekKey, week);
    await prefs.setInt(StillScoutConstants.scoutQuotaCountKey, 0);
  }

  static Future<int> usedThisWeek() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewWeek(prefs);
    return prefs.getInt(StillScoutConstants.scoutQuotaCountKey) ?? 0;
  }

  static Future<int> remainingThisWeek({required bool isPro}) async {
    if (isPro) return StillScoutConstants.unlimitedScoutsSentinel;
    final used = await usedThisWeek();
    return (StillScoutConstants.freeScoutsPerWeek - used)
        .clamp(0, StillScoutConstants.freeScoutsPerWeek);
  }

  static Future<bool> canStartScout({required bool isPro}) async {
    if (isPro) return true;
    return (await remainingThisWeek(isPro: false)) > 0;
  }

  /// Call once per successfully completed scout (free tier only).
  static Future<void> recordCompletedScout({required bool isPro}) async {
    if (isPro) return;
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewWeek(prefs);
    final used = prefs.getInt(StillScoutConstants.scoutQuotaCountKey) ?? 0;
    await prefs.setInt(StillScoutConstants.scoutQuotaCountKey, used + 1);
  }

  @visibleForTesting
  static Future<void> resetForTests() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      StillScoutConstants.scoutQuotaWeekKey,
      _weekKeyUtc(),
    );
    await prefs.setInt(StillScoutConstants.scoutQuotaCountKey, 0);
  }
}
