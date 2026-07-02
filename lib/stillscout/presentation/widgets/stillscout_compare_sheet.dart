import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/models/scored_frame.dart';
import '../../domain/stillscout_access_policy.dart';
import '../theme/stillscout_theme.dart';

/// Side-by-side frame comparison sheet.
///
/// Select exactly 2 frames in the gallery, then call [show] — it presents
/// a full-screen 2-up view with synced score bars so the creator can see
/// at a glance which take is technically better without eyeballing numbers.
class StillScoutCompareSheet extends StatelessWidget {
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
            frameA: frameA,
            frameB: frameB,
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
          Expanded(child: _FramePanel(frame: frameA, label: 'A', rank: rankA, isPro: isPro)),
          const SizedBox(width: StillScoutSpacing.s),
          Expanded(child: _FramePanel(frame: frameB, label: 'B', rank: rankB, isPro: isPro)),
        ],
      ),
    );
  }

  Widget _buildScoreRows() {
    return Padding(
      padding: const EdgeInsets.all(StillScoutSpacing.m),
      child: Container(
        padding: const EdgeInsets.all(StillScoutSpacing.m),
        decoration: StillScoutDecorations.surfaceCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score Breakdown', style: StillScoutTextStyles.subtitle),
            const SizedBox(height: StillScoutSpacing.m),
            _ScoreRow('Sharpness', frameA.metadata.blurScore, frameB.metadata.blurScore),
            const SizedBox(height: StillScoutSpacing.s),
            _ScoreRow('Lighting', frameA.metadata.lightingScore, frameB.metadata.lightingScore),
            const SizedBox(height: StillScoutSpacing.s),
            _ScoreRow('Open Eyes', frameA.metadata.openEyesScore, frameB.metadata.openEyesScore),
            const SizedBox(height: StillScoutSpacing.s),
            _ScoreRow('Composition', frameA.metadata.compositionScore, frameB.metadata.compositionScore),
            const SizedBox(height: StillScoutSpacing.m),
            const Divider(color: StillScoutColors.slate, height: 1),
            const SizedBox(height: StillScoutSpacing.m),
            _ScoreRow('Overall', frameA.score, frameB.score, isTotal: true),
          ],
        ),
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

class _ScoreRow extends StatelessWidget {
  const _ScoreRow(this.label, this.scoreA, this.scoreB, {this.isTotal = false});

  final String label;
  final int scoreA;
  final int scoreB;
  final bool isTotal;

  Color _barColor(int score, int other) {
    if (score > other) return StillScoutColors.accent;
    if (score < other) return StillScoutColors.silver;
    return StillScoutColors.silver;
  }

  @override
  Widget build(BuildContext context) {
    final aStyle = isTotal
        ? StillScoutTextStyles.subtitle.copyWith(fontSize: 17)
        : StillScoutTextStyles.body;
    final bStyle = aStyle;

    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(label, style: StillScoutTextStyles.caption),
        ),
        Expanded(
          child: _ScoreBar(
            score: scoreA,
            color: _barColor(scoreA, scoreB),
            alignment: Alignment.centerRight,
          ),
        ),
        const SizedBox(width: StillScoutSpacing.s),
        Text('$scoreA', style: aStyle),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: StillScoutSpacing.xs),
          child: Text('·', style: StillScoutTextStyles.caption),
        ),
        Text('$scoreB', style: bStyle),
        const SizedBox(width: StillScoutSpacing.s),
        Expanded(
          child: _ScoreBar(
            score: scoreB,
            color: _barColor(scoreB, scoreA),
            alignment: Alignment.centerLeft,
          ),
        ),
      ],
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({
    required this.score,
    required this.color,
    required this.alignment,
  });

  final int score;
  final Color color;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth * (score / 100);
        return Stack(
          alignment: alignment,
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: StillScoutColors.slateLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Align(
              alignment: alignment,
              child: Container(
                width: width,
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
