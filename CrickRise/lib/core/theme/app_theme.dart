import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════
// CRICKRISE DESIGN SYSTEM — "STADIUM NIGHT"
// Inspired by live cricket broadcasts under floodlights
// ═══════════════════════════════════════════════════════════════

class CR {
  CR._();

  // ── Backgrounds ────────────────────────────────────────────────
  static const bg        = Color(0xFF070A07);   // pitch black
  static const surface   = Color(0xFF0D140D);   // dark outfield
  static const card      = Color(0xFF111811);   // card surface
  static const cardHigh  = Color(0xFF18221A);   // elevated card
  static const overlay   = Color(0xFF1E2A1F);   // modal/overlay

  // ── Brand ──────────────────────────────────────────────────────
  static const green     = Color(0xFF00E676);   // electric green (floodlit grass)
  static const greenDim  = Color(0xFF00391E);   // dim green bg
  static const greenDeep = Color(0xFF002713);   // very deep green

  // ── Accents ────────────────────────────────────────────────────
  static const gold      = Color(0xFFFFD700);   // real gold (achievements/OVR)
  static const goldDim   = Color(0xFF3D2D00);   // gold background
  static const ballRed   = Color(0xFFFF1744);   // cricket ball red (wicket)
  static const amber     = Color(0xFFFF8F00);   // hot streak / warning

  // ── Text ───────────────────────────────────────────────────────
  static const white     = Color(0xFFFFFFFF);
  static const t1        = Color(0xFFF5FFF7);   // warm white (pitch/crease)
  static const t2        = Color(0xFF5E8C64);   // muted green
  static const t3        = Color(0xFF2D4A31);   // very muted
  static const inv       = Color(0xFF070A07);   // text on green

  // ── Glass ──────────────────────────────────────────────────────
  static const glass     = Color(0x0AFFFFFF);   // 4% white
  static const glassBorder = Color(0x14FFFFFF); // 8% white border

  // ── Text aliases ───────────────────────────────────────────────
  static const text1     = t1;
  static const text2     = t2;
  static const text3     = t3;
  static const textInv   = inv;
  static const textPrimary   = t1;
  static const textSecondary = t2;
  static const textMuted     = t3;

  // ── Old aliases (backward compat) ──────────────────────────────
  static const background     = bg;
  static const surfaceCard    = card;
  static const surfaceElevated = cardHigh;
  static const primary        = green;
  static const primaryDark    = Color(0xFF00B248);
  static const primaryDeep    = greenDim;
  static const accent         = gold;
  static const goldDimColor   = goldDim;
  static const cricketRed     = ballRed;
  static const danger         = ballRed;
  static const warning        = amber;
  static const red            = ballRed;
  static const orange         = amber;
  static const blue           = Color(0xFF40C4FF);

  // ── Ball chips ─────────────────────────────────────────────────
  static const bDot    = Color(0xFF18221A);
  static const bRuns   = Color(0xFF1A2A1E);
  static const bFour   = Color(0xFF00391E);
  static const bSix    = Color(0xFF3D2D00);
  static const bWicket = Color(0xFF4A0010);
  static const bExtra  = Color(0xFF3D1A00);
  static const dot     = bDot;
  static const runs    = bRuns;
  static const four    = bFour;
  static const six     = bSix;
  static const wicket  = bWicket;
  static const extra   = bExtra;

  // ── Gradient helpers ───────────────────────────────────────────
  static const List<Color> cardGradient  = [Color(0xFF111811), Color(0xFF0D140D)];
  static const List<Color> heroGradient  = [Color(0xFF0D1A0F), Color(0xFF070A07)];
  static const List<Color> goldGradient  = [Color(0xFFFFD700), Color(0xFFFF8F00)];
  static const List<Color> greenGradient = [Color(0xFF00B248), Color(0xFF00E676)];
}

// Keep old class for backward compatibility
class CrickRiseColors {
  CrickRiseColors._();

  static const Color background      = CR.bg;
  static const Color surface         = CR.card;
  static const Color surfaceElevated = CR.cardHigh;
  static const Color surfaceCard     = CR.card;
  static const Color overlay         = CR.overlay;

  static const Color primary     = CR.green;
  static const Color primaryDark = CR.primaryDark;
  static const Color primaryDeep = CR.greenDim;

  static const Color gold    = CR.gold;
  static const Color goldDim = CR.goldDim;
  static const Color cricketRed = CR.ballRed;
  static const Color pitch   = Color(0xFFC8B882);

  static const Color textPrimary   = CR.t1;
  static const Color textSecondary = CR.t2;
  static const Color textMuted     = CR.t3;
  static const Color textInverse   = CR.inv;

  static const Color danger  = CR.ballRed;
  static const Color warning = CR.amber;

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

// ── App Theme ──────────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: CR.bg,
      colorScheme: const ColorScheme.dark(
        surface: CR.card,
        primary: CR.green,
        secondary: CR.gold,
        error: CR.ballRed,
        onSurface: CR.t1,
        onPrimary: CR.inv,
        onSecondary: CR.inv,
        surfaceContainerHighest: CR.cardHigh,
      ),
      textTheme: _buildTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: CR.bg,
        foregroundColor: CR.t1,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.oswald(
          color: CR.t1,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: const CardTheme(
        color: CR.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CR.green,
          foregroundColor: CR.inv,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle: GoogleFonts.oswald(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CR.green,
          side: const BorderSide(color: CR.green),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.oswald(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: CR.cardHigh,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CR.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CR.cardHigh),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CR.cardHigh),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CR.green, width: 2),
        ),
        labelStyle: const TextStyle(color: CR.t2),
        hintStyle: const TextStyle(color: CR.t3),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: CR.cardHigh,
        selectedColor: CR.green.withOpacity(0.2),
        labelStyle: GoogleFonts.inter(color: CR.t1, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: CR.surface,
        modalBackgroundColor: CR.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: CR.bg,
        selectedItemColor: CR.green,
        unselectedItemColor: CR.t3,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    return TextTheme(
      // OVR numbers — Space Grotesk Black
      displayLarge:  GoogleFonts.spaceGrotesk(color: CR.t1, fontSize: 96, fontWeight: FontWeight.w900, height: 0.9),
      displayMedium: GoogleFonts.spaceGrotesk(color: CR.t1, fontSize: 64, fontWeight: FontWeight.w800, height: 0.9),
      displaySmall:  GoogleFonts.spaceGrotesk(color: CR.t1, fontSize: 48, fontWeight: FontWeight.w700),
      // Headlines — Oswald (condensed sports broadcast energy)
      headlineLarge:  GoogleFonts.oswald(color: CR.t1, fontSize: 32, fontWeight: FontWeight.w600),
      headlineMedium: GoogleFonts.oswald(color: CR.t1, fontSize: 24, fontWeight: FontWeight.w600),
      headlineSmall:  GoogleFonts.oswald(color: CR.t1, fontSize: 20, fontWeight: FontWeight.w500),
      // Titles — Inter
      titleLarge:  GoogleFonts.inter(color: CR.t1, fontSize: 16, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.inter(color: CR.t1, fontSize: 14, fontWeight: FontWeight.w600),
      titleSmall:  GoogleFonts.inter(color: CR.t2, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5),
      // Body — Inter
      bodyLarge:  GoogleFonts.inter(color: CR.t1, fontSize: 16),
      bodyMedium: GoogleFonts.inter(color: CR.t1, fontSize: 14),
      bodySmall:  GoogleFonts.inter(color: CR.t2, fontSize: 12),
      // Labels
      labelLarge:  GoogleFonts.inter(color: CR.t1, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.3),
      labelMedium: GoogleFonts.inter(color: CR.t2, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8),
      labelSmall:  GoogleFonts.inter(color: CR.t3, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.2),
    );
  }
}

// ── CRSectionLabel ────────────────────────────────────────────────────────────
// Oswald-styled section headers — condensed, sporty

class CRSectionLabel extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry padding;
  const CRSectionLabel(this.text, {super.key, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: CR.greenGradient,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text.toUpperCase(),
            style: GoogleFonts.oswald(
              color: CR.t2,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ── CRBallDot ────────────────────────────────────────────────────────────────

class CRBallDot extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final double size;

  const CRBallDot({
    super.key,
    required this.label,
    required this.bgColor,
    this.textColor = CR.t1,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            color: textColor,
            fontSize: size * 0.38,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ── CRBadge ──────────────────────────────────────────────────────────────────

class CRBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const CRBadge(this.text, {super.key, this.color = CR.gold, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── CRCard ────────────────────────────────────────────────────────────────────
// Premium card with gradient background and green-glow border

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
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: color != null
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: CR.cardGradient,
              ),
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: glow ? CR.green.withOpacity(0.2) : CR.glass,
          width: glow ? 1.5 : 1,
        ),
        boxShadow: glow
            ? [BoxShadow(color: CR.green.withOpacity(0.1), blurRadius: 20, spreadRadius: -4, offset: const Offset(0, 8))]
            : null,
      ),
      child: child,
    );
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }
}

// ── CRDomainBar ──────────────────────────────────────────────────────────────

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
        SizedBox(
          width: 44,
          child: Text(
            label,
            style: GoogleFonts.inter(color: CR.t2, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            value.round().toString(),
            style: GoogleFonts.spaceGrotesk(color: color, fontSize: 18, fontWeight: FontWeight.w700, height: 1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedBuilder(
            animation: animation,
            builder: (_, __) => Stack(
              children: [
                Container(height: 5, decoration: BoxDecoration(color: CR.cardHigh, borderRadius: BorderRadius.circular(3))),
                FractionallySizedBox(
                  widthFactor: (value / 99) * animation.value,
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color.withOpacity(0.6), color]),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)],
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

// ── SeamCurvePainter ─────────────────────────────────────────────────────────
// Cricket ball seam as atmospheric decoration

class SeamCurvePainter extends CustomPainter {
  final Color color;
  final double opacity;
  const SeamCurvePainter({this.color = CR.green, this.opacity = 0.04});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path()
      ..moveTo(0, size.height * 0.4)
      ..cubicTo(size.width * 0.3, size.height * 0.1, size.width * 0.7, size.height * 0.9, size.width, size.height * 0.6);
    canvas.drawPath(path, paint);

    paint.strokeWidth = 0.5;
    paint.color = color.withOpacity(opacity * 0.6);
    final path2 = Path()
      ..moveTo(0, size.height * 0.6)
      ..cubicTo(size.width * 0.25, size.height * 0.35, size.width * 0.75, size.height * 0.65, size.width, size.height * 0.4);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(SeamCurvePainter oldDelegate) => false;
}

class FieldRadialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}
  @override
  bool shouldRepaint(FieldRadialPainter oldDelegate) => false;
}

// ── CRRoleBadge ──────────────────────────────────────────────────────────────

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
          color: active ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? color.withOpacity(0.4) : CR.t3.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.oswald(
            color: active ? color : CR.t3,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
