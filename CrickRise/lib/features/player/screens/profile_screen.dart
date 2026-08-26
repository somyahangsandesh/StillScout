import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/player.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cr_widgets.dart';
import '../providers/player_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _ovrAnim, _batAnim, _bowlAnim, _fieldAnim;
  int _tab = 0; // 0 = season, 1 = career
  int _formatFilter = 0; // 0=ALL, 1=T20, 2=10-over, 3=5-over
  bool _ovrRevealShown = false;
  bool _insightsExpanded = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _ovrAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    _batAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.2, 0.65, curve: Curves.easeOut)),
    );
    _bowlAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.35, 0.75, curve: Curves.easeOut)),
    );
    _fieldAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.45, 0.85, curve: Curves.easeOut)),
    );
    _ctrl.forward().then((_) {
      final rating = ref.read(currentPlayerRatingProvider);
      // OVR Reveal Moment: exactly 5 matches = first OVR unlock
      if (rating.matchesPlayed == 5 && !_ovrRevealShown) {
        _ovrRevealShown = true;
        _showOvrReveal(rating.ovr.round());
      }
    });
  }

  void _showOvrReveal(int ovr) {
    // Brief overlay then Pro upsell
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _OvrRevealOverlay(ovr: ovr),
    ).then((_) {
      if (mounted) {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const _ProUpsellSheet(),
        );
      }
    });
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
      backgroundColor: CR.bg,
      body: Stack(
        children: [
          // Atmospheric radial glow
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
          CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            backgroundColor: CR.bg,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            title: Text(
              'Me',
              style: GoogleFonts.inter(
                color: CR.text1,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () => context.push('/player/${player.id}/card'),
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: CR.card,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.ios_share, color: CR.green, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Share Card',
                        style: GoogleFonts.inter(
                          color: CR.green,
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
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // OVR Hero Card
                _ProfileOvrCard(
                  player: player,
                  rating: rating,
                  ovrAnim: _ovrAnim,
                  batAnim: _batAnim,
                  bowlAnim: _bowlAnim,
                  fieldAnim: _fieldAnim,
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 20),

                // Season / Career tab toggle
                _TabToggle(
                  tab: _tab,
                  onChanged: (t) => setState(() => _tab = t),
                ),
                const SizedBox(height: 12),

                // Career tab replaces format filter + stats grid
                if (_tab == 1) ...[
                  const _CareerTab(),
                  const SizedBox(height: 20),
                ] else ...[
                  // Format filter pills
                  _FormatFilter(
                    selected: _formatFilter,
                    onChanged: (f) => setState(() => _formatFilter = f),
                  ),
                  const SizedBox(height: 16),

                  // Stats grid
                  _StatsGrid(stats: stats),
                  const SizedBox(height: 20),
                ],

                // MY POSITION
                const CRSectionLabel('My Position'),
                const SizedBox(height: 12),
                _ProfilePositionWidget(
                  player: player,
                  rating: rating,
                  rival: rival,
                  rivalRating: rivalRating,
                  below: below,
                  belowRating: belowRating,
                ),
                const SizedBox(height: 20),

                // RECENT MATCHES
                const CRSectionLabel('Recent Matches'),
                const SizedBox(height: 12),
                const _RecentMatchesList(),
                const SizedBox(height: 20),

                // BATTING INSIGHTS (Pro gate)
                const SizedBox(height: 20),
                _PlayerInsightsSection(
                  expanded: _insightsExpanded,
                  onToggle: () =>
                      setState(() => _insightsExpanded = !_insightsExpanded),
                ),
                const SizedBox(height: 20),

                // BEST PERFORMANCES
                const CRSectionLabel('Best Performances'),
                const SizedBox(height: 12),
                const _BestPerformances(),
                const SizedBox(height: 20),

                // MILESTONES
                const CRSectionLabel('Milestones'),
                const SizedBox(height: 12),
                const _MilestoneChips(),
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

class _ProfileOvrCard extends StatelessWidget {
  final Player player;
  final PlayerRating rating;
  final Animation<double> ovrAnim, batAnim, bowlAnim, fieldAnim;

  const _ProfileOvrCard({
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
        color: CR.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Jersey number watermark
            Positioned(
              right: -20,
              bottom: -30,
              child: Text(
                player.jerseyNumber?.toString() ?? '',
                style: GoogleFonts.spaceGrotesk(
                  color: CR.green.withOpacity(0.03),
                  fontSize: 220,
                  fontWeight: FontWeight.w800,
                  height: 0.8,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Role badge + name row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: CR.green.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                player.role.displayName.toUpperCase(),
                                style: GoogleFonts.inter(
                                  color: CR.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              player.displayName,
                              style: GoogleFonts.inter(
                                color: CR.text1,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // CR Number
                            Text(
                              player.crDisplay,
                              style: GoogleFonts.spaceGrotesk(
                                color: CR.text3,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                            if (rating.hasHotStreak || player.hasHeritage) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                children: [
                  if (player.hasElder)
                    const _MicroBadge('ELDER', CR.gold),
                  if (!player.hasElder && player.hasHeritage)
                    const _MicroBadge('HERITAGE', CR.blue),
                                  if (rating.hasHotStreak)
                                    _MicroBadge('🔥 ${rating.hotStreakCount} streak', CR.orange),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      // OVR with decorative glow ring
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'OVR',
                            style: GoogleFonts.inter(
                              color: CR.gold.withOpacity(0.6),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: CR.gold.withOpacity(0.15),
                                width: 1,
                              ),
                              gradient: RadialGradient(
                                colors: [
                                  CR.gold.withOpacity(0.08),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Center(
                              child: AnimatedBuilder(
                                animation: ovrAnim,
                                builder: (_, __) {
                                  final v =
                                      (50 + (rating.ovr - 50) * ovrAnim.value)
                                          .round();
                                  return Text(
                                    v.toString(),
                                    style: GoogleFonts.spaceGrotesk(
                                      color: CR.gold,
                                      fontSize: 56,
                                      fontWeight: FontWeight.w800,
                                      height: 0.9,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Domain bars
                  CRDomainBar(
                      label: 'BAT',
                      value: rating.bat,
                      animation: batAnim,
                      color: CR.green),
                  const SizedBox(height: 8),
                  CRDomainBar(
                      label: 'BOWL',
                      value: rating.bowl,
                      animation: bowlAnim,
                      color: CR.gold),
                  const SizedBox(height: 8),
                  CRDomainBar(
                      label: 'FIELD',
                      value: rating.field,
                      animation: fieldAnim,
                      color: CR.blue),
                  const SizedBox(height: 16),
                  // Form sparkline
                  const _FormSparkline(
                    // Sample OVR history — last 5 matches
                    dataPoints: [72.0, 74.0, 77.0, 76.0, 84.0],
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

// ─── Tab Toggle ───────────────────────────────────────────────────────────────

class _TabToggle extends StatelessWidget {
  final int tab;
  final ValueChanged<int> onChanged;

  const _TabToggle({required this.tab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ToggleItem(
          label: 'Season',
          selected: tab == 0,
          onTap: () => onChanged(0),
        ),
        const SizedBox(width: 20),
        _ToggleItem(
          label: 'Career',
          selected: tab == 1,
          onTap: () => onChanged(1),
        ),
      ],
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleItem({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: selected ? CR.text1 : CR.text3,
              fontSize: 15,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2,
            width: selected ? 40 : 0,
            decoration: BoxDecoration(
              color: CR.green,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Format Filter ────────────────────────────────────────────────────────────

class _FormatFilter extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _FormatFilter({required this.selected, required this.onChanged});

  static const _labels = ['ALL', 'T20', '10-over', '5-over'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _labels.asMap().entries.map((e) {
          final i = e.key;
          final label = e.value;
          final isSelected = selected == i;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? CR.green : CR.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? CR.green : CR.cardHigh,
                ),
              ),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: isSelected ? CR.textInv : CR.text3,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Player Insights Section ──────────────────────────────────────────────────

class _PlayerInsightsSection extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;

  const _PlayerInsightsSection({
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header row — tappable to expand
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'PLAYER INSIGHTS',
                    style: GoogleFonts.inter(
                      color: CR.text3,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: CR.gold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'PRO',
                      style: GoogleFonts.inter(
                        color: CR.gold,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: CR.text3,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1, color: CR.cardHigh),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Toss stats
                  const _InsightRow(
                    label: 'Toss: Win batting',
                    value: '67% win rate',
                    valueColor: CR.green,
                  ),
                  const _InsightRow(
                    label: 'Toss: Win fielding',
                    value: '55% win rate',
                    valueColor: CR.text2,
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: CR.cardHigh),
                  const SizedBox(height: 12),
                  // Wicket type breakdown
                  Text(
                    'Wicket Types',
                    style: GoogleFonts.inter(
                      color: CR.text3,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _WicketChip('Caught', '41%'),
                      _WicketChip('Bowled', '32%'),
                      _WicketChip('LBW', '18%'),
                      _WicketChip('Run Out', '9%'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: CR.cardHigh),
                  const SizedBox(height: 12),
                  // Phase strike rates
                  Text(
                    'Strike Rate by Phase',
                    style: GoogleFonts.inter(
                      color: CR.text3,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Expanded(
                          child: _PhaseCell('PP\n0–6 ov', '141')),
                      Expanded(
                          child: _PhaseCell('MID\n7–15 ov', '138')),
                      Expanded(
                          child: _PhaseCell('DEATH\n16–20 ov', '163',
                              highlight: true)),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // Blurred preview when collapsed
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ClipRect(
                child: ImageFiltered(
                  imageFilter: ColorFilter.mode(
                      CR.card, BlendMode.saturation),
                  child: Opacity(
                    opacity: 0.3,
                    child: Column(
                      children: [
                        _InsightRow(
                            label: 'Toss: Win batting', value: '67%'),
                        _InsightRow(
                            label: 'Wicket type: Caught', value: '41%'),
                      ],
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

class _InsightRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InsightRow(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(color: CR.text2, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: valueColor ?? CR.text1,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WicketChip extends StatelessWidget {
  final String type;
  final String pct;
  const _WicketChip(this.type, this.pct);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: CR.cardHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            type,
            style: GoogleFonts.inter(color: CR.text2, fontSize: 11),
          ),
          const SizedBox(width: 6),
          Text(
            pct,
            style: GoogleFonts.inter(
              color: CR.text1,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseCell extends StatelessWidget {
  final String label;
  final String sr;
  final bool highlight;
  const _PhaseCell(this.label, this.sr, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: highlight ? CR.green.withOpacity(0.08) : CR.cardHigh,
        borderRadius: BorderRadius.circular(8),
        border: highlight
            ? Border.all(color: CR.green.withOpacity(0.3))
            : null,
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: CR.text3,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sr,
            style: GoogleFonts.spaceGrotesk(
              color: highlight ? CR.green : CR.text1,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'SR',
            style: GoogleFonts.inter(
              color: CR.text3,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats Grid ───────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final PlayerStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Primary stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              CRStatCell(label: 'M', value: stats.matches.toString(), valueFontSize: 24),
              _VDivider(),
              CRStatCell(label: 'R', value: stats.runsScored.toString(), valueFontSize: 24),
              _VDivider(),
              CRStatCell(label: 'W', value: stats.wicketsTaken.toString(), valueFontSize: 24),
              _VDivider(),
              CRStatCell(label: 'C', value: stats.catches.toString(), valueFontSize: 24),
              _VDivider(),
              CRStatCell(label: 'MVP', value: stats.mvpAwards.toString(), valueFontSize: 24, valueColor: CR.gold),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: CR.cardHigh),
          const SizedBox(height: 16),
          // Secondary stats
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
            color: CR.text3,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: CR.text2,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: CR.cardHigh);
  }
}

// ─── Profile Position Widget ─────────────────────────────────────────────────

class _ProfilePositionWidget extends StatelessWidget {
  final Player player, rival, below;
  final PlayerRating rating, rivalRating, belowRating;

  const _ProfilePositionWidget({
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
          _PosRow(
            rank: '#2', jersey: rival.jerseyDisplay, name: rival.name,
            team: rival.teamName ?? '', ovr: rivalRating.ovr.round(),
            sub: '↑ $gapAbove OVR ahead', highlighted: false,
          ),
          Container(height: 1, color: CR.cardHigh),
          _PosRow(
            rank: '#3', jersey: player.jerseyDisplay, name: player.name,
            team: '', ovr: rating.ovr.round(),
            sub: rating.hasHotStreak ? rating.hotStreakDisplay : 'YOUR POSITION',
            highlighted: true,
          ),
          Container(height: 1, color: CR.cardHigh),
          _PosRow(
            rank: '#4', jersey: below.jerseyDisplay, name: below.name,
            team: below.teamName ?? '', ovr: belowRating.ovr.round(),
            sub: '↓ $gapBelow behind you', highlighted: false,
          ),
        ],
      ),
    );
  }
}

class _PosRow extends StatelessWidget {
  final String rank, jersey, name, team, sub;
  final int ovr;
  final bool highlighted;

  const _PosRow({
    required this.rank, required this.jersey, required this.name,
    required this.team, required this.ovr, required this.sub,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: highlighted ? CR.green.withOpacity(0.05) : Colors.transparent,
      child: Row(
        children: [
          if (highlighted)
            Container(
              width: 3, height: 42,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(color: CR.green, borderRadius: BorderRadius.circular(2)),
            )
          else
            const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('$rank  $jersey', style: GoogleFonts.spaceGrotesk(color: CR.text3, fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      team.isNotEmpty ? '$name · $team' : name,
                      style: GoogleFonts.inter(
                        color: highlighted ? CR.text1 : CR.text2,
                        fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
                const SizedBox(height: 3),
                Text(sub, style: GoogleFonts.inter(color: highlighted ? CR.green : CR.text3, fontSize: 11, fontWeight: highlighted ? FontWeight.w600 : FontWeight.w400)),
              ],
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(ovr.toString(), style: GoogleFonts.spaceGrotesk(color: highlighted ? CR.gold : CR.text2, fontSize: highlighted ? 30 : 22, fontWeight: FontWeight.w700, height: 1)),
            Text('OVR', style: GoogleFonts.inter(color: CR.text3, fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
          ]),
        ],
      ),
    );
  }
}

// ─── Recent Matches ───────────────────────────────────────────────────────────

class _RecentMatchesList extends StatelessWidget {
  const _RecentMatchesList();

  @override
  Widget build(BuildContext context) {
    final matches = [
      (opponent: 'vs Tokyo Rhinos', stats: '58*(39)  ·  3/24', positive: true, result: 'WON'),
      (opponent: 'vs Osaka Kings', stats: '44*(32)  ·  1/18', positive: false, result: 'LOST'),
      (opponent: 'vs Kobe Bulls', stats: '12*(11)  ·  0/22', positive: null, result: 'WON'),
    ];

    return Column(
      children: matches.asMap().entries.map((e) {
        final m = e.value;
        final color = m.positive == null
            ? CR.text3
            : m.positive!
                ? CR.green
                : CR.red;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CR.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(width: 3, height: 44, margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(m.opponent, style: GoogleFonts.inter(color: CR.text1, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Text(m.result, style: GoogleFonts.inter(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 3),
                  Text(m.stats, style: GoogleFonts.inter(color: CR.text2, fontSize: 12)),
                ]),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (e.key * 60).ms);
      }).toList(),
    );
  }
}

// ─── Best Performances ────────────────────────────────────────────────────────

// TODO: Replace with real computed records from match history
class _BestPerformances extends StatelessWidget {
  const _BestPerformances();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('🏏', 'Best innings', '127*', 'vs Tokyo Rhinos'),
      ('🎳', 'Best bowling', '5/18', 'vs Osaka Kings'),
      ('🤝', 'Most catches', '3', 'vs Fukuoka Tigers'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: items.map((item) {
          final (emoji, label, value, match) = item;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(color: CR.t2, fontSize: 13),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.spaceGrotesk(
                    color: CR.t1,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  match,
                  style: GoogleFonts.inter(color: CR.t3, fontSize: 11),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Milestones ───────────────────────────────────────────────────────────────

class _MilestoneChips extends StatelessWidget {
  const _MilestoneChips();

  @override
  Widget build(BuildContext context) {
    final items = [
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
      children: items.map((m) {
        final (icon, label) = m;
        final champion = icon == '🏆';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: champion ? CR.gold.withOpacity(0.08) : CR.card,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(icon, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: champion ? CR.gold : CR.text2,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]),
        );
      }).toList(),
    );
  }
}

// ─── Career Tab ───────────────────────────────────────────────────────────────

class _CareerTab extends StatelessWidget {
  const _CareerTab();

  static const _seasons = [
    _SeasonRow(year: '2026', club: 'Okinawa Warriors', ovrFrom: 72, ovrTo: 86, runs: 487, wickets: 21, champion: true),
    _SeasonRow(year: '2025', club: 'Okinawa Warriors', ovrFrom: 63, ovrTo: 72, runs: 312, wickets: 14, champion: false),
    _SeasonRow(year: '2024', club: 'Nepal Tokyo XI', ovrFrom: 55, ovrTo: 63, runs: 198, wickets: 18, champion: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Career summary card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: CR.card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CAREER SUMMARY',
                style: GoogleFonts.inter(
                  color: CR.text3,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const CRStatCell(label: 'Seasons', value: '3'),
                  _CareerVDivider(),
                  const CRStatCell(label: 'Matches', value: '87'),
                  _CareerVDivider(),
                  const CRStatCell(label: 'Runs', value: '2,418'),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: CR.cardHigh),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const CRStatCell(label: 'Wickets', value: '96'),
                  _CareerVDivider(),
                  const CRStatCell(label: 'Catches', value: '61'),
                  _CareerVDivider(),
                  const CRStatCell(label: 'MVPs', value: '14', valueColor: CR.gold),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: CR.cardHigh),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Text(
                    '1 Championship',
                    style: GoogleFonts.inter(
                      color: CR.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Per-season timeline
        Text(
          'CAREER BY SEASON',
          style: GoogleFonts.inter(
            color: CR.text3,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: CR.card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: _seasons.asMap().entries.map((e) {
              final i = e.key;
              final s = e.value;
              return Column(
                children: [
                  if (i > 0) Container(height: 1, color: CR.cardHigh),
                  _SeasonRowWidget(data: s),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _CareerVDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: CR.cardHigh);
  }
}

class _SeasonRow {
  final String year;
  final String club;
  final int ovrFrom;
  final int ovrTo;
  final int runs;
  final int wickets;
  final bool champion;

  const _SeasonRow({
    required this.year,
    required this.club,
    required this.ovrFrom,
    required this.ovrTo,
    required this.runs,
    required this.wickets,
    required this.champion,
  });
}

class _SeasonRowWidget extends StatelessWidget {
  final _SeasonRow data;
  const _SeasonRowWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    final isCurrent = data.year == '2026';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Year
          SizedBox(
            width: 38,
            child: Text(
              data.year,
              style: GoogleFonts.spaceGrotesk(
                color: isCurrent ? CR.green : CR.text3,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Club
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data.club,
                        style: GoogleFonts.inter(
                          color: isCurrent ? CR.text1 : CR.text2,
                          fontSize: 13,
                          fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (data.champion)
                      const Text('🏆', style: TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${data.runs}R  ${data.wickets}W',
                  style: GoogleFonts.inter(
                    color: CR.text3,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // OVR progression
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'OVR ${data.ovrFrom}→${data.ovrTo}',
                style: GoogleFonts.spaceGrotesk(
                  color: isCurrent ? CR.gold : CR.text3,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '+${data.ovrTo - data.ovrFrom}',
                style: GoogleFonts.inter(
                  color: CR.green,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Form Sparkline ───────────────────────────────────────────────────────────

class _FormSparkline extends StatelessWidget {
  final List<double> dataPoints;

  const _FormSparkline({required this.dataPoints});

  @override
  Widget build(BuildContext context) {
    if (dataPoints.length < 2) return const SizedBox.shrink();

    final first = dataPoints.first;
    final last = dataPoints.last;
    final trendingUp = last >= first;
    final lineColor = trendingUp ? CR.green : CR.red;

    final spots = dataPoints.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            const SizedBox(width: 4),
            Text(
              'last 5 matches',
              style: GoogleFonts.inter(color: CR.text3, fontSize: 9),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              minX: 0,
              maxX: (dataPoints.length - 1).toDouble(),
              minY: dataPoints.reduce((a, b) => a < b ? a : b) - 5,
              maxY: dataPoints.reduce((a, b) => a > b ? a : b) + 5,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: lineColor,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      final isLast = index == spots.length - 1;
                      return FlDotCirclePainter(
                        radius: isLast ? 4 : 2,
                        color: isLast ? lineColor : lineColor.withOpacity(0.4),
                        strokeWidth: 0,
                        strokeColor: Colors.transparent,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        lineColor.withOpacity(0.15),
                        lineColor.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── OVR Reveal Overlay ───────────────────────────────────────────────────────

class _OvrRevealOverlay extends StatefulWidget {
  final int ovr;
  const _OvrRevealOverlay({required this.ovr});

  @override
  State<_OvrRevealOverlay> createState() => _OvrRevealOverlayState();
}

class _OvrRevealOverlayState extends State<_OvrRevealOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _countAnim;
  bool _showUnlocked = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _countAnim = Tween<double>(begin: 50, end: widget.ovr.toDouble()).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward().then((_) {
      if (mounted) {
        setState(() => _showUnlocked = true);
        // After showing "UNLOCKED", wait then pop and let the caller show Pro upsell
        Future.delayed(const Duration(milliseconds: 1600), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _countAnim,
            builder: (_, __) {
              return Text(
                _countAnim.value.round().toString(),
                style: GoogleFonts.spaceGrotesk(
                  color: CR.gold,
                  fontSize: 120,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              );
            },
          ),
          Text(
            'OVR',
            style: GoogleFonts.inter(
              color: CR.gold.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 20),
          if (_showUnlocked)
            Text(
              'YOUR OVR IS UNLOCKED',
              style: GoogleFonts.inter(
                color: CR.gold,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .scale(begin: const Offset(0.8, 0.8)),
        ],
      ),
    );
  }
}

// ─── Pro Upsell Sheet ─────────────────────────────────────────────────────────

class _ProUpsellSheet extends StatelessWidget {
  const _ProUpsellSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: const BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: CR.text3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Lock icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: CR.gold.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_rounded,
                    color: CR.gold, size: 28),
              ),
              const SizedBox(height: 16),

              Text(
                'YOUR OVR BREAKDOWN',
                style: GoogleFonts.inter(
                  color: CR.text1,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'See exactly what\'s driving your rating.',
                style: GoogleFonts.inter(color: CR.text2, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Blurred domain scores
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CR.cardHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const _LockedDomainItem(label: 'BAT', value: '89'),
                    Container(width: 1, height: 44, color: CR.overlay),
                    const _LockedDomainItem(label: 'BOWL', value: '78'),
                    Container(width: 1, height: 44, color: CR.overlay),
                    const _LockedDomainItem(label: 'FIELD', value: '84'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Trial CTA
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CR.gold,
                    foregroundColor: CR.textInv,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Start 7-day free trial',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: CR.textInv,
                        ),
                      ),
                      Text(
                        '¥1,980/year after',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: CR.textInv.withOpacity(0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Dismiss
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Text(
                  'Not now',
                  style: GoogleFonts.inter(
                    color: CR.text3,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedDomainItem extends StatelessWidget {
  final String label;
  final String value;

  const _LockedDomainItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: CR.text3,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        ImageFiltered(
          imageFilter: const ColorFilter.mode(CR.text3, BlendMode.srcIn),
          child: Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: CR.text3,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Micro Badge ──────────────────────────────────────────────────────────────

class _MicroBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _MicroBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
