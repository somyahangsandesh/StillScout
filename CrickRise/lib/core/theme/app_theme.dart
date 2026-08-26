import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
// Pure black minimalism: less green-black, more broadcast-dark

class CR {
  CR._();

  // Backgrounds
  static const bg       = Color(0xFF0A0A0A);
  static const card     = Color(0xFF141414);
  static const cardHigh = Color(0xFF1C1C1C);
  static const overlay  = Color(0xFF222222);

  // Brand
  static const green    = Color(0xFF22C55E);
  static const greenDim = Color(0xFF052E16);
  static const gold     = Color(0xFFF59E0B);
  static const goldDim  = Color(0xFF2D1500);
  static const red      = Color(0xFFEF4444);
  static const orange   = Color(0xFFF97316);
  // Blue used for FIELD domain across stats cards
  static const blue     = Color(0xFF60A5FA);

  // Text (long names — keep for backward compatibility)
  static const white   = Color(0xFFFFFFFF);
  static const text1   = Color(0xFFF5F5F5);
  static const text2   = Color(0xFF9B9B9B);
  static const text3   = Color(0xFF4A4A4A);
  static const textInv = Color(0xFF0A0A0A);

  // Text (short aliases)
  static const t1  = text1;
  static const t2  = text2;
  static const t3  = text3;
  static const inv = textInv;

  // Ball chips (long names)
  static const dot    = Color(0xFF1C1C1C);
  static const runs   = Color(0xFF222222);
  static const four   = Color(0xFF052E16);
  static const six    = Color(0xFF2D1500);
  static const wicket = Color(0xFF2D0A0A);
  static const extra  = Color(0xFF1E1200);

  // Ball chips (short aliases)
  static const bDot    = dot;
  static const bRuns   = runs;
  static const bFour   = four;
  static const bSix    = six;
  static const bWicket = wicket;
  static const bExtra  = extra;
}

// Keep old name for backward compatibility during transition
class CrickRiseColors {
  CrickRiseColors._();

  static const Color background = CR.bg;
  static const Color surface = CR.card;
  static const Color surfaceElevated = CR.cardHigh;
  static const Color surfaceCard = CR.card;
  static const Color overlay = CR.overlay;

  static const Color primary = CR.green;
  static const Color primaryDark = Color(0xFF16A34A);
  static const Color primaryDeep = CR.greenDim;

  static const Color gold = CR.gold;
  static const Color goldDim = CR.goldDim;
  static const Color cricketRed = CR.red;
  static const Color pitch = Color(0xFFC8B882);

  static const Color textPrimary = CR.text1;
  static const Color textSecondary = CR.text2;
  static const Color textMuted = CR.text3;
  static const Color textInverse = CR.textInv;

  static const Color danger = CR.red;
  static const Color warning = CR.orange;

  static const Color ballDot = CR.dot;
  static const Color ballRuns = CR.runs;
  static const Color ballFour = CR.four;
  static const Color ballSix = CR.six;
  static const Color ballWicket = CR.wicket;
  static const Color ballExtra = CR.extra;

  static const List<Color> cardGradient = [
    Color(0xFF141414),
    Color(0xFF161616),
    Color(0xFF121212),
  ];

  static const List<Color> heroGradient = [
    CR.bg,
    Color(0xFF0F0F0F),
    CR.bg,
  ];

  static const List<Color> goldGradient = [
    Color(0xFFF59E0B),
    Color(0xFFD97706),
  ];

  static const List<Color> primaryGradient = [
    Color(0xFF16A34A),
    Color(0xFF22C55E),
  ];
}

// ─── Theme ───────────────────────────────────────────────────────────────────

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
        error: CR.red,
        onSurface: CR.text1,
        onPrimary: CR.textInv,
        onSecondary: CR.textInv,
        surfaceContainerHighest: CR.cardHigh,
      ),
      textTheme: _buildTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: CR.bg,
        foregroundColor: CR.text1,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: CR.text1,
          fontSize: 18,
          fontWeight: FontWeight.w600,
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
          foregroundColor: CR.textInv,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CR.white,
          side: const BorderSide(color: CR.white),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
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
        labelStyle: const TextStyle(color: CR.text2),
        hintStyle: const TextStyle(color: CR.text3),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: CR.cardHigh,
        selectedColor: CR.green.withOpacity(0.2),
        labelStyle: GoogleFonts.inter(
          color: CR.text1,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: CR.card,
        modalBackgroundColor: CR.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: CR.bg,
        selectedItemColor: CR.green,
        unselectedItemColor: CR.text3,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.spaceGrotesk(
        color: CR.text1,
        fontSize: 88,
        fontWeight: FontWeight.w800,
        height: 0.9,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        color: CR.text1,
        fontSize: 56,
        fontWeight: FontWeight.w700,
        height: 0.95,
      ),
      displaySmall: GoogleFonts.spaceGrotesk(
        color: CR.text1,
        fontSize: 40,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: GoogleFonts.inter(
        color: CR.text1,
        fontSize: 28,
        fontWeight: FontWeight.w800,
      ),
      headlineMedium: GoogleFonts.inter(
        color: CR.text1,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: GoogleFonts.inter(
        color: CR.text1,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: GoogleFonts.inter(
        color: CR.text1,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.inter(
        color: CR.text1,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: GoogleFonts.inter(
        color: CR.text2,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
      bodyLarge: GoogleFonts.inter(
        color: CR.text1,
        fontSize: 16,
      ),
      bodyMedium: GoogleFonts.inter(
        color: CR.text1,
        fontSize: 14,
      ),
      bodySmall: GoogleFonts.inter(
        color: CR.text2,
        fontSize: 12,
      ),
      labelLarge: GoogleFonts.inter(
        color: CR.text1,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
      labelMedium: GoogleFonts.inter(
        color: CR.text2,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
      labelSmall: GoogleFonts.inter(
        color: CR.text3,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.0,
      ),
    );
  }
}

// ─── Shared Widgets ──────────────────────────────────────────────────────────

/// Section header — uppercase, muted, letterSpaced, with green left accent bar
class CRSectionLabel extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry padding;

  const CRSectionLabel(this.text,
      {super.key, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 3,
            height: 12,
            decoration: BoxDecoration(
              color: CR.green,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text.toUpperCase(),
            style: GoogleFonts.inter(
              color: CR.text3,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cricket ball dot chip
class CRBallDot extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final double size;

  const CRBallDot({
    super.key,
    required this.label,
    required this.bgColor,
    this.textColor = CR.text1,
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

/// Stat badge pill
class CRBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const CRBadge(this.text,
      {super.key, this.color = CR.gold, this.icon});

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

/// Animated domain bar (BAT / BOWL / FIELD)
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
            style: GoogleFonts.inter(
              color: CR.text2,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            value.round().toString(),
            style: GoogleFonts.spaceGrotesk(
              color: CR.text1,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              return Stack(
                children: [
                  Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: CR.cardHigh,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: (value / 99) * animation.value,
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Card container — no border, background contrast only
class CRCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final VoidCallback? onTap;
  final double radius;

  const CRCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.onTap,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? CR.card,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }
}

// Keep for legacy compatibility — painters are no longer used but referenced
class SeamCurvePainter extends CustomPainter {
  final Color color;
  final double opacity;

  const SeamCurvePainter({
    this.color = CR.green,
    this.opacity = 0.04,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // No-op — seam decoration removed in new design
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

/// Role badge — active: filled tint + colored border; inactive: transparent with muted border
class CRRoleBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool active;
  final VoidCallback? onTap;

  const CRRoleBadge(
    this.label,
    this.color, {
    super.key,
    this.active = false,
    this.onTap,
  });

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
            color: active ? color.withOpacity(0.4) : CR.text3.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: active ? color : CR.text3,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
