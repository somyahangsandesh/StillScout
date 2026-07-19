import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/stillscout_theme.dart';

typedef StillScoutSourceAction = void Function();

/// Cinematic import sheet — gallery vs camera with premium card layout.
class StillScoutSourceSheet extends StatefulWidget {
  const StillScoutSourceSheet({
    super.key,
    required this.onGallery,
    required this.onCamera,
  });

  final StillScoutSourceAction onGallery;
  final StillScoutSourceAction onCamera;

  static Future<void> show(
    BuildContext context, {
    required StillScoutSourceAction onGallery,
    required StillScoutSourceAction onCamera,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (_) => StillScoutSourceSheet(
        onGallery: onGallery,
        onCamera: onCamera,
      ),
    );
  }

  @override
  State<StillScoutSourceSheet> createState() => _StillScoutSourceSheetState();
}

class _StillScoutSourceSheetState extends State<StillScoutSourceSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _pick(VoidCallback action) {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            StillScoutSpacing.m,
            0,
            StillScoutSpacing.m,
            bottomInset + StillScoutSpacing.m,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(StillScoutRadius.xl),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: DecoratedBox(
                decoration: StillScoutDecorations.glassCard(
                  borderColor: StillScoutColors.accent.withValues(alpha: 0.28),
                ).copyWith(
                  borderRadius: BorderRadius.circular(StillScoutRadius.xl),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(StillScoutRadius.xl),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -StillScoutSpacing.xl,
                        right: -StillScoutSpacing.m,
                        child: Container(
                          width: StillScoutSpacing.xxl * 2.9,
                          height: StillScoutSpacing.xxl * 2.9,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                StillScoutColors.accent.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          StillScoutSpacing.m + 6,
                          StillScoutSpacing.s + 6,
                          StillScoutSpacing.m + 6,
                          StillScoutSpacing.m + 6,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width:
                                    StillScoutSpacing.xl + StillScoutSpacing.s,
                                height: StillScoutSpacing.xs,
                                margin: const EdgeInsets.only(
                                  bottom: StillScoutSpacing.m + 2,
                                ),
                                decoration: BoxDecoration(
                                  color: StillScoutColors.silver
                                      .withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(
                                      StillScoutRadius.xs),
                                ),
                              ),
                            ),
                            Text(
                              'Import footage',
                              style: StillScoutTextStyles.title
                                  .copyWith(fontSize: 22),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: StillScoutSpacing.xs + 2),
                            Text(
                              'Scout the sharpest, most expressive stills from any clip.',
                              style: StillScoutTextStyles.bodySmall.copyWith(
                                color: StillScoutColors.silver
                                    .withValues(alpha: 0.9),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: StillScoutSpacing.m + 6),
                            _SourceCard(
                              delayMs: 0,
                              icon: Icons.photo_library_rounded,
                              title: 'Choose from library',
                              subtitle: 'Any video up to 10 minutes',
                              badge: 'Most popular',
                              gradient: const [
                                Color(0xFF2A2418),
                                Color(0xFF16120E),
                              ],
                              accent: StillScoutColors.scoutGold,
                              onTap: () => _pick(widget.onGallery),
                            ),
                            const SizedBox(height: StillScoutSpacing.s + 4),
                            _SourceCard(
                              delayMs: 80,
                              icon: Icons.videocam_rounded,
                              title: 'Record new video',
                              subtitle: 'Shoot fresh footage up to 5 minutes',
                              badge: 'Live capture',
                              gradient: const [
                                Color(0xFF2E2418),
                                Color(0xFF17130E),
                              ],
                              accent: StillScoutColors.accent,
                              onTap: () => _pick(widget.onCamera),
                            ),
                            const SizedBox(height: StillScoutSpacing.s + 6),
                            Text(
                              'AI ranks blur, lighting, eyes & composition for you.',
                              style: StillScoutTextStyles.caption.copyWith(
                                color: StillScoutColors.silver
                                    .withValues(alpha: 0.65),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SourceCard extends StatefulWidget {
  const _SourceCard({
    required this.delayMs,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.gradient,
    required this.accent,
    required this.onTap,
  });

  final int delayMs;
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final List<Color> gradient;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_SourceCard> createState() => _SourceCardState();
}

class _SourceCardState extends State<_SourceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _scale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    Future<void>.delayed(Duration(milliseconds: widget.delayMs), () {
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
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Container(
            padding: StillScoutSpacing.cardPadding,
            decoration: BoxDecoration(
              borderRadius: StillScoutRadius.card,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.gradient,
              ),
              border: Border.all(
                color: widget.accent.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accent.withValues(alpha: 0.12),
                  blurRadius: StillScoutSpacing.m + 2,
                  offset: const Offset(0, StillScoutSpacing.s),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: StillScoutSpacing.xxl + 4,
                  height: StillScoutSpacing.xxl + 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.accent.withValues(alpha: 0.35),
                        widget.accent.withValues(alpha: 0.08),
                      ],
                    ),
                    border: Border.all(
                      color: widget.accent.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Icon(widget.icon, color: widget.accent, size: 26),
                ),
                const SizedBox(width: StillScoutSpacing.s + 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.title,
                              style: StillScoutTextStyles.subtitle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: StillScoutSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: StillScoutSpacing.s,
                              vertical: StillScoutSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: widget.accent.withValues(alpha: 0.14),
                              borderRadius: StillScoutRadius.badge,
                              border: Border.all(
                                color: widget.accent.withValues(alpha: 0.28),
                              ),
                            ),
                            child: Text(
                              widget.badge,
                              style: StillScoutTextStyles.label.copyWith(
                                color: widget.accent,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: StillScoutSpacing.xs),
                      Text(
                        widget.subtitle,
                        style: StillScoutTextStyles.caption.copyWith(
                          color:
                              StillScoutColors.silver.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: StillScoutSpacing.m,
                  color: widget.accent.withValues(alpha: 0.75),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
