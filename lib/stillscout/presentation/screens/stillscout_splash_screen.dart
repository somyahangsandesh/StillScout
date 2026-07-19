import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/stillscout_theme.dart';
import '../widgets/stillscout_logo.dart';
import 'stillscout_onboarding_screen.dart';
import 'stillscout_screen.dart';

/// Branded boot screen — bridges native splash → home with a short cinematic fade.
class StillScoutSplashScreen extends StatefulWidget {
  const StillScoutSplashScreen({super.key});

  @override
  State<StillScoutSplashScreen> createState() => _StillScoutSplashScreenState();
}

class _StillScoutSplashScreenState extends State<StillScoutSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _glow;
  late final Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: StillScoutColors.voidBlack,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _glow = Tween<double>(begin: 0.08, end: 0.42).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _taglineFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );

    unawaited(_boot());
  }

  Future<void> _boot() async {
    await _ctrl.forward();
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;

    final onboardingDone = await stillScoutOnboardingComplete();
    if (!mounted) return;

    if (!onboardingDone) {
      // Capture the NavigatorState *before* pushReplacement so the callback
      // has a live reference even after the splash route is removed from the
      // tree.
      final nav = Navigator.of(context);
      await nav.pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 420),
          pageBuilder: (_, __, ___) => StillScoutOnboardingScreen(
            onFinished: () {
              nav.pushReplacement(
                PageRouteBuilder<void>(
                  transitionDuration: const Duration(milliseconds: 520),
                  pageBuilder: (_, __, ___) => const StillScoutScreen(),
                  transitionsBuilder: (_, animation, __, child) =>
                      FadeTransition(
                    opacity: CurvedAnimation(
                        parent: animation, curve: Curves.easeOut),
                    child: child,
                  ),
                ),
              );
            },
          ),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 520),
        pageBuilder: (_, __, ___) => const StillScoutScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StillScoutColors.voidBlack,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: StillScoutColors.vignette),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Film grain dots
            IgnorePointer(
              child: CustomPaint(painter: _SplashGrainPainter()),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fade.value,
                    child: Transform.scale(
                      scale: _scale.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StillScoutLogo(
                            size: 96,
                            showWordmark: true,
                            glowStrength: _glow.value,
                          ),
                          const SizedBox(height: StillScoutSpacing.l),
                          FadeTransition(
                            opacity: _taglineFade,
                            child: Column(
                              children: [
                                Text(
                                  'STILL. SCOUT. POST.',
                                  style: StillScoutTextStyles.display.copyWith(
                                    fontSize: 20,
                                    letterSpacing: 3.2,
                                    color: StillScoutColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 48,
              child: FadeTransition(
                opacity: _fade,
                child: Column(
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: StillScoutColors.accent.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: StillScoutSpacing.m),
                    Text(
                      'Loading…',
                      style: StillScoutTextStyles.caption.copyWith(
                        color: StillScoutColors.silver.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.018);
    const step = 18.0;
    for (var y = 0.0; y < size.height; y += step) {
      for (var x = 0.0; x < size.width; x += step) {
        if (((x + y) / step).round().isOdd) {
          canvas.drawCircle(Offset(x, y), 0.6, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
