import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/stillscout_theme.dart';

/// Real frosted-glass surface — blurs whatever sits behind it via
/// [BackdropFilter], then tints on top with [StillScoutDecorations.glassCard].
///
/// Previously every "glass card" in the app was simulated with a gradient +
/// opacity only (no actual blur-behind), which reads as flat rather than
/// premium. Use this widget instead of `Container(decoration: glassCard())`
/// for any static card — it costs nothing extra and keeps every glass
/// surface in the app behaving consistently.
///
/// Not suitable for cards with an *animated* decoration (border color/width
/// changing over time) or ones wrapped in `Material`/`Ink` for splash
/// effects — those need `ClipRRect` + `BackdropFilter` applied by hand
/// around the existing widget so the animation/ink still works.
class StillScoutGlassSurface extends StatelessWidget {
  const StillScoutGlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.borderColor,
    this.borderWidth = 1,
    this.blurSigma = 22,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? StillScoutRadius.card;
    final surface = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: StillScoutDecorations.glassCard(
            borderColor: borderColor,
            borderWidth: borderWidth,
          ).copyWith(borderRadius: radius),
          child: child,
        ),
      ),
    );
    return margin == null ? surface : Padding(padding: margin!, child: surface);
  }
}
