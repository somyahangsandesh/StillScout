import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/player.dart';
import '../../../core/theme/app_theme.dart';
import '../../player/providers/player_provider.dart';

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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Text(
                'Good evening,',
                style: GoogleFonts.inter(
                  color: CR.text2,
                  fontSize: 14,
                ),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 2),
              Text(
                player.name.split(' ').first,
                style: GoogleFonts.inter(
                  color: CR.text1,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ).animate().fadeIn(delay: 80.ms),
              if (player.roles.length > 1) ...[
                const SizedBox(height: 10),
                _RoleBadgeRow(player: player)
                    .animate()
                    .fadeIn(delay: 120.ms),
              ],
              const SizedBox(height: 24),

              // OVR Card
              _OvrCard(
                rating: rating,
                player: player,
                onTap: () => context.push('/me'),
              ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.05),
              const SizedBox(height: 20),

              // HUNTING LIST
              _HuntingListHeader(),
              const SizedBox(height: 10),
              _PositionCard(
                player: player,
                rating: rating,
                rival: rival,
                rivalRating: rivalRating,
                below: below,
                belowRating: belowRating,
              ).animate().fadeIn(delay: 250.ms),
              const SizedBox(height: 24),

              // START MATCH
              _StartMatchButton(onTap: () => context.go('/match/scorer'))
                  .animate()
                  .fadeIn(delay: 320.ms),
              const SizedBox(height: 24),

              // UPCOMING
              const CRSectionLabel('Upcoming'),
              const SizedBox(height: 10),
              _UpcomingMatchCard(canScore: player.canScore)
                  .animate()
                  .fadeIn(delay: 380.ms),
              const SizedBox(height: 24),

              // LAST MATCH
              const CRSectionLabel('Last Match'),
              const SizedBox(height: 10),
              _LastMatchCard()
                  .animate()
                  .fadeIn(delay: 420.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Role Badge Row ────────────────────────────────────────────────────────────

class _RoleBadgeRow extends StatelessWidget {
  final Player player;
  const _RoleBadgeRow({required this.player});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CRRoleBadge('PLAYER', CR.green, active: true),
        if (player.isOrganizer) ...[
          const SizedBox(width: 6),
          CRRoleBadge(
            'ORGANIZER',
            CR.gold,
            active: false,
            onTap: () => context.push('/organizer'),
          ),
        ],
        if (player.canScore && !player.isOrganizer) ...[
          const SizedBox(width: 6),
          const CRRoleBadge('SCORER', CR.orange, active: false),
        ],
      ],
    );
  }
}

// ─── OVR Card ─────────────────────────────────────────────────────────────────

class _OvrCard extends StatelessWidget {
  final PlayerRating rating;
  final Player player;
  final VoidCallback onTap;

  const _OvrCard({
    required this.rating,
    required this.player,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CR.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: OVR
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OVR',
                  style: GoogleFonts.inter(
                    color: CR.gold,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  rating.ovr.round().toString(),
                  style: GoogleFonts.spaceGrotesk(
                    color: CR.gold,
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    height: 0.9,
                  ),
                ),
                const SizedBox(height: 8),
                if (rating.hasHotStreak)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: CR.gold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '🔥 ${rating.hotStreakCount}-match streak',
                      style: GoogleFonts.inter(
                        color: CR.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            // Right: domain scores
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _DomainLine(label: 'BAT', value: rating.bat.round()),
                const SizedBox(height: 12),
                _DomainLine(label: 'BOWL', value: rating.bowl.round()),
                const SizedBox(height: 12),
                _DomainLine(label: 'FIELD', value: rating.field.round()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DomainLine extends StatelessWidget {
  final String label;
  final int value;

  const _DomainLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: CR.text3,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value.toString(),
          style: GoogleFonts.spaceGrotesk(
            color: CR.text1,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ],
    );
  }
}

// ─── Hunting List Header ─────────────────────────────────────────────────────

class _HuntingListHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'HUNTING LIST',
          style: GoogleFonts.inter(
            color: CR.text3,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
        const Spacer(),
        // League selector hint
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: CR.card,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'League',
                style: GoogleFonts.inter(
                  color: CR.text3,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, color: CR.text3, size: 14),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Position Card ────────────────────────────────────────────────────────────

class _PositionCard extends StatelessWidget {
  final Player player;
  final PlayerRating rating;
  final Player rival;
  final PlayerRating rivalRating;
  final Player below;
  final PlayerRating belowRating;

  const _PositionCard({
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
    final gapBelow = (rating.ovr - belowRating.ovr).round();

    return Container(
      decoration: BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _PositionRow(
            rank: '#2',
            jersey: rival.jerseyDisplay,
            name: rival.name,
            team: rival.teamName ?? '',
            ovr: rivalRating.ovr.round(),
            sub: '↑ $gapAbove points ahead of you',
            highlighted: false,
            showGapIndicator: true,
            gapPoints: gapAbove,
          ),
          Container(height: 1, color: CR.cardHigh),
          _PositionRow(
            rank: '#3',
            jersey: player.jerseyDisplay,
            name: player.name,
            team: player.teamName ?? '',
            ovr: rating.ovr.round(),
            sub: rating.hasHotStreak ? '🔥 ${rating.hotStreakDisplay}' : 'YOUR POSITION',
            highlighted: true,
            showGapIndicator: false,
            gapPoints: 0,
          ),
          Container(height: 1, color: CR.cardHigh),
          _PositionRow(
            rank: '#4',
            jersey: below.jerseyDisplay,
            name: below.name,
            team: below.teamName ?? '',
            ovr: belowRating.ovr.round(),
            sub: '↓ $gapBelow points below you',
            highlighted: false,
            showGapIndicator: false,
            gapPoints: gapBelow,
          ),
        ],
      ),
    );
  }
}

class _PositionRow extends StatelessWidget {
  final String rank;
  final String jersey;
  final String name;
  final String team;
  final int ovr;
  final String sub;
  final bool highlighted;
  final bool showGapIndicator;
  final int gapPoints;

  const _PositionRow({
    required this.rank,
    required this.jersey,
    required this.name,
    required this.team,
    required this.ovr,
    required this.sub,
    required this.highlighted,
    required this.showGapIndicator,
    required this.gapPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: highlighted ? CR.green.withOpacity(0.05) : Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (highlighted)
                Container(
                  width: 3,
                  height: 44,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: CR.green,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
              else
                const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$rank  $jersey',
                          style: GoogleFonts.spaceGrotesk(
                            color: CR.text3,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            team.isNotEmpty ? '$name · $team' : name,
                            style: GoogleFonts.inter(
                              color: highlighted ? CR.text1 : CR.text2,
                              fontWeight: highlighted
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      sub,
                      style: GoogleFonts.inter(
                        color: highlighted ? CR.green : CR.text3,
                        fontSize: 11,
                        fontWeight: highlighted
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    ovr.toString(),
                    style: GoogleFonts.spaceGrotesk(
                      color: highlighted ? CR.gold : CR.text2,
                      fontSize: highlighted ? 28 : 22,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                  Text(
                    'OVR',
                    style: GoogleFonts.inter(
                      color: CR.text3,
                      fontSize: 9,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Gap closeable indicator for rival-above row
          if (showGapIndicator && gapPoints <= 5) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: CR.gold.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Gap closeable — play well this weekend',
                      style: GoogleFonts.inter(
                        color: CR.gold,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Notification trigger concept
          // TODO: When rival above closes gap by 1 OVR, send push notification
        ],
      ),
    );
  }
}

// ─── Start Match Button ───────────────────────────────────────────────────────

class _StartMatchButton extends StatelessWidget {
  final VoidCallback onTap;
  const _StartMatchButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: CR.green,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'START MATCH',
                    style: GoogleFonts.spaceGrotesk(
                      color: CR.textInv,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Friendly · League · Tournament',
                    style: GoogleFonts.inter(
                      color: CR.textInv.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Text('🏏', style: TextStyle(fontSize: 28)),
          ],
        ),
      ),
    );
  }
}

// ─── Upcoming Match Card ──────────────────────────────────────────────────────

class _UpcomingMatchCard extends StatelessWidget {
  final bool canScore;
  const _UpcomingMatchCard({this.canScore = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.circular(16),
        border: const Border(left: BorderSide(color: CR.green, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Match header: next match · countdown
          Row(
            children: [
              Text(
                'NEXT MATCH',
                style: GoogleFonts.inter(
                  color: CR.text3,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 3,
                height: 3,
                decoration:
                    const BoxDecoration(color: CR.text3, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                'SAT  ·  4 DAYS',
                style: GoogleFonts.inter(
                  color: CR.green,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Teams + OVR
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Okinawa Warriors',
                      style: GoogleFonts.inter(
                        color: CR.text1,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'OVR 74',
                      style: GoogleFonts.spaceGrotesk(
                        color: CR.gold,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'vs',
                style: GoogleFonts.inter(color: CR.text3, fontSize: 13),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Tokyo Rhinos',
                      style: GoogleFonts.inter(
                        color: CR.text2,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'OVR 71',
                      style: GoogleFonts.spaceGrotesk(
                        color: CR.text3,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Venue + format
          Container(height: 1, color: CR.cardHigh),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.place_outlined, color: CR.text3, size: 14),
              const SizedBox(width: 4),
              Text(
                'Okinawa Sports Park',
                style: GoogleFonts.inter(color: CR.text3, fontSize: 12),
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 10, color: CR.cardHigh),
              const SizedBox(width: 8),
              Text(
                'T20',
                style: GoogleFonts.inter(
                  color: CR.text3,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // YOUR STAKES
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CR.cardHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR STAKES',
                  style: GoogleFonts.inter(
                    color: CR.text3,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                const _StakeLine(
                  icon: Icons.arrow_upward_rounded,
                  text: 'Win and you climb to #2 in batting',
                ),
                const SizedBox(height: 6),
                const _StakeLine(
                  icon: Icons.flag_outlined,
                  text: '13 runs from your season 500',
                ),
              ],
            ),
          ),

          if (canScore) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => context.go('/match/scorer'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: CR.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'SCORE THIS MATCH →',
                    style: GoogleFonts.inter(
                      color: CR.textInv,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StakeLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _StakeLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: CR.gold, size: 13),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '"$text"',
            style: GoogleFonts.inter(
              color: CR.text1,
              fontSize: 12,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Last Match Card ──────────────────────────────────────────────────────────

class _LastMatchCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: CR.green,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'vs Tokyo Rhinos',
                      style: GoogleFonts.inter(
                        color: CR.text1,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'WON',
                      style: GoogleFonts.inter(
                        color: CR.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: CR.gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '⭐ MVP',
                        style: GoogleFonts.inter(
                          color: CR.gold,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '58*(39)  ·  3/24',
                  style: GoogleFonts.inter(color: CR.text2, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+2',
                style: GoogleFonts.spaceGrotesk(
                  color: CR.green,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              Text(
                'OVR',
                style: GoogleFonts.inter(
                  color: CR.text3,
                  fontSize: 9,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
