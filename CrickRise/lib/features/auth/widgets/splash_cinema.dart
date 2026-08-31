import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/cr_matchday.dart';

/// Cinematic splash: stadium → physics bounce → delivery → bat swing → ball engulfs screen.
class SplashCinema extends StatelessWidget {
  final double progress; // 0.0 – 1.0 master timeline

  const SplashCinema({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pitchY = size.height * 0.72;

    final bounceT = _clampMap(progress, 0.0, 0.38);
    final deliveryT = _clampMap(progress, 0.36, 0.58);
    final swingT = _clampMap(progress, 0.54, 0.72);
    final impactT = _clampMap(progress, 0.70, 0.82);
    final zoomT = _clampMap(progress, 0.78, 1.0);

    final shake = impactT > 0 && impactT < 1
        ? math.sin(impactT * math.pi * 14) * (1 - impactT) * 6
        : 0.0;

    final ballPos = zoomT > 0.05
        ? _impactBallPos(size, zoomT)
        : deliveryT > 0.01
            ? _deliveryBallPos(size, pitchY, deliveryT, swingT)
            : _bounceBallPos(size, pitchY, bounceT);

    final ballScale = zoomT > 0
        ? 1.0 + Curves.easeInExpo.transform(zoomT) * 42
        : _squashScale(bounceT, deliveryT);
    final ballVisible = progress < 0.995;

    final batsmanOpacity = Curves.easeOut.transform(_clampMap(progress, 0.30, 0.48));
    final batSwing = Curves.easeInOutCubic.transform(swingT);
    final flash = impactT > 0 ? math.pow(math.sin(impactT * math.pi), 0.7).toDouble() * 0.92 : 0.0;

    return Transform.translate(
      offset: Offset(shake, shake * 0.4),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _StadiumSky(),
          _Floodlights(pulse: progress),
          CustomPaint(painter: _PitchPainter(pitchY: pitchY)),
          if (batsmanOpacity > 0.01 && zoomT < 0.35)
            Positioned(
              right: size.width * 0.06,
              bottom: pitchY - 8,
              child: Opacity(
                opacity: batsmanOpacity * (1 - zoomT * 2.5).clamp(0.0, 1.0),
                child: _BatsmanSilhouette(swing: batSwing, height: size.height * 0.28),
              ),
            ),
          if (deliveryT > 0.08 && deliveryT < 0.95 && zoomT < 0.1)
            ..._motionTrail(size, pitchY, deliveryT, swingT),
          if (ballVisible) ...[
            Positioned(
              left: ballPos.dx + 4,
              top: pitchY - 6,
              child: Opacity(
                opacity: (1 - zoomT) * (0.35 + _bounceContacts(bounceT) * 0.25),
                child: Transform.scale(
                  scaleX: 0.8 + (1 - _ballHeightNorm(size, pitchY, ballPos)) * 0.5,
                  child: Container(
                    width: 36,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: ballPos.dx,
              top: ballPos.dy,
              child: Transform.scale(
                scale: ballScale,
                child: _CricketBallHero(
                  rotation: zoomT * 3.2 + deliveryT * 2,
                  glow: 0.6 + zoomT * 0.4,
                ),
              ),
            ),
          ],
          if (flash > 0.02)
            Container(color: CR.chalk.withValues(alpha: flash)),
          if (zoomT > 0.55)
            Container(
              color: CR.terracotta.withValues(
                alpha: Curves.easeIn.transform(_clampMap(zoomT, 0.55, 1.0)) * 0.95,
              ),
            ),
          _Vignette(intensity: 0.55 - zoomT * 0.3),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Opacity(
                  opacity: (1 - zoomT * 1.8).clamp(0.0, 1.0),
                  child: Column(
                    children: [
                      Text('CRICKRISE', style: CRType.overline(color: CR.brass, size: 11)),
                      const SizedBox(height: 8),
                      Text(_statusText(progress), style: CRType.caption()),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusText(double t) {
    if (t < 0.38) return 'Warming up…';
    if (t < 0.68) return 'Play!';
    if (t < 0.85) return '';
    return '';
  }

  double _squashScale(double bounceT, double deliveryT) {
    if (deliveryT > 0) return 1.0;
    final contact = _bounceContacts(bounceT);
    return 1.0 + contact * 0.35 - (contact > 0 ? 0.18 : 0);
  }

  List<Widget> _motionTrail(Size size, double pitchY, double deliveryT, double swingT) {
    final widgets = <Widget>[];
    for (var i = 1; i <= 4; i++) {
      final lag = (deliveryT - i * 0.06).clamp(0.0, 1.0);
      if (lag <= 0) continue;
      final pos = _deliveryBallPos(size, pitchY, lag, swingT);
      widgets.add(
        Positioned(
          left: pos.dx,
          top: pos.dy,
          child: Opacity(
            opacity: 0.12 / i,
            child: Transform.scale(
              scale: 0.7,
              child: const _CricketBallHero(rotation: 0, glow: 0.2),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  Offset _bounceBallPos(Size size, double pitchY, double t) {
    if (t <= 0) return Offset(size.width * 0.5 - 20, pitchY - 120);
    final contact = _bounceContacts(t);
    final bounceIndex = (t * 3.2).floor();
    final localT = (t * 3.2) - bounceIndex;
    final damp = math.pow(0.55, bounceIndex).toDouble();
    final height = math.sin(localT * math.pi) * 140 * damp;
    final x = size.width * 0.5 + math.sin(t * math.pi * 2) * 18;
    return Offset(x - 20, pitchY - 24 - height);
  }

  double _bounceContacts(double t) {
    final phase = (t * 3.2) % 1.0;
    return phase < 0.08 ? (1 - phase / 0.08) : 0.0;
  }

  Offset _deliveryBallPos(Size size, double pitchY, double t, double swingT) {
    final eased = Curves.easeInOut.transform(t);
    final start = Offset(size.width * 0.08, pitchY - 100);
    final mid = Offset(size.width * 0.42, pitchY - 60);
    final end = Offset(size.width * 0.72, pitchY - 130);
    if (eased < 0.5) {
      final u = eased * 2;
      return _lerpOffset(_lerpOffset(start, mid, u), mid, u * 0.3);
    }
    final u = (eased - 0.5) * 2;
    final hit = Offset(size.width * 0.76, pitchY - 145 - swingT * 20);
    return _lerpOffset(mid, hit, Curves.easeIn.transform(u));
  }

  Offset _impactBallPos(Size size, double t) {
    final cx = size.width * 0.5 - 22;
    final cy = size.height * 0.48 - 22;
    return Offset(cx, cy - t * 40);
  }

  Offset _lerpOffset(Offset a, Offset b, double t) =>
      Offset(lerpDouble(a.dx, b.dx, t)!, lerpDouble(a.dy, b.dy, t)!);

  double _clampMap(double t, double a, double b) {
    if (t <= a) return 0;
    if (t >= b) return 1;
    return (t - a) / (b - a);
  }

  double _ballHeightNorm(Size size, double pitchY, Offset ballPos) {
    return ((pitchY - 24) - ballPos.dy).clamp(0.0, 160.0) / 160.0;
  }
}

class _StadiumSky extends StatelessWidget {
  const _StadiumSky();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.55),
          radius: 1.35,
          colors: [
            Color(0xFF1F3D2E),
            Color(0xFF0F0B08),
            Color(0xFF050403),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
    );
  }
}

class _Floodlights extends StatelessWidget {
  final double pulse;
  const _Floodlights({required this.pulse});

  @override
  Widget build(BuildContext context) {
    final glow = 0.12 + math.sin(pulse * math.pi * 4) * 0.04;
    return Stack(
      children: [
        Positioned(
          top: -40,
          left: -20,
          child: _lightCone(glow, Alignment.bottomRight),
        ),
        Positioned(
          top: -40,
          right: -20,
          child: _lightCone(glow, Alignment.bottomLeft),
        ),
      ],
    );
  }

  Widget _lightCone(double opacity, Alignment align) {
    return Container(
      width: 200,
      height: 280,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: align,
          radius: 1.0,
          colors: [
            CR.brass.withValues(alpha: opacity),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _PitchPainter extends CustomPainter {
  final double pitchY;
  const _PitchPainter({required this.pitchY});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, pitchY - 20, size.width, size.height - pitchY + 40);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            CR.mossLight.withValues(alpha: 0.22),
            CR.moss.withValues(alpha: 0.35),
          ],
        ).createShader(rect),
    );

    final stripe = Paint()..color = CR.mossLight.withValues(alpha: 0.06);
    for (var x = 0.0; x < size.width; x += 28) {
      canvas.drawRect(Rect.fromLTWH(x, pitchY, 14, size.height - pitchY), stripe);
    }

    final crease = Paint()
      ..color = CR.chalk.withValues(alpha: 0.35)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, pitchY), Offset(size.width, pitchY), crease);

    final popping = Paint()
      ..color = CR.chalk.withValues(alpha: 0.5)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final popX = size.width * 0.78;
    canvas.drawLine(Offset(popX, pitchY - 18), Offset(popX, pitchY + 4), popping);
  }

  @override
  bool shouldRepaint(covariant _PitchPainter old) => old.pitchY != pitchY;
}

class _Vignette extends StatelessWidget {
  final double intensity;
  const _Vignette({required this.intensity});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Colors.transparent,
              CR.voidBlack.withValues(alpha: intensity),
            ],
            radius: 1.1,
          ),
        ),
      ),
    );
  }
}

class _CricketBallHero extends StatelessWidget {
  final double rotation;
  final double glow;

  const _CricketBallHero({required this.rotation, required this.glow});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: CR.terracotta.withValues(alpha: glow * 0.55),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const CustomPaint(painter: _HeroBallPainter()),
      ),
    );
  }
}

class _HeroBallPainter extends CustomPainter {
  const _HeroBallPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: const [Color(0xFFFF6B6B), CR.terracotta, const Color(0xFF7F1D1D)],
          stops: const [0.15, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    final seam = Paint()
      ..color = CR.chalk.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final path = Path();
    for (var i = 0; i <= 360; i += 3) {
      final rad = i * math.pi / 180;
      final wobble = math.sin(rad * 2.2) * r * 0.14;
      final x = c.dx + (r * 0.52 + wobble) * math.cos(rad);
      final y = c.dy + r * 0.52 * math.sin(rad);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, seam);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BatsmanSilhouette extends StatelessWidget {
  final double swing;
  final double height;

  const _BatsmanSilhouette({required this.swing, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: height * 0.55,
      height: height,
      child: CustomPaint(
        painter: _BatsmanPainter(swing: swing),
      ),
    );
  }
}

class _BatsmanPainter extends CustomPainter {
  final double swing;
  const _BatsmanPainter({required this.swing});

  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()..color = CR.chalk.withValues(alpha: 0.92);
    final w = size.width;
    final h = size.height;
    final cx = w * 0.42;

    canvas.drawCircle(Offset(cx, h * 0.12), h * 0.09, body);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, h * 0.38), width: w * 0.34, height: h * 0.34),
        const Radius.circular(6),
      ),
      body,
    );
    canvas.drawRect(
      Rect.fromLTWH(cx - w * 0.28, h * 0.52, w * 0.22, h * 0.38),
      body,
    );
    canvas.drawRect(
      Rect.fromLTWH(cx + w * 0.06, h * 0.52, w * 0.22, h * 0.38),
      body,
    );

    final batAngle = lerpDouble(-2.1, 0.35, swing)!;
    final batPaint = Paint()
      ..shader = LinearGradient(
        colors: [CR.brass, const Color(0xFFE8C9A0)],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(cx + w * 0.18, h * 0.36);
    canvas.rotate(batAngle);
    canvas.drawLine(const Offset(0, 0), Offset(0, -h * 0.52), batPaint);
    canvas.drawCircle(Offset(0, -h * 0.52), 5, Paint()..color = CR.brass);
    canvas.restore();

    if (swing > 0.35) {
      final arc = Paint()
        ..color = CR.brass.withValues(alpha: (swing - 0.35) * 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, h * 0.36), radius: h * 0.38),
        -2.4 + swing,
        1.6,
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BatsmanPainter old) => old.swing != swing;
}
