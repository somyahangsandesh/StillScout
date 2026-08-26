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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Create League — coming soon'),
                    behavior: SnackBarBehavior.floating,
                  ));
                },
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
              Tab(text: 'SEASON STORY'),
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
              _SeasonStoryTab(),
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
    _TeamRow(rank: 1, name: 'Tokyo Rhinos', p: 8, w: 6, l: 2, pts: 12, isYou: false, nrr: 0.82, form: ['W','W','L','W','W']),
    _TeamRow(rank: 2, name: 'Osaka Kings', p: 8, w: 5, l: 3, pts: 10, isYou: false, nrr: 0.42, form: ['W','L','W','W','L']),
    _TeamRow(rank: 3, name: 'Okinawa Warriors', p: 8, w: 5, l: 3, pts: 10, isYou: true, nrr: 0.31, form: ['W','W','W','W','L']),
    _TeamRow(rank: 4, name: 'Kobe Bulls', p: 8, w: 4, l: 4, pts: 8, isYou: false, nrr: -0.05, form: ['L','W','L','W','W']),
    _TeamRow(rank: 5, name: 'Fukuoka FC', p: 8, w: 3, l: 5, pts: 6, isYou: false, nrr: -0.18, form: ['L','L','W','L','W']),
    _TeamRow(rank: 6, name: 'Nagoya Stars', p: 8, w: 3, l: 5, pts: 6, isYou: false, nrr: -0.29, form: ['W','L','L','W','L']),
    _TeamRow(rank: 7, name: 'Kyoto Hawks', p: 8, w: 2, l: 6, pts: 4, isYou: false, nrr: -0.55, form: ['L','L','W','L','L']),
    _TeamRow(rank: 8, name: 'Sapporo Ice', p: 8, w: 1, l: 7, pts: 2, isYou: false, nrr: -0.91, form: ['L','L','L','L','W']),
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
              const _HeaderCell('NRR'),
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
  final double nrr;
  final List<String> form; // last 5: 'W' or 'L'

  const _TeamRow({
    required this.rank,
    required this.name,
    required this.p,
    required this.w,
    required this.l,
    required this.pts,
    required this.isYou,
    this.nrr = 0.0,
    this.form = const [],
  });
}

class _StandingsRow extends StatelessWidget {
  final _TeamRow team;
  final bool even;

  const _StandingsRow({required this.team, required this.even});

  @override
  Widget build(BuildContext context) {
    final isQualZone = team.rank <= 2;
    final nrrStr =
        team.nrr >= 0 ? '+${team.nrr.toStringAsFixed(2)}' : team.nrr.toStringAsFixed(2);
    final nrrColor = team.nrr >= 0 ? CR.green : CR.red;

    return Container(
      decoration: BoxDecoration(
        color: team.isYou
            ? CR.green.withOpacity(0.07)
            : even
                ? CR.card
                // Slightly darker than CR.card for alternating zebra stripe
                : const Color(0xFF131313),
        border: team.isYou
            ? const Border(left: BorderSide(color: CR.green, width: 3))
            : isQualZone
                ? Border(
                    left: BorderSide(
                        color: CR.green.withOpacity(0.3), width: 2),
                    bottom: BorderSide(
                        color: CR.green.withOpacity(0.08), width: 1),
                  )
                : null,
      ),
      child: Column(
        children: [
          // Main row
          SizedBox(
            height: 44,
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
                        fontSize: 12,
                        fontWeight:
                            team.isYou ? FontWeight.w700 : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                _Cell(team.p.toString()),
                _Cell(team.w.toString()),
                _Cell(nrrStr, color: nrrColor),
                _Cell(
                  team.pts.toString(),
                  bold: true,
                  color: team.isYou ? CR.green : null,
                ),
              ],
            ),
          ),
          // Form chips row
          if (team.form.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 32, bottom: 6),
              child: Row(
                children: team.form.map((f) {
                  final isW = f == 'W';
                  return Container(
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: isW
                          ? CR.green.withOpacity(0.15)
                          : CR.red.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        f,
                        style: GoogleFonts.inter(
                          color: isW ? CR.green : CR.red,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
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

// ─── Season Story Tab ─────────────────────────────────────────────────────────

class _SeasonStoryTab extends StatelessWidget {
  const _SeasonStoryTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        Text(
          'OKINAWA LEAGUE 2026 — THE STORY SO FAR',
          style: GoogleFonts.inter(
            color: CR.text1,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ).animate().fadeIn(duration: 300.ms),
        const SizedBox(height: 20),

        // Narrative paragraphs
        const _StoryParagraph(
          heading: 'Weeks 1–3',
          body:
              'Warriors and Rhinos dominated early, with Roshan KC emerging as the season\'s standout batter. Back-to-back centuries set the tone.',
        ).animate().fadeIn(delay: 80.ms),
        const SizedBox(height: 12),

        const _StoryParagraph(
          heading: 'Week 4',
          body:
              'Fukuoka Tigers upset the standings with back-to-back wins. Three teams within 2 points — the title race is wide open.',
        ).animate().fadeIn(delay: 140.ms),
        const SizedBox(height: 12),

        const _StoryParagraph(
          heading: 'Week 7 (last week)',
          highlight: true,
          body:
              'Roshan KC broke the league record for highest individual score — 127* vs Osaka Kings. Warriors are now 3 points clear at the top.',
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 24),

        // Current Form table
        Text(
          'CURRENT FORM',
          style: GoogleFonts.inter(
            color: CR.text3,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ).animate().fadeIn(delay: 240.ms),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: CR.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            children: [
              _FormRow('Okinawa Warriors', ['W', 'W', 'W', 'W', 'L'], 'HOT', isYou: true),
              Divider(height: 1, color: CR.cardHigh),
              _FormRow('Tokyo Rhinos', ['W', 'L', 'W', 'W', 'W'], 'STRONG'),
              Divider(height: 1, color: CR.cardHigh),
              _FormRow('Fukuoka Tigers', ['L', 'W', 'W', 'L', 'W'], 'INCONSISTENT'),
            ],
          ),
        ).animate().fadeIn(delay: 280.ms),
        const SizedBox(height: 24),

        // Title race
        Text(
          'TITLE RACE',
          style: GoogleFonts.inter(
            color: CR.text3,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ).animate().fadeIn(delay: 320.ms),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CR.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TitleRaceRow('Okinawa Warriors', 'Win 2 of last 3'),
              SizedBox(height: 8),
              _TitleRaceRow(
                  'Tokyo Rhinos', 'Win all 3 + Warriors drop points'),
            ],
          ),
        ).animate().fadeIn(delay: 340.ms),
        const SizedBox(height: 24),

        // Records this season
        Text(
          'RECORDS THIS SEASON',
          style: GoogleFonts.inter(
            color: CR.text3,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ).animate().fadeIn(delay: 380.ms),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: CR.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            children: [
              _SeasonRecordRow(label: 'Highest Score', value: '127*  Roshan', detail: 'Week 7'),
              Divider(height: 1, color: CR.cardHigh),
              _SeasonRecordRow(label: 'Best Bowling', value: '5/18  Bikash', detail: 'Week 4'),
              Divider(height: 1, color: CR.cardHigh),
              _SeasonRecordRow(label: 'Most MVPs', value: 'Roshan  ×3', detail: 'Season'),
            ],
          ),
        ).animate().fadeIn(delay: 420.ms),
      ],
    );
  }
}

class _StoryParagraph extends StatelessWidget {
  final String heading;
  final String body;
  final bool highlight;

  const _StoryParagraph({
    required this.heading,
    required this.body,
    this.highlight = false,
  });

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading.toUpperCase(),
            style: GoogleFonts.inter(
              color: highlight ? CR.green : CR.text3,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: GoogleFonts.inter(
              color: CR.text1,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormRow extends StatelessWidget {
  final String team;
  final List<String> form;
  final String label;
  final bool isYou;

  const _FormRow(this.team, this.form, this.label, {this.isYou = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isYou ? CR.green.withOpacity(0.06) : Colors.transparent,
      ),
      child: Row(
        children: [
          if (isYou)
            Container(
              width: 3,
              height: 20,
              margin: const EdgeInsets.only(right: 10),
              color: CR.green,
            ),
          Expanded(
            child: Text(
              team,
              style: GoogleFonts.inter(
                color: isYou ? CR.text1 : CR.text2,
                fontSize: 13,
                fontWeight: isYou ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Row(
            children: form.map((f) {
              final isW = f == 'W';
              return Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: isW
                      ? CR.green.withOpacity(0.15)
                      : CR.red.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    f,
                    style: GoogleFonts.inter(
                      color: isW ? CR.green : CR.red,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: isYou ? CR.gold : CR.text3,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleRaceRow extends StatelessWidget {
  final String team;
  final String needs;

  const _TitleRaceRow(this.team, this.needs);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          team,
          style: GoogleFonts.inter(
            color: CR.text1,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'needs: $needs',
            style: GoogleFonts.inter(
              color: CR.text2,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _SeasonRecordRow extends StatelessWidget {
  final String label;
  final String value;
  final String detail;

  const _SeasonRecordRow({
    required this.label,
    required this.value,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: CR.text3,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: CR.text1,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            detail,
            style: GoogleFonts.inter(
              color: CR.text3,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
