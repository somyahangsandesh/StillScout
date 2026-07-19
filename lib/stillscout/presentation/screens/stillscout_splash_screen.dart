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
  late final Animation<double> _markFade;
  late final Animation<double> _markScale;
  late final Animation<double> _glow;
  late final Animation<double> _taglineFade;
  late final Animation<double> _statusFade;

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
      duration: const Duration(milliseconds: 1100),
    );
    _markFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.55, curve: StillScoutMotion.entrance),
    );
    _markScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.65, curve: StillScoutMotion.emphasis),
      ),
    );
    _glow = Tween<double>(begin: 0.12, end: 0.40).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.1, 0.75, curve: StillScoutMotion.toggle),
      ),
    );
    _taglineFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.42, 0.9, curve: StillScoutMotion.entrance),
    );
    _statusFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.7, 1.0, curve: StillScoutMotion.entrance),
    );

    unawaited(_boot());
  }

  Future<void> _boot() async {
    await _ctrl.forward();
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;

    final onboardingDone = await stillScoutOnboardingComplete();
    if (!mounted) return;

    if (!onboardingDone) {
      final nav = Navigator.of(context);
      await nav.pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: StillScoutMotion.slow,
          pageBuilder: (_, __, ___) => StillScoutOnboardingScreen(
            onFinished: () {
              nav.pushReplacement(
                PageRouteBuilder<void>(
                  transitionDuration: StillScoutMotion.slow,
                  pageBuilder: (_, __, ___) => const StillScoutScreen(),
                  transitionsBuilder: (_, animation, __, child) =>
                      FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: StillScoutMotion.entrance,
                    ),
                    child: child,
                  ),
                ),
              );
            },
          ),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: StillScoutMotion.entrance,
            ),
            child: child,
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: StillScoutMotion.slow,
        pageBuilder: (_, __, ___) => const StillScoutScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: StillScoutMotion.entrance,
            ),
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
      body: Semantics(
        label: 'StillScout. Still. Scout. Post. Loading.',
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: StillScoutColors.vignette),
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: CustomPaint(painter: _SplashGrainPainter()),
              ),
              Center(
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _markFade.value,
                      child: Transform.scale(
                        scale: _markScale.value,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _glow,
                        builder: (context, _) {
                          return StillScoutLogo(
                            size: 108,
                            showWordmark: true,
                            glowStrength: _glow.value,
                          );
                        },
                      ),
                      const SizedBox(height: StillScoutSpacing.l),
                      FadeTransition(
                        opacity: _taglineFade,
                        child: Text(
                          'STILL. SCOUT. POST.',
                          style: StillScoutTextStyles.display.copyWith(
                            fontSize: 18,
                            letterSpacing: 4.0,
                            color: StillScoutColors.scoutGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 52,
                child: FadeTransition(
                  opacity: _statusFade,
                  child: ExcludeSemantics(
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color:
                              StillScoutColors.silver.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
