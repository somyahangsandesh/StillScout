import 'package:flutter/material.dart';

import '../theme/stillscout_theme.dart';

/// Circular icon badge with a soft tinted glow — the same "hero" treatment
/// used for premium moments elsewhere in the app (paywall badge, completion
/// hero), reused here so full-screen status states (error/empty/cancelled)
/// don't look like an afterthought next to the rest of StillScout's polish.
class StillScoutStatusBadge extends StatelessWidget {
  const StillScoutStatusBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 72,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: size * 0.44),
    );
  }
}

/// Shared full-screen "status" layout for empty/error/cancelled states —
/// icon badge, title, body copy, and up to two actions — with a single
/// purposeful entrance animation (fade + rise) instead of each surface
/// re-implementing its own static `Column`.
class StillScoutStatusView extends StatefulWidget {
  const StillScoutStatusView({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    this.primaryLabel,
    this.onPrimary,
    this.primaryIcon,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final IconData? primaryIcon;

  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  State<StillScoutStatusView> createState() => _StillScoutStatusViewState();
}

class _StillScoutStatusViewState extends State<StillScoutStatusView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: StillScoutMotion.slow,
  )..forward();

  late final Animation<double> _fade =
      CurvedAnimation(parent: _ctrl, curve: StillScoutMotion.entrance);
  late final Animation<Offset> _rise = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ctrl, curve: StillScoutMotion.entrance));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(StillScoutSpacing.xl),
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _rise,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StillScoutStatusBadge(icon: widget.icon, color: widget.iconColor),
                const SizedBox(height: StillScoutSpacing.l),
                Text(
                  widget.title,
                  style: StillScoutTextStyles.title,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: StillScoutSpacing.s),
                Text(
                  widget.body,
                  style: StillScoutTextStyles.body,
                  textAlign: TextAlign.center,
                ),
                if (widget.primaryLabel != null) ...[
                  const SizedBox(height: StillScoutSpacing.l),
                  Semantics(
                    label: widget.primaryLabel,
                    button: true,
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: widget.onPrimary,
                        icon: widget.primaryIcon == null
                            ? const SizedBox.shrink()
                            : Icon(widget.primaryIcon, size: 18),
                        label: Text(widget.primaryLabel!),
                        style: FilledButton.styleFrom(
                          backgroundColor: StillScoutColors.accent,
                          foregroundColor: StillScoutColors.voidBlack,
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: StillScoutRadius.card,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (widget.secondaryLabel != null) ...[
                  const SizedBox(height: StillScoutSpacing.s),
                  Semantics(
                    label: widget.secondaryLabel,
                    button: true,
                    child: TextButton(
                      onPressed: widget.onSecondary,
                      style: TextButton.styleFrom(
                        foregroundColor:
                            StillScoutColors.silver.withValues(alpha: 0.85),
                        minimumSize: const Size(44, 44),
                      ),
                      child: Text(widget.secondaryLabel!),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
