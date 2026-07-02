import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens for StillScout's cinematic photography aesthetic.
///
/// All spacing, radius, and elevation values are derived from a base-8 grid.
/// Use these constants rather than sprinkling magic numbers across widgets —
/// that's how ad hoc `12/14/16/18/20/24` scatter accumulates.
class StillScoutColors {
  StillScoutColors._();

  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const Color voidBlack = Color(0xFF050505);
  static const Color filmGray = Color(0xFF121212);
  static const Color slate = Color(0xFF1C1C1E);
  static const Color slateLight = Color(0xFF2C2C2E);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color silver = Color(0xFF8E8E93);
  static const Color chalk = Color(0xFFF2F2F7);

  // ── Brand / Accent ───────────────────────────────────────────────────────
  static const Color accent = Color(0xFFE8C97A);
  static const Color accentGlow = Color(0x66E8C97A);
  static const Color accentDim = Color(0x1AE8C97A);
  static const Color scoutGold = Color(0xFFFFD60A);

  // ── Status ───────────────────────────────────────────────────────────────
  static const Color danger = Color(0xFFFF453A);
  static const Color success = Color(0xFF30D158);

  // ── Rank podium ──────────────────────────────────────────────────────────
  static const Color rankGold = scoutGold;
  static const Color rankSilver = Color(0xFFD9D9DF);
  static const Color rankBronze = Color(0xFFCD8E5A);

  // ── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient vignette = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A0A0A), Color(0xFF050505), Color(0xFF000000)],
  );

  static const LinearGradient frameShadow = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [Color(0xCC000000), Colors.transparent],
  );

  static BoxShadow goldGlow({double alpha = 0.35, double blur = 18}) =>
      BoxShadow(
        color: scoutGold.withValues(alpha: alpha),
        blurRadius: blur,
        spreadRadius: 1,
      );
}

/// Base-8 spacing scale.
class StillScoutSpacing {
  StillScoutSpacing._();

  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: m);

  static const EdgeInsets cardPadding =
      EdgeInsets.all(m);

  static const EdgeInsets tileOverlay =
      EdgeInsets.fromLTRB(s, l, s, s);
}

/// Consistent radius scale.
class StillScoutRadius {
  StillScoutRadius._();

  static const double xs = 4;
  static const double s = 8;
  static const double m = 14;
  static const double l = 18;
  static const double xl = 24;
  static const double pill = 100;

  static BorderRadius card = BorderRadius.circular(l);
  static BorderRadius tile = BorderRadius.circular(m);
  static BorderRadius chip = BorderRadius.circular(s);
  static BorderRadius badge = BorderRadius.circular(pill);
  static BorderRadius sheet =
      const BorderRadius.vertical(top: Radius.circular(xl));
}

class StillScoutTextStyles {
  StillScoutTextStyles._();

  static TextStyle get display => GoogleFonts.bebasNeue(
        fontSize: 42,
        letterSpacing: 4,
        color: StillScoutColors.chalk,
        height: 1.0,
      );

  static TextStyle get title => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: StillScoutColors.chalk,
        letterSpacing: -0.3,
      );

  static TextStyle get subtitle => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: StillScoutColors.chalk,
        letterSpacing: -0.2,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: StillScoutColors.silver,
        height: 1.45,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: StillScoutColors.silver,
        height: 1.4,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: StillScoutColors.silver,
        letterSpacing: 0.2,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: StillScoutColors.silver,
        letterSpacing: 0.5,
      );

  static TextStyle get badge => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: StillScoutColors.voidBlack,
        letterSpacing: 0.6,
      );

  static TextStyle get numeric => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: StillScoutColors.accent,
        letterSpacing: -0.5,
      );
}

/// Re-usable card decoration to avoid copy-paste across widgets.
class StillScoutDecorations {
  StillScoutDecorations._();

  static BoxDecoration surfaceCard({
    Color? borderColor,
    double borderWidth = 1,
  }) =>
      BoxDecoration(
        color: StillScoutColors.filmGray,
        borderRadius: StillScoutRadius.card,
        border: Border.all(
          color: borderColor ??
              StillScoutColors.accent.withValues(alpha: 0.2),
          width: borderWidth,
        ),
      );

  static BoxDecoration tileSelected = BoxDecoration(
    borderRadius: StillScoutRadius.tile,
    border: Border.all(color: StillScoutColors.accent, width: 2.5),
  );

  static BoxDecoration tileTopScout = BoxDecoration(
    borderRadius: StillScoutRadius.tile,
    border: Border.all(color: StillScoutColors.scoutGold, width: 2.5),
    boxShadow: [StillScoutColors.goldGlow()],
  );

  static BoxDecoration glassCard({
    Color? borderColor,
    double borderWidth = 1,
  }) =>
      BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            StillScoutColors.slate.withValues(alpha: 0.72),
            StillScoutColors.filmGray.withValues(alpha: 0.88),
          ],
        ),
        borderRadius: StillScoutRadius.card,
        border: Border.all(
          color: borderColor ??
              StillScoutColors.accent.withValues(alpha: 0.28),
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: StillScoutColors.accent.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static Widget rankBadge(int rank) {
    final (color, label) = switch (rank) {
      0 => (StillScoutColors.rankGold, '#1'),
      1 => (StillScoutColors.rankSilver, '#2'),
      2 => (StillScoutColors.rankBronze, '#3'),
      _ => (StillScoutColors.silver, '#${rank + 1}'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        label,
        style: StillScoutTextStyles.badge.copyWith(
          color: StillScoutColors.voidBlack,
          fontSize: 10,
        ),
      ),
    );
  }
}
