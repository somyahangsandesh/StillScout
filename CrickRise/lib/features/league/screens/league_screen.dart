import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

class LeagueScreen extends StatefulWidget {
  const LeagueScreen({super.key});

  @override
  State<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends State<LeagueScreen>
    with SingleTickerProviderStateMixin {
  // Toggle between empty state and in-league state
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
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 20),
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
              'Ask your organizer to share the league link.',
              style: GoogleFonts.inter(color: CR.text2, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {},
                child: Text(
                  '+ Create League',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: CR.textInv,
                  ),
                ),
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
                'Japan Premier T20',
                style: GoogleFonts.inter(
                  color: CR.text1,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 2),
              Text(
                'Season 2026  ·  8 Teams',
                style: GoogleFonts.inter(color: CR.text2, fontSize: 13),
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
            labelColor: CR.text1,
            unselectedLabelColor: CR.text3,
            indicator: BoxDecoration(
              color: CR.green,
              borderRadius: BorderRadius.circular(8),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 1,
            ),
            tabs: const [
              Tab(text: 'STANDINGS'),
              Tab(text: 'FIXTURES'),
              Tab(text: 'RECORDS'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Content
        Expanded(
          child: TabBarView(
            controller: tabCtrl,
            children: const [
              _StandingsTab(),
              _FixturesTab(),
              _RecordsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Standings Tab ────────────────────────────────────────────────────────────

class _StandingsTab extends StatelessWidget {
  const _StandingsTab();

  static const _teams = [
    _TeamRow(rank: 1, name: 'Tokyo Rhinos', p: 8, w: 6, l: 2, pts: 12, isYou: false),
    _TeamRow(rank: 2, name: 'Osaka Kings', p: 8, w: 5, l: 3, pts: 10, isYou: false),
    _TeamRow(rank: 3, name: 'Okinawa Warriors', p: 8, w: 5, l: 3, pts: 10, isYou: true),
    _TeamRow(rank: 4, name: 'Kobe Bulls', p: 8, w: 4, l: 4, pts: 8, isYou: false),
    _TeamRow(rank: 5, name: 'Fukuoka FC', p: 8, w: 3, l: 5, pts: 6, isYou: false),
    _TeamRow(rank: 6, name: 'Nagoya Stars', p: 8, w: 3, l: 5, pts: 6, isYou: false),
    _TeamRow(rank: 7, name: 'Kyoto Hawks', p: 8, w: 2, l: 6, pts: 4, isYou: false),
    _TeamRow(rank: 8, name: 'Sapporo Ice', p: 8, w: 1, l: 7, pts: 2, isYou: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Column headers
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Row(
            children: [
              const SizedBox(width: 24),
              Expanded(
                child: Text(
                  'TEAM',
                  style: GoogleFonts.inter(
                    color: CR.text3,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const _HeaderCell('P'),
              const _HeaderCell('W'),
              const _HeaderCell('L'),
              const _HeaderCell('PTS'),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _teams.length,
            itemBuilder: (ctx, i) {
              final t = _teams[i];
              return _StandingsRow(team: t, even: i.isEven)
                  .animate()
                  .fadeIn(delay: (i * 50).ms);
            },
          ),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: CR.text3,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TeamRow {
  final int rank;
  final String name;
  final int p, w, l, pts;
  final bool isYou;

  const _TeamRow({
    required this.rank,
    required this.name,
    required this.p,
    required this.w,
    required this.l,
    required this.pts,
    required this.isYou,
  });
}

class _StandingsRow extends StatelessWidget {
  final _TeamRow team;
  final bool even;

  const _StandingsRow({required this.team, required this.even});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: team.isYou
            ? CR.green.withOpacity(0.07)
            : even
                ? CR.card
                : const Color(0xFF131313),
        border: team.isYou
            ? const Border(left: BorderSide(color: CR.green, width: 3))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Center(
              child: Text(
                '${team.rank}',
                style: GoogleFonts.spaceGrotesk(
                  color: team.isYou ? CR.green : CR.text3,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                team.name,
                style: GoogleFonts.inter(
                  color: team.isYou ? CR.text1 : CR.text2,
                  fontSize: 13,
                  fontWeight: team.isYou ? FontWeight.w700 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          _Cell(team.p.toString()),
          _Cell(team.w.toString()),
          _Cell(team.l.toString()),
          _Cell(
            team.pts.toString(),
            bold: true,
            color: team.isYou ? CR.green : null,
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final bool bold;
  final Color? color;
  const _Cell(this.text, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Text(
        text,
        style: GoogleFonts.spaceGrotesk(
          color: color ?? CR.text2,
          fontSize: 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ─── Fixtures Tab ─────────────────────────────────────────────────────────────

class _FixturesTab extends StatelessWidget {
  const _FixturesTab();

  @override
  Widget build(BuildContext context) {
    const fixtures = [
      _FixtureData(round: 'Round 9', date: 'Sep 2, 2026', teamA: 'Okinawa Warriors', teamB: 'Tokyo Rhinos', result: null, upcoming: true),
      _FixtureData(round: 'Round 8', date: 'Aug 19, 2026', teamA: 'Okinawa Warriors', teamB: 'Kobe Bulls', result: 'W 178/6 v 142/9', upcoming: false),
      _FixtureData(round: 'Round 7', date: 'Aug 5, 2026', teamA: 'Osaka Kings', teamB: 'Okinawa Warriors', result: 'L 165/8 v 189/4', upcoming: false),
    ];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: fixtures.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        return _FixtureCard(data: fixtures[i])
            .animate()
            .fadeIn(delay: (i * 60).ms);
      },
    );
  }
}

class _FixtureData {
  final String round;
  final String date;
  final String teamA;
  final String teamB;
  final String? result;
  final bool upcoming;

  const _FixtureData({
    required this.round,
    required this.date,
    required this.teamA,
    required this.teamB,
    required this.result,
    required this.upcoming,
  });
}

class _FixtureCard extends StatelessWidget {
  final _FixtureData data;
  const _FixtureCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Date column
          SizedBox(
            width: 64,
            child: Text(
              data.date,
              style: GoogleFonts.inter(
                color: CR.text3,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Teams
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                if (data.result != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    data.result!,
                    style: GoogleFonts.inter(
                      color: CR.text2,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Status
          if (data.upcoming)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: CR.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'UPCOMING',
                style: GoogleFonts.inter(
                  color: CR.green,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Records Tab ──────────────────────────────────────────────────────────────

class _RecordsTab extends StatelessWidget {
  const _RecordsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        Text(
          'OKINAWA LEAGUE RECORDS',
          style: GoogleFonts.inter(
            color: CR.text1,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ).animate().fadeIn(duration: 300.ms),
        const SizedBox(height: 20),

        // BATTING
        const _RecordSection(
          title: 'BATTING',
          records: [
            _RecordEntry(
              type: 'Highest Score',
              holder: '#7 Roshan',
              value: '127*',
              context: 'vs Tokyo · Aug 26',
              isNew: true,
            ),
            _RecordEntry(
              type: 'Most Runs (Season)',
              holder: '#7 Roshan',
              value: '487',
              context: '2026 Season',
              isNew: false,
            ),
            _RecordEntry(
              type: 'Best SR (min 20b)',
              holder: '#18 Bikash',
              value: '183.3',
              context: 'vs Fukuoka · Mar 15',
              isNew: false,
            ),
          ],
        ).animate().fadeIn(delay: 80.ms),
        const SizedBox(height: 20),

        // BOWLING
        const _RecordSection(
          title: 'BOWLING',
          records: [
            _RecordEntry(
              type: 'Best Figures',
              holder: '#12 Arjun',
              value: '5/18',
              context: 'vs Osaka · Jul 4',
              isNew: false,
            ),
            _RecordEntry(
              type: 'Best Economy (min 3ov)',
              holder: '#6 Pradeep',
              value: '4.2/ov',
              context: 'vs Kobe · Jun 12',
              isNew: false,
            ),
          ],
        ).animate().fadeIn(delay: 160.ms),
        const SizedBox(height: 20),

        // TEAM
        const _RecordSection(
          title: 'TEAM',
          records: [
            _RecordEntry(
              type: 'Highest Total',
              holder: 'Okinawa Warriors',
              value: '218/3',
              context: 'vs Tokyo · Aug 26',
              isNew: true,
            ),
            _RecordEntry(
              type: 'Biggest Win',
              holder: 'Okinawa Warriors',
              value: '+87 runs',
              context: 'vs Fukuoka · Mar 15',
              isNew: false,
            ),
          ],
        ).animate().fadeIn(delay: 240.ms),
      ],
    );
  }
}

class _RecordSection extends StatelessWidget {
  final String title;
  final List<_RecordEntry> records;

  const _RecordSection({
    required this.title,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: CR.text3,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: CR.cardHigh),
        ...records.map((r) => _RecordRow(entry: r)),
      ],
    );
  }
}

class _RecordEntry {
  final String type;
  final String holder;
  final String value;
  final String context;
  final bool isNew;

  const _RecordEntry({
    required this.type,
    required this.holder,
    required this.value,
    required this.context,
    required this.isNew,
  });
}

class _RecordRow extends StatelessWidget {
  final _RecordEntry entry;

  const _RecordRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CR.cardHigh, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.type.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: CR.text3,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (entry.isNew) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: CR.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'NEW',
                          style: GoogleFonts.inter(
                            color: CR.green,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  entry.holder,
                  style: GoogleFonts.inter(
                    color: CR.text1,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  entry.context,
                  style: GoogleFonts.inter(
                    color: CR.text2,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            entry.value,
            style: GoogleFonts.spaceGrotesk(
              color: CR.text1,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
