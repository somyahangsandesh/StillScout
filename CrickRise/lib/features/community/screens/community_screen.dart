import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../player/providers/player_provider.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(currentPlayerProvider);

    return Scaffold(
      backgroundColor: CR.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'THE COMMUNITY',
                    style: GoogleFonts.inter(
                      color: CR.t1,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                  const Spacer(),
                  // Region dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: CR.card,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'JAPAN',
                          style: GoogleFonts.inter(
                            color: CR.t2,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, color: CR.t3, size: 14),
                      ],
                    ),
                  ).animate().fadeIn(delay: 80.ms),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: CR.card,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabCtrl,
                  labelColor: CR.t1,
                  unselectedLabelColor: CR.t3,
                  indicator: BoxDecoration(
                    color: CR.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                  tabs: const [
                    Tab(text: 'OVR'),
                    Tab(text: 'FORM'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Top Players list
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _TopPlayersTab(currentPlayerId: player.id, rankType: 'OVR'),
                  _TopPlayersTab(currentPlayerId: player.id, rankType: 'FORM'),
                ],
              ),
            ),

            // Records section
            const _RecordsSection(),

            // The Movement
            const _TheMovementSection(),
          ],
        ),
      ),
    );
  }
}

// ─── Top Players Tab ──────────────────────────────────────────────────────────

class _TopPlayersTab extends StatelessWidget {
  final String currentPlayerId;
  final String rankType;

  const _TopPlayersTab({
    required this.currentPlayerId,
    required this.rankType,
  });

  static const _players = [
    _PlayerEntry(rank: 1, name: 'Roshan KC', crNum: 'CR-1247', team: 'Okinawa Warriors', ovr: 91, bat: 94, bowl: 78, form: 93, isHot: true),
    _PlayerEntry(rank: 2, name: 'Dipesh Sharma', crNum: 'CR-0441', team: 'Tokyo Rhinos', ovr: 88, bat: 90, bowl: 71, form: 86, isHot: false),
    _PlayerEntry(rank: 3, name: 'Bikash Rai', crNum: 'CR-0892', team: 'Okinawa Warriors', ovr: 86, bat: 84, bowl: 79, form: 88, isHot: true),
    _PlayerEntry(rank: 4, name: 'Anil Tamang', crNum: 'CR-1103', team: 'Osaka Nepal XI', ovr: 83, bat: 72, bowl: 88, form: 81, isHot: false),
    _PlayerEntry(rank: 5, name: 'Sandip Gurung', crNum: 'CR-0654', team: 'Fukuoka Tigers', ovr: 81, bat: 85, bowl: 65, form: 79, isHot: false),
    _PlayerEntry(rank: 6, name: 'Rajan KC', crNum: 'CR-1412', team: 'Tokyo Rhinos', ovr: 79, bat: 76, bowl: 80, form: 74, isHot: false),
    _PlayerEntry(rank: 7, name: 'Dev Limbu', crNum: 'CR-0329', team: 'Okinawa Warriors', ovr: 77, bat: 79, bowl: 66, form: 82, isHot: false),
    _PlayerEntry(rank: 8, name: 'Pradeep Shrestha', crNum: 'CR-1567', team: 'Kobe Bulls', ovr: 75, bat: 68, bowl: 82, form: 71, isHot: false),
  ];

  int _valueForType(_PlayerEntry p) {
    switch (rankType) {
      case 'BAT': return p.bat;
      case 'BOWL': return p.bowl;
      case 'FORM': return p.form;
      default: return p.ovr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [..._players]
      ..sort((a, b) => _valueForType(b).compareTo(_valueForType(a)));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: sorted.length,
      itemBuilder: (ctx, i) {
        final p = sorted[i];
        final isMe = p.name == 'Roshan KC';
        return _PlayerRow(
          entry: p,
          rank: i + 1,
          value: _valueForType(p),
          rankType: rankType,
          isMe: isMe,
        ).animate().fadeIn(delay: (i * 80).ms);
      },
    );
  }
}

class _PlayerEntry {
  final int rank;
  final String name;
  final String crNum;
  final String team;
  final int ovr;
  final int bat;
  final int bowl;
  final int form;
  final bool isHot;

  const _PlayerEntry({
    required this.rank,
    required this.name,
    required this.crNum,
    required this.team,
    required this.ovr,
    required this.bat,
    required this.bowl,
    required this.form,
    required this.isHot,
  });
}

class _PlayerRow extends StatelessWidget {
  final _PlayerEntry entry;
  final int rank;
  final int value;
  final String rankType;
  final bool isMe;

  const _PlayerRow({
    required this.entry,
    required this.rank,
    required this.value,
    required this.rankType,
    required this.isMe,
  });

  Widget _rankIndicator(int r) {
    if (r == 1) {
      return const Text(
        '🥇',
        style: TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      );
    }
    if (r == 2) {
      return const Text(
        '🥈',
        style: TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      );
    }
    if (r == 3) {
      return const Text(
        '🥉',
        style: TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      );
    }
    return Text(
      '#$r',
      style: GoogleFonts.spaceGrotesk(
        color: CR.t3,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      textAlign: TextAlign.center,
    );
  }

  @override
  Widget build(BuildContext context) {
    Color medalTint() {
      if (isMe) return CR.green.withOpacity(0.06);
      if (rank == 1) return CR.gold.withOpacity(0.04);
      if (rank == 2) return const Color(0xFF9E9E9E).withOpacity(0.04);
      if (rank == 3) return const Color(0xFF8D4A1F).withOpacity(0.04);
      return Colors.transparent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: medalTint(),
        border: isMe
            ? const Border(left: BorderSide(color: CR.green, width: 3))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: _rankIndicator(rank),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.name,
                        style: GoogleFonts.inter(
                          color: isMe ? CR.t1 : CR.t2,
                          fontSize: 14,
                          fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (entry.isHot)
                      const Text('🔥', style: TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.crNum}  ·  ${entry.team}',
                  style: GoogleFonts.inter(
                    color: CR.t3,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value.toString(),
                style: GoogleFonts.spaceGrotesk(
                  color: isMe ? CR.gold : CR.t2,
                  fontSize: rank <= 3 ? 22 : 18,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              Text(
                rankType,
                style: GoogleFonts.inter(
                  color: CR.t3,
                  fontSize: 9,
                  letterSpacing: 1,
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

// ─── Records Section ──────────────────────────────────────────────────────────

class _RecordsSection extends StatelessWidget {
  const _RecordsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RECORDS',
            style: GoogleFonts.inter(
              color: CR.t3,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          const _RecordLine(label: 'Most career runs', holder: 'Roshan KC', value: '2,418'),
          const _RecordLine(label: 'Highest score ever', holder: 'Anil Tamang', value: '147*'),
          const _RecordLine(label: 'Best bowling figures', holder: 'Bikash Rai', value: '6/14'),
          const _RecordLine(label: 'Most sessions played', holder: 'Roshan KC', value: '87'),
        ],
      ),
    );
  }
}

class _RecordLine extends StatelessWidget {
  final String label;
  final String holder;
  final String value;

  const _RecordLine({
    required this.label,
    required this.holder,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(color: CR.t3, fontSize: 11),
                ),
                Text(
                  holder,
                  style: GoogleFonts.inter(
                    color: CR.t1,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: CR.t1,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── The Movement Section ─────────────────────────────────────────────────────

class _TheMovementSection extends StatelessWidget {
  const _TheMovementSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THE MOVEMENT',
            style: GoogleFonts.inter(
              color: CR.t3,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '1,847 sessions recorded in Japan',
            style: GoogleFonts.inter(
              color: CR.t1,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '312 players with Cricket Passports',
            style: GoogleFonts.inter(color: CR.t2, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            'Last session: 2 hours ago',
            style: GoogleFonts.inter(color: CR.t3, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            '3 matches in progress right now',
            style: GoogleFonts.inter(
              color: CR.green,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
