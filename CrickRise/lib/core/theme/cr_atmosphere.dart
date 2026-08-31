import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Full-screen atmospheric layer — floodlight cones, pitch diagonal, night sky.
class CRAtmosphere extends StatelessWidget {
  final Widget? child;
  final bool showPitch;
  final bool showLights;

  const CRAtmosphere({
    super.key,
    this.child,
    this.showPitch = true,
    this.showLights = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [CR.nightTop, CR.bg, CR.nightBottom],
            ),
          ),
        ),
        if (showLights)
          const Positioned.fill(child: CustomPaint(painter: _FloodlightPainter())),
        if (showPitch)
          const Positioned.fill(child: CustomPaint(painter: _PitchDiagonalPainter())),
        const Positioned.fill(child: CustomPaint(painter: _GrainPainter())),
        if (child != null) child!,
      ],
    );
  }
}

class _FloodlightPainter extends CustomPainter {
  const _FloodlightPainter();

  @override
  void paint(Canvas canvas, Size size) {
    _cone(canvas, size, size.width * 0.15, -40, 0.14);
    _cone(canvas, size, size.width * 0.85, -40, 0.10);
    _cone(canvas, size, size.width * 0.5, -60, 0.18);
  }

  void _cone(Canvas canvas, Size size, double x, double y, double opacity) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topCenter,
        radius: 1.2,
        colors: [
          CR.flood.withValues(alpha: opacity),
          CR.flood.withValues(alpha: opacity * 0.35),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(x - size.width * 0.5, y, size.width, size.height * 0.85));

    final path = Path()
      ..moveTo(x - size.width * 0.35, y)
      ..lineTo(x + size.width * 0.35, y)
      ..lineTo(x + size.width * 0.55, size.height * 0.7)
      ..lineTo(x - size.width * 0.55, size.height * 0.7)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PitchDiagonalPainter extends CustomPainter {
  const _PitchDiagonalPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CR.grass.withValues(alpha: 0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = -2; i < 8; i++) {
      final offset = i * 48.0;
      canvas.drawLine(
        Offset(-40, size.height * 0.55 + offset),
        Offset(size.width + 40, size.height * 0.35 + offset),
        paint,
      );
    }

    final crease = Paint()
      ..color = CR.cream.withValues(alpha: 0.04)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(0, size.height * 0.62),
      Offset(size.width, size.height * 0.62),
      crease,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(42);
    final paint = Paint()..color = CR.cream.withValues(alpha: 0.018);
    for (var i = 0; i < 280; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), rnd.nextDouble() * 0.8 + 0.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Frosted glass panel used across the app.
class CRGlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final bool highlight;

  const CRGlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.radius = 20,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: highlight
                  ? [CR.cardHigh.withValues(alpha: 0.92), CR.card.withValues(alpha: 0.88)]
                  : [CR.card.withValues(alpha: 0.82), CR.surface.withValues(alpha: 0.78)],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: highlight
                  ? CR.flood.withValues(alpha: 0.28)
                  : CR.cream.withValues(alpha: 0.07),
              width: highlight ? 1.5 : 1,
            ),
            boxShadow: highlight
                ? [
                    BoxShadow(
                      color: CR.flood.withValues(alpha: 0.12),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Giant broadcast-style number — scoreboard energy.
class CRBroadcastNumber extends StatelessWidget {
  final String value;
  final String? label;
  final double size;
  final Color color;

  const CRBroadcastNumber({
    super.key,
    required this.value,
    this.label,
    this.size = 88,
    this.color = CR.flood,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Text(
            label!.toUpperCase(),
            style: CRType.label(color: color.withValues(alpha: 0.55), size: 11),
          ),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [CR.floodLight, color],
          ).createShader(bounds),
          child: Text(
            value,
            style: CRType.score(size: size, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

/// Pulsing LIVE badge for active matches.
class CRLiveBadge extends StatefulWidget {
  const CRLiveBadge({super.key});

  @override
  State<CRLiveBadge> createState() => _CRLiveBadgeState();
}

class _CRLiveBadgeState extends State<CRLiveBadge> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: CR.ball.withValues(alpha: 0.15 + _ctrl.value * 0.08),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: CR.ball.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: CR.ball,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: CR.ball.withValues(alpha: 0.6 + _ctrl.value * 0.3),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text('LIVE', style: CRType.label(color: CR.ball, size: 10)),
          ],
        ),
      ),
    );
  }
}
