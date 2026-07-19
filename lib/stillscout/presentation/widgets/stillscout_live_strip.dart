import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/models/extracted_frame.dart';
import '../theme/stillscout_theme.dart';

class StillScoutLiveStrip extends StatelessWidget {
  const StillScoutLiveStrip({super.key, required this.frames});

  final List<ExtractedFrame> frames;

  @override
  Widget build(BuildContext context) {
    if (frames.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: StillScoutSpacing.m),
        reverse: true,
        itemCount: frames.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final frame = frames[i];
          // Keyed by frame id so each thumbnail's entrance animation plays
          // exactly once, even as the strip keeps growing during extraction.
          return _LiveStripThumbnail(key: ValueKey(frame.id), frame: frame);
        },
      ),
    );
  }
}

/// A single live-strip thumbnail that scales + fades in on first appearance.
class _LiveStripThumbnail extends StatefulWidget {
  const _LiveStripThumbnail({super.key, required this.frame});

  final ExtractedFrame frame;

  @override
  State<_LiveStripThumbnail> createState() => _LiveStripThumbnailState();
}

class _LiveStripThumbnailState extends State<_LiveStripThumbnail>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: StillScoutMotion.base,
  );
  late final Animation<double> _entrance = CurvedAnimation(
    parent: _controller,
    curve: StillScoutMotion.entrance,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _formatMs(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    final rem = (s % 60).toString().padLeft(2, '0');
    return m > 0 ? '${m}m ${rem}s' : '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Frame at ${_formatMs(widget.frame.timestampMs)}',
      child: FadeTransition(
        opacity: _entrance,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.72, end: 1.0).animate(_entrance),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(StillScoutRadius.xs),
            child: Image.file(
              File(widget.frame.filePath),
              width: 44,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 44,
                height: 72,
                color: StillScoutColors.slate,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
