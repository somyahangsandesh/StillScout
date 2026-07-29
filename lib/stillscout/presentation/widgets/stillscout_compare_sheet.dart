import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/models/scored_frame.dart';
import '../../domain/stillscout_access_policy.dart';
import '../../services/stillscout_compare_export.dart';
import '../theme/stillscout_theme.dart';
import 'stillscout_buttons.dart';
import 'stillscout_score_breakdown.dart';

/// Side-by-side frame comparison sheet.
///
/// Select exactly 2 frames in the gallery, then call [show] — it presents
/// a full-screen 2-up view with the same compact score grid as frame detail.
class StillScoutCompareSheet extends StatefulWidget {
  const StillScoutCompareSheet({
    super.key,
    required this.frameA,
    required this.frameB,
    this.isPro = true,
    this.rankA = 0,
    this.rankB = 1,
  });

  final ScoredFrame frameA;
  final ScoredFrame frameB;
  final bool isPro;
  final int rankA;
  final int rankB;

  static Future<void> show(
    BuildContext context, {
    required ScoredFrame frameA,
    required ScoredFrame frameB,
    bool isPro = true,
    int rankA = 0,
    int rankB = 1,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: StillScoutColors.voidBlack,
      shape: RoundedRectangleBorder(borderRadius: StillScoutRadius.sheet),
      useSafeArea: true,
      builder: (_) => StillScoutCompareSheet(
        frameA: frameA,
        frameB: frameB,
        isPro: isPro,
        rankA: rankA,
        rankB: rankB,
      ),
    );
  }

  @override
  State<StillScoutCompareSheet> createState() => _StillScoutCompareSheetState();
}

class _StillScoutCompareSheetState extends State<StillScoutCompareSheet> {
  bool _sharing = false;

  Future<void> _shareCompare() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final ok = await StillScoutCompareExport.shareSideBySide(
      frameA: widget.frameA,
      frameB: widget.frameB,
    );
    if (!mounted) return;
    setState(() => _sharing = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not share compare image.',
            style: StillScoutTextStyles.caption.copyWith(
              color: StillScoutColors.chalk,
            ),
          ),
          backgroundColor: StillScoutColors.slate,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) {
        return CustomScrollView(
          controller: scrollCtrl,
          slivers: [
            SliverToBoxAdapter(child: _buildHandle()),
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildImages()),
            SliverToBoxAdapter(child: _buildScoreRows()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  StillScoutSpacing.m,
                  0,
                  StillScoutSpacing.m,
                  StillScoutSpacing.m,
                ),
                child: StillScoutPrimaryButton(
                  label: 'Share compare image',
                  icon: Icons.ios_share_rounded,
                  isLoading: _sharing,
                  height: 52,
                  expand: true,
                  onPressed: _sharing ? null : _shareCompare,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: StillScoutSpacing.xxl)),
          ],
        );
      },
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: StillScoutSpacing.m),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: StillScoutColors.silver.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        StillScoutSpacing.m,
        StillScoutSpacing.m,
        StillScoutSpacing.m,
        StillScoutSpacing.s,
      ),
      child: Row(
        children: [
          const Icon(Icons.compare, color: StillScoutColors.accent, size: 20),
          const SizedBox(width: StillScoutSpacing.s),
          Text('Compare Frames', style: StillScoutTextStyles.subtitle),
          const Spacer(),
          _WinnerBadge(
            frameA: widget.frameA,
            frameB: widget.frameB,
          ),
        ],
      ),
    );
  }

  Widget _buildImages() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: StillScoutSpacing.m),
      child: Row(
        children: [
          Expanded(
            child: _FramePanel(
              frame: widget.frameA,
              label: 'A',
              rank: widget.rankA,
              isPro: widget.isPro,
            ),
          ),
          const SizedBox(width: StillScoutSpacing.s),
          Expanded(
            child: _FramePanel(
              frame: widget.frameB,
              label: 'B',
              rank: widget.rankB,
              isPro: widget.isPro,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRows() {
    return Padding(
      padding: const EdgeInsets.all(StillScoutSpacing.m),
      child: StillScoutCompareScoreGrid(
        sharpnessA: widget.frameA.metadata.blurScore,
        sharpnessB: widget.frameB.metadata.blurScore,
        lightingA: widget.frameA.metadata.lightingScore,
        lightingB: widget.frameB.metadata.lightingScore,
        openEyesA: widget.frameA.metadata.openEyesScore,
        openEyesB: widget.frameB.metadata.openEyesScore,
        compositionA: widget.frameA.metadata.compositionScore,
        compositionB: widget.frameB.metadata.compositionScore,
        overallA: widget.frameA.score,
        overallB: widget.frameB.score,
      ),
    );
  }
}

class _FramePanel extends StatelessWidget {
  const _FramePanel({
    required this.frame,
    required this.label,
    required this.rank,
    required this.isPro,
  });

  final ScoredFrame frame;
  final String label;
  final int rank;
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(StillScoutRadius.m),
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: Image.file(
              File(frame.frame.filePath),
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),
        ),
        const SizedBox(height: StillScoutSpacing.s),
        Row(
          children: [
            _LabelBadge(label: label),
            const SizedBox(width: StillScoutSpacing.xs),
        Text(
          StillScoutAccessPolicy.frameFooterLabel(
            rank: rank,
            isPro: isPro,
            formattedTimestamp: _formatTimestamp(frame.frame.timestampMs),
          ),
          style: StillScoutTextStyles.caption,
        ),
          ],
        ),
      ],
    );
  }

  static String _formatTimestamp(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    final rem = (s % 60).toString().padLeft(2, '0');
    return '$m:$rem';
  }
}

class _LabelBadge extends StatelessWidget {
  const _LabelBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: StillScoutColors.accent,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: StillScoutTextStyles.badge.copyWith(fontSize: 12),
      ),
    );
  }
}

class _WinnerBadge extends StatelessWidget {
  const _WinnerBadge({required this.frameA, required this.frameB});

  final ScoredFrame frameA;
  final ScoredFrame frameB;

  @override
  Widget build(BuildContext context) {
    if (frameA.score == frameB.score) {
      return const SizedBox.shrink();
    }
    final winner = frameA.score > frameB.score ? 'A' : 'B';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: StillScoutColors.scoutGold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(StillScoutRadius.pill),
        border: Border.all(
          color: StillScoutColors.scoutGold.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 12, color: StillScoutColors.scoutGold),
          const SizedBox(width: 4),
          Text(
            'Frame $winner wins',
            style: StillScoutTextStyles.badge.copyWith(
              color: StillScoutColors.scoutGold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

