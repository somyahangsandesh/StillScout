import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/match.dart';
import '../../../core/models/player.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/cr_atmosphere.dart';
import '../../player/providers/player_provider.dart';
import '../../scorer/providers/scorer_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

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
      body: CRAtmosphere(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ActiveMatchBannerSlot(),
                const SizedBox(height: 8),
                Text(_greeting(), style: CRType.caption(color: CR.mist, size: 14)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        player.name.split(' ').first.toUpperCase(),
                        style: CRType.display(size: 44),
                      ),
                    ),
                    Text(player.crDisplay, style: CRType.label(color: CR.fog, size: 10)),
                  ],
                ),
                if (player.roles.length > 1) ...[
                  const SizedBox(height: 12),
                  _RoleBadgeRow(player: player),
                ],
                const SizedBox(height: 28),
                if (rating.matchesPlayed < 5)
                  _OvrUnlockCard(matchesPlayed: rating.matchesPlayed)
                else
                  _BroadcastOvrCard(
                    rating: rating,
                    player: player,
                    onTap: () => context.push('/me'),
                  ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const CRSectionLabel('The Gap'),
                    Text('League', style: CRType.caption(size: 12, color: CR.fog)),
                  ],
                ),
                const SizedBox(height: 12),
                _RivalryStrip(
                  player: player,
                  rating: rating,
                  rival: rival,
                  rivalRating: rivalRating,
                  below: below,
                  belowRating: belowRating,
                ),
                const SizedBox(height: 28),
                _PlayTodayButton(onTap: () => context.go('/play')),
                const SizedBox(height: 28),
                const CRSectionLabel('Next Up'),
                const SizedBox(height: 12),
                _NextMatchCard(canScore: player.canScore),
                const SizedBox(height: 20),
                _CommunityWhisper(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveMatchBannerSlot extends ConsumerWidget {
  const _ActiveMatchBannerSlot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchState = ref.watch(scorerProvider);
    if (matchState == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _LiveMatchBanner(state: matchState),
    );
  }
}

class _RoleBadgeRow extends StatelessWidget {
  final Player player;
  const _RoleBadgeRow({required this.player});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CRRoleBadge('PLAYER', CR.grass, active: true),
        if (player.isOrganizer) ...[
          const SizedBox(width: 8),
          CRRoleBadge('ORGANIZER', CR.flood, onTap: () => context.push('/organizer')),
        ],
      ],
    );
  }
}

class _OvrUnlockCard extends StatelessWidget {
  final int matchesPlayed;
  const _OvrUnlockCard({required this.matchesPlayed});

  @override
  Widget build(BuildContext context) {
    final remaining = 5 - matchesPlayed;
    return CRGlassPanel(
      highlight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FIRST OVR UNLOCK', style: CRType.label(color: CR.flood)),
          const SizedBox(height: 12),
          Text(
            '$remaining more ${remaining == 1 ? 'match' : 'matches'}',
            style: CRType.headline(size: 32),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: matchesPlayed / 5,
              backgroundColor: CR.cardHigh,
              valueColor: const AlwaysStoppedAnimation(CR.flood),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text('$matchesPlayed / 5 played', style: CRType.caption()),
        ],
      ),
    );
  }
}

class _BroadcastOvrCard extends StatelessWidget {
  final PlayerRating rating;
  final Player player;
  final VoidCallback onTap;

  const _BroadcastOvrCard({
    required this.rating,
    required this.player,
    required this.onTap,
  });

  static const _form = [72.0, 76.0, 79.0, 77.0, 86.0];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CRGlassPanel(
        highlight: true,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -30,
              child: Text(
                player.jerseyNumber?.toString() ?? '7',
                style: CRType.display(
                  size: 140,
                  color: CR.cream.withValues(alpha: 0.03),
                ),
              ),
            ),
            Positioned.fill(child: CustomPaint(painter: SeamCurvePainter())),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(player.name.toUpperCase(), style: CRType.headline(size: 22)),
                          const SizedBox(height: 4),
                          Text(player.crDisplay, style: CRType.label(size: 10, color: CR.fog)),
                          if (rating.hasHotStreak) ...[
                            const SizedBox(height: 10),
                            CRBadge('${rating.hotStreakCount}-match streak', color: CR.flood),
                          ],
                        ],
                      ),
                    ),
                    CRBroadcastNumber(
                      value: rating.ovr.round().toString(),
                      label: 'OVR',
                      size: 80,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(height: 1, color: CR.cream.withValues(alpha: 0.08)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StatPill('BAT', rating.bat.round(), CR.grass),
                    const SizedBox(width: 16),
                    _StatPill('BOWL', rating.bowl.round(), CR.flood),
                    const SizedBox(width: 16),
                    _StatPill('FIELD', rating.field.round(), CR.sky),
                    const Spacer(),
                    SizedBox(
                      width: 72,
                      height: 32,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineTouchData: const LineTouchData(enabled: false),
                          minX: 0,
                          maxX: 4,
                          minY: 68,
                          maxY: 90,
                          lineBarsData: [
                            LineChartBarData(
                              spots: _form.asMap().entries
                                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                                  .toList(),
                              isCurved: true,
                              color: CR.flood,
                              barWidth: 2,
                              dotData: const FlDotData(show: false),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatPill(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value.toString(), style: CRType.score(size: 22, color: color)),
        Text(label, style: CRType.label(size: 9, color: CR.fog)),
      ],
    );
  }
}

class _RivalryStrip extends StatelessWidget {
  final Player player;
  final PlayerRating rating;
  final Player rival;
  final PlayerRating rivalRating;
  final Player below;
  final PlayerRating belowRating;

  const _RivalryStrip({
    required this.player,
    required this.rating,
    required this.rival,
    required this.rivalRating,
    required this.below,
    required this.belowRating,
  });

  @override
  Widget build(BuildContext context) {
    final gapAbove = (rivalRating.ovr - rating.ovr).round();
    const rank = 3;

    return CRGlassPanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _RivalRow(
            rank: rank - 1,
            name: rival.name,
            ovr: rivalRating.ovr.round(),
            note: '$gapAbove ahead',
            highlight: false,
          ),
          Divider(height: 1, color: CR.cream.withValues(alpha: 0.06)),
          _RivalRow(
            rank: rank,
            name: player.name,
            ovr: rating.ovr.round(),
            note: 'YOU',
            highlight: true,
          ),
          Divider(height: 1, color: CR.cream.withValues(alpha: 0.06)),
          _RivalRow(
            rank: rank + 1,
            name: below.name,
            ovr: belowRating.ovr.round(),
            note: '${(rating.ovr - belowRating.ovr).round()} behind',
            highlight: false,
          ),
        ],
      ),
    );
  }
}

class _RivalRow extends StatelessWidget {
  final int rank;
  final String name;
  final int ovr;
  final String note;
  final bool highlight;

  const _RivalRow({
    required this.rank,
    required this.name,
    required this.ovr,
    required this.note,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: highlight ? CR.flood.withValues(alpha: 0.06) : null,
      child: Row(
        children: [
          Text('#$rank', style: CRType.label(size: 11, color: CR.fog)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: CRType.body(
                    size: 15,
                    weight: highlight ? FontWeight.w600 : FontWeight.w400,
                    color: highlight ? CR.cream : CR.mist,
                  ),
                ),
                Text(
                  note,
                  style: CRType.caption(
                    size: 11,
                    color: highlight ? CR.flood : CR.fog,
                  ),
                ),
              ],
            ),
          ),
          Text(
            ovr.toString(),
            style: CRType.score(
              size: highlight ? 28 : 22,
              color: highlight ? CR.flood : CR.mist,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayTodayButton extends StatefulWidget {
  final VoidCallback onTap;
  const _PlayTodayButton({required this.onTap});

  @override
  State<_PlayTodayButton> createState() => _PlayTodayButtonState();
}

class _PlayTodayButtonState extends State<_PlayTodayButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: CR.flood.withValues(alpha: 0.15 + _ctrl.value * 0.2),
              blurRadius: 32,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: child,
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: CR.floodGradient),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PLAY TODAY', style: CRType.headline(size: 28, color: CR.inv)),
                    Text(
                      'Friendly · League · Tournament',
                      style: CRType.caption(size: 13, color: CR.inv.withValues(alpha: 0.65)),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: CR.inv.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(child: Text('🏏', style: TextStyle(fontSize: 22))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextMatchCard extends StatelessWidget {
  final bool canScore;
  const _NextMatchCard({this.canScore = false});

  @override
  Widget build(BuildContext context) {
    return CRGlassPanel(
      child: Row(
        children: [
          Column(
            children: [
              Text('SAT', style: CRType.label(size: 10, color: CR.fog)),
              Text('14', style: CRType.score(size: 28, color: CR.cream)),
              Text('SEP', style: CRType.label(size: 10, color: CR.fog)),
            ],
          ),
          Container(
            width: 1,
            height: 48,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: CR.cream.withValues(alpha: 0.08),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Okinawa Warriors vs Tokyo Rhinos', style: CRType.body(weight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Yomitan Ground · 2:00 PM · T20', style: CRType.caption()),
              ],
            ),
          ),
          if (canScore)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: CR.grassDim,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: CR.grass.withValues(alpha: 0.3)),
              ),
              child: Text('SCORER', style: CRType.label(size: 9, color: CR.grass)),
            ),
        ],
      ),
    );
  }
}

class _CommunityWhisper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: CR.flood.withValues(alpha: 0.5), width: 2),
        ),
      ),
      child: Text(
        '⚡ 3 matches live across Japan  ·  Amit KC just crossed 500 runs',
        style: CRType.caption(size: 13, color: CR.mist),
      ),
    );
  }
}

class _LiveMatchBanner extends StatelessWidget {
  final MatchState state;
  const _LiveMatchBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/match/scorer'),
      child: CRGlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        radius: 14,
        child: Row(
          children: [
            const CRLiveBadge(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${state.battingTeamName.toUpperCase()}  ${state.scoreDisplay}  ${state.oversDisplay}',
                    style: CRType.body(size: 13, weight: FontWeight.w600),
                  ),
                  if (state.striker != null)
                    Text(
                      '${state.striker!.player.jerseyDisplay} ${state.striker!.player.displayName}  ${state.striker!.runs}*',
                      style: CRType.caption(size: 12),
                    ),
                ],
              ),
            ),
            Text('→', style: CRType.body(color: CR.flood, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
