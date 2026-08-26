import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) context.go('/welcome');
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CR.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CRICKRISE',
              style: GoogleFonts.spaceGrotesk(
                color: CR.green,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ).animate().fadeIn(duration: 600.ms),
            const SizedBox(height: 20),
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) {
                return Opacity(
                  opacity: 0.5 + 0.5 * _pulseCtrl.value,
                  child: const Text(
                    '●',
                    style: TextStyle(
                      color: CR.green,
                      fontSize: 18,
                    ),
                  ),
                );
              },
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }
}
