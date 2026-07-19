import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/stillscout_theme.dart';

/// Shared press-scale + haptic behavior so Primary/Secondary buttons stay
/// visually distinct but feel identical to touch.
class _PressableButton extends StatefulWidget {
  const _PressableButton({
    required this.builder,
    this.onPressed,
    this.enabled = true,
  });

  final VoidCallback? onPressed;
  final Widget Function(BuildContext context) builder;
  final bool enabled;

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton> {
  double _scale = 1;

  bool get _canPress => widget.enabled && widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _canPress ? (_) => setState(() => _scale = 0.96) : null,
      onTapUp: _canPress ? (_) => setState(() => _scale = 1) : null,
      onTapCancel: _canPress ? () => setState(() => _scale = 1) : null,
      onTap: _canPress
          ? () {
              HapticFeedback.lightImpact();
              widget.onPressed!();
            }
          : null,
      child: AnimatedScale(
        scale: _scale,
        duration: StillScoutMotion.fast,
        curve: StillScoutMotion.toggle,
        child: widget.builder(context),
      ),
    );
  }
}

/// Primary call-to-action button — solid accent fill. Centralizes styling,
/// press-scale, haptic feedback, and loading state so every primary CTA
/// (Start Scout, Save Polished, etc.) behaves identically instead of each
/// screen inline-styling a `FilledButton`.
class StillScoutPrimaryButton extends StatelessWidget {
  const StillScoutPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 56,
    this.expand = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double height;
  final bool expand;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? StillScoutColors.accent;
    final fg = foregroundColor ?? StillScoutColors.voidBlack;
    final enabled = onPressed != null && !isLoading;
    return _PressableButton(
      enabled: enabled,
      onPressed: onPressed,
      builder: (context) => AnimatedOpacity(
        opacity: enabled ? 1 : 0.55,
        duration: StillScoutMotion.fast,
        child: Container(
          width: expand ? double.infinity : null,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: StillScoutRadius.card,
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: bg.withValues(alpha: 0.30),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: fg, size: 20),
                      const SizedBox(width: 10),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: StillScoutTextStyles.subtitle.copyWith(color: fg),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Secondary action button — outlined, used for lower-emphasis actions
/// (Share, "Pick a different video", etc.) alongside a primary CTA.
class StillScoutSecondaryButton extends StatelessWidget {
  const StillScoutSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 56,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double height;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor ?? StillScoutColors.chalk;
    final enabled = onPressed != null && !isLoading;
    return _PressableButton(
      enabled: enabled,
      onPressed: onPressed,
      builder: (context) => AnimatedOpacity(
        opacity: enabled ? 1 : 0.55,
        duration: StillScoutMotion.fast,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: StillScoutRadius.card,
            border: Border.all(
              color: StillScoutColors.silver.withValues(alpha: 0.4),
            ),
          ),
          alignment: Alignment.center,
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: fg, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: StillScoutTextStyles.subtitle
                            .copyWith(color: fg, fontSize: 15),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
