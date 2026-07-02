// ============================================================================
// app_bootstrap.dart — Pre-runApp initialisation for StillScout
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/stillscout_purchase_service.dart';
import '../stillscout/domain/stillscout_constants.dart';
import '../stillscout/services/stillscout_maintenance.dart';
import '../stillscout/services/stillscout_scout_background.dart';

class AppBootstrap {
  AppBootstrap._();

  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Hive — score cache + session history
    await Hive.initFlutter();
    await Hive.openBox(StillScoutConstants.scoreCacheBoxName);
    await Hive.openBox(StillScoutConstants.sessionCacheBoxName);

    // Trim oversized caches from prior sessions (non-blocking, best-effort).
    await StillScoutMaintenance.runOnStartup();

    // RevenueCat IAP
    await StillScoutPurchaseService.initialize();

    // Android foreground notification while scouting in background.
    StillScoutScoutBackground.initialize();
  }
}
