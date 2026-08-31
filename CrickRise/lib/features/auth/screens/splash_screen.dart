import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/cr_matchday.dart';

/// Animated splash: bouncing ball → batsman hits → ball covers screen → welcome.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _bounce;
  late final AnimationController _hit;
  late final AnimationController _zoom;

  _SplashPhase _phase = _SplashPhase.bouncing;

  @override
  void initState() {
    super.initState();

    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _hit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _zoom = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    setState(() => _phase = _SplashPhase.batting);
    _bounce.stop();

    await _hit.forward();
    if (!mounted) return;
    setState(() => _phase = _SplashPhase.impact);
    await _zoom.forward();
    if (!mounted) return;
    context.go('/welcome');
  }

  @override
  void dispose() {
    _bounce.dispose();
    _hit.dispose();
    _zoom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: CR.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, 0.2),
                radius: 1.2,
                colors: [CR.moss, CR.bg, CR.voidBlack],
              ),
            ),
          ),
          CustomPaint(painter: _PitchPainter()),
          if (_phase != _SplashPhase.impact)
            AnimatedBuilder(
              animation: Listenable.merge([_bounce, _hit]),
              builder: (_, __) {
                final ballPos = _ballOffset(size);
                final batsmanOpacity = _phase == _SplashPhase.batting
                    ? Curves.easeOut.transform(_hit.value)
                    : 0.0;
                final swing = _phase == _SplashPhase.batting
                    ? Curves.easeInOut.transform(_hit.value)
                    : 0.0;

                return Stack(
                  children: [
                    if (batsmanOpacity > 0)
                      Positioned(
                        right: size.width * 0.08,
                        bottom: size.height * 0.22,
                        child: Opacity(
                          opacity: batsmanOpacity,
                          child: CustomPaint(
                            size: const Size(90, 120),
                            painter: _BatsmanPainter(swing: swing),
                          ),
                        ),
                      ),
                    Positioned(
                      left: ballPos.dx - 18,
                      top: ballPos.dy - 18,
                      child: const CRCricketBall(size: 36, glow: true),
                    ),
                  ],
                );
              },
            ),
          if (_phase == _SplashPhase.impact)
            AnimatedBuilder(
              animation: _zoom,
              builder: (_, __) {
                final t = Curves.easeIn.transform(_zoom.value);
                final scale = 1 + t * 28;
                return Container(
                  color: CR.bg.withValues(alpha: 1 - t * 0.15),
                  child: Center(
                    child: Transform.scale(
                      scale: scale,
                      child: const CRCricketBall(size: 48, glow: true),
                    ),
                  ),
                );
              },
            ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Text('CRICKRISE', style: CRType.overline(color: CR.brass, size: 11)),
                const SizedBox(height: 8),
                Text(
                  _phase == _SplashPhase.bouncing
                      ? 'Warming up…'
                      : _phase == _SplashPhase.batting
                          ? 'Play!'
                          : '',
                  style: CRType.caption(),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Offset _ballOffset(Size size) {
    if (_phase == _SplashPhase.batting) {
      final t = Curves.easeIn.transform(_hit.value);
      final start = Offset(size.width * 0.42, size.height * 0.55);
      final end = Offset(size.width * 0.78, size.height * 0.38);
      return Offset.lerp(start, end, t)!;
    }

    final t = _bounce.value;
    final x = size.width * (0.25 + 0.12 * math.sin(t * math.pi * 2));
    final bounce = (math.sin(t * math.pi * 2).abs());
    final y = size.height * (0.62 - bounce * 0.18);
    return Offset(x, y);
  }
}

enum _SplashPhase { bouncing, batting, impact }

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strip = Paint()..color = CR.mossLight.withValues(alpha: 0.12);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.58, size.width, size.height * 0.42), strip);

    final crease = Paint()
      ..color = CR.chalk.withValues(alpha: 0.25)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, size.height * 0.58),
      Offset(size.width, size.height * 0.58),
      crease,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BatsmanPainter extends CustomPainter {
  final double swing;

  const _BatsmanPainter({required this.swing});

  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()
      ..color = CR.chalk
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final bat = Paint()
      ..color = CR.brass
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final cx = size.width * 0.45;
    final ground = size.height * 0.92;

    canvas.drawLine(Offset(cx, ground - 70), Offset(cx, ground - 20), body);
    canvas.drawCircle(Offset(cx, ground - 82), 10, body);
    canvas.drawLine(Offset(cx, ground - 55), Offset(cx - 18, ground - 35), body);
    canvas.drawLine(Offset(cx, ground - 55), Offset(cx + 16, ground - 30), body);
    canvas.drawLine(Offset(cx, ground - 25), Offset(cx - 12, ground), body);
    canvas.drawLine(Offset(cx, ground - 25), Offset(cx + 14, ground), body);

    final batAngle = -1.2 + swing * 2.4;
    final batX = cx + 20;
    final batY = ground - 50;
    canvas.save();
    canvas.translate(batX, batY);
    canvas.rotate(batAngle);
    canvas.drawLine(const Offset(0, 0), const Offset(0, -48), bat);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BatsmanPainter oldDelegate) =>
      oldDelegate.swing != swing;
}
