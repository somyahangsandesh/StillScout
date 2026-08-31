import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';

Future<void> _preloadFonts() async {
  final fonts = [
    GoogleFonts.instrumentSerif(),
    GoogleFonts.dmSans(),
    GoogleFonts.barlowCondensed(),
  ];
  try {
    await GoogleFonts.pendingFonts(fonts).timeout(const Duration(seconds: 4));
  } catch (_) {
    // Never block app launch on font CDN — fall back to system fonts.
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await _preloadFonts();
  } else {
    unawaited(_preloadFonts());
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: CrickRiseApp(),
    ),
  );
}
