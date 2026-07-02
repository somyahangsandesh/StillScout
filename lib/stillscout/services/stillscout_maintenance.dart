import 'package:flutter/foundation.dart';

import '../data/repositories/session_repository_impl.dart';
import 'stillscout_score_cache.dart';

/// Best-effort housekeeping on cold start — keeps disk usage bounded.
class StillScoutMaintenance {
  StillScoutMaintenance._();

  static Future<void> runOnStartup() async {
    try {
      await StillScoutScoreCache.evictIfOversized();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Maintenance] score cache eviction skipped: $e');
      }
    }

    try {
      await SessionRepositoryImpl().evictOldSessions();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Maintenance] session/cache eviction skipped: $e');
      }
    }
  }
}
