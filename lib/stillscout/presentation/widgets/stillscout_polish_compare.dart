import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/stillscout_theme.dart';
import 'stillscout_glass_surface.dart';

/// Rotating micro-copy shown while Auto Polish is processing, cycled on a
/// fixed interval for the duration of the async polish call (no progress
/// estimate is available from the polish service to time these against).
const List<String> _kPolishPhrases = [
  'Balancing exposure…',
  'Sharpening details…',
  'Perfecting tones…',
  'Enhancing clarity…',
];

/// Orchestrates the Auto Polish preview lifecycle: the shimmering loading
/// state, a one-time wipe-reveal into the before/after compare slider once a
/// polished result lands, and the plain-image fallback when polish yields no
/// usable result. Centralizing this here (rather than in the detail sheet)
/// keeps the reveal animation next to the widgets it choreographs and keeps
/// `stillscout_frame_detail_sheet.dart` free of animation bookkeeping.
class StillScoutPolishStage extends StatefulWidget {
  const StillScoutPolishStage({
    super.key,
    required this.imagePath,
    required this.isLoading,
    required this.polishedPath,
  });

  /// The original (source) frame path.
  final String imagePath;

  /// Whether `StillScoutAutoPolish.polishWithFaceDetection` is in flight.
  final bool isLoading;

  /// The polished result path once available, or null while loading / if
  /// polish produced no usable result.
  final String? polishedPath;

  @override
  State<StillScoutPolishStage> createState() => _StillScoutPolishStageState();
}

class _StillScoutPolishStageState extends State<StillScoutPolishStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _revealController;
  late final Animation<double> _reveal;
  bool _hasRevealed = false;

  bool get _polishedReady =>
      widget.polishedPath != null && widget.polishedPath != widget.imagePath;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: StillScoutMotion.slow,
    );
    _reveal = CurvedAnimation(
      parent: _revealController,
      curve: StillScoutMotion.entrance,
    );
    if (!widget.isLoading) {
      // Already resolved on first build (e.g. cached) — show without
      // replaying the reveal animation.
      _revealController.value = 1;
      _hasRevealed = true;
    }
  }

  @override
  void didUpdateWidget(covariant StillScoutPolishStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final startedNewLoad = widget.imagePath != oldWidget.imagePath ||
        (widget.isLoading && !oldWidget.isLoading);
    if (startedNewLoad) {
      _hasRevealed = false;
      _revealController.value = 0;
      return;
    }
    final justFinishedLoading = !widget.isLoading && oldWidget.isLoading;
    if (justFinishedLoading && !_hasRevealed) {
      _hasRevealed = true;
      if (_polishedReady) {
        HapticFeedback.lightImpact();
        _revealController.forward(from: 0);
      } else {
        _revealController.value = 1;
      }
    }
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  Widget _buildBase() {
    if (_polishedReady) {
      return StillScoutPolishCompare(
        beforePath: widget.imagePath,
        afterPath: widget.polishedPath!,
      );
    }
    return ClipRRect(
      borderRadius: StillScoutRadius.card,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Image.file(
          File(widget.imagePath),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _reveal,
      builder: (context, _) {
        final progress = _reveal.value;
        final showOverlay = widget.isLoading || progress < 1;
        return ClipRRect(
          borderRadius: StillScoutRadius.card,
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildBase(),
                if (showOverlay)
                  ClipRect(
                    clipper: _RevealMaskClipper(revealed: progress),
                    child: Opacity(
                      opacity: (1 - progress).clamp(0.0, 1.0),
                      child: StillScoutPolishLoadingPreview(
                        imagePath: widget.imagePath,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Clips the polishing overlay to the region right of `revealed * width`, so
/// as the reveal animation progresses the overlay appears to wipe away
/// left-to-right, uncovering the polished result beneath.
class _RevealMaskClipper extends CustomClipper<Rect> {
  _RevealMaskClipper({required this.revealed});

  final double revealed;

  @override
  Rect getClip(Size size) {
    final clamped = revealed.clamp(0.0, 1.0);
    final left = size.width * clamped;
    return Rect.fromLTWH(left, 0, size.width - left, size.height);
  }

  @override
  bool shouldReclip(_RevealMaskClipper oldClipper) =>
      oldClipper.revealed != revealed;
}

/// Before/after slider for the Auto Polish preview in frame detail.
class StillScoutPolishCompare extends StatefulWidget {
  const StillScoutPolishCompare({
    super.key,
    required this.beforePath,
    required this.afterPath,
  });

  final String beforePath;
  final String afterPath;

  @override
  State<StillScoutPolishCompare> createState() =>
      _StillScoutPolishCompareState();
}

class _StillScoutPolishCompareState extends State<StillScoutPolishCompare> {
  double _split = 0.5;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final handleX = (width * _split).clamp(0.0, width);

        return ClipRRect(
          borderRadius: StillScoutRadius.card,
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                Image.file(
                  File(widget.afterPath),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
                ClipRect(
                  clipper: _LeftClipper(fraction: _split),
                  child: Image.file(
                    File(widget.beforePath),
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                ),
                Positioned(
                  left: handleX - 1,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: StillScoutColors.accent.withValues(alpha: 0.95),
                      boxShadow: [
                        BoxShadow(
                          color: StillScoutColors.accent.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: (handleX - 16).clamp(0.0, width - 32),
                  top: 0,
                  bottom: 0,
                  width: 32,
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color:
                            StillScoutColors.voidBlack.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: StillScoutColors.accent,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                StillScoutColors.accent.withValues(alpha: 0.4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.compare_arrows_rounded,
                        size: 16,
                        color: StillScoutColors.accent,
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  left: 12,
                  top: 12,
                  child: _Pill(label: 'Original'),
                ),
                const Positioned(
                  right: 12,
                  top: 12,
                  child: _Pill(
                    label: 'Polished',
                    accent: true,
                  ),
                ),
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragUpdate: (d) {
                      setState(() {
                        _split = (_split + d.delta.dx / width).clamp(0.0, 1.0);
                      });
                    },
                    onTapDown: (d) {
                      setState(() {
                        _split = (d.localPosition.dx / width).clamp(0.0, 1.0);
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LeftClipper extends CustomClipper<Rect> {
  _LeftClipper({required this.fraction});

  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_LeftClipper oldClipper) => oldClipper.fraction != fraction;
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.accent = false});

  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return StillScoutGlassSurface(
      blurSigma: 12,
      borderRadius: BorderRadius.circular(StillScoutRadius.pill),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      borderColor: accent
          ? StillScoutColors.accent.withValues(alpha: 0.7)
          : StillScoutColors.silver.withValues(alpha: 0.5),
      child: Text(
        label,
        style: StillScoutTextStyles.badge.copyWith(
          color: accent ? StillScoutColors.accent : StillScoutColors.chalk,
          fontSize: 10,
        ),
      ),
    );
  }
}

/// Loading placeholder while polish renders off the UI thread: a diagonal
/// gradient sweep plays across the dimmed image, with rotating micro-copy
/// cross-fading beneath the spinner so the wait reads as active work rather
/// than a stalled spinner.
class StillScoutPolishLoadingPreview extends StatefulWidget {
  const StillScoutPolishLoadingPreview({super.key, required this.imagePath});

  final String imagePath;

  @override
  State<StillScoutPolishLoadingPreview> createState() =>
      _StillScoutPolishLoadingPreviewState();
}

class _StillScoutPolishLoadingPreviewState
    extends State<StillScoutPolishLoadingPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweepController;
  Timer? _captionTimer;
  int _captionIndex = 0;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _captionTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (!mounted) return;
      setState(
          () => _captionIndex = (_captionIndex + 1) % _kPolishPhrases.length);
    });
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _captionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: StillScoutRadius.card,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(widget.imagePath),
              fit: BoxFit.cover,
              color: StillScoutColors.voidBlack.withValues(alpha: 0.4),
              colorBlendMode: BlendMode.darken,
            ),
            AnimatedBuilder(
              animation: _sweepController,
              builder: (context, _) {
                // The band travels fully off-screen at both ends of the
                // loop (t spans roughly -1.3..1.3), so the abrupt reset from
                // repeat() is invisible — the sweep reads as a continuous
                // diagonal pass rather than a jump-cut.
                final t = _sweepController.value * 2.6 - 0.8;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(t - 0.5, -1),
                      end: Alignment(t + 0.5, 1),
                      colors: [
                        Colors.transparent,
                        StillScoutColors.chalk.withValues(alpha: 0.16),
                        Colors.transparent,
                      ],
                      stops: const [0.35, 0.5, 0.65],
                    ),
                  ),
                );
              },
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: StillScoutColors.accent,
                    ),
                  ),
                  const SizedBox(height: StillScoutSpacing.m),
                  SizedBox(
                    height: 18,
                    child: AnimatedSwitcher(
                      duration: StillScoutMotion.base,
                      switchInCurve: StillScoutMotion.entrance,
                      switchOutCurve: StillScoutMotion.entrance,
                      child: Text(
                        _kPolishPhrases[_captionIndex],
                        key: ValueKey(_captionIndex),
                        style: StillScoutTextStyles.caption.copyWith(
                          color: StillScoutColors.chalk,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
