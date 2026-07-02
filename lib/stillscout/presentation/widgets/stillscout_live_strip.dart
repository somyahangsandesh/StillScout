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
          return ClipRRect(
            borderRadius: BorderRadius.circular(StillScoutRadius.xs),
            child: Image.file(
              File(frame.filePath),
              width: 44,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 44,
                height: 72,
                color: StillScoutColors.slate,
              ),
            ),
          );
        },
      ),
    );
  }
}
