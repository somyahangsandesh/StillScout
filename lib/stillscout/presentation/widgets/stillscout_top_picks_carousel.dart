import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/models/scored_frame.dart';
import '../../domain/stillscout_access_policy.dart';
import '../theme/stillscout_theme.dart';

class StillScoutTopPicksCarousel extends StatelessWidget {
  const StillScoutTopPicksCarousel({
    super.key,
    required this.frames,
    required this.onFrameTap,
    required this.isPro,
    required this.rankFor,
  });

  final List<ScoredFrame> frames;
  final void Function(ScoredFrame frame) onFrameTap;
  final bool isPro;
  final int Function(ScoredFrame frame) rankFor;

  @override
  Widget build(BuildContext context) {
    final topPicks = frames.take(3).toList(growable: false);
    if (topPicks.isEmpty) return const SizedBox.shrink();

    final carouselHeight = MediaQuery.sizeOf(context).width < 360 ? 220.0 : 240.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        StillScoutSpacing.m,
        StillScoutSpacing.xs,
        StillScoutSpacing.m,
        StillScoutSpacing.l + 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                size: 18,
                color: StillScoutColors.scoutGold,
              ),
              const SizedBox(width: StillScoutSpacing.s),
              Text('Top Picks', style: StillScoutTextStyles.title),
            ],
          ),
          const SizedBox(height: StillScoutSpacing.xs),
          Text(
            'Our scout\'s confident calls — the best shots, ranked.',
            style: StillScoutTextStyles.caption,
          ),
          const SizedBox(height: StillScoutSpacing.m),
          SizedBox(
            height: carouselHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: topPicks.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: StillScoutSpacing.s + 6),
              itemBuilder: (context, index) {
                final frame = topPicks[index];
                final rank = rankFor(frame);
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 380 + index * 90),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.9 + (value * 0.1),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: _PodiumCard(
                    rank: rank + 1,
                    frame: frame,
                    isPro: isPro,
                    displayRank: rank,
                    onTap: () => onFrameTap(frame),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({
    required this.rank,
    required this.frame,
    required this.onTap,
    required this.isPro,
    required this.displayRank,
  });

  final int rank;
  final ScoredFrame frame;
  final VoidCallback onTap;
  final bool isPro;
  final int displayRank;

  static const _rankColors = {
    1: StillScoutColors.rankGold,
    2: StillScoutColors.rankSilver,
    3: StillScoutColors.rankBronze,
  };

  @override
  Widget build(BuildContext context) {
    final rankColor = _rankColors[rank] ?? StillScoutColors.silver;
    final width = rank == 1 ? 168.0 : 150.0;
    final footer = StillScoutAccessPolicy.frameFooterLabel(
      rank: displayRank,
      isPro: isPro,
      formattedTimestamp: frame.frame.formattedTimestamp,
    );

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: StillScoutRadius.card,
                  border: Border.all(
                    color: rankColor,
                    width: rank == 1 ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    if (rank == 1)
                      StillScoutColors.goldGlow(
                        alpha: 0.4,
                        blur: StillScoutSpacing.m + 2,
                      )
                    else
                      BoxShadow(
                        color: rankColor.withValues(alpha: 0.18),
                        blurRadius: StillScoutSpacing.s + 2,
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: StillScoutRadius.tile,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(frame.frame.filePath), fit: BoxFit.cover),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: StillScoutSpacing.tileOverlay,
                          decoration: const BoxDecoration(
                            gradient: StillScoutColors.frameShadow,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  footer,
                                  style: StillScoutTextStyles.caption
                                      .copyWith(color: StillScoutColors.chalk),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${frame.score}',
                                style: StillScoutTextStyles.caption.copyWith(
                                  color: rankColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: StillScoutSpacing.s + 2,
                        left: StillScoutSpacing.s + 2,
                        child: Container(
                          width: StillScoutSpacing.l + 4,
                          height: StillScoutSpacing.l + 4,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: rankColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: rankColor.withValues(alpha: 0.5),
                                blurRadius: StillScoutSpacing.s,
                              ),
                            ],
                          ),
                          child: Text(
                            '#$rank',
                            style:
                                StillScoutTextStyles.badge.copyWith(fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
