import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

class TeamAssignmentScreen extends StatefulWidget {
  const TeamAssignmentScreen({super.key});

  @override
  State<TeamAssignmentScreen> createState() => _TeamAssignmentScreenState();
}

class _TeamAssignmentScreenState extends State<TeamAssignmentScreen> {
  static const _allPlayers = [
    'Roshan KC #7',
    'Bikash Rai #23',
    'Sandip Gurung #18',
    'Dev Limbu #9',
    'Arjun Magar #12',
    'Suraj Rai #4',
    'Pradeep Shrestha #6',
    'Kumar Tamang #2',
    'Hari Rana #15',
    'Rajan Basnet #22',
  ];

  late List<String> _teamA;
  late List<String> _teamB;

  @override
  void initState() {
    super.initState();
    final mid = _allPlayers.length ~/ 2;
    _teamA = List.from(_allPlayers.sublist(0, mid));
    _teamB = List.from(_allPlayers.sublist(mid));
  }

  void _randomize() {
    final all = [..._teamA, ..._teamB]..shuffle();
    setState(() {
      final mid = all.length ~/ 2;
      _teamA = all.sublist(0, mid);
      _teamB = all.sublist(mid);
    });
  }

  void _moveToB(String name) {
    setState(() {
      _teamA.remove(name);
      _teamB.add(name);
    });
  }

  void _moveToA(String name) {
    setState(() {
      _teamB.remove(name);
      _teamA.add(name);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CR.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_ios_new, color: CR.t2, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'ASSIGN TEAMS',
                    style: GoogleFonts.inter(
                      color: CR.t1,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _randomize,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: CR.card,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shuffle, color: CR.t2, size: 14),
                          const SizedBox(width: 5),
                          Text(
                            'RANDOMIZE',
                            style: GoogleFonts.inter(
                              color: CR.t2,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 200.ms),
            ),
            const SizedBox(height: 12),

            Text(
              'Tap a player to move them between teams',
              style: GoogleFonts.inter(color: CR.t3, fontSize: 12),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 16),

            // Teams
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _TeamColumn(
                        label: 'TEAM A',
                        color: CR.green,
                        players: _teamA,
                        onTap: _moveToB,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TeamColumn(
                        label: 'TEAM B',
                        color: const Color(0xFF60A5FA),
                        players: _teamB,
                        onTap: _moveToA,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Confirm button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _teamA.isNotEmpty && _teamB.isNotEmpty
                      ? () => context.go('/match/scorer')
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CR.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'CONFIRM TEAMS →',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: CR.inv,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),
          ],
        ),
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  final String label;
  final Color color;
  final List<String> players;
  final ValueChanged<String> onTap;

  const _TeamColumn({
    required this.label,
    required this.color,
    required this.players,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                '$label  (${players.length})',
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...players.map((p) {
          return GestureDetector(
            onTap: () => onTap(p),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: CR.card,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      p,
                      style: GoogleFonts.inter(
                        color: CR.t1,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.swap_horiz,
                    color: CR.t3,
                    size: 14,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 200.ms),
          );
        }),
      ],
    );
  }
}
