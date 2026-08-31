import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/match.dart';
import '../../../core/models/player.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/cr_matchday.dart';
import '../../player/providers/player_provider.dart';
import '../../scorer/providers/scorer_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    final rating = ref.watch(currentPlayerRatingProvider);
    final rival = ref.watch(rivalProvider);
    final rivalRating = ref.watch(rivalRatingProvider);
    final below = ref.watch(belowPlayerProvider);
    final belowRating = ref.watch(belowPlayerRatingProvider);

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
                _PassportStrip(player: player),
                const SizedBox(height: 28),
                if (rating.matchesPlayed < 5)
                  _UnlockCard(matches: rating.matchesPlayed)
                else
                  _OvrHero(player: player, rating: rating, onTap: () => context.push('/me')),
                const SizedBox(height: 32),
                const CRSectionLabel('The Gap'),
                const SizedBox(height: 14),
                _GapTickets(
                  player: player,
                  rating: rating,
                  rival: rival,
                  rivalRating: rivalRating,
                  below: below,
                  belowRating: belowRating,
                ),
                const SizedBox(height: 32),
                CRProgrammeButton(
                  label: 'Play today',
                  onTap: () => context.go('/play'),
                ),
                const SizedBox(height: 28),
                const CRSectionLabel('Next fixture'),
                const SizedBox(height: 14),
                CRTicket(
                  onTap: () {},
                  stub: Container(
                    width: 64,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('SAT', style: CRType.overline(size: 8)),
                        Text('14', style: CRType.score(size: 26)),
                        Text('SEP', style: CRType.overline(size: 8)),
                      ],
                    ),
                  ),
                  body: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Okinawa Warriors vs Tokyo Rhinos', style: CRType.body(weight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Yomitan Ground · 2:00 PM · T20', style: CRType.caption()),
                        if (player.canScore) ...[
                          const SizedBox(height: 8),
                          CRBadge('You are scorer', color: CR.mossLight),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: CR.terracotta.withValues(alpha: 0.5), width: 2)),
                  ),
                  child: Text(
                    '3 matches live in Japan · Amit KC crossed 500 runs',
                    style: CRType.caption(color: CR.ink),
                  ),
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

class _PassportStrip extends StatelessWidget {
  final Player player;
  const _PassportStrip({required this.player});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 52,
          height: 64,
          decoration: BoxDecoration(
            color: CR.cardHigh,
            border: Border.all(color: CR.chalk.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('PHOTO', style: CRType.overline(size: 7, color: CR.fog)),
              const SizedBox(height: 4),
              Text(
                player.jerseyNumber?.toString() ?? '—',
                style: CRType.score(size: 20, color: CR.brass),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(player.name, style: CRType.headline(size: 24)),
              const SizedBox(height: 2),
              Text(player.teamName ?? 'Free agent', style: CRType.caption()),
            ],
          ),
        ),
        CRStamp(line1: 'CR NO.', line2: player.crDisplay.replaceAll('CR-', '')),
      ],
    );
  }
}

class _UnlockCard extends StatelessWidget {
  final int matches;
  const _UnlockCard({required this.matches});

  @override
  Widget build(BuildContext context) {
    final left = 5 - matches;
    return CRPaper(
      accent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('First OVR unlock', style: CRType.overline(color: CR.brass)),
          const SizedBox(height: 8),
          Text('$left more ${left == 1 ? 'match' : 'matches'}', style: CRType.display(size: 32)),
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

class _OvrHero extends StatelessWidget {
  final Player player;
  final PlayerRating rating;
  final VoidCallback onTap;

  const _OvrHero({required this.player, required this.rating, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CRPaper(
        accent: true,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Stack(
          children: [
            Positioned(
              right: -8,
              bottom: -12,
              child: Text(
                player.jerseyNumber?.toString() ?? '',
                style: CRType.display(size: 120, color: CR.chalk.withValues(alpha: 0.03)),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Overall rating', style: CRType.overline(color: CR.brass)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _Stat('BAT', rating.bat.round(), CR.mossLight),
                          const SizedBox(width: 20),
                          _Stat('BOWL', rating.bowl.round(), CR.brass),
                          const SizedBox(width: 20),
                          _Stat('FLD', rating.field.round(), CR.slate),
                        ],
                      ),
                      if (rating.hasHotStreak) ...[
                        const SizedBox(height: 12),
                        CRBadge('${rating.hotStreakCount}-match streak'),
                      ],
                    ],
                  ),
                ),
                CRScoreboard(value: rating.ovr.round().toString(), label: 'OVR', digitSize: 48),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String l;
  final int v;
  final Color c;
  const _Stat(this.l, this.v, this.c);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(v.toString(), style: CRType.score(size: 22, color: c)),
        Text(l, style: CRType.overline(size: 8, color: CR.fog)),
      ],
    );
  }
}

class _GapTickets extends StatelessWidget {
  final Player player;
  final PlayerRating rating;
  final Player rival;
  final PlayerRating rivalRating;
  final Player below;
  final PlayerRating belowRating;

  const _GapTickets({
    required this.player,
    required this.rating,
    required this.rival,
    required this.rivalRating,
    required this.below,
    required this.belowRating,
  });

  @override
  Widget build(BuildContext context) {
    const rank = 3;
    final gapUp = (rivalRating.ovr - rating.ovr).round();
    final gapDown = (rating.ovr - belowRating.ovr).round();

    return Column(
      children: [
        _GapRow('#${rank - 1}', rival.name, rivalRating.ovr.round(), '$gapUp OVR ahead', false),
        const SizedBox(height: 8),
        _GapRow('#$rank', player.name, rating.ovr.round(), 'YOU', true),
        const SizedBox(height: 8),
        _GapRow('#${rank + 1}', below.name, belowRating.ovr.round(), '$gapDown behind', false),
      ],
    );
  }
}

class _GapRow extends StatelessWidget {
  final String rank;
  final String name;
  final int ovr;
  final String sub;
  final bool you;

  const _GapRow(this.rank, this.name, this.ovr, this.sub, this.you);

  @override
  Widget build(BuildContext context) {
    return CRPaper(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: you ? CR.brassDim.withValues(alpha: 0.35) : CR.card,
      accent: you,
      child: Row(
        children: [
          Text(rank, style: CRType.overline(size: 9, color: CR.fog)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: CRType.body(weight: you ? FontWeight.w600 : FontWeight.w400)),
                Text(sub, style: CRType.overline(size: 8, color: you ? CR.brass : CR.fog)),
              ],
            ),
          ),
          Text(ovr.toString(), style: CRType.score(size: you ? 26 : 20, color: you ? CR.brass : CR.ink)),
        ],
      ),
    );
  }
}
