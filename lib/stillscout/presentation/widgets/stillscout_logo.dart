import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/stillscout_theme.dart';

/// StillScout mark — cinematic viewfinder with scout sparkle.
class StillScoutLogo extends StatefulWidget {
  const StillScoutLogo({
    super.key,
    this.size = 72,
    this.showWordmark = false,
    this.animateGlow = false,
    this.glowStrength = 0.35,
  });

  final double size;
  final bool showWordmark;
  /// When true, pulses [glowStrength] gently (empty state, idle hero).
  /// When false, uses [glowStrength] as a fixed value (splash can drive it).
  final bool animateGlow;
  final double glowStrength;

  @override
  State<StillScoutLogo> createState() => _StillScoutLogoState();
}

class _StillScoutLogoState extends State<StillScoutLogo>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  @override
  void initState() {
    super.initState();
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant StillScoutLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animateGlow != widget.animateGlow) {
      _syncPulse();
    }
  }

  void _syncPulse() {
    if (widget.animateGlow) {
      _pulse ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2200),
      )..repeat(reverse: true);
    } else {
      _pulse?.dispose();
      _pulse = null;
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  double get _effectiveGlow {
    if (_pulse != null) {
      final t = Curves.easeInOut.transform(_pulse!.value);
      return widget.glowStrength * (0.55 + t * 0.45);
    }
    return widget.glowStrength;
  }

  @override
  Widget build(BuildContext context) {
    Widget icon;
    if (_pulse != null) {
      icon = AnimatedBuilder(
        animation: _pulse!,
        builder: (_, __) => CustomPaint(
          size: Size.square(widget.size),
          painter: _StillScoutLogoPainter(glowStrength: _effectiveGlow),
        ),
      );
    } else {
      icon = CustomPaint(
        size: Size.square(widget.size),
        painter: _StillScoutLogoPainter(glowStrength: _effectiveGlow),
      );
    }

    if (!widget.showWordmark) return icon;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        SizedBox(height: widget.size * 0.18),
        Text(
          'STILLSCOUT',
          style: StillScoutTextStyles.display.copyWith(
            fontSize: widget.size * 0.34,
            letterSpacing: widget.size * 0.04,
          ),
        ),
        SizedBox(height: widget.size * 0.04),
        Text(
          'AI frame scout for creators',
          style: StillScoutTextStyles.caption.copyWith(
            color: StillScoutColors.silver.withValues(alpha: 0.85),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _StillScoutLogoPainter extends CustomPainter {
  _StillScoutLogoPainter({required this.glowStrength});

  final double glowStrength;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final pad = s * 0.14;
    final corner = s * 0.22;
    final stroke = math.max(2.0, s / 24);

    final glowPaint = Paint()
      ..color = StillScoutColors.accent.withValues(alpha: glowStrength)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.08);
    canvas.drawCircle(Offset(s / 2, s / 2), s * 0.28, glowPaint);

    final ring = Paint()
      ..color = StillScoutColors.accent.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.6;
    canvas.drawCircle(Offset(s / 2, s / 2), s * 0.34, ring);

    final accent = Paint()..color = StillScoutColors.accent;
    void cornerL(double x, double y, {required bool flipX, required bool flipY}) {
      canvas.drawRect(
        Rect.fromLTWH(
          flipX ? x - corner : x,
          flipY ? y - stroke : y,
          corner,
          stroke,
        ),
        accent,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          flipX ? x - stroke : x,
          flipY ? y - corner : y,
          stroke,
          corner,
        ),
        accent,
      );
    }

    cornerL(pad, pad, flipX: false, flipY: false);
    cornerL(s - pad, pad, flipX: true, flipY: false);
    cornerL(pad, s - pad, flipX: false, flipY: true);
    cornerL(s - pad, s - pad, flipX: true, flipY: true);

    canvas.drawCircle(Offset(s / 2, s / 2), s * 0.055, accent);
    canvas.drawCircle(Offset(s * 0.68, s * 0.30), s * 0.028, accent);
  }

  @override
  bool shouldRepaint(covariant _StillScoutLogoPainter oldDelegate) =>
      oldDelegate.glowStrength != glowStrength;
}
