import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

class OrganizerHomeScreen extends StatefulWidget {
  final bool isNewOrganizer;
  const OrganizerHomeScreen({super.key, this.isNewOrganizer = false});

  @override
  State<OrganizerHomeScreen> createState() => _OrganizerHomeScreenState();
}

class _OrganizerHomeScreenState extends State<OrganizerHomeScreen> {
  bool _hasLeague = false; // new organizers start without a league

  @override
  void initState() {
    super.initState();
    // If arriving from onboarding, show creation flow first
    _hasLeague = !widget.isNewOrganizer;
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasLeague) {
      return _CreateLeagueScreen(onCreated: () => setState(() => _hasLeague = true));
    }
    return const _OrganizerDashboard();
  }
}

// ─── Create League Screen (shown to new organizers) ───────────────────────────

class _CreateLeagueScreen extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateLeagueScreen({required this.onCreated});

  @override
  State<_CreateLeagueScreen> createState() => _CreateLeagueScreenState();
}

class _CreateLeagueScreenState extends State<_CreateLeagueScreen> {
  final _nameCtrl = TextEditingController();
  int _overs = 20;
  static const _overOpts = [5, 10, 15, 20];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CR.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Row(children: [
                  const Icon(Icons.arrow_back_ios, color: CR.text3, size: 14),
                  const SizedBox(width: 4),
                  Text('Back', style: GoogleFonts.inter(color: CR.text3, fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 24),
              Text('CREATE YOUR LEAGUE',
                  style: GoogleFonts.inter(color: CR.gold, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text('Set up your cricket community',
                  style: GoogleFonts.inter(color: CR.text1, fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 32),

              // League name
              Text('LEAGUE NAME', style: GoogleFonts.inter(color: CR.text3, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameCtrl,
                style: GoogleFonts.inter(color: CR.text1, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'e.g. Okinawa Nepali Cricket League',
                  hintStyle: GoogleFonts.inter(color: CR.text3, fontSize: 15),
                  filled: true,
                  fillColor: CR.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: CR.green, width: 2),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 28),

              // Format
              Text('FORMAT (OVERS PER SIDE)', style: GoogleFonts.inter(color: CR.text3, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
              const SizedBox(height: 10),
              Row(
                children: _overOpts.map((o) {
                  final sel = _overs == o;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _overs = o),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 48,
                          decoration: BoxDecoration(
                            color: sel ? CR.green : CR.card,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text('$o',
                                style: GoogleFonts.spaceGrotesk(
                                    color: sel ? CR.inv : CR.text2,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _nameCtrl.text.trim().length > 3 ? widget.onCreated : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CR.green,
                    foregroundColor: CR.inv,
                    disabledBackgroundColor: CR.cardHigh,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    'CREATE LEAGUE →',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15,
                        color: _nameCtrl.text.trim().length > 3 ? CR.inv : CR.text3),
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

// ─── Organizer Dashboard ──────────────────────────────────────────────────────

class _OrganizerDashboard extends StatelessWidget {
  const _OrganizerDashboard();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CR.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back to player view
              GestureDetector(
                onTap: () => context.pop(),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back_ios, color: CR.text3, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Back to Player View',
                      style: GoogleFonts.inter(
                        color: CR.text3,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Text(
                'ORGANIZER',
                style: GoogleFonts.inter(
                  color: CR.gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Okinawa Nepali Cricket League',
                style: GoogleFonts.inter(
                  color: CR.text1,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Season 2026 · Active',
                style: GoogleFonts.inter(
                  color: CR.green,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),

              // Quick actions
              const CRSectionLabel('Quick Actions'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.add_circle_outline,
                      label: '+ Create Fixture',
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.person_add_outlined,
                      label: '+ Add Player',
                      onTap: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Upcoming matches
              const CRSectionLabel('Upcoming Matches'),
              const SizedBox(height: 12),
              _UpcomingMatchItem(
                homeTeam: 'Okinawa',
                awayTeam: 'Tokyo',
                day: 'SAT',
                scorerName: 'Roshan KC',
                scorerJersey: '#7',
                scorerAssigned: true,
                onTap: () {},
              ),
              const SizedBox(height: 8),
              _UpcomingMatchItem(
                homeTeam: 'Osaka',
                awayTeam: 'Fukuoka',
                day: 'SUN',
                scorerAssigned: false,
                onTap: () {},
              ),
              const SizedBox(height: 28),

              // Results pending approval
              const CRSectionLabel('Pending Approval'),
              const SizedBox(height: 12),
              _PendingResultCard(
                homeTeam: 'Okinawa',
                awayTeam: 'Tokyo',
                result: '127/4 def 98/9',
                onApprove: () {},
                onEdit: () {},
              ),
              const SizedBox(height: 28),

              // Compact standings
              const CRSectionLabel('Standings'),
              const SizedBox(height: 12),
              _StandingsTable(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quick Action Button ──────────────────────────────────────────────────────

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: CR.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CR.cardHigh),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: CR.text2, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: CR.text1,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Upcoming Match Item ──────────────────────────────────────────────────────

class _UpcomingMatchItem extends StatelessWidget {
  final String homeTeam;
  final String awayTeam;
  final String day;
  final bool scorerAssigned;
  final String? scorerName;
  final String? scorerJersey;
  final VoidCallback onTap;

  const _UpcomingMatchItem({
    required this.homeTeam,
    required this.awayTeam,
    required this.day,
    required this.scorerAssigned,
    this.scorerName,
    this.scorerJersey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CR.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$homeTeam vs $awayTeam',
                    style: GoogleFonts.inter(
                      color: CR.text1,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        day,
                        style: GoogleFonts.inter(
                          color: CR.text3,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (scorerAssigned && scorerName != null) ...[
                        Text(
                          'Scorer: $scorerJersey $scorerName',
                          style: GoogleFonts.inter(
                            color: CR.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('✓',
                            style: TextStyle(color: CR.green, fontSize: 12)),
                      ] else ...[
                        Text(
                          'Scorer: unassigned',
                          style: GoogleFonts.inter(
                            color: CR.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('⚠',
                            style: TextStyle(color: CR.orange, fontSize: 12)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: CR.text3, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── Pending Result Card ──────────────────────────────────────────────────────

class _PendingResultCard extends StatelessWidget {
  final String homeTeam;
  final String awayTeam;
  final String result;
  final VoidCallback onApprove;
  final VoidCallback onEdit;

  const _PendingResultCard({
    required this.homeTeam,
    required this.awayTeam,
    required this.result,
    required this.onApprove,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CR.gold.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$homeTeam vs $awayTeam',
                      style: GoogleFonts.inter(
                        color: CR.text1,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      result,
                      style: GoogleFonts.inter(
                        color: CR.text2,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CR.gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: CR.gold.withOpacity(0.3)),
                ),
                child: Text(
                  'PENDING',
                  style: GoogleFonts.inter(
                    color: CR.gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onApprove,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: CR.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'APPROVE',
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
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: CR.cardHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'EDIT',
                        style: GoogleFonts.inter(
                          color: CR.text2,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Standings Table ──────────────────────────────────────────────────────────

class _StandingsTable extends StatelessWidget {
  static const _teams = [
    ('Okinawa Warriors', 6, 5, 1, 10),
    ('Tokyo Rhinos', 6, 4, 2, 8),
    ('Osaka Kings', 6, 3, 3, 6),
    ('Fukuoka Bulls', 6, 1, 5, 2),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    'TEAM',
                    style: GoogleFonts.inter(
                      color: CR.text3,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const _StandingHeader('P'),
                const _StandingHeader('W'),
                const _StandingHeader('L'),
                const _StandingHeader('PTS'),
              ],
            ),
          ),
          Container(height: 1, color: CR.cardHigh),
          ..._teams.asMap().entries.map((entry) {
            final idx = entry.key;
            final (name, p, w, l, pts) = entry.value;
            final isLast = idx == _teams.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 11),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        child: Text(
                          '${idx + 1}',
                          style: GoogleFonts.spaceGrotesk(
                            color: idx == 0 ? CR.gold : CR.text3,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.inter(
                            color: CR.text1,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      _StandingValue(p.toString()),
                      _StandingValue(w.toString(), highlight: true),
                      _StandingValue(l.toString()),
                      _StandingValue(
                        pts.toString(),
                        bold: true,
                        highlight: true,
                      ),
                    ],
                  ),
                ),
                if (!isLast) Container(height: 1, color: CR.cardHigh),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _StandingHeader extends StatelessWidget {
  final String text;
  const _StandingHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: CR.text3,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _StandingValue extends StatelessWidget {
  final String text;
  final bool highlight;
  final bool bold;

  const _StandingValue(this.text,
      {this.highlight = false, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.spaceGrotesk(
          color: highlight ? CR.text1 : CR.text2,
          fontSize: 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}
