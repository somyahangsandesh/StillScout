import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  bool _hasLeague = false;

  @override
  void initState() {
    super.initState();
    _hasLeague = !widget.isNewOrganizer;
    if (!_hasLeague) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/organizer/setup');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasLeague) {
      return const Scaffold(backgroundColor: CR.bg, body: SizedBox.shrink());
    }
    return const _OrganizerDashboard();
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          children: [
            // ── Top bar ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ORGANIZER',
                          style: GoogleFonts.oswald(
                            color: CR.gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 2.5,
                          ),
                        ),
                        Text(
                          'Okinawa League · Season 2026 · Week 8',
                          style: GoogleFonts.inter(
                            color: CR.text1,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: CR.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: CR.cardHigh),
                      ),
                      child: Text(
                        '← Player',
                        style: GoogleFonts.inter(
                            color: CR.text2, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 250.ms),

            // ── NEXT ACTION ───────────────────────────────────────────
            _NextActionCard(
              urgency: _Urgency.warning,
              title: 'Upcoming match has no scorer assigned',
              detail: 'Warriors vs Rhinos · Saturday',
              actionLabel: 'ASSIGN SCORER →',
              onAction: () => _toast(context, 'Assign scorer — coming soon'),
            ).animate().fadeIn(delay: 80.ms),

            const SizedBox(height: 24),

            // ── THIS WEEK ─────────────────────────────────────────────
            _sectionLabel('THIS WEEK'),
            const SizedBox(height: 10),
            _WeekMatchItem(
              day: 'Saturday',
              teams: 'Warriors vs Rhinos',
              scorerAssigned: false,
              onAssign: () => _toast(context, 'Assign scorer — coming soon'),
              onEdit: () => _toast(context, 'Edit match — coming soon'),
            ).animate().fadeIn(delay: 140.ms),
            const SizedBox(height: 8),
            _WeekMatchItem(
              day: 'Sunday',
              teams: 'Osaka vs Fukuoka',
              scorerAssigned: true,
              scorerName: 'Bikash',
              onAssign: () {},
              onEdit: () => _toast(context, 'Edit match — coming soon'),
            ).animate().fadeIn(delay: 180.ms),

            const SizedBox(height: 24),

            // ── PENDING APPROVAL ──────────────────────────────────────
            _sectionLabel('PENDING APPROVAL'),
            const SizedBox(height: 10),
            _PendingApprovalCard(
              result: 'Warriors 174/6  def  Rhinos 172/9',
              onApprove: () => _toast(context, 'Result approved!'),
              onEdit: () => _toast(context, 'Edit result — coming soon'),
            ).animate().fadeIn(delay: 220.ms),

            const SizedBox(height: 24),

            // ── QUICK ACTIONS ─────────────────────────────────────────
            _sectionLabel('QUICK ACTIONS'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _QuickBtn(
                    icon: Icons.add_circle_outline,
                    label: '+ Add Match',
                    onTap: () => _toast(context, 'Add match — coming soon'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickBtn(
                    icon: Icons.person_add_outlined,
                    label: '+ Add Player',
                    onTap: () => _toast(context, 'Add player — coming soon'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickBtn(
                    icon: Icons.list_alt_outlined,
                    label: 'All Results',
                    onTap: () => _toast(context, 'All results — coming soon'),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 280.ms),

            const SizedBox(height: 24),

            // ── SEASON SNAPSHOT ───────────────────────────────────────
            _sectionLabel('SEASON SNAPSHOT'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CR.card,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _SnapStat('Matches', '8'),
                      const SizedBox(width: 24),
                      _SnapStat('Players', '45'),
                      const SizedBox(width: 24),
                      _SnapStat('Disputes', '0', valueColor: CR.green),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: CR.cardHigh),
                  const SizedBox(height: 12),
                  _SnapRecord('Top batter', 'Roshan KC', '487 runs'),
                  const SizedBox(height: 6),
                  _SnapRecord('Top bowler', 'Bikash Rai', '21 wkts'),
                ],
              ),
            ).animate().fadeIn(delay: 340.ms),

            const SizedBox(height: 24),

            // ── STANDINGS (mini) ──────────────────────────────────────
            _sectionLabel('STANDINGS'),
            const SizedBox(height: 10),
            _MiniStandingsTable().animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  static Widget _sectionLabel(String text) {
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
          text.toUpperCase(),
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

  static void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
}

// ─── Next Action Card ─────────────────────────────────────────────────────────

enum _Urgency { blocking, warning, ok }

class _NextActionCard extends StatelessWidget {
  final _Urgency urgency;
  final String title;
  final String detail;
  final String actionLabel;
  final VoidCallback onAction;

  const _NextActionCard({
    required this.urgency,
    required this.title,
    required this.detail,
    required this.actionLabel,
    required this.onAction,
  });

  Color get _color => switch (urgency) {
        _Urgency.blocking => CR.ballRed,
        _Urgency.warning => CR.amber,
        _Urgency.ok => CR.green,
      };

  String get _icon => switch (urgency) {
        _Urgency.blocking => '🚨',
        _Urgency.warning => '⚠️',
        _Urgency.ok => '✅',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'NEXT ACTION',
                style: GoogleFonts.oswald(
                    color: _color,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2),
              ),
              const Spacer(),
              Text(_icon, style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.inter(
                color: CR.text1, fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: GoogleFonts.inter(color: CR.text2, fontSize: 13),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: _color,
                foregroundColor: CR.inv,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(
                actionLabel,
                style: GoogleFonts.oswald(
                    fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1, color: CR.inv),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Week Match Item ──────────────────────────────────────────────────────────

class _WeekMatchItem extends StatelessWidget {
  final String day;
  final String teams;
  final bool scorerAssigned;
  final String? scorerName;
  final VoidCallback onAssign;
  final VoidCallback onEdit;

  const _WeekMatchItem({
    required this.day,
    required this.teams,
    required this.scorerAssigned,
    this.scorerName,
    required this.onAssign,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  day,
                  style: GoogleFonts.inter(color: CR.text3, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  teams,
                  style: GoogleFonts.inter(
                      color: CR.text1, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                if (scorerAssigned && scorerName != null)
                  Row(
                    children: [
                      Text(
                        'Scorer: $scorerName',
                        style: GoogleFonts.inter(
                            color: CR.green, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 4),
                      const Text('✓', style: TextStyle(color: CR.green, fontSize: 12)),
                    ],
                  )
                else
                  Row(
                    children: [
                      const Text('⚠', style: TextStyle(color: CR.amber, fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        'Scorer: unassigned',
                        style: GoogleFonts.inter(
                            color: CR.amber, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Action buttons
          Row(
            children: [
              if (!scorerAssigned)
                GestureDetector(
                  onTap: onAssign,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: CR.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CR.amber.withOpacity(0.3)),
                    ),
                    child: Text(
                      'ASSIGN',
                      style: GoogleFonts.oswald(
                          color: CR.amber, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: CR.cardHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'EDIT',
                    style: GoogleFonts.oswald(
                        color: CR.text2, fontSize: 10, fontWeight: FontWeight.w600),
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

// ─── Pending Approval Card ────────────────────────────────────────────────────

class _PendingApprovalCard extends StatelessWidget {
  final String result;
  final VoidCallback onApprove;
  final VoidCallback onEdit;

  const _PendingApprovalCard({
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
        border: Border.all(color: CR.gold.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: CR.gold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: CR.gold.withOpacity(0.3)),
                      ),
                      child: Text(
                        'PENDING',
                        style: GoogleFonts.oswald(
                            color: CR.gold, fontSize: 9, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  result,
                  style: GoogleFonts.inter(
                      color: CR.text1, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Action buttons
          Row(
            children: [
              GestureDetector(
                onTap: onApprove,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: CR.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'APPROVE',
                    style: GoogleFonts.oswald(
                        color: CR.inv, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: CR.cardHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'EDIT',
                    style: GoogleFonts.oswald(
                        color: CR.text2, fontSize: 11, fontWeight: FontWeight.w600),
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

// ─── Quick Button ─────────────────────────────────────────────────────────────

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: CR.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CR.cardHigh),
        ),
        child: Column(
          children: [
            Icon(icon, color: CR.text2, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                  color: CR.text2, fontSize: 11, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Season Snapshot Widgets ──────────────────────────────────────────────────

class _SnapStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SnapStat(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: valueColor ?? CR.text1,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(color: CR.text3, fontSize: 11),
        ),
      ],
    );
  }
}

class _SnapRecord extends StatelessWidget {
  final String label;
  final String name;
  final String stat;

  const _SnapRecord(this.label, this.name, this.stat);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: GoogleFonts.inter(color: CR.text3, fontSize: 12)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(name,
              style: GoogleFonts.inter(
                  color: CR.text1, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        Text(
          stat,
          style: GoogleFonts.spaceGrotesk(
              color: CR.green, fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

// ─── Mini Standings Table ─────────────────────────────────────────────────────

class _MiniStandingsTable extends StatelessWidget {
  static const _rows = [
    ('Warriors', 5, 2, 10),
    ('Rhinos', 4, 3, 8),
    ('Osaka', 3, 4, 6),
    ('Fukuoka', 1, 6, 2),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.circular(14),
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
                  child: Text('TEAM',
                      style: GoogleFonts.oswald(
                          color: CR.text3,
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w500)),
                ),
                const _MHdr('W'),
                const _MHdr('L'),
                const _MHdr('PTS'),
              ],
            ),
          ),
          Container(height: 1, color: CR.cardHigh),
          ..._rows.asMap().entries.map((entry) {
            final idx = entry.key;
            final (name, w, l, pts) = entry.value;
            final isLast = idx == _rows.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        child: Text(
                          '${idx + 1}.',
                          style: GoogleFonts.spaceGrotesk(
                            color: idx == 0 ? CR.gold : CR.text3,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(name,
                            style: GoogleFonts.inter(
                                color: CR.text1, fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                      _MVal(w.toString(), green: true),
                      _MVal(l.toString()),
                      _MVal(pts.toString(), bold: true, green: true),
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

class _MHdr extends StatelessWidget {
  final String text;
  const _MHdr(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.oswald(
            color: CR.text3, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _MVal extends StatelessWidget {
  final String text;
  final bool bold;
  final bool green;

  const _MVal(this.text, {this.bold = false, this.green = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.spaceGrotesk(
          color: green ? CR.text1 : CR.text2,
          fontSize: 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}
