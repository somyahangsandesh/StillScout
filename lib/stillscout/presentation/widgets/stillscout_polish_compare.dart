import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/stillscout_theme.dart';

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
  State<StillScoutPolishCompare> createState() => _StillScoutPolishCompareState();
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
          borderRadius: BorderRadius.circular(18),
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
                    color: StillScoutColors.chalk.withValues(alpha: 0.95),
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
                        color: StillScoutColors.voidBlack.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                        border: Border.all(color: StillScoutColors.chalk),
                      ),
                      child: const Icon(
                        Icons.compare_arrows_rounded,
                        size: 16,
                        color: StillScoutColors.chalk,
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
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_LeftClipper oldClipper) => oldClipper.fraction != fraction;
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.accent = false});

  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: StillScoutColors.voidBlack.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent
              ? StillScoutColors.accent.withValues(alpha: 0.7)
              : StillScoutColors.silver.withValues(alpha: 0.5),
        ),
      ),
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

/// Shimmer placeholder while polish renders off the UI thread.
class StillScoutPolishLoadingPreview extends StatelessWidget {
  const StillScoutPolishLoadingPreview({super.key, required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              color: StillScoutColors.voidBlack.withValues(alpha: 0.35),
              colorBlendMode: BlendMode.darken,
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
                  const SizedBox(height: 12),
                  Text(
                    'Polishing…',
                    style: StillScoutTextStyles.caption.copyWith(
                      color: StillScoutColors.chalk,
                      fontWeight: FontWeight.w600,
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
