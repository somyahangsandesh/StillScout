import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'cr_matchday.dart' show CRProgrammeRule;

// ═══════════════════════════════════════════════════════════════
// CRICKRISE — "MATCHDAY"
// Programme cover × scorebook × passport stamp. Editorial. Human.
// ═══════════════════════════════════════════════════════════════

class CR {
  CR._();

  // ── Ink & paper ───────────────────────────────────────────────
  static const voidBlack  = Color(0xFF080604);
  static const bg         = Color(0xFF0F0B08);
  static const inkDeep    = Color(0xFF1A1410);
  static const surface    = Color(0xFF1E1712);
  static const card       = Color(0xFF241C16);
  static const cardHigh   = Color(0xFF2E241C);
  static const overlay    = Color(0xFF362A22);
  static const paper      = Color(0xFFE8DFD0);

  // ── Cricket palette ───────────────────────────────────────────
  static const terracotta = Color(0xFFB91C1C);
  static const terracottaDim = Color(0xFF4A1515);
  static const moss       = Color(0xFF1B4332);
  static const mossLight  = Color(0xFF2D6A4F);
  static const brass      = Color(0xFFD4A574);
  static const brassDim   = Color(0xFF3D2E1A);
  static const pitch      = Color(0xFF8B7355);
  static const slate      = Color(0xFF3D5A80);

  // ── Text ──────────────────────────────────────────────────────
  static const chalk      = Color(0xFFF7F2EA);
  static const ink        = Color(0xFF9C8B7E);
  static const fog        = Color(0xFF5C4F46);
  static const inv        = Color(0xFF0F0B08);

  // ── Glass (legacy) ────────────────────────────────────────────
  static const glass       = Color(0x0AFFFFFF);
  static const glassBorder = Color(0x14FFFFFF);

  // ── Backward-compat aliases ───────────────────────────────────
  static const green       = mossLight;
  static const greenDim    = moss;
  static const greenDeep   = Color(0xFF0D2818);
  static const gold        = brass;
  static const goldDim     = brassDim;
  static const flood       = brass;
  static const floodLight  = Color(0xFFE8C9A0);
  static const floodDim    = brassDim;
  static const floodGlow   = Color(0x33D4A574);
  static const ball        = terracotta;
  static const ballRed     = terracotta;
  static const ballDim     = terracottaDim;
  static const grass       = mossLight;
  static const grassDim    = moss;
  static const grassDeep   = Color(0xFF0D2818);
  static const cream       = chalk;
  static const mist        = ink;
  static const amber       = brass;
  static const white       = chalk;
  static const t1          = chalk;
  static const t2          = ink;
  static const t3          = fog;
  static const text1       = chalk;
  static const text2       = ink;
  static const text3       = fog;
  static const textInv     = inv;
  static const textPrimary   = chalk;
  static const textSecondary = ink;
  static const textMuted     = fog;
  static const background     = bg;
  static const surfaceCard    = card;
  static const surfaceElevated = cardHigh;
  static const primary        = terracotta;
  static const primaryDark    = Color(0xFF991B1B);
  static const primaryDeep    = terracottaDim;
  static const accent         = brass;
  static const goldDimColor   = brassDim;
  static const cricketRed     = terracotta;
  static const danger         = terracotta;
  static const warning        = brass;
  static const red            = terracotta;
  static const orange         = brass;
  static const blue           = slate;
  static const nightTop       = inkDeep;
  static const nightBottom    = voidBlack;
  static const sky            = slate;

  // ── Ball chips ────────────────────────────────────────────────
  static const bDot    = Color(0xFF2E241C);
  static const bRuns   = Color(0xFF362A22);
  static const bFour   = Color(0xFF1B4332);
  static const bSix    = Color(0xFF3D2E1A);
  static const bWicket = Color(0xFF4A1515);
  static const bExtra  = Color(0xFF3D2208);
  static const dot     = bDot;
  static const runs    = bRuns;
  static const four    = bFour;
  static const six     = bSix;
  static const wicket  = bWicket;
  static const extra   = bExtra;

  // ── Gradients ─────────────────────────────────────────────────
  static const List<Color> cardGradient  = [Color(0xFF2E241C), Color(0xFF1A1410)];
  static const List<Color> heroGradient  = [Color(0xFF241C16), Color(0xFF0F0B08)];
  static const List<Color> goldGradient  = [Color(0xFFE8C9A0), Color(0xFFD4A574)];
  static const List<Color> greenGradient = [Color(0xFF2D6A4F), Color(0xFF1B4332)];
  static const List<Color> floodGradient = goldGradient;
}

class CrickRiseColors {
  CrickRiseColors._();
  static const Color background      = CR.bg;
  static const Color surface         = CR.card;
  static const Color surfaceElevated = CR.cardHigh;
  static const Color surfaceCard     = CR.card;
  static const Color overlay         = CR.overlay;
  static const Color primary     = CR.terracotta;
  static const Color primaryDark = CR.primaryDark;
  static const Color primaryDeep = CR.terracottaDim;
  static const Color gold    = CR.brass;
  static const Color goldDim = CR.brassDim;
  static const Color cricketRed = CR.terracotta;
  static const Color pitch   = CR.pitch;
  static const Color textPrimary   = CR.chalk;
  static const Color textSecondary = CR.ink;
  static const Color textMuted     = CR.fog;
  static const Color textInverse   = CR.inv;
  static const Color danger  = CR.terracotta;
  static const Color warning = CR.brass;
  static const Color ballDot    = CR.dot;
  static const Color ballRuns   = CR.runs;
  static const Color ballFour   = CR.four;
  static const Color ballSix    = CR.six;
  static const Color ballWicket = CR.wicket;
  static const Color ballExtra  = CR.extra;
  static const List<Color> cardGradient  = CR.cardGradient;
  static const List<Color> heroGradient  = CR.heroGradient;
  static const List<Color> goldGradient  = CR.goldGradient;
  static const List<Color> primaryGradient = CR.greenGradient;
}

/// Playfair editorial + JetBrains scoreboard + Outfit body.
class CRType {
  CRType._();

  static TextStyle display({double size = 42, Color color = CR.chalk, FontStyle style = FontStyle.normal}) =>
      GoogleFonts.playfairDisplay(color: color, fontSize: size, height: 1.05, fontWeight: FontWeight.w700, fontStyle: style);

  static TextStyle headline({double size = 28, Color color = CR.chalk}) =>
      GoogleFonts.playfairDisplay(color: color, fontSize: size, height: 1.1, fontWeight: FontWeight.w600);

  static TextStyle score({double size = 48, Color color = CR.brass}) =>
      GoogleFonts.jetBrainsMono(color: color, fontSize: size, fontWeight: FontWeight.w700, height: 0.95);

  static TextStyle body({double size = 15, Color color = CR.chalk, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.outfit(color: color, fontSize: size, fontWeight: weight, height: 1.5);

  static TextStyle label({double size = 13, Color color = CR.chalk}) =>
      GoogleFonts.outfit(color: color, fontSize: size, fontWeight: FontWeight.w600, letterSpacing: 0.8);

  static TextStyle overline({double size = 10, Color color = CR.ink}) =>
      GoogleFonts.outfit(color: color, fontSize: size, fontWeight: FontWeight.w600, letterSpacing: 2.4);

  static TextStyle caption({double size = 13, Color color = CR.ink}) =>
      GoogleFonts.outfit(color: color, fontSize: size, height: 1.45);
}

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: CR.bg,
      colorScheme: const ColorScheme.dark(
        surface: CR.card,
        primary: CR.terracotta,
        secondary: CR.brass,
        error: CR.terracotta,
        onSurface: CR.chalk,
        onPrimary: CR.chalk,
        onSecondary: CR.inv,
        surfaceContainerHighest: CR.cardHigh,
      ),
      textTheme: _buildTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: CR.chalk,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: CRType.headline(size: 20),
      ),
      cardTheme: const CardThemeData(
        color: CR.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CR.terracotta,
          foregroundColor: CR.chalk,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
          elevation: 0,
          textStyle: CRType.label(size: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CR.chalk,
          side: BorderSide(color: CR.chalk.withValues(alpha: 0.2)),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
          textStyle: CRType.label(),
        ),
      ),
      dividerTheme: DividerThemeData(color: CR.chalk.withValues(alpha: 0.08)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CR.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: BorderSide(color: CR.chalk.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: BorderSide(color: CR.chalk.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: CR.brass, width: 1.5),
        ),
        hintStyle: CRType.caption(color: CR.fog),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: CR.cardHigh,
        selectedColor: CR.brassDim,
        labelStyle: CRType.caption(color: CR.chalk),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: CR.surface,
        modalBackgroundColor: CR.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: CR.brass,
        unselectedItemColor: CR.fog,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge:  CRType.score(size: 88, color: CR.chalk),
      displayMedium: CRType.score(size: 56, color: CR.chalk),
      displaySmall:  CRType.score(size: 40, color: CR.chalk),
      headlineLarge:  CRType.display(size: 36),
      headlineMedium: CRType.headline(size: 28),
      headlineSmall:  CRType.headline(size: 22),
      titleLarge:  CRType.body(size: 17, weight: FontWeight.w600),
      titleMedium: CRType.body(size: 15, weight: FontWeight.w600),
      titleSmall:  CRType.overline(),
      bodyLarge:  CRType.body(size: 16),
      bodyMedium: CRType.body(size: 14),
      bodySmall:  CRType.caption(size: 12),
      labelLarge:  CRType.label(),
      labelMedium: CRType.overline(size: 9),
      labelSmall:  CRType.overline(size: 8, color: CR.fog),
    );
  }
}

class CRSectionLabel extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry padding;
  const CRSectionLabel(this.text, {super.key, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: CRProgrammeRule(label: text),
    );
  }
}

class CRBallDot extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final double size;
  const CRBallDot({super.key, required this.label, required this.bgColor, this.textColor = CR.chalk, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Center(child: Text(label, style: CRType.score(size: size * 0.38, color: textColor))),
    );
  }
}

class CRBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const CRBadge(this.text, {super.key, this.color = CR.brass, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, color: color, size: 11), const SizedBox(width: 4)],
          Text(text.toUpperCase(), style: CRType.overline(color: color, size: 8)),
        ],
      ),
    );
  }
}

class CRCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final bool glow;
  final VoidCallback? onTap;
  final double radius;
  const CRCard({super.key, required this.child, this.padding, this.color, this.glow = false, this.onTap, this.radius = 4});

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? CR.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: glow ? CR.brass.withValues(alpha: 0.4) : CR.chalk.withValues(alpha: 0.06)),
      ),
      child: child,
    );
    if (onTap != null) return GestureDetector(onTap: onTap, child: content);
    return content;
  }
}

class CRDomainBar extends StatelessWidget {
  final String label;
  final double value;
  final Animation<double> animation;
  final Color color;
  const CRDomainBar({super.key, required this.label, required this.value, required this.animation, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 44, child: Text(label, style: CRType.overline(size: 9))),
        SizedBox(width: 36, child: Text(value.round().toString(), style: CRType.score(size: 18, color: color))),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedBuilder(
            animation: animation,
            builder: (_, __) => Stack(
              children: [
                Container(height: 3, color: CR.cardHigh),
                FractionallySizedBox(
                  widthFactor: (value / 99) * animation.value,
                  child: Container(height: 3, color: color),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SeamCurvePainter extends CustomPainter {
  final Color color;
  final double opacity;
  const SeamCurvePainter({this.color = CR.brass, this.opacity = 0.06});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color.withValues(alpha: opacity)..style = PaintingStyle.stroke..strokeWidth = 1;
    canvas.drawPath(Path()..moveTo(0, size.height * 0.4)..quadraticBezierTo(size.width * 0.5, size.height * 0.1, size.width, size.height * 0.5), p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FieldRadialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CRRoleBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool active;
  final VoidCallback? onTap;
  const CRRoleBadge(this.label, this.color, {super.key, this.active = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: active ? color : CR.fog.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(2),
          color: active ? color.withValues(alpha: 0.1) : null,
        ),
        child: Text(label, style: CRType.overline(color: active ? color : CR.fog, size: 8)),
      ),
    );
  }
}
