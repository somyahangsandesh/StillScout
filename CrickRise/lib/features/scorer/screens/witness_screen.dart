import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/player.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/scorer_provider.dart';

class WitnessScreen extends ConsumerStatefulWidget {
  const WitnessScreen({super.key});

  @override
  ConsumerState<WitnessScreen> createState() => _WitnessScreenState();
}

class _WitnessScreenState extends ConsumerState<WitnessScreen> {
  Player? _witness1;
  Player? _witness2;

  bool get _isVerified => _witness1 != null && _witness2 != null;

  void _enterJersey(int slot) {
    final state = ref.read(scorerProvider);
    if (state == null) return;

    final allPlayers = [
      ...state.battingTeamPlayers,
      ...state.fieldingTeamPlayers,
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JerseyEntrySheet(
        players: allPlayers,
        alreadyConfirmed: [
          if (_witness1 != null) _witness1!.id,
          if (_witness2 != null) _witness2!.id,
        ],
        onConfirm: (player) {
          setState(() {
            if (slot == 1) {
              _witness1 = player;
            } else {
              _witness2 = player;
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scorerProvider);
    if (state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final chasingTeamWon =
        state.currentInnings == 2 && state.runs >= state.targetRuns;
    final winnerName = chasingTeamWon ? state.teamBName : state.teamAName;
    final loserName = chasingTeamWon ? state.teamAName : state.teamBName;
    final margin = chasingTeamWon
        ? '${10 - state.wickets} wickets'
        : '${(state.targetRuns - state.runs - 1).abs()} runs';

    return Scaffold(
      backgroundColor: CR.bg,
      appBar: AppBar(
        backgroundColor: CR.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CR.text1),
          onPressed: () => context.go('/match/scorer'),
        ),
        title: Text(
          'Confirm Result',
          style: GoogleFonts.inter(
            color: CR.text1,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                '2 players must verify this scorecard is correct.',
                style: GoogleFonts.inter(
                  color: CR.text2,
                  fontSize: 14,
                ),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 20),

              // Final scorecard summary
              _ScorecardSummary(
                teamAName: state.teamAName,
                teamBName: state.teamBName,
                innings1Score: state.innings1Runs != null
                    ? '${state.innings1Runs}/${state.innings1Wickets} (${state.totalOvers} ov)'
                    : '${state.runs}/${state.wickets} (${state.totalOvers} ov)',
                innings2Score: state.innings1Runs != null
                    ? '${state.runs}/${state.wickets} (${state.oversDisplay})'
                    : '—',
                winnerName: winnerName,
                loserName: loserName,
                margin: margin,
              ).animate().fadeIn(delay: 80.ms),
              const SizedBox(height: 24),

              // Witness slots
              Text(
                'WITNESSES',
                style: GoogleFonts.inter(
                  color: CR.text3,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ).animate().fadeIn(delay: 160.ms),
              const SizedBox(height: 12),

              _WitnessSlot(
                label: 'WITNESS 1',
                player: _witness1,
                onTap: () => _enterJersey(1),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 12),

              _WitnessSlot(
                label: 'WITNESS 2',
                player: _witness2,
                onTap: () => _enterJersey(2),
              ).animate().fadeIn(delay: 240.ms),
              const SizedBox(height: 24),

              // Verified badge
              if (_isVerified) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: CR.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: CR.green.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: CR.green, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'RESULT VERIFIED — 2 WITNESSES',
                        style: GoogleFonts.inter(
                          color: CR.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95)),
                const SizedBox(height: 16),
              ],

              // Confirm button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isVerified
                      ? () => context.go('/match/post-match')
                      : null,
                  style: ElevatedButton.styleFrom(
                    disabledBackgroundColor: CR.cardHigh,
                    disabledForegroundColor: CR.text3,
                  ),
                  child: Text(
                    'CONFIRM RESULT',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 280.ms),
              const SizedBox(height: 16),

              // Skip witnesses
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/match/post-match'),
                  child: Text(
                    'Skip witnesses (informal match)',
                    style: GoogleFonts.inter(
                      color: CR.text3,
                      fontSize: 13,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 320.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Scorecard Summary ────────────────────────────────────────────────────────

class _ScorecardSummary extends StatelessWidget {
  final String teamAName;
  final String teamBName;
  final String innings1Score;
  final String innings2Score;
  final String winnerName;
  final String loserName;
  final String margin;

  const _ScorecardSummary({
    required this.teamAName,
    required this.teamBName,
    required this.innings1Score,
    required this.innings2Score,
    required this.winnerName,
    required this.loserName,
    required this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.circular(14),
        border: const Border(left: BorderSide(color: CR.green, width: 3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                teamAName,
                style: GoogleFonts.inter(
                  color: CR.text2,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                innings1Score,
                style: GoogleFonts.spaceGrotesk(
                  color: CR.text1,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: CR.cardHigh),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                teamBName,
                style: GoogleFonts.inter(
                  color: CR.text2,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                innings2Score,
                style: GoogleFonts.spaceGrotesk(
                  color: CR.text1,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: CR.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$winnerName beat $loserName by $margin',
              style: GoogleFonts.inter(
                color: CR.green,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Witness Slot ─────────────────────────────────────────────────────────────

class _WitnessSlot extends StatelessWidget {
  final String label;
  final Player? player;
  final VoidCallback onTap;

  const _WitnessSlot({
    required this.label,
    required this.player,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: CR.text3,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: CR.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: player != null ? CR.green.withOpacity(0.5) : CR.cardHigh,
                width: player != null ? 1.5 : 1,
              ),
            ),
            child: player == null
                ? Row(
                    children: [
                      const Icon(Icons.add_circle_outline,
                          color: CR.text3, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Enter jersey number',
                        style: GoogleFonts.inter(
                          color: CR.text3,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: CR.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            player!.jerseyDisplay,
                            style: GoogleFonts.spaceGrotesk(
                              color: CR.green,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          player!.name,
                          style: GoogleFonts.inter(
                            color: CR.text1,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.check_circle_rounded,
                          color: CR.green, size: 20),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

// ─── Jersey Entry Bottom Sheet ────────────────────────────────────────────────

class _JerseyEntrySheet extends StatefulWidget {
  final List<Player> players;
  final List<String> alreadyConfirmed;
  final ValueChanged<Player> onConfirm;

  const _JerseyEntrySheet({
    required this.players,
    required this.alreadyConfirmed,
    required this.onConfirm,
  });

  @override
  State<_JerseyEntrySheet> createState() => _JerseyEntrySheetState();
}

class _JerseyEntrySheetState extends State<_JerseyEntrySheet> {
  String _input = '';
  Player? _found;
  String? _error;

  void _onDigit(String d) {
    if (_input.length >= 3) return;
    setState(() {
      _input += d;
      _error = null;
      _found = null;
      _tryFind();
    });
  }

  void _onDelete() {
    if (_input.isEmpty) return;
    setState(() {
      _input = _input.substring(0, _input.length - 1);
      _error = null;
      _found = null;
      if (_input.isNotEmpty) _tryFind();
    });
  }

  void _tryFind() {
    final num = int.tryParse(_input);
    if (num == null) return;
    final match = widget.players.where((p) => p.jerseyNumber == num).firstOrNull;
    if (match != null) {
      if (widget.alreadyConfirmed.contains(match.id)) {
        _error = 'This player has already confirmed.';
        _found = null;
      } else {
        _found = match;
      }
    }
  }

  void _confirm() {
    if (_found == null) return;
    widget.onConfirm(_found!);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: const BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
            const SizedBox(height: 20),
            Text(
              'Enter Jersey Number',
              style: GoogleFonts.inter(
                color: CR.text1,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),

            // Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: CR.cardHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _input.isEmpty ? '—' : '#$_input',
                    style: GoogleFonts.spaceGrotesk(
                      color: _found != null ? CR.green : CR.text1,
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  if (_found != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _found!.name,
                      style: GoogleFonts.inter(
                        color: CR.green,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _error!,
                      style: GoogleFonts.inter(color: CR.red, fontSize: 13),
                    ),
                  ],
                  if (_input.isNotEmpty && _found == null && _error == null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'No player with #$_input',
                      style: GoogleFonts.inter(color: CR.text3, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Number pad
            _NumPad(onDigit: _onDigit, onDelete: _onDelete),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _found != null ? _confirm : null,
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: CR.cardHigh,
                  disabledForegroundColor: CR.text3,
                ),
                child: Text(
                  _found != null
                      ? 'CONFIRM — ${_found!.name}'
                      : 'CONFIRM',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumPad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  const _NumPad({required this.onDigit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((d) {
              if (d.isEmpty) {
                return const SizedBox(width: 80, height: 56);
              }
              final isDel = d == '⌫';
              return GestureDetector(
                onTap: () => isDel ? onDelete() : onDigit(d),
                child: Container(
                  width: 80,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDel ? Colors.transparent : CR.cardHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: isDel
                        ? const Icon(Icons.backspace_outlined,
                            color: CR.text2, size: 22)
                        : Text(
                            d,
                            style: GoogleFonts.spaceGrotesk(
                              color: CR.text1,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
