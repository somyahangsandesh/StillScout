import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/match.dart';
import '../../../core/models/player.dart';
import '../../../core/theme/app_theme.dart';
import '../../player/providers/player_provider.dart';
import '../../scorer/providers/scorer_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    final rating = ref.watch(currentPlayerRatingProvider);
    final rival = ref.watch(rivalProvider);
    final rivalRating = ref.watch(rivalRatingProvider);
    final below = ref.watch(belowPlayerProvider);
    final belowRating = ref.watch(belowPlayerRatingProvider);
    final matchState = ref.watch(scorerProvider);

    return Scaffold(
      backgroundColor: CR.bg,
      body: Stack(
        children: [
          // Atmospheric radial glow — very subtle sports-app atmosphere
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    CR.green.withOpacity(0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live match banner — appears when scorer has active match
              if (matchState != null)
                _LiveMatchBanner(state: matchState)
                    .animate()
                    .fadeIn(duration: 300.ms),
              if (matchState != null) const SizedBox(height: 16),
              // Greeting — time-aware
              Text(
                _greeting(),
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

              // OVR Card — show progress card for new players (<5 matches)
              if (rating.matchesPlayed < 5)
                _OvrProgressCard(matchesPlayed: rating.matchesPlayed)
                    .animate()
                    .fadeIn(delay: 150.ms)
                    .slideY(begin: 0.05)
              else
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
              _StartMatchButton(onTap: () => context.go('/play'))
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
              const SizedBox(height: 24),

              // IN THE COMMUNITY
              const CRSectionLabel('In the Community'),
              const SizedBox(height: 10),
              _CommunityTeaser()
                  .animate()
                  .fadeIn(delay: 460.ms),
              const SizedBox(height: 24),

              // LOOKING FOR OPPONENTS — ultra-compact stub
              _LookingForChip()
                  .animate()
                  .fadeIn(delay: 500.ms),
            ],
          ),
        ),
          ),
        ],
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

// ─── OVR Progress Card (new players, <5 matches) ──────────────────────────────

class _OvrProgressCard extends StatelessWidget {
  final int matchesPlayed;
  const _OvrProgressCard({required this.matchesPlayed});

  @override
  Widget build(BuildContext context) {
    final remaining = 5 - matchesPlayed;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR FIRST OVR',
            style: GoogleFonts.inter(
              color: CR.text3,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Play $remaining more ${remaining == 1 ? 'match' : 'matches'} to unlock',
            style: GoogleFonts.inter(
              color: CR.text1,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: matchesPlayed / 5,
              backgroundColor: CR.cardHigh,
              valueColor: const AlwaysStoppedAnimation<Color>(CR.green),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$matchesPlayed / 5 matches played',
            style: GoogleFonts.inter(
              color: CR.text2,
              fontSize: 12,
            ),
          ),
        ],
      ),
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

  // Sample form data — last 5 OVR values
  static const _formData = [72.0, 76.0, 79.0, 77.0, 86.0];

  @override
  Widget build(BuildContext context) {
    final trending = _formData.last >= _formData.first;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CR.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: OVR number + streak with radial glow
                Stack(
                  alignment: Alignment.topLeft,
                  children: [
                    // Radial glow behind number
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              CR.gold.withOpacity(0.08),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
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
                  ],
                ),
                const Spacer(),
                // Right: BAT/BOWL/FIELD
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _DomainLine(label: 'BAT', value: rating.bat.round(), color: CR.green),
                    const SizedBox(height: 12),
                    _DomainLine(label: 'BOWL', value: rating.bowl.round(), color: CR.gold),
                    const SizedBox(height: 12),
                    _DomainLine(label: 'FIELD', value: rating.field.round(), color: CR.blue),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: CR.cardHigh),
            const SizedBox(height: 8),
            // Form sparkline
            Row(
              children: [
                Text(
                  'FORM',
                  style: GoogleFonts.inter(
                    color: CR.text3,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineTouchData: const LineTouchData(enabled: false),
                        minX: 0,
                        maxX: 4,
                        minY: _formData.reduce((a, b) => a < b ? a : b) - 5,
                        maxY: _formData.reduce((a, b) => a > b ? a : b) + 5,
                        lineBarsData: [
                          LineChartBarData(
                            spots: _formData.asMap().entries
                                .map((e) => FlSpot(e.key.toDouble(), e.value))
                                .toList(),
                            isCurved: true,
                            color: trending ? CR.green : CR.red,
                            barWidth: 2,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: trending
                                  ? CR.green.withOpacity(0.08)
                                  : CR.red.withOpacity(0.08),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  trending ? '↑' : '↓',
                  style: TextStyle(
                    color: trending ? CR.green : CR.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
  final Color color;

  const _DomainLine({required this.label, required this.value, required this.color});

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
            color: color,
            fontSize: 18,
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: CR.card,
            borderRadius: BorderRadius.circular(20),
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
    // Player rank derived from gap (sample: player is #3)
    const playerRank = 3;

    return Container(
      decoration: BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _PositionRow(
            rank: '#${playerRank - 1}',
            jersey: rival.jerseyDisplay,
            name: rival.name,
            team: rival.teamName ?? '',
            ovr: rivalRating.ovr.round(),
            sub: '↑ $gapAbove OVR ahead',
            highlighted: false,
            showGapIndicator: gapAbove <= 5,
            gapPoints: gapAbove,
          ),
          Container(height: 1, color: CR.cardHigh),
          _PositionRow(
            rank: '#$playerRank',
            jersey: player.jerseyDisplay,
            name: player.name,
            team: player.teamName ?? '',
            ovr: rating.ovr.round(),
            sub: rating.hasHotStreak ? '🔥 ${rating.hotStreakDisplay}' : 'YOU',
            highlighted: true,
            showGapIndicator: false,
            gapPoints: 0,
          ),
          Container(height: 1, color: CR.cardHigh),
          _PositionRow(
            rank: '#${playerRank + 1}',
            jersey: below.jerseyDisplay,
            name: below.name,
            team: below.teamName ?? '',
            ovr: belowRating.ovr.round(),
            sub: '↓ $gapBelow OVR behind you',
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

class _StartMatchButton extends StatefulWidget {
  final VoidCallback onTap;
  const _StartMatchButton({required this.onTap});

  @override
  State<_StartMatchButton> createState() => _StartMatchButtonState();
}

class _StartMatchButtonState extends State<_StartMatchButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.15, end: 0.45).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CR.green.withOpacity(_glowAnim.value),
              blurRadius: 20,
              spreadRadius: -4,
            ),
          ],
        ),
        child: child,
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            color: CR.green,
            borderRadius: BorderRadius.circular(12),
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
              onTap: () => context.go('/play'),
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
        borderRadius: BorderRadius.circular(16),
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

// ─── Community Teaser ─────────────────────────────────────────────────────────

class _CommunityTeaser extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '3 matches in progress across Japan',
            style: GoogleFonts.inter(
              color: CR.text1,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Amit KC (Osaka) just hit his first century',
            style: GoogleFonts.inter(
              color: CR.text2,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Live Match Banner ────────────────────────────────────────────────────────

class _LiveMatchBanner extends StatefulWidget {
  final MatchState state;
  const _LiveMatchBanner({required this.state});

  @override
  State<_LiveMatchBanner> createState() => _LiveMatchBannerState();
}

class _LiveMatchBannerState extends State<_LiveMatchBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return GestureDetector(
      onTap: () => context.go('/match/scorer'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: CR.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CR.red.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CR.red.withOpacity(
                      0.5 + _pulseCtrl.value * 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: CR.red.withOpacity(
                          0.3 * _pulseCtrl.value),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'LIVE',
              style: GoogleFonts.inter(
                color: CR.red,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        state.battingTeamName.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: CR.text1,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        state.scoreDisplay,
                        style: GoogleFonts.spaceGrotesk(
                          color: CR.text1,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        state.oversDisplay,
                        style: GoogleFonts.inter(
                          color: CR.text3,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  if (state.striker != null)
                    Text(
                      '${state.striker!.player.jerseyDisplay} ${state.striker!.player.displayName}  ${state.striker!.runs}*',
                      style: GoogleFonts.inter(
                        color: CR.text2,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              'VIEW →',
              style: GoogleFonts.inter(
                color: CR.green,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Looking For Chip ─────────────────────────────────────────────────────────
// Ultra-compact one-liner stub — full opponent matching coming in a future release

class _LookingForChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Find opponents — coming soon'),
          backgroundColor: CR.cardHigh,
          behavior: SnackBarBehavior.floating,
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: CR.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Text('🔍', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Looking for opponents? Post availability',
                style: GoogleFonts.inter(color: CR.text2, fontSize: 13),
              ),
            ),
            const Icon(Icons.chevron_right, color: CR.text3, size: 18),
          ],
        ),
      ),
    );
  }
}
