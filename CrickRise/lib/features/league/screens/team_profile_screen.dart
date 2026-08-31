import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TEAM PROFILE SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class TeamProfileScreen extends StatelessWidget {
  final String teamId;
  const TeamProfileScreen({super.key, required this.teamId});

  // Mock data — replace with real data source
  static const _teamName = 'Okinawa Warriors';
  static const _teamOvr = 82;

  static const _squad = [
    _SquadMember(jersey: 7, name: 'Roshan KC', ovr: 86, role: 'BAT ALL-ROUNDER', isCaptain: true),
    _SquadMember(jersey: 18, name: 'Sandip Thapa', ovr: 79, role: 'BATTER'),
    _SquadMember(jersey: 23, name: 'Bikash Rai', ovr: 74, role: 'BOWLER'),
    _SquadMember(jersey: 12, name: 'Arjun Magar', ovr: 72, role: 'BOWL ALL-ROUNDER'),
    _SquadMember(jersey: 4, name: 'Suraj Rai', ovr: 71, role: 'BATTER'),
    _SquadMember(jersey: 9, name: 'Dev Limbu', ovr: 70, role: 'WICKETKEEPER'),
    _SquadMember(jersey: 6, name: 'Pradeep Shrestha', ovr: 68, role: 'BOWLER'),
    _SquadMember(jersey: 2, name: 'Kumar Tamang', ovr: 65, role: 'BOWLER'),
    _SquadMember(jersey: 15, name: 'Hari Rana', ovr: 63, role: 'BAT ALL-ROUNDER'),
    _SquadMember(jersey: 22, name: 'Rajan Basnet', ovr: 61, role: 'BATTER'),
    _SquadMember(jersey: 3, name: 'Sagar Poudel', ovr: 59, role: 'BOWLER'),
  ];

  static const _form = ['W', 'W', 'L', 'W', 'L'];
  static const _nextMatch = 'Sunday vs Fukuoka Tigers';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CR.bg,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            backgroundColor: CR.bg,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: CR.t2, size: 18),
              onPressed: () => context.pop(),
            ),
            title: Text(
              _teamName,
              style: GoogleFonts.oswald(
                color: CR.t1,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: CR.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CR.gold.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'OVR',
                      style: GoogleFonts.oswald(
                          color: CR.gold, fontSize: 10, letterSpacing: 1.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_teamOvr',
                      style: GoogleFonts.spaceGrotesk(
                          color: CR.gold, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Squad ────────────────────────────────────────────────────
                _sectionLabel('SQUAD (${_squad.length} PLAYERS)'),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: CR.card,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: _squad.asMap().entries.map((e) {
                      final i = e.key;
                      final m = e.value;
                      final isLast = i == _squad.length - 1;
                      return Column(
                        children: [
                          _SquadRow(member: m)
                              .animate()
                              .fadeIn(delay: (i * 40).ms),
                          if (!isLast)
                            const Divider(height: 1, color: CR.cardHigh, indent: 16),
                        ],
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Season Stats ─────────────────────────────────────────────
                _sectionLabel('SEASON STATS'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CR.card,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      _StatRow('Matches', '8'),
                      const SizedBox(height: 10),
                      _StatRow('Won', '5', valueColor: CR.green),
                      const SizedBox(height: 10),
                      _StatRow('Lost', '3', valueColor: CR.ballRed),
                      const SizedBox(height: 10),
                      _StatRow('NRR', '+0.31', valueColor: CR.green),
                      const SizedBox(height: 10),
                      _StatRow('Points', '10'),
                      const Divider(height: 24, color: CR.cardHigh),
                      _StatRow('Highest score', '218/3 vs Osaka (Week 9)'),
                      const SizedBox(height: 10),
                      _StatRow('Best bowling', '5/18 by Bikash (Week 4)'),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 28),

                // ── Form ─────────────────────────────────────────────────────
                _sectionLabel('FORM (LAST 5)'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CR.card,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: _form.asMap().entries.map((e) {
                      final isW = e.value == 'W';
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Column(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isW
                                    ? CR.green.withOpacity(0.15)
                                    : CR.ballRed.withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isW
                                      ? CR.green.withOpacity(0.4)
                                      : CR.ballRed.withOpacity(0.4),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  e.value,
                                  style: GoogleFonts.oswald(
                                    color: isW ? CR.green : CR.ballRed,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ).animate().fadeIn(delay: 280.ms),

                const SizedBox(height: 28),

                // ── Upcoming ─────────────────────────────────────────────────
                _sectionLabel('UPCOMING'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CR.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: CR.green.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: CR.green, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        _nextMatch,
                        style: GoogleFonts.inter(
                          color: CR.t1,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 360.ms),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
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
            color: CR.t2,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }
}

// ─── Squad Row ────────────────────────────────────────────────────────────────

class _SquadMember {
  final int jersey;
  final String name;
  final int ovr;
  final String role;
  final bool isCaptain;

  const _SquadMember({
    required this.jersey,
    required this.name,
    required this.ovr,
    required this.role,
    this.isCaptain = false,
  });
}

class _SquadRow extends StatelessWidget {
  final _SquadMember member;
  const _SquadRow({required this.member});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Jersey
          SizedBox(
            width: 32,
            child: Text(
              '#${member.jersey}',
              style: GoogleFonts.spaceGrotesk(
                color: CR.t3,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Name + captain
          Expanded(
            child: Row(
              children: [
                Text(
                  member.name,
                  style: GoogleFonts.inter(
                    color: CR.t1,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (member.isCaptain) ...[
                  const SizedBox(width: 6),
                  Text(
                    '©',
                    style: GoogleFonts.inter(
                      color: CR.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // OVR
          Container(
            width: 36,
            height: 28,
            decoration: BoxDecoration(
              color: CR.goldDim,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${member.ovr}',
                style: GoogleFonts.spaceGrotesk(
                  color: CR.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Role
          SizedBox(
            width: 88,
            child: Text(
              member.role,
              style: GoogleFonts.oswald(
                color: CR.t3,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Row ─────────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: CR.t3, fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: valueColor ?? CR.t1,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
