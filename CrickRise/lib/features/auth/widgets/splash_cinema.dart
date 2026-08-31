import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/cr_matchday.dart';

/// Splash timeline — one continuous ball path, no teleports, scale from center.
class SplashCinema extends StatelessWidget {
  final double progress;

  const SplashCinema({super.key, required this.progress});

  static const _ballSize = 48.0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pitchY = size.height * 0.74;
    final scene = _computeScene(size, pitchY, progress);

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        const _StadiumBg(),
        CustomPaint(painter: _PitchPainter(pitchY: pitchY)),
        if (scene.batsmanOpacity > 0.01)
          Positioned(
            right: size.width * 0.07,
            bottom: pitchY - 6,
            child: Opacity(
              opacity: scene.batsmanOpacity,
              child: _BatsmanFigure(swing: scene.batSwing, height: size.height * 0.26),
            ),
          ),
        if (scene.showShadow)
          Positioned(
            left: scene.ballCenter.dx - 20,
            top: pitchY - 4,
            child: Opacity(
              opacity: scene.shadowOpacity,
              child: Transform.scale(
                scaleX: scene.shadowScaleX,
                child: Container(
                  width: 40,
                  height: 9,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          left: scene.ballCenter.dx - (_ballSize * scene.ballScale) / 2,
          top: scene.ballCenter.dy - (_ballSize * scene.ballScale) / 2,
          child: Transform.scale(
            scale: scene.ballScale,
            alignment: Alignment.center,
            child: Transform.rotate(
              angle: scene.ballRotation,
              child: const _Ball(size: _ballSize),
            ),
          ),
        ),
        if (scene.flash > 0)
          ColoredBox(color: CR.chalk.withValues(alpha: scene.flash)),
        if (scene.wipe > 0)
          ColoredBox(color: CR.terracotta.withValues(alpha: scene.wipe)),
        _Vignette(strength: 0.45 - scene.wipe * 0.2),
        SafeArea(
          child: Column(
            children: [
              const Spacer(),
              Opacity(
                opacity: (1 - scene.wipe * 2).clamp(0.0, 1.0),
                child: Column(
                  children: [
                    Text('CRICKRISE', style: CRType.overline(color: CR.brass, size: 11)),
                    const SizedBox(height: 8),
                    if (scene.label.isNotEmpty)
                      Text(scene.label, style: CRType.caption()),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  _Scene _computeScene(Size size, double pitchY, double t) {
    final w = size.width;
    final h = size.height;
    final creaseBallY = pitchY - 28;

    // ── Phase 1: bounce (0 → 0.36) ─────────────────────────────────────
    if (t < 0.36) {
      final p = t / 0.36;
      final bounce = _bouncePhysics(p);
      final cx = w * 0.5;
      final cy = creaseBallY - bounce.height;
      final squash = 1.0 + bounce.squash * 0.22;
      return _Scene(
        ballCenter: Offset(cx, cy),
        ballScale: squash,
        ballRotation: p * math.pi * 4,
        shadowOpacity: bounce.shadow,
        shadowScaleX: 0.5 + bounce.shadow * 0.5,
        showShadow: true,
        label: 'Warming up…',
      );
    }

    // ── Phase 2: ball travels to batsman (0.36 → 0.62) ──────────────────
    if (t < 0.62) {
      final p = (t - 0.36) / 0.26;
      final batX = w * 0.76;
      final batY = creaseBallY - 118;

      // Continue from bounce end (center) — no teleport
      final startX = w * 0.5;
      final startY = creaseBallY - 6;
      final eased = Curves.easeInOut.transform(p);
      final cx = _lerp(startX, batX, eased);
      final arc = math.sin(p * math.pi) * 80;
      final cy = _lerp(startY, batY, eased) - arc;

      return _Scene(
        ballCenter: Offset(cx, cy),
        ballScale: 1.0,
        ballRotation: p * math.pi * 6,
        shadowOpacity: (1 - p) * 0.25,
        shadowScaleX: 0.7,
        showShadow: p < 0.85,
        batsmanOpacity: Curves.easeOut.transform(_clamp((t - 0.38) / 0.12)),
        batSwing: 0,
        label: 'Play!',
      );
    }

    // ── Phase 3: bat swing + contact (0.62 → 0.74) ──────────────────────
    if (t < 0.74) {
      final p = (t - 0.62) / 0.12;
      final batX = w * 0.76;
      final batY = creaseBallY - 118;
      final swing = Curves.easeInOutCubic.transform(p);

      return _Scene(
        ballCenter: Offset(batX - 8 + swing * 6, batY - swing * 8),
        ballScale: 1.0,
        ballRotation: swing * math.pi * 2,
        showShadow: false,
        batsmanOpacity: 1,
        batSwing: swing,
        flash: p > 0.72 ? math.sin(((p - 0.72) / 0.28) * math.pi) * 0.75 : 0,
        label: '',
      );
    }

    // ── Phase 4: zoom to camera (0.74 → 1.0) ────────────────────────────
    final p = (t - 0.74) / 0.26;
    final ease = Curves.easeInCubic.transform(p);
    final start = Offset(w * 0.76, creaseBallY - 118);
    final end = Offset(w * 0.5, h * 0.44);
    final center = Offset(
      _lerp(start.dx, end.dx, math.min(p * 2.2, 1.0)),
      _lerp(start.dy, end.dy, math.min(p * 2.2, 1.0)),
    );

    return _Scene(
      ballCenter: center,
      ballScale: 1.0 + ease * 36,
      ballRotation: ease * math.pi * 3,
      showShadow: false,
      batsmanOpacity: (1 - p * 3).clamp(0.0, 1.0),
      batSwing: 1,
      flash: p < 0.12 ? (1 - p / 0.12) * 0.5 : 0,
      wipe: p > 0.55 ? Curves.easeIn.transform((p - 0.55) / 0.45) * 0.98 : 0,
      label: '',
    );
  }

  _Bounce _bouncePhysics(double t) {
    const bounces = 3;
    final phase = (t * bounces).clamp(0.0, bounces - 0.001);
    final idx = phase.floor();
    final local = phase - idx;
    final damp = math.pow(0.52, idx).toDouble();
    final height = math.sin(local * math.pi) * 130 * damp;
    final squash = local < 0.1 ? (1 - local / 0.1) : 0.0;
    final shadow = (1 - height / (130 * damp + 1)).clamp(0.15, 1.0);
    return _Bounce(height: height, squash: squash, shadow: shadow);
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
  double _clamp(double v) => v.clamp(0.0, 1.0);
}

class _Scene {
  final Offset ballCenter;
  final double ballScale;
  final double ballRotation;
  final double shadowOpacity;
  final double shadowScaleX;
  final bool showShadow;
  final double batsmanOpacity;
  final double batSwing;
  final double flash;
  final double wipe;
  final String label;

  const _Scene({
    required this.ballCenter,
    this.ballScale = 1,
    this.ballRotation = 0,
    this.shadowOpacity = 0,
    this.shadowScaleX = 1,
    this.showShadow = false,
    this.batsmanOpacity = 0,
    this.batSwing = 0,
    this.flash = 0,
    this.wipe = 0,
    this.label = '',
  });
}

class _Bounce {
  final double height;
  final double squash;
  final double shadow;
  const _Bounce({required this.height, required this.squash, required this.shadow});
}

// ─── Visual layers ───────────────────────────────────────────────────────────

class _StadiumBg extends StatelessWidget {
  const _StadiumBg();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.5),
          radius: 1.3,
          colors: [Color(0xFF1A3328), Color(0xFF0F0B08), Color(0xFF050403)],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x18D4A574), Colors.transparent, Color(0x10D4A574)],
          ),
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
    final grass = Rect.fromLTWH(0, pitchY - 8, size.width, size.height - pitchY + 20);
    canvas.drawRect(
      grass,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2D6A4F), Color(0xFF1B4332)],
        ).createShader(grass),
    );

    final stripe = Paint()..color = const Color(0x0FFFFFFF);
    for (var x = 0.0; x < size.width; x += 32) {
      canvas.drawRect(Rect.fromLTWH(x, pitchY, 16, size.height), stripe);
    }

    final crease = Paint()
      ..color = CR.chalk.withValues(alpha: 0.4)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, pitchY), Offset(size.width, pitchY), crease);
  }

  @override
  bool shouldRepaint(covariant _PitchPainter old) => old.pitchY != pitchY;
}

class _Vignette extends StatelessWidget {
  final double strength;
  const _Vignette({required this.strength});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [Colors.transparent, CR.voidBlack.withValues(alpha: strength)],
            radius: 1.05,
          ),
        ),
      ),
    );
  }
}

class _Ball extends StatelessWidget {
  final double size;
  const _Ball({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: CR.terracotta.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: CustomPaint(painter: _BallPainter()),
    );
  }
}

class _BallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFF7070), CR.terracotta, Color(0xFF7F1D1D)],
          stops: [0.2, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    final seam = Paint()
      ..color = CR.chalk.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path();
    for (var i = 0; i <= 360; i += 4) {
      final rad = i * math.pi / 180;
      final wobble = math.sin(rad * 2) * r * 0.13;
      final x = c.dx + (r * 0.5 + wobble) * math.cos(rad);
      final y = c.dy + r * 0.5 * math.sin(rad);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, seam);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BatsmanFigure extends StatelessWidget {
  final double swing;
  final double height;
  const _BatsmanFigure({required this.swing, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: height * 0.5,
      height: height,
      child: CustomPaint(painter: _BatsmanPainter(swing: swing)),
    );
  }
}

class _BatsmanPainter extends CustomPainter {
  final double swing;
  const _BatsmanPainter({required this.swing});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.45;
    final body = Paint()..color = CR.chalk;

    canvas.drawCircle(Offset(cx, h * 0.1), h * 0.085, body);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, h * 0.36), width: w * 0.36, height: h * 0.32),
        const Radius.circular(5),
      ),
      body,
    );
    canvas.drawRect(Rect.fromLTWH(cx - w * 0.26, h * 0.5, w * 0.2, h * 0.42), body);
    canvas.drawRect(Rect.fromLTWH(cx + w * 0.06, h * 0.5, w * 0.2, h * 0.42), body);

    final angle = lerpDouble(-2.0, 0.5, swing)!;
    final bat = Paint()
      ..color = CR.brass
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.translate(cx + w * 0.15, h * 0.34);
    canvas.rotate(angle);
    canvas.drawLine(Offset.zero, Offset(0, -h * 0.5), bat);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BatsmanPainter old) => old.swing != swing;
}
