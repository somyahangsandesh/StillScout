import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../theme/stillscout_theme.dart';

enum StillScoutCropRatio { original, nineSixteen, oneOne, fourFive }

extension StillScoutCropRatioExt on StillScoutCropRatio {
  String get label => switch (this) {
        StillScoutCropRatio.original => 'Original',
        StillScoutCropRatio.nineSixteen => '9:16',
        StillScoutCropRatio.oneOne => '1:1',
        StillScoutCropRatio.fourFive => '4:5',
      };

  String get sublabel => switch (this) {
        StillScoutCropRatio.original => 'Keep full frame',
        StillScoutCropRatio.nineSixteen => 'TikTok · Reels',
        StillScoutCropRatio.oneOne => 'Instagram square',
        StillScoutCropRatio.fourFive => 'Instagram portrait',
      };

  double? get ratio => switch (this) {
        StillScoutCropRatio.original => null,
        StillScoutCropRatio.nineSixteen => 9 / 16,
        StillScoutCropRatio.oneOne => 1.0,
        StillScoutCropRatio.fourFive => 4 / 5,
      };
}

/// Bottom sheet for choosing an export crop ratio before saving/sharing.
class StillScoutCropPicker extends StatelessWidget {
  const StillScoutCropPicker({
    super.key,
    required this.imagePath,
    required this.onSelected,
  });

  final String imagePath;
  final ValueChanged<StillScoutCropRatio> onSelected;

  static Future<StillScoutCropRatio?> show(
    BuildContext context, {
    required String imagePath,
  }) {
    return showModalBottomSheet<StillScoutCropRatio>(
      context: context,
      isScrollControlled: true,
      backgroundColor: StillScoutColors.filmGray,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(StillScoutRadius.xl),
        ),
      ),
      builder: (ctx) => StillScoutCropPicker(
        imagePath: imagePath,
        onSelected: (ratio) => Navigator.pop(ctx, ratio),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            StillScoutSpacing.m,
            StillScoutSpacing.s,
            StillScoutSpacing.m,
            StillScoutSpacing.m + bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: StillScoutColors.silver.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: StillScoutSpacing.m),
            Text('Choose crop', style: StillScoutTextStyles.subtitle),
            const SizedBox(height: StillScoutSpacing.s),
            Text(
              'Pick an aspect ratio for export.',
              style: StillScoutTextStyles.body,
            ),
            const SizedBox(height: StillScoutSpacing.m),
            ...StillScoutCropRatio.values.map(
              (ratio) => _CropOptionTile(
                ratio: ratio,
                imagePath: imagePath,
                onTap: () => onSelected(ratio),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CropOptionTile extends StatelessWidget {
  const _CropOptionTile({
    required this.ratio,
    required this.imagePath,
    required this.onTap,
  });

  final StillScoutCropRatio ratio;
  final String imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: StillScoutSpacing.s),
      child: Material(
        color: StillScoutColors.slate,
        borderRadius: BorderRadius.circular(StillScoutRadius.m),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(StillScoutRadius.m),
          child: Padding(
            padding: const EdgeInsets.all(StillScoutSpacing.s),
            child: Row(
              children: [
                _CropPreview(imagePath: imagePath, ratio: ratio.ratio),
                const SizedBox(width: StillScoutSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ratio.label, style: StillScoutTextStyles.title.copyWith(fontSize: 16)),
                      Text(ratio.sublabel, style: StillScoutTextStyles.caption),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: StillScoutColors.silver),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CropPreview extends StatelessWidget {
  const _CropPreview({required this.imagePath, required this.ratio});

  final String imagePath;
  final double? ratio;

  @override
  Widget build(BuildContext context) {
    const previewW = 36.0;
    final previewH = ratio == null ? 48.0 : previewW / ratio!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(StillScoutRadius.xs),
      child: SizedBox(
        width: previewW,
        height: previewH.clamp(36, 56),
        child: Image.file(
          File(imagePath),
          fit: ratio == null ? BoxFit.cover : BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}

img.Image centerCropImage(img.Image src, double targetRatio) {
  final srcRatio = src.width / src.height;
  int cropW;
  int cropH;
  if (srcRatio > targetRatio) {
    cropH = src.height;
    cropW = (src.height * targetRatio).round();
  } else {
    cropW = src.width;
    cropH = (src.width / targetRatio).round();
  }
  final x = (src.width - cropW) ~/ 2;
  final y = (src.height - cropH) ~/ 2;
  return img.copyCrop(src, x: x, y: y, width: cropW, height: cropH);
}
