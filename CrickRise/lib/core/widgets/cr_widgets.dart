import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Fade-in that runs once on mount — safe inside screens that rebuild often.
class CRFadeInOnce extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double slideY;

  const CRFadeInOnce({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 300),
    this.slideY = 0,
  });

  @override
  State<CRFadeInOnce> createState() => _CRFadeInOnceState();
}

class _CRFadeInOnceState extends State<CRFadeInOnce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.slideY),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Shows a brief full-screen milestone toast that auto-dismisses after 3 seconds.
/// Call this after key achievements (500 runs, first century, etc.).
void showMilestoneToast(
  BuildContext context,
  String emoji,
  String title,
  String subtitle,
) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: CR.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CR.gold.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48))
                .animate()
                .scale(
                    begin: const Offset(0, 0),
                    duration: 400.ms,
                    curve: Curves.elasticOut),
            const SizedBox(height: 12),
            Text(
              'MILESTONE',
              style: GoogleFonts.inter(
                color: CR.gold,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.inter(
                color: CR.t1,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(color: CR.t2, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
  Future.delayed(const Duration(seconds: 3), () {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  });
}

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
