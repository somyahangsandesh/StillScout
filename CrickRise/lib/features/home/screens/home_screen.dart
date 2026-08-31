import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/community.dart';
import '../../../core/providers/app_context_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/cr_matchday.dart';
import '../../player/providers/player_provider.dart';
import '../../scorer/providers/scorer_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    final ctx = ref.watch(appContextProvider);
    final poll = ref.watch(sundayPollProvider);
    final lastStory = ref.watch(lastSundayStoryProvider);
    final rating = ref.watch(currentPlayerRatingProvider);

    final inCount = poll.where((p) => p.status == PollStatus.in_).length;
    final maybeCount = poll.where((p) => p.status == PollStatus.maybe).length;
    final outCount = poll.where((p) => p.status == PollStatus.out).length;

    return Scaffold(
      backgroundColor: CR.bg,
      body: CRProgrammeBg(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LiveBanner(),
                const SizedBox(height: 20),
                _HeaderRow(player: player, ctx: ctx),
                const SizedBox(height: 24),
                _CityPulse(ctx: ctx),
                const SizedBox(height: 28),
                const CRSectionLabel('Sunday poll'),
                const SizedBox(height: 6),
                Text(
                  'Who\'s in this Sunday?',
                  style: CRType.caption(),
                ),
                const SizedBox(height: 14),
                _PollSummary(inCount: inCount, maybeCount: maybeCount, outCount: outCount),
                const SizedBox(height: 12),
                _PollList(poll: poll),
                const SizedBox(height: 28),
                const CRSectionLabel('This Sunday'),
                const SizedBox(height: 14),
                CRTicket(
                  onTap: () => context.go('/play'),
                  stub: Container(
                    width: 64,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('SUN', style: CRType.overline(size: 8)),
                        Text('7', style: CRType.score(size: 26)),
                        Text('SEP', style: CRType.overline(size: 8)),
                      ],
                    ),
                  ),
                  body: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ctx.squad.name} vs Tokyo Rhinos',
                          style: CRType.body(weight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${ctx.squad.venue} · 2:00 PM · T20',
                          style: CRType.caption(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CRBadge('$inCount confirmed', color: CR.mossLight),
                            const SizedBox(width: 8),
                            if (maybeCount > 0)
                              CRBadge('$maybeCount maybe', color: CR.slate),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const CRSectionLabel('Last Sunday Story'),
                const SizedBox(height: 14),
                _LastStoryTeaser(
                  story: lastStory,
                  onTap: () => context.push('/story'),
                ),
                const SizedBox(height: 28),
                if (rating.matchesPlayed < 5)
                  _PassportUnlock(matches: rating.matchesPlayed)
                else
                  _PassportTeaser(player: player, rating: rating, onTap: () => context.go('/me')),
                const SizedBox(height: 24),
                CRProgrammeButton(
                  label: 'Start Sunday match',
                  onTap: () => context.go('/play'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(scorerProvider);
    if (s == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => context.go('/match/scorer'),
      child: CRPaper(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        color: CR.terracottaDim,
        child: Row(
          children: [
            const CRLiveDot(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${s.battingTeamName}  ${s.scoreDisplay}  (${s.oversDisplay})',
                    style: CRType.body(size: 13, weight: FontWeight.w600),
                  ),
                  if (s.striker != null)
                    Text(
                      '${s.striker!.player.displayName}  ${s.striker!.runs}*',
                      style: CRType.caption(size: 12),
                    ),
                ],
              ),
            ),
            Text('→', style: CRType.body(color: CR.brass)),
          ],
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final dynamic player;
  final AppContext ctx;

  const _HeaderRow({required this.player, required this.ctx});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CrickRise', style: CRType.overline(color: CR.brass, size: 9)),
              const SizedBox(height: 4),
              Text(
                'Every Sunday,\na story worth sending home.',
                style: CRType.headline(size: 26),
              ),
              const SizedBox(height: 6),
              Text(
                '${ctx.squad.name} · ${ctx.city.name}',
                style: CRType.caption(),
              ),
            ],
          ),
        ),
        CRStamp(line1: 'CR NO.', line2: player.crDisplay.replaceAll('CR-', '')),
      ],
    );
  }
}

class _CityPulse extends StatelessWidget {
  final AppContext ctx;
  const _CityPulse({required this.ctx});

  @override
  Widget build(BuildContext context) {
    return CRPaper(
      accent: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(ctx.country.flag, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ctx.sundayMatchesNearby} matches this Sunday',
                  style: CRType.body(weight: FontWeight.w600, size: 15),
                ),
                Text(
                  'Across ${ctx.country.name} · ${ctx.heritage.label} crews playing abroad',
                  style: CRType.caption(size: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: CR.fog, size: 18),
        ],
      ),
    );
  }
}

class _PollSummary extends StatelessWidget {
  final int inCount;
  final int maybeCount;
  final int outCount;

  const _PollSummary({
    required this.inCount,
    required this.maybeCount,
    required this.outCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Pill('$inCount IN', CR.mossLight),
        const SizedBox(width: 8),
        if (maybeCount > 0) ...[
          _Pill('$maybeCount MAYBE', CR.slate),
          const SizedBox(width: 8),
        ],
        _Pill('$outCount OUT', CR.fog),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(label, style: CRType.overline(size: 8, color: color)),
    );
  }
}

class _PollList extends ConsumerWidget {
  final List<PollPlayer> poll;
  const _PollList({required this.poll});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CRPaper(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: poll.take(5).map((p) {
          final icon = switch (p.status) {
            PollStatus.in_ => ('✓', CR.mossLight),
            PollStatus.maybe => ('?', CR.slate),
            PollStatus.out => ('×', CR.fog),
          };
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: icon.$2.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(icon.$1, style: CRType.label(size: 11, color: icon.$2)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(p.name, style: CRType.body(size: 14))),
                Text(
                  switch (p.status) {
                    PollStatus.in_ => 'IN',
                    PollStatus.maybe => 'MAYBE',
                    PollStatus.out => 'OUT',
                  },
                  style: CRType.overline(size: 8, color: icon.$2),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LastStoryTeaser extends StatelessWidget {
  final dynamic story;
  final VoidCallback onTap;

  const _LastStoryTeaser({required this.story, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CRPaper(
        child: Row(
          children: [
            Container(
              width: 52,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [CR.terracottaDim, CR.inkDeep],
                ),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: CR.brass.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CRCricketBall(size: 20),
                  const SizedBox(height: 4),
                  Text('#${story.storyNumber}', style: CRType.overline(size: 7)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Share again', style: CRType.overline(color: CR.brass, size: 8)),
                  Text(story.headline, style: CRType.body(weight: FontWeight.w600, size: 14)),
                  const SizedBox(height: 4),
                  Text(
                    '${story.playerOfSunday} · ${story.playerStats}',
                    style: CRType.caption(size: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.ios_share, color: CR.brass, size: 18),
          ],
        ),
      ),
    );
  }
}

class _PassportUnlock extends StatelessWidget {
  final int matches;
  const _PassportUnlock({required this.matches});

  @override
  Widget build(BuildContext context) {
    final left = 5 - matches;
    return CRPaper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Passport unlocks after 5 Sundays', style: CRType.overline(color: CR.brass)),
          const SizedBox(height: 8),
          Text('$left more to unlock OVR', style: CRType.display(size: 28)),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: matches / 5,
            backgroundColor: CR.cardHigh,
            valueColor: const AlwaysStoppedAnimation(CR.brass),
            minHeight: 3,
          ),
        ],
      ),
    );
  }
}

class _PassportTeaser extends StatelessWidget {
  final dynamic player;
  final dynamic rating;
  final VoidCallback onTap;

  const _PassportTeaser({
    required this.player,
    required this.rating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CRPaper(
        accent: true,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CRScoreboard(value: rating.ovr.round().toString(), label: 'OVR', digitSize: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(player.name, style: CRType.body(weight: FontWeight.w600)),
                  Text('Your passport · tap to view', style: CRType.caption(size: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: CR.fog),
          ],
        ),
      ),
    );
  }
}
