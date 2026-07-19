import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/stillscout_theme.dart';

/// Keys used to track which coach marks have already been shown.
abstract final class StillScoutCoachMarkKeys {
  static const contextChips = 'coach_context_chips';
  static const scoreBadge = 'coach_score_badge';
}

/// Manages one-time coach-mark display via SharedPreferences.
///
/// Usage:
/// ```dart
/// final tracker = StillScoutCoachMarkTracker();
/// if (await tracker.shouldShow(StillScoutCoachMarkKeys.contextChips)) {
///   _showContextChipsCoachMark(context);
///   await tracker.markShown(StillScoutCoachMarkKeys.contextChips);
/// }
/// ```
class StillScoutCoachMarkTracker {
  Future<bool> shouldShow(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(key) ?? false);
  }

  Future<void> markShown(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
  }

  /// Resets all coach marks (useful for testing / debug).
  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StillScoutCoachMarkKeys.contextChips);
    await prefs.remove(StillScoutCoachMarkKeys.scoreBadge);
  }
}

/// A dismissible one-time coach-mark overlay.
///
/// Wrap the target widget with [StillScoutCoachMark] and supply a [message].
/// On first display (tracked externally via [StillScoutCoachMarkTracker]) it
/// draws a gold tooltip arrow + message atop everything. Tap anywhere to dismiss.
class StillScoutCoachMark extends StatefulWidget {
  const StillScoutCoachMark({
    super.key,
    required this.child,
    required this.message,
    required this.visible,
    required this.onDismiss,
    this.preferBelow = true,
  });

  final Widget child;
  final String message;
  final bool visible;
  final VoidCallback onDismiss;

  /// If true, the tooltip arm points upward (mark appears below target).
  final bool preferBelow;

  @override
  State<StillScoutCoachMark> createState() => _StillScoutCoachMarkState();
}

class _StillScoutCoachMarkState extends State<StillScoutCoachMark>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _entry;
  late AnimationController _ctrl;
  late Animation<double> _fade;
  final _targetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    if (widget.visible) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _show());
    }
  }

  @override
  void didUpdateWidget(StillScoutCoachMark old) {
    super.didUpdateWidget(old);
    if (!old.visible && widget.visible) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _show());
    } else if (old.visible && !widget.visible) {
      _hide();
    }
  }

  void _show() {
    if (_entry != null) return;
    final box = _targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);
    final size = box.size;

    _entry = OverlayEntry(
      builder: (_) => FadeTransition(
        opacity: _fade,
        child: _CoachMarkOverlay(
          targetRect: pos & size,
          message: widget.message,
          preferBelow: widget.preferBelow,
          onDismiss: () {
            _hide();
            widget.onDismiss();
          },
        ),
      ),
    );
    Overlay.of(context).insert(_entry!);
    _ctrl.forward();
  }

  void _hide() {
    _ctrl.reverse().then((_) {
      _entry?.remove();
      _entry = null;
    });
  }

  @override
  void dispose() {
    _entry?.remove();
    _entry = null;
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _targetKey, child: widget.child);
  }
}

class _CoachMarkOverlay extends StatelessWidget {
  const _CoachMarkOverlay({
    required this.targetRect,
    required this.message,
    required this.preferBelow,
    required this.onDismiss,
  });

  final Rect targetRect;
  final String message;
  final bool preferBelow;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    // Position the tip above or below the target.
    final tipY = preferBelow
        ? targetRect.bottom + 10
        : targetRect.top - 10 - 80; // rough height
    final tipX = (targetRect.left + targetRect.right) / 2;
    final bubbleX = (tipX - 100).clamp(16.0, screen.width - 216.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onDismiss,
      child: Stack(
        children: [
          // Semi-transparent scrim.
          Container(color: Colors.black.withValues(alpha: 0.45)),
          // Clear spotlight around target.
          Positioned.fromRect(
            rect: targetRect.inflate(6),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: StillScoutColors.scoutGold.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
            ),
          ),
          // Tooltip bubble.
          Positioned(
            top: tipY,
            left: bubbleX,
            width: 200,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: StillScoutSpacing.m,
                  vertical: StillScoutSpacing.s,
                ),
                decoration: BoxDecoration(
                  color: StillScoutColors.scoutGold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  message,
                  style: StillScoutTextStyles.caption.copyWith(
                    color: StillScoutColors.voidBlack,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          // "Tap to dismiss" hint.
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Tap anywhere to dismiss',
                style: StillScoutTextStyles.caption.copyWith(
                  color: StillScoutColors.silver.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
