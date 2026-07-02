import 'package:flutter/material.dart';

import '../theme/stillscout_theme.dart';

/// Floating action bar shown once the creator long-presses into multi-select
/// mode in the gallery — batch export is the kind of "obviously useful"
/// feature creators expect once they realize they want more than one frame.
class StillScoutBatchExportBar extends StatelessWidget {
  const StillScoutBatchExportBar({
    super.key,
    required this.selectedCount,
    required this.isPro,
    required this.isBusy,
    required this.onSaveToGallery,
    required this.onShare,
    required this.onClear,
  });

  final int selectedCount;
  final bool isPro;
  final bool isBusy;
  final VoidCallback onSaveToGallery;
  final VoidCallback onShare;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          decoration: BoxDecoration(
            color: StillScoutColors.filmGray,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: StillScoutColors.accent.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: isBusy ? null : onClear,
                icon: const Icon(Icons.close_rounded, color: StillScoutColors.silver),
                tooltip: 'Clear selection',
              ),
              Expanded(
                child: Text(
                  '$selectedCount selected'
                  '${isPro ? '' : ' · uses $selectedCount export${selectedCount == 1 ? '' : 's'}'}',
                  style: StillScoutTextStyles.body.copyWith(color: StillScoutColors.chalk),
                ),
              ),
              if (isBusy)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else ...[
                IconButton(
                  onPressed: onShare,
                  icon: const Icon(Icons.ios_share_rounded, color: StillScoutColors.chalk),
                  tooltip: 'Share selected',
                ),
                FilledButton.icon(
                  onPressed: onSaveToGallery,
                  style: FilledButton.styleFrom(
                    backgroundColor: StillScoutColors.accent,
                    foregroundColor: StillScoutColors.voidBlack,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Save'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
