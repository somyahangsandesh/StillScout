import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/player.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/player_provider.dart';

class PlayerProfileScreen extends ConsumerStatefulWidget {
  final String playerId;
  const PlayerProfileScreen({super.key, required this.playerId});

  @override
  ConsumerState<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends ConsumerState<PlayerProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _ovrAnim;
  late Animation<double> _batAnim;
  late Animation<double> _bowlAnim;
  late Animation<double> _fieldAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _ovrAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl,
          curve: const Interval(0.0, 0.55, curve: Curves.easeOut)));
    _batAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl,
          curve: const Interval(0.25, 0.65, curve: Curves.easeOut)));
    _bowlAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl,
          curve: const Interval(0.35, 0.75, curve: Curves.easeOut)));
    _fieldAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl,
          curve: const Interval(0.45, 0.85, curve: Curves.easeOut)));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(currentPlayerProvider);
    final rating = ref.watch(currentPlayerRatingProvider);
    final stats = ref.watch(currentPlayerStatsProvider);
    final rival = ref.watch(rivalProvider);
    final rivalRating = ref.watch(rivalRatingProvider);
    final below = ref.watch(belowPlayerProvider);
    final belowRating = ref.watch(belowPlayerRatingProvider);

    return Scaffold(
      backgroundColor: CrickRiseColors.background,
      body: Stack(
        children: [
          // Background atmospheric glow
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 360,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    CrickRiseColors.primaryDeep.withOpacity(0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Seam decoration behind the OVR card
          const Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 280,
              child: CustomPaint(
                painter: SeamCurvePainter(opacity: 0.05),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              // App bar
              SliverAppBar(
                backgroundColor: Colors.transparent,
                pinned: true,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: CrickRiseColors.textSecondary, size: 18),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  GestureDetector(
                    onTap: () => context.push('/player/${player.id}/card'),
                    child: Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: CrickRiseColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: CrickRiseColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.ios_share,
                              color: CrickRiseColors.primary, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'Share Card',
                            style: GoogleFonts.inter(
                              color: CrickRiseColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── The OVR Hero Card ──────────────────────────────
                    _OvrHeroCard(
                      player: player,
                      rating: rating,
                      ovrAnim: _ovrAnim,
                      batAnim: _batAnim,
                      bowlAnim: _bowlAnim,
                      fieldAnim: _fieldAnim,
                    ),
                    const SizedBox(height: 24),

                    // ── My Position ────────────────────────────────────
                    const CRSectionLabel('My Position'),
                    const SizedBox(height: 10),
                    _PositionWidget(
                      player: player,
                      rating: rating,
                      rival: rival,
                      rivalRating: rivalRating,
                      below: below,
                      belowRating: belowRating,
                    ),
                    const SizedBox(height: 24),

                    // ── This Season ────────────────────────────────────
                    const CRSectionLabel('This Season'),
                    const SizedBox(height: 10),
                    _SeasonStats(stats: stats),
                    const SizedBox(height: 24),

                    // ── Recent Form ────────────────────────────────────
                    const CRSectionLabel('Recent Form'),
                    const SizedBox(height: 10),
                    const _RecentForm(),
                    const SizedBox(height: 24),

                    // ── Milestones ─────────────────────────────────────
                    const CRSectionLabel('Milestones'),
                    const SizedBox(height: 10),
                    const _Milestones(),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── OVR Hero Card ────────────────────────────────────────────────────────────
// This is the centerpiece. FIFA card energy: jersey number watermark,
// massive gold OVR, glowing domain bars.

class _OvrHeroCard extends StatelessWidget {
  final Player player;
  final PlayerRating rating;
  final Animation<double> ovrAnim;
  final Animation<double> batAnim;
  final Animation<double> bowlAnim;
  final Animation<double> fieldAnim;

  const _OvrHeroCard({
    required this.player,
    required this.rating,
    required this.ovrAnim,
    required this.batAnim,
    required this.bowlAnim,
    required this.fieldAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
          colors: [
            Color(0xFF0E2018),
            Color(0xFF0A1912),
            Color(0xFF08140E),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CrickRiseColors.primary.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: CrickRiseColors.primary.withOpacity(0.1),
            blurRadius: 32,
            spreadRadius: -4,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Jersey number watermark — the stadium number on the back of a shirt
            Positioned(
              right: -20,
              bottom: -30,
              child: Text(
                player.jerseyNumber?.toString() ?? '',
                style: GoogleFonts.spaceGrotesk(
                  color: CrickRiseColors.primary.withOpacity(0.04),
                  fontSize: 220,
                  fontWeight: FontWeight.w800,
                  height: 0.8,
                ),
              ),
            ),
            // Subtle radial glow from OVR area
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 220,
                height: 180,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      CrickRiseColors.gold.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top: name + role badge | OVR
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Role badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: CrickRiseColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: CrickRiseColors.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                player.role.displayName.toUpperCase(),
                                style: GoogleFonts.inter(
                                  color: CrickRiseColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Jersey + Name
                            Row(
                              children: [
                                Text(
                                  player.jerseyDisplay,
                                  style: GoogleFonts.spaceGrotesk(
                                    color: CrickRiseColors.textMuted,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    player.displayName,
                                    style: GoogleFonts.inter(
                                      color: CrickRiseColors.textPrimary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              player.teamName ?? '',
                              style: GoogleFonts.inter(
                                color: CrickRiseColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (rating.hasHotStreak)
                              CRBadge(
                                '🔥 ${rating.hotStreakCount}-match streak',
                                color: CrickRiseColors.gold,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // OVR — the hero number
                      Column(
                        children: [
                          Text(
                            'OVR',
                            style: GoogleFonts.inter(
                              color: CrickRiseColors.gold.withOpacity(0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                          AnimatedBuilder(
                            animation: ovrAnim,
                            builder: (_, __) {
                              final v = (50 + (rating.ovr - 50) * ovrAnim.value)
                                  .round();
                              return Text(
                                v.toString(),
                                style: GoogleFonts.spaceGrotesk(
                                  color: CrickRiseColors.gold,
                                  fontSize: 88,
                                  fontWeight: FontWeight.w800,
                                  height: 0.9,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  // Divider
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          CrickRiseColors.primary.withOpacity(0.3),
                          CrickRiseColors.primary.withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Domain bars
                  CRDomainBar(
                    label: 'BAT',
                    value: rating.bat,
                    animation: batAnim,
                    color: CrickRiseColors.primary,
                  ),
                  const SizedBox(height: 14),
                  CRDomainBar(
                    label: 'BOWL',
                    value: rating.bowl,
                    animation: bowlAnim,
                    color: CrickRiseColors.gold,
                  ),
                  const SizedBox(height: 14),
                  CRDomainBar(
                    label: 'FIELD',
                    value: rating.field,
                    animation: fieldAnim,
                    color: const Color(0xFF60A5FA),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── My Position ─────────────────────────────────────────────────────────────

class _PositionWidget extends StatelessWidget {
  final Player player;
  final PlayerRating rating;
  final Player rival;
  final PlayerRating rivalRating;
  final Player below;
  final PlayerRating belowRating;

  const _PositionWidget({
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
        color: CrickRiseColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CrickRiseColors.surfaceElevated),
      ),
      child: Column(
        children: [
          _ProfilePositionRow(
            rank: '#2',
            jerseyDisplay: rival.jerseyDisplay,
            name: rival.name,
            teamName: rival.teamName ?? '',
            ovr: rivalRating.ovr.round(),
            subtext: '↑ $gapAbove OVR ahead of you',
            isHighlighted: false,
            roundTop: true,
          ),
          Container(height: 1, color: CrickRiseColors.surfaceElevated),
          _ProfilePositionRow(
            rank: '#3',
            jerseyDisplay: player.jerseyDisplay,
            name: player.name,
            teamName: '',
            ovr: rating.ovr.round(),
            subtext: rating.hasHotStreak ? rating.hotStreakDisplay : 'YOUR POSITION',
            isHighlighted: true,
            roundTop: false,
          ),
          Container(height: 1, color: CrickRiseColors.surfaceElevated),
          _ProfilePositionRow(
            rank: '#4',
            jerseyDisplay: below.jerseyDisplay,
            name: below.name,
            teamName: below.teamName ?? '',
            ovr: belowRating.ovr.round(),
            subtext: '↓ $gapBelow behind you',
            isHighlighted: false,
            roundTop: false,
          ),
        ],
      ),
    );
  }
}

class _ProfilePositionRow extends StatelessWidget {
  final String rank;
  final String jerseyDisplay;
  final String name;
  final String teamName;
  final int ovr;
  final String subtext;
  final bool isHighlighted;
  final bool roundTop;

  const _ProfilePositionRow({
    required this.rank,
    required this.jerseyDisplay,
    required this.name,
    required this.teamName,
    required this.ovr,
    required this.subtext,
    required this.isHighlighted,
    required this.roundTop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: isHighlighted
          ? CrickRiseColors.primary.withOpacity(0.05)
          : Colors.transparent,
      child: Row(
        children: [
          if (isHighlighted)
            Container(
              width: 3,
              height: 42,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: CrickRiseColors.primaryGradient,
                ),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: CrickRiseColors.primary.withOpacity(0.6),
                    blurRadius: 8,
                  ),
                ],
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
                      '$rank  $jerseyDisplay',
                      style: GoogleFonts.spaceGrotesk(
                        color: CrickRiseColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        teamName.isNotEmpty ? '$name · $teamName' : name,
                        style: GoogleFonts.inter(
                          color: isHighlighted
                              ? CrickRiseColors.textPrimary
                              : CrickRiseColors.textSecondary,
                          fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtext,
                  style: GoogleFonts.inter(
                    color: isHighlighted
                        ? CrickRiseColors.primary
                        : CrickRiseColors.textMuted,
                    fontSize: 11,
                    fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
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
                  color: isHighlighted
                      ? CrickRiseColors.gold
                      : CrickRiseColors.textSecondary,
                  fontSize: isHighlighted ? 30 : 22,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              Text(
                'OVR',
                style: GoogleFonts.inter(
                  color: CrickRiseColors.textMuted,
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

// ─── Season Stats ─────────────────────────────────────────────────────────────

class _SeasonStats extends StatelessWidget {
  final PlayerStats stats;
  const _SeasonStats({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CrickRiseColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CrickRiseColors.surfaceElevated),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatCell('M', stats.matches.toString()),
              _Vdivider(),
              _StatCell('R', stats.runsScored.toString()),
              _Vdivider(),
              _StatCell('W', stats.wicketsTaken.toString()),
              _Vdivider(),
              _StatCell('C', stats.catches.toString()),
              _Vdivider(),
              _StatCell('MVP', stats.mvpAwards.toString(),
                  color: CrickRiseColors.gold),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: CrickRiseColors.surfaceElevated),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MiniStat('AVG', stats.battingAverage.toStringAsFixed(1)),
              _MiniStat('SR', stats.strikeRate.toStringAsFixed(0)),
              _MiniStat('ECON', stats.economy.toStringAsFixed(1)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _StatCell(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: color ?? CrickRiseColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            color: CrickRiseColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: CrickRiseColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: CrickRiseColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Vdivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: CrickRiseColors.surfaceElevated,
    );
  }
}

// ─── Recent Form ──────────────────────────────────────────────────────────────

class _RecentForm extends StatelessWidget {
  const _RecentForm();

  @override
  Widget build(BuildContext context) {
    final matches = [
      (arrow: '↑', label: 'vs Tokyo Rhinos', stats: '58*(39)  ·  3/24', positive: true),
      (arrow: '↑', label: 'vs Osaka Kings', stats: '44*(32)  ·  1/18', positive: true),
      (arrow: '→', label: 'vs Kobe Bulls', stats: '12*(11)  ·  0/22', positive: null),
      (arrow: '↑', label: 'vs Fukuoka FC', stats: '71*(48)  ·  2/16', positive: true),
      (arrow: '↓', label: 'vs Nagoya Stars', stats: '8*(9)  ·  0/30', positive: false),
    ];

    return Column(
      children: matches.map((m) {
        final color = m.positive == null
            ? CrickRiseColors.textMuted
            : m.positive!
                ? CrickRiseColors.primary
                : CrickRiseColors.danger;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: CrickRiseColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.15),
            ),
          ),
          child: Row(
            children: [
              // Arrow indicator
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    m.arrow,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.label,
                      style: GoogleFonts.inter(
                        color: CrickRiseColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m.stats,
                      style: GoogleFonts.inter(
                        color: CrickRiseColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'OVR ${m.arrow}',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Milestones ───────────────────────────────────────────────────────────────

class _Milestones extends StatelessWidget {
  const _Milestones();

  @override
  Widget build(BuildContext context) {
    final milestones = [
      ('✓', 'First Match'),
      ('✓', 'First MVP'),
      ('✓', '50+ ×11'),
      ('✓', '5-wkt ×2'),
      ('✓', 'Century ×1'),
      ('🏆', 'Champion 2025'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: milestones.map((m) {
        final (icon, label) = m;
        final isChampion = icon == '🏆';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isChampion
                ? CrickRiseColors.gold.withOpacity(0.08)
                : CrickRiseColors.surfaceCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isChampion
                  ? CrickRiseColors.gold.withOpacity(0.3)
                  : CrickRiseColors.surfaceElevated,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: isChampion
                      ? CrickRiseColors.gold
                      : CrickRiseColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
