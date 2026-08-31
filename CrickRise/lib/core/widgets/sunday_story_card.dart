import 'package:flutter/material.dart';

import '../models/community.dart';
import '../models/sunday_story.dart';
import '../theme/app_theme.dart';
import '../theme/cr_matchday.dart';

/// 9:16 shareable Sunday Story card — designed for WhatsApp, IG Story, Facebook.
class SundayStoryCard extends StatelessWidget {
  final SundayStory story;
  final double width;

  const SundayStoryCard({
    super.key,
    required this.story,
    this.width = 320,
  });

  @override
  Widget build(BuildContext context) {
    final height = width * 16 / 9;
    final initials = story.playerOfSunday
        .split(' ')
        .take(2)
        .map((p) => p.isNotEmpty ? p[0] : '')
        .join()
        .toUpperCase();

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [CR.inkDeep, CR.bg, Color(0xFF1A0F08)],
          ),
          border: Border.all(color: CR.brass.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Stack(
            children: [
              const Positioned(
                top: -30,
                right: -20,
                child: _BallWatermark(size: 160, opacity: 0.08),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('CRICKRISE', style: CRType.overline(color: CR.brass, size: 9)),
                        const Spacer(),
                        Text(
                          'SUNDAY STORY #${story.storyNumber}',
                          style: CRType.overline(color: CR.fog, size: 8),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('SUNDAY STORY', style: CRType.display(size: 28, style: FontStyle.italic)),
                    const SizedBox(height: 4),
                    Text(story.locationLine, style: CRType.caption(size: 12)),
                    const SizedBox(height: 20),
                    const CRProgrammeRule(),
                    const SizedBox(height: 18),
                    Text(
                      story.squadName,
                      style: CRType.headline(size: 22),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text('vs ${story.opponentName}', style: CRType.body(color: CR.ink)),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(story.squadScore, style: CRType.score(size: 26, color: CR.mossLight)),
                              const SizedBox(height: 4),
                              Text(story.opponentScore, style: CRType.score(size: 20, color: CR.ink)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            CRBadge('Won by ${story.margin}', color: CR.brass),
                            const SizedBox(height: 6),
                            Text(story.homeCountryName.toUpperCase(),
                                style: CRType.overline(size: 7, color: CR.fog)),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: CR.card.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: CR.brass.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: CR.terracottaDim,
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: CR.brass.withValues(alpha: 0.4)),
                            ),
                            child: Text(initials, style: CRType.score(size: 18, color: CR.brass)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('PLAYER OF SUNDAY', style: CRType.overline(size: 7, color: CR.brass)),
                                Text(story.playerOfSunday, style: CRType.body(weight: FontWeight.w600)),
                                Text(story.playerStats, style: CRType.caption(size: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (story.captainQuote != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        '"${story.captainQuote}"',
                        style: CRType.body(size: 13, color: CR.ink).copyWith(fontStyle: FontStyle.italic),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text(story.countryFlag, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            story.shareUrl.replaceAll('https://', ''),
                            style: CRType.overline(size: 7, color: CR.fog),
                          ),
                        ),
                        const CRCricketBall(size: 22),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BallWatermark extends StatelessWidget {
  final double size;
  final double opacity;
  const _BallWatermark({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: CRCricketBall(size: size),
    );
  }
}
