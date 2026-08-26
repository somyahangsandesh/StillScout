import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

// Shared cricket stat display — value in Space Grotesk, label in Inter uppercase
class CRStatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final double valueFontSize;

  const CRStatCell({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueFontSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: valueColor ?? CR.t1,
            fontSize: valueFontSize,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            color: CR.t3,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

// Cricket ball dot chip — used in scorer recent-balls row and live match views
class CRBallChip extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final double size;

  const CRBallChip({
    super.key,
    required this.label,
    required this.bgColor,
    this.textColor = CR.t1,
    this.size = 34,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: CR.cardHigh, width: 1),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            color: textColor,
            fontSize: size * 0.35,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// Compact info row — emoji · label · value (used in innings transition, awards, etc.)
class CRInfoRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const CRInfoRow({
    super.key,
    required this.emoji,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(color: CR.t2, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: CR.t1,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
