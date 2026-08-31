import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

class LeagueScreen extends StatefulWidget {
  const LeagueScreen({super.key});

  @override
  State<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends State<LeagueScreen>
    with SingleTickerProviderStateMixin {
  static const bool _inLeague = true;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CR.bg,
      body: SafeArea(
        child: _inLeague ? _LeagueView(tabCtrl: _tabCtrl) : const _EmptyState(),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'No league yet',
              style: GoogleFonts.inter(
                color: CR.text1,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask your organiser for an invite code, or create your own league.',
              style: GoogleFonts.inter(color: CR.text2, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => context.go('/auth/invite'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CR.green,
                  foregroundColor: CR.textInv,
                ),
                child: Text('JOIN A LEAGUE',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, fontSize: 14, color: CR.textInv)),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }
}

// ─── League View ─────────────────────────────────────────────────────────────

class _LeagueView extends StatelessWidget {
  final TabController tabCtrl;
  const _LeagueView({required this.tabCtrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OKINAWA NEPALI CRICKET LEAGUE',
                style: GoogleFonts.oswald(
                  color: CR.text1,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 2),
              Text(
                'Season 2026  ·  Week 8 of 12  ·  3 matches remaining',
                style: GoogleFonts.inter(color: CR.text2, fontSize: 12),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        // Tab bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: CR.card,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TabBar(
            controller: tabCtrl,
            labelColor: CR.inv,
            unselectedLabelColor: CR.text3,
            indicator: BoxDecoration(
              color: CR.green,
              borderRadius: BorderRadius.circular(8),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelStyle: GoogleFonts.oswald(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 1.5,
            ),
            unselectedLabelStyle: GoogleFonts.oswald(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              letterSpacing: 1.5,
            ),
            tabs: const [
              Tab(text: 'SEASON'),
              Tab(text: 'FIXTURES'),
              Tab(text: 'STATS'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: tabCtrl,
            children: const [
              _SeasonTab(),
              _FixturesTab(),
              _StatsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SEASON TAB
// ═══════════════════════════════════════════════════════════════

class _SeasonTab extends StatelessWidget {
  const _SeasonTab();

  static const _teams = [
    _TeamStanding(rank: 1, name: 'Tokyo Rhinos', p: 8, w: 6, l: 2, pts: 12, nrr: 0.82, form: ['W', 'W', 'L', 'W', 'W'], isQualify: true),
    _TeamStanding(rank: 2, name: 'Osaka Kings', p: 8, w: 5, l: 3, pts: 10, nrr: 0.42, form: ['W', 'L', 'W', 'W', 'L'], isQualify: true),
    _TeamStanding(rank: 3, name: 'Okinawa Warriors', p: 8, w: 5, l: 3, pts: 10, nrr: 0.31, form: ['W', 'W', 'W', 'W', 'L'], isYou: true),
    _TeamStanding(rank: 4, name: 'Kobe Bulls', p: 8, w: 4, l: 4, pts: 8, nrr: -0.05, form: ['L', 'W', 'L', 'W', 'W']),
    _TeamStanding(rank: 5, name: 'Fukuoka FC', p: 8, w: 3, l: 5, pts: 6, nrr: -0.18, form: ['L', 'L', 'W', 'L', 'W']),
    _TeamStanding(rank: 6, name: 'Nagoya Stars', p: 8, w: 3, l: 5, pts: 6, nrr: -0.29, form: ['W', 'L', 'L', 'W', 'L']),
    _TeamStanding(rank: 7, name: 'Kyoto Hawks', p: 8, w: 2, l: 6, pts: 4, nrr: -0.55, form: ['L', 'L', 'W', 'L', 'L']),
    _TeamStanding(rank: 8, name: 'Sapporo Ice', p: 8, w: 1, l: 7, pts: 2, nrr: -0.91, form: ['L', 'L', 'L', 'L', 'W']),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        // ── Your Team Headline ────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CR.greenDim,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CR.green.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR TEAM',
                style: GoogleFonts.oswald(
                    color: CR.green, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                'Okinawa Warriors',
                style: GoogleFonts.oswald(
                    color: CR.text1, fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                '3rd place  ·  2 points behind leaders',
                style: GoogleFonts.inter(color: CR.text2, fontSize: 13),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 280.ms),

        const SizedBox(height: 24),

        // ── Standings Table Header ────────────────────────────────────
        _StandingsHeader(),
        const SizedBox(height: 6),

        // ── Standings Rows ────────────────────────────────────────────
        ..._teams.asMap().entries.map((e) {
          return _StandingsRow(team: e.value, even: e.key.isEven)
              .animate()
              .fadeIn(delay: (e.key * 50).ms);
        }),

        const SizedBox(height: 24),

        // ── QUALIFY legend ────────────────────────────────────────────
        Row(
          children: [
            Container(width: 10, height: 10, color: CR.green.withOpacity(0.6)),
            const SizedBox(width: 6),
            Text(
              'Top 2 qualify for finals',
              style: GoogleFonts.inter(color: CR.text3, fontSize: 11),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // ── Title Race ────────────────────────────────────────────────
        _SectionLabel('TITLE RACE'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CR.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TitleRaceEntry('Warriors', 'Win 2 of last 3 matches'),
              SizedBox(height: 8),
              _TitleRaceEntry('Rhinos', 'Win all 3 + Warriors drop points'),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms),

        const SizedBox(height: 28),

        // ── Season Awards CTA ─────────────────────────────────────────
        GestureDetector(
          onTap: () => context.push('/league/awards'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2A1F00), Color(0xFF1A1500)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CR.gold.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Season Awards 2026',
                        style: GoogleFonts.oswald(
                            color: CR.gold, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Golden Bat · Golden Ball · MVP · Most Improved',
                        style: GoogleFonts.inter(color: CR.text3, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: CR.gold, size: 20),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 480.ms),

        const SizedBox(height: 28),

        // ── NRR Explainer ─────────────────────────────────────────────
        _NrrExplainer(),
      ],
    );
  }
}

class _StandingsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const SizedBox(width: 24),
          Expanded(
            child: Text('TEAM',
                style: GoogleFonts.oswald(
                    color: CR.text3, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w500)),
          ),
          const _Hdr('P'),
          const _Hdr('W'),
          const _Hdr('L'),
          const _Hdr('NRR'),
          const _Hdr('PTS'),
        ],
      ),
    );
  }
}

class _Hdr extends StatelessWidget {
  final String text;
  const _Hdr(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      child: Text(
        text,
        style: GoogleFonts.oswald(
            color: CR.text3, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TeamStanding {
  final int rank;
  final String name;
  final int p, w, l, pts;
  final double nrr;
  final List<String> form;
  final bool isYou;
  final bool isQualify;

  const _TeamStanding({
    required this.rank,
    required this.name,
    required this.p,
    required this.w,
    required this.l,
    required this.pts,
    required this.nrr,
    required this.form,
    this.isYou = false,
    this.isQualify = false,
  });
}

class _StandingsRow extends StatelessWidget {
  final _TeamStanding team;
  final bool even;

  const _StandingsRow({required this.team, required this.even});

  @override
  Widget build(BuildContext context) {
    final nrrStr =
        team.nrr >= 0 ? '+${team.nrr.toStringAsFixed(2)}' : team.nrr.toStringAsFixed(2);
    final nrrColor = team.nrr >= 0 ? CR.green : CR.ballRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: team.isYou
            ? CR.green.withOpacity(0.07)
            : even
                ? CR.card
                : const Color(0xFF0F160F),
        borderRadius: BorderRadius.circular(6),
        border: team.isYou
            ? const Border(left: BorderSide(color: CR.green, width: 3))
            : team.isQualify
                ? Border(left: BorderSide(color: CR.green.withOpacity(0.4), width: 2))
                : null,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Center(
                      child: Text(
                        '${team.rank}',
                        style: GoogleFonts.spaceGrotesk(
                          color: team.isYou
                              ? CR.green
                              : team.isQualify
                                  ? CR.green.withOpacity(0.7)
                                  : CR.text3,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              team.name,
                              style: GoogleFonts.inter(
                                color: team.isYou ? CR.text1 : CR.text2,
                                fontSize: 12,
                                fontWeight: team.isYou ? FontWeight.w700 : FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (team.isQualify && !team.isYou)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: CR.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                'Q',
                                style: GoogleFonts.oswald(
                                    color: CR.green, fontSize: 8, fontWeight: FontWeight.w700),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  _Cel(team.p.toString()),
                  _Cel(team.w.toString()),
                  _Cel(team.l.toString()),
                  _Cel(nrrStr, color: nrrColor),
                  _Cel(team.pts.toString(),
                      bold: true, color: team.isYou ? CR.green : null),
                ],
              ),
            ),
          ),
          // Form chips
          if (team.form.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 36, bottom: 6),
              child: Row(
                children: team.form.map((f) {
                  final isW = f == 'W';
                  return Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: isW ? CR.green.withOpacity(0.15) : CR.ballRed.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        f,
                        style: GoogleFonts.inter(
                            color: isW ? CR.green : CR.ballRed,
                            fontSize: 8,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _Cel extends StatelessWidget {
  final String text;
  final bool bold;
  final Color? color;
  const _Cel(this.text, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      child: Text(
        text,
        style: GoogleFonts.spaceGrotesk(
          color: color ?? CR.text2,
          fontSize: 11,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TitleRaceEntry extends StatelessWidget {
  final String team;
  final String needs;
  const _TitleRaceEntry(this.team, this.needs);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          team,
          style: GoogleFonts.inter(color: CR.text1, fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'needs: $needs',
            style: GoogleFonts.inter(color: CR.text2, fontSize: 12, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _NrrExplainer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CR.cardHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NRR EXPLAINED',
            style: GoogleFonts.oswald(
                color: CR.text3, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Net Run Rate = (Total runs scored ÷ Total overs faced) − (Total runs conceded ÷ Total overs bowled)',
            style: GoogleFonts.inter(color: CR.text2, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 10),
          Text(
            'Your team: +0.31  ·  Nearest rival: −0.05',
            style: GoogleFonts.inter(
                color: CR.green, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'To improve NRR: score fast, bowl teams out early.',
            style: GoogleFonts.inter(color: CR.text3, fontSize: 11),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 560.ms);
  }
}

// ═══════════════════════════════════════════════════════════════
// FIXTURES TAB
// ═══════════════════════════════════════════════════════════════

class _FixturesTab extends StatelessWidget {
  const _FixturesTab();

  static const _fixtures = [
    _FixtureData(
      round: 'Round 9',
      date: 'Sat, Sep 6',
      time: '10:00 AM',
      teamA: 'Okinawa Warriors',
      teamB: 'Tokyo Rhinos',
      venue: 'Okinawa Sports Park',
      isMyTeam: true,
      isUpcoming: true,
    ),
    _FixtureData(
      round: 'Round 9',
      date: 'Sun, Sep 7',
      time: '2:00 PM',
      teamA: 'Osaka Kings',
      teamB: 'Fukuoka FC',
      venue: 'Osaka Ground',
      isUpcoming: true,
    ),
    _FixtureData(
      round: 'Round 8',
      date: 'Aug 19',
      teamA: 'Okinawa Warriors',
      teamB: 'Kobe Bulls',
      result: 'Warriors won — 178/6 v 142/9',
      isMyTeam: true,
    ),
    _FixtureData(
      round: 'Round 8',
      date: 'Aug 19',
      teamA: 'Tokyo Rhinos',
      teamB: 'Osaka Kings',
      result: 'Rhinos won — 189/4 v 165/8',
    ),
    _FixtureData(
      round: 'Round 7',
      date: 'Aug 5',
      teamA: 'Osaka Kings',
      teamB: 'Okinawa Warriors',
      result: 'Osaka won — 189/4 v 165/8',
      isMyTeam: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Group by round
    final Map<String, List<_FixtureData>> byRound = {};
    for (final f in _fixtures) {
      byRound.putIfAbsent(f.round, () => []).add(f);
    }

    int delay = 0;
    final sections = <Widget>[];

    // Pin: my team's next match
    final myNext = _fixtures.where((f) => f.isMyTeam && f.isUpcoming).firstOrNull;
    if (myNext != null) {
      sections.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel('YOUR NEXT MATCH'),
            const SizedBox(height: 8),
            _FixtureCard(data: myNext, highlight: true)
                .animate()
                .fadeIn(delay: (delay++ * 60).ms),
            const SizedBox(height: 20),
          ],
        ),
      );
    }

    byRound.forEach((round, fixtures) {
      sections.add(_SectionLabel(round));
      sections.add(const SizedBox(height: 8));
      for (final f in fixtures) {
        if (f.isMyTeam && f.isUpcoming) continue; // already pinned
        sections.add(_FixtureCard(data: f)
            .animate()
            .fadeIn(delay: (delay++ * 60).ms));
        sections.add(const SizedBox(height: 8));
      }
      sections.add(const SizedBox(height: 12));
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: sections,
    );
  }
}

class _FixtureData {
  final String round;
  final String date;
  final String? time;
  final String teamA;
  final String teamB;
  final String? venue;
  final String? result;
  final bool isMyTeam;
  final bool isUpcoming;
  final bool isLive;

  const _FixtureData({
    required this.round,
    required this.date,
    this.time,
    required this.teamA,
    required this.teamB,
    this.venue,
    this.result,
    this.isMyTeam = false,
    this.isUpcoming = false,
    this.isLive = false,
  });
}

class _FixtureCard extends StatelessWidget {
  final _FixtureData data;
  final bool highlight;
  const _FixtureCard({required this.data, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.circular(12),
        border: highlight
            ? const Border(left: BorderSide(color: CR.green, width: 3))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date column
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.date,
                    style: GoogleFonts.inter(color: CR.text3, fontSize: 11)),
                if (data.time != null)
                  Text(data.time!,
                      style: GoogleFonts.spaceGrotesk(
                          color: CR.text2, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Teams + result
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.teamA} vs ${data.teamB}',
                  style: GoogleFonts.inter(
                    color: CR.text1,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (data.venue != null && data.isUpcoming) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: CR.text3, size: 11),
                      const SizedBox(width: 3),
                      Text(data.venue!,
                          style: GoogleFonts.inter(color: CR.text3, fontSize: 11)),
                    ],
                  ),
                ],
                if (data.result != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    data.result!,
                    style: GoogleFonts.inter(
                        color: data.isMyTeam ? CR.text2 : CR.text3, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          // Status badge
          if (data.isLive)
            _LiveBadge()
          else if (data.isUpcoming)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: CR.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('UPCOMING',
                  style: GoogleFonts.oswald(
                      color: CR.green, fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatefulWidget {
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
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
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: CR.ballRed.withOpacity(0.1 + _ctrl.value * 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: CR.ballRed.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: CR.ballRed.withOpacity(0.4 + _ctrl.value * 0.6),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text('LIVE',
                style: GoogleFonts.oswald(
                    color: CR.ballRed,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STATS TAB
// ═══════════════════════════════════════════════════════════════

class _StatsTab extends StatelessWidget {
  const _StatsTab();

  static const _batters = [
    _LeaderEntry(jersey: 7, name: 'Roshan KC', team: 'Warriors', value: '487 runs'),
    _LeaderEntry(jersey: 18, name: 'Sandip Thapa', team: 'Warriors', value: '312 runs'),
    _LeaderEntry(jersey: 2, name: 'Amit Shrestha', team: 'Rhinos', value: '298 runs'),
    _LeaderEntry(jersey: 11, name: 'Priya Singh', team: 'Osaka', value: '261 runs'),
    _LeaderEntry(jersey: 4, name: 'Suraj KC', team: 'Rhinos', value: '244 runs'),
  ];

  static const _bowlers = [
    _LeaderEntry(jersey: 23, name: 'Bikash Rai', team: 'Warriors', value: '21 wkts'),
    _LeaderEntry(jersey: 9, name: 'Dev Thapa', team: 'Rhinos', value: '18 wkts'),
    _LeaderEntry(jersey: 6, name: 'Pradeep KC', team: 'Osaka', value: '15 wkts'),
    _LeaderEntry(jersey: 3, name: 'Sagar Poudel', team: 'Warriors', value: '14 wkts'),
    _LeaderEntry(jersey: 11, name: 'Arjun Lama', team: 'Fukuoka', value: '12 wkts'),
  ];

  static const _mvp = [
    _LeaderEntry(jersey: 7, name: 'Roshan KC', team: 'Warriors', value: '3 MVPs'),
    _LeaderEntry(jersey: 23, name: 'Bikash Rai', team: 'Warriors', value: '2 MVPs'),
    _LeaderEntry(jersey: 9, name: 'Dev Thapa', team: 'Rhinos', value: '2 MVPs'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        _LeaderboardSection(
          emoji: '🏏',
          title: 'TOP BATTERS',
          subtitle: 'Most runs this season',
          entries: _batters,
          valueColor: CR.gold,
        ).animate().fadeIn(duration: 280.ms),

        const SizedBox(height: 24),

        _LeaderboardSection(
          emoji: '🎳',
          title: 'TOP BOWLERS',
          subtitle: 'Most wickets this season',
          entries: _bowlers,
          valueColor: CR.ballRed,
        ).animate().fadeIn(delay: 120.ms),

        const SizedBox(height: 24),

        _LeaderboardSection(
          emoji: '⭐',
          title: 'MVP RACE',
          subtitle: 'Most player-of-match awards',
          entries: _mvp,
          valueColor: CR.amber,
        ).animate().fadeIn(delay: 240.ms),

        const SizedBox(height: 24),

        // Awards CTA
        GestureDetector(
          onTap: () => context.push('/league/awards'),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CR.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CR.gold.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Text(
                  'View Season Awards →',
                  style: GoogleFonts.inter(
                      color: CR.gold, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 360.ms),
      ],
    );
  }
}

class _LeaderEntry {
  final int jersey;
  final String name;
  final String team;
  final String value;

  const _LeaderEntry({
    required this.jersey,
    required this.name,
    required this.team,
    required this.value,
  });
}

class _LeaderboardSection extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final List<_LeaderEntry> entries;
  final Color valueColor;

  const _LeaderboardSection({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.entries,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.oswald(
                      color: CR.text1, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                ),
                Text(subtitle,
                    style: GoogleFonts.inter(color: CR.text3, fontSize: 11)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: CR.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: entries.asMap().entries.map((e) {
              final rank = e.key + 1;
              final entry = e.value;
              final isLast = e.key == entries.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    child: Row(
                      children: [
                        // Rank
                        SizedBox(
                          width: 20,
                          child: Text(
                            '#$rank',
                            style: GoogleFonts.spaceGrotesk(
                              color: rank == 1 ? CR.gold : CR.text3,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        // Jersey
                        Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: valueColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '#${entry.jersey}',
                              style: GoogleFonts.spaceGrotesk(
                                  color: valueColor, fontSize: 9, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        // Name + team
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.name,
                                  style: GoogleFonts.inter(
                                      color: CR.text1,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              Text(entry.team,
                                  style: GoogleFonts.inter(color: CR.text3, fontSize: 11)),
                            ],
                          ),
                        ),
                        // Value
                        Text(
                          entry.value,
                          style: GoogleFonts.spaceGrotesk(
                            color: valueColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(height: 1, color: CR.cardHigh, indent: 14, endIndent: 14),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: CR.greenGradient,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.oswald(
            color: CR.text2,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }
}
