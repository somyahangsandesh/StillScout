import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════
// CRICKRISE — "FLOODLIGHT"
// Night cricket under stadium lights. Warm. Cinematic. Human.
// ═══════════════════════════════════════════════════════════════

class CR {
  CR._();

  // ── Night sky ─────────────────────────────────────────────────
  static const bg          = Color(0xFF060A12);
  static const nightTop    = Color(0xFF0C1424);
  static const nightBottom = Color(0xFF040608);
  static const surface     = Color(0xFF0E1520);
  static const card        = Color(0xFF121C2A);
  static const cardHigh    = Color(0xFF1A2535);
  static const overlay     = Color(0xFF1E2D42);

  // ── Floodlight amber (hero accent) ──────────────────────────────
  static const flood       = Color(0xFFFFB020);
  static const floodLight  = Color(0xFFFFD080);
  static const floodDim    = Color(0xFF3D2A08);
  static const floodGlow   = Color(0x33FFB020);

  // ── Grass (live states only) ────────────────────────────────────
  static const grass       = Color(0xFF3DDB84);
  static const grassDim    = Color(0xFF0F2D1F);
  static const grassDeep   = Color(0xFF081A12);

  // ── Cricket accents ─────────────────────────────────────────────
  static const ball        = Color(0xFFDC2626);
  static const ballDim     = Color(0xFF4A0A10);
  static const sky         = Color(0xFF4A9EFF);
  static const pitch       = Color(0xFFC4A86A);

  // ── Text — warm, not cold green ────────────────────────────────
  static const cream       = Color(0xFFF5F0E6);
  static const mist        = Color(0xFF8A9BB0);
  static const fog         = Color(0xFF3D4F66);
  static const inv         = Color(0xFF060A12);

  // ── Glass ─────────────────────────────────────────────────────
  static const glass       = Color(0x0DFFFFFF);
  static const glassBorder = Color(0x1AFFFFFF);

  // ── Aliases (backward compat) ─────────────────────────────────
  static const green       = grass;
  static const greenDim    = grassDim;
  static const greenDeep   = grassDeep;
  static const gold        = flood;
  static const goldDim     = floodDim;
  static const ballRed     = ball;
  static const amber       = flood;
  static const white       = cream;
  static const t1          = cream;
  static const t2          = mist;
  static const t3          = fog;
  static const text1       = cream;
  static const text2       = mist;
  static const text3       = fog;
  static const textInv     = inv;
  static const textPrimary   = cream;
  static const textSecondary = mist;
  static const textMuted     = fog;
  static const background     = bg;
  static const surfaceCard    = card;
  static const surfaceElevated = cardHigh;
  static const primary        = flood;
  static const primaryDark    = Color(0xFFE09010);
  static const primaryDeep    = floodDim;
  static const accent         = flood;
  static const goldDimColor   = floodDim;
  static const cricketRed     = ball;
  static const danger         = ball;
  static const warning        = flood;
  static const red            = ball;
  static const orange         = flood;
  static const blue           = sky;

  // ── Ball chips (scoreboard) ───────────────────────────────────
  static const bDot    = Color(0xFF1A2535);
  static const bRuns   = Color(0xFF1E3040);
  static const bFour   = Color(0xFF0F2D1F);
  static const bSix    = Color(0xFF3D2A08);
  static const bWicket = Color(0xFF4A0A10);
  static const bExtra  = Color(0xFF3D2208);
  static const dot     = bDot;
  static const runs    = bRuns;
  static const four    = bFour;
  static const six     = bSix;
  static const wicket  = bWicket;
  static const extra   = bExtra;

  // ── Gradients ─────────────────────────────────────────────────
  static const List<Color> cardGradient  = [Color(0xFF161F2E), Color(0xFF0E1520)];
  static const List<Color> heroGradient  = [Color(0xFF1A2535), Color(0xFF060A12)];
  static const List<Color> goldGradient  = [Color(0xFFFFD080), Color(0xFFFFB020)];
  static const List<Color> greenGradient = [Color(0xFF2ECC71), Color(0xFF3DDB84)];
  static const List<Color> floodGradient = [Color(0xFFFFD080), Color(0xFFFFB020), Color(0xFFE09010)];
}

class CrickRiseColors {
  CrickRiseColors._();
  static const Color background      = CR.bg;
  static const Color surface         = CR.card;
  static const Color surfaceElevated = CR.cardHigh;
  static const Color surfaceCard     = CR.card;
  static const Color overlay         = CR.overlay;
  static const Color primary     = CR.flood;
  static const Color primaryDark = CR.primaryDark;
  static const Color primaryDeep = CR.floodDim;
  static const Color gold    = CR.flood;
  static const Color goldDim = CR.floodDim;
  static const Color cricketRed = CR.ball;
  static const Color pitch   = CR.pitch;
  static const Color textPrimary   = CR.cream;
  static const Color textSecondary = CR.mist;
  static const Color textMuted     = CR.fog;
  static const Color textInverse   = CR.inv;
  static const Color danger  = CR.ball;
  static const Color warning = CR.flood;
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

/// Typography shortcuts — Bebas for broadcast, DM Mono for scores, Source Sans for body.
class CRType {
  CRType._();

  static TextStyle display({double size = 48, Color color = CR.cream}) =>
      GoogleFonts.bebasNeue(color: color, fontSize: size, height: 0.95, letterSpacing: 1.5);

  static TextStyle headline({double size = 28, Color color = CR.cream}) =>
      GoogleFonts.bebasNeue(color: color, fontSize: size, height: 1.0, letterSpacing: 1.2);

  static TextStyle score({double size = 64, Color color = CR.flood}) =>
      GoogleFonts.dmMono(color: color, fontSize: size, fontWeight: FontWeight.w700, height: 0.9);

  static TextStyle body({double size = 15, Color color = CR.cream, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.sourceSans3(color: color, fontSize: size, fontWeight: weight, height: 1.45);

  static TextStyle label({double size = 11, Color color = CR.mist}) =>
      GoogleFonts.sourceSans3(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
      );

  static TextStyle caption({double size = 13, Color color = CR.mist}) =>
      GoogleFonts.sourceSans3(color: color, fontSize: size, height: 1.4);
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
        primary: CR.flood,
        secondary: CR.grass,
        error: CR.ball,
        onSurface: CR.cream,
        onPrimary: CR.inv,
        onSecondary: CR.inv,
        surfaceContainerHighest: CR.cardHigh,
      ),
      textTheme: _buildTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: CR.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: CRType.headline(size: 22),
      ),
      cardTheme: const CardThemeData(
        color: CR.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CR.flood,
          foregroundColor: CR.inv,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle: GoogleFonts.bebasNeue(fontSize: 18, letterSpacing: 1.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CR.cream,
          side: BorderSide(color: CR.cream.withValues(alpha: 0.2)),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.sourceSans3(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      dividerTheme: DividerThemeData(color: CR.cream.withValues(alpha: 0.06), thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CR.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: CR.cream.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: CR.cream.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CR.flood, width: 2),
        ),
        labelStyle: CRType.caption(color: CR.mist),
        hintStyle: CRType.caption(color: CR.fog),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: CR.cardHigh,
        selectedColor: CR.floodDim,
        labelStyle: CRType.caption(color: CR.cream, size: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: CR.surface,
        modalBackgroundColor: CR.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: CR.flood,
        unselectedItemColor: CR.fog,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge:  CRType.score(size: 96, color: CR.cream),
      displayMedium: CRType.score(size: 64, color: CR.cream),
      displaySmall:  CRType.score(size: 48, color: CR.cream),
      headlineLarge:  CRType.display(size: 40),
      headlineMedium: CRType.headline(size: 32),
      headlineSmall:  CRType.headline(size: 24),
      titleLarge:  CRType.body(size: 17, weight: FontWeight.w600),
      titleMedium: CRType.body(size: 15, weight: FontWeight.w600),
      titleSmall:  CRType.label(size: 11),
      bodyLarge:  CRType.body(size: 16),
      bodyMedium: CRType.body(size: 14),
      bodySmall:  CRType.caption(size: 12),
      labelLarge:  CRType.body(size: 13, weight: FontWeight.w600),
      labelMedium: CRType.label(size: 10),
      labelSmall:  CRType.label(size: 9, color: CR.fog),
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
      child: Text(text.toUpperCase(), style: CRType.label()),
    );
  }
}

class CRBallDot extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final double size;

  const CRBallDot({
    super.key,
    required this.label,
    required this.bgColor,
    this.textColor = CR.cream,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Center(
        child: Text(label, style: CRType.score(size: size * 0.38, color: textColor)),
      ),
    );
  }
}

class CRBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const CRBadge(this.text, {super.key, this.color = CR.flood, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, color: color, size: 12), const SizedBox(width: 4)],
          Text(text, style: CRType.caption(color: color, size: 11)),
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

  const CRCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.glow = false,
    this.onTap,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: color == null
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: CR.cardGradient,
              )
            : null,
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: glow ? CR.flood.withValues(alpha: 0.25) : CR.cream.withValues(alpha: 0.06),
          width: glow ? 1.5 : 1,
        ),
        boxShadow: glow
            ? [BoxShadow(color: CR.floodGlow, blurRadius: 28, offset: const Offset(0, 10))]
            : null,
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

  const CRDomainBar({
    super.key,
    required this.label,
    required this.value,
    required this.animation,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 44, child: Text(label, style: CRType.label(size: 10))),
        SizedBox(
          width: 36,
          child: Text(value.round().toString(), style: CRType.score(size: 18, color: color)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedBuilder(
            animation: animation,
            builder: (_, __) => Stack(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: CR.cardHigh,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: (value / 99) * animation.value,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color.withValues(alpha: 0.5), color]),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 6)],
                    ),
                  ),
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
  const SeamCurvePainter({this.color = CR.flood, this.opacity = 0.05});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path()
      ..moveTo(0, size.height * 0.35)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.05,
        size.width * 0.7,
        size.height * 0.95,
        size.width,
        size.height * 0.65,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SeamCurvePainter oldDelegate) => false;
}

class FieldRadialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [CR.flood.withValues(alpha: 0.08), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(FieldRadialPainter oldDelegate) => false;
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
          color: active ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.45) : CR.fog.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.bebasNeue(
            color: active ? color : CR.fog,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
