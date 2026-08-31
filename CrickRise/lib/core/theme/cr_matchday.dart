import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MATCHDAY — Programme cover × scorebook × match ticket
// Hand-crafted editorial cricket. Not a dark-mode template.
// ═══════════════════════════════════════════════════════════════════════════

/// Warm programme background with pitch vignette and ruled lines.
class CRProgrammeBg extends StatelessWidget {
  final Widget? child;
  final bool ruled;

  const CRProgrammeBg({super.key, this.child, this.ruled = true});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.35),
              radius: 1.4,
              colors: [CR.inkDeep, CR.bg, CR.voidBlack],
            ),
          ),
        ),
        if (ruled)
          const Positioned.fill(child: CustomPaint(painter: _RuledPaperPainter())),
        const Positioned(
          top: -60,
          right: -40,
          child: _BallWatermark(size: 220, opacity: 0.06),
        ),
        if (child != null) child!,
      ],
    );
  }
}

class _RuledPaperPainter extends CustomPainter {
  const _RuledPaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = CR.chalk.withValues(alpha: 0.025)
      ..strokeWidth = 1;
    for (var y = 32.0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final margin = Paint()
      ..color = CR.terracotta.withValues(alpha: 0.08)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(28, 0), Offset(28, size.height), margin);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paper sheet with hard offset shadow — tactile, not glassmorphism.
class CRPaper extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final bool accent;

  const CRPaper({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 5,
          top: 5,
          right: -5,
          bottom: -5,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: CR.voidBlack.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: color ?? CR.card,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: accent ? CR.brass.withValues(alpha: 0.45) : CR.chalk.withValues(alpha: 0.08),
              width: accent ? 1.5 : 1,
            ),
          ),
          child: Padding(padding: padding ?? const EdgeInsets.all(20), child: child),
        ),
      ],
    );
  }
}

/// Match ticket with perforated left edge.
class CRTicket extends StatelessWidget {
  final Widget stub;
  final Widget body;
  final VoidCallback? onTap;

  const CRTicket({super.key, required this.stub, required this.body, this.onTap});

  @override
  Widget build(BuildContext context) {
    final ticket = CustomPaint(
      painter: const _TicketEdgePainter(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          stub,
          Container(width: 1, color: CR.chalk.withValues(alpha: 0.1)),
          Expanded(child: body),
        ],
      ),
    );

    final wrapped = CRPaper(
      padding: EdgeInsets.zero,
      child: ticket,
    );

    if (onTap != null) return GestureDetector(onTap: onTap, child: wrapped);
    return wrapped;
  }
}

class _TicketEdgePainter extends CustomPainter {
  const _TicketEdgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = CR.bg;
    const r = 5.0;
    for (var y = 12.0; y < size.height; y += 14) {
      canvas.drawCircle(Offset(0, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Flip-scoreboard style digit cells.
class CRScoreboard extends StatelessWidget {
  final String value;
  final String? label;
  final double digitSize;

  const CRScoreboard({
    super.key,
    required this.value,
    this.label,
    this.digitSize = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (label != null) ...[
          Text(label!.toUpperCase(), style: CRType.overline(color: CR.brass)),
          const SizedBox(height: 6),
        ],
        Row(
          mainAxisSize: MainAxisSize.min,
          children: value.split('').map((d) {
            return Container(
              width: digitSize * 0.72,
              height: digitSize,
              margin: const EdgeInsets.only(left: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CR.inkDeep,
                border: Border.all(color: CR.brass.withValues(alpha: 0.55), width: 1.5),
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: CR.brass.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(d, style: CRType.score(size: digitSize * 0.62, color: CR.brass)),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Passport stamp badge — rotated, dashed circle.
class CRStamp extends StatelessWidget {
  final String line1;
  final String line2;
  final Color color;

  const CRStamp({
    super.key,
    required this.line1,
    required this.line2,
    this.color = CR.terracotta,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.18,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.7), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(line1, style: CRType.overline(color: color, size: 8)),
            Text(line2, style: CRType.score(size: 13, color: color)),
          ],
        ),
      ),
    );
  }
}

/// Illustrated cricket ball with seam.
class CRCricketBall extends StatelessWidget {
  final double size;
  final bool glow;

  const CRCricketBall({super.key, this.size = 48, this.glow = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: glow
          ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: CR.terracotta.withValues(alpha: 0.45),
                  blurRadius: size * 0.35,
                ),
              ],
            )
          : null,
      child: CustomPaint(painter: _BallPainter()),
    );
  }
}

class _BallWatermark extends StatelessWidget {
  final double size;
  final double opacity;
  const _BallWatermark({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: CustomPaint(
        size: Size(size, size),
        painter: _BallPainter(),
      ),
    );
  }
}

class _BallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFFE53E3E), CR.terracotta, const Color(0xFF7F1D1D)],
          stops: const [0.2, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    final seam = Paint()
      ..color = CR.chalk.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.07;

    final path = Path();
    for (var i = 0; i < 360; i += 4) {
      final rad = i * math.pi / 180;
      final wobble = math.sin(rad * 2) * r * 0.12;
      final x = center.dx + (r * 0.55 + wobble) * math.cos(rad);
      final y = center.dy + r * 0.55 * math.sin(rad);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, seam);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Decorative programme rule with centre diamond.
class CRProgrammeRule extends StatelessWidget {
  final String? label;
  const CRProgrammeRule({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: CR.chalk.withValues(alpha: 0.12))),
        if (label != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label!.toUpperCase(), style: CRType.overline()),
          ),
          Expanded(child: Container(height: 1, color: CR.chalk.withValues(alpha: 0.12))),
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  border: Border.all(color: CR.brass.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Primary CTA — programme button with inset border.
class CRProgrammeButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool primary;

  const CRProgrammeButton({
    super.key,
    required this.label,
    this.onTap,
    this.primary = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.45 : 1,
        child: Container(
        width: double.infinity,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? CR.terracotta : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: primary ? CR.terracotta : CR.chalk.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: primary
              ? [BoxShadow(color: CR.terracotta.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))]
              : null,
        ),
        child: Text(
          label.toUpperCase(),
          style: CRType.label(
            size: 14,
            color: primary ? CR.chalk : CR.chalk.withValues(alpha: 0.8),
          ),
        ),
        ),
      ),
    );
  }
}

/// Pulsing live dot for active matches.
class CRLiveDot extends StatefulWidget {
  const CRLiveDot({super.key});

  @override
  State<CRLiveDot> createState() => _CRLiveDotState();
}

class _CRLiveDotState extends State<CRLiveDot> with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CR.terracotta,
              boxShadow: [
                BoxShadow(
                  color: CR.terracotta.withValues(alpha: 0.4 + _c.value * 0.4),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text('LIVE', style: CRType.overline(color: CR.terracotta, size: 9)),
        ],
      ),
    );
  }
}

// Legacy alias
class CRAtmosphere extends CRProgrammeBg {
  const CRAtmosphere({super.key, super.child, bool showPitch = true, bool showLights = true})
      : super(ruled: showPitch);
}

class CRGlassPanel extends CRPaper {
  const CRGlassPanel({
    super.key,
    required super.child,
    super.padding,
    bool highlight = false,
    double radius = 20,
  }) : super(accent: highlight);
}

class CRBroadcastNumber extends CRScoreboard {
  const CRBroadcastNumber({
    super.key,
    required super.value,
    super.label,
    double size = 88,
  }) : super(digitSize: size * 0.65);
}

class CRLiveBadge extends CRLiveDot {
  const CRLiveBadge({super.key});
}

class CRFadeInOnce extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const CRFadeInOnce({super.key, required this.child, this.delay = Duration.zero});

  @override
  State<CRFadeInOnce> createState() => _CRFadeInOnceState();
}

class _CRFadeInOnceState extends State<CRFadeInOnce> with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _c, child: widget.child);
  }
}
