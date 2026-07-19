// ============================================================================
// app.dart — Root MaterialApp for the standalone StillScout app
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'stillscout/presentation/screens/stillscout_splash_screen.dart';
import 'stillscout/presentation/theme/stillscout_theme.dart';

class StillScoutApp extends ConsumerWidget {
  const StillScoutApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'StillScout',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          surface: StillScoutColors.filmGray,
          primary: StillScoutColors.accent,
        ),
        scaffoldBackgroundColor: StillScoutColors.voidBlack,
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const StillScoutSplashScreen(),
    );
  }
}
