import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/verdict_generator.dart';
import '../../../core/theme/app_theme.dart';
import '../../player/providers/player_provider.dart';
import '../providers/scorer_provider.dart';

class PostMatchScreen extends ConsumerWidget {
  const PostMatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scorerProvider);
    final player = ref.watch(currentPlayerProvider);
    final stats = ref.watch(currentPlayerStatsProvider);

    if (state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final chasingTeamWon = state.currentInnings == 2 &&
        state.runs >= state.targetRuns;
    final winnerName = chasingTeamWon ? state.teamBName : state.teamAName;
    final loserName = chasingTeamWon ? state.teamAName : state.teamBName;
    final margin = chasingTeamWon
        ? '${10 - state.wickets} wickets'
        : '${(state.targetRuns - state.runs - 1).abs()} runs';

    // Sample verdict data — in production these come from the match log
    final verdictText = VerdictGenerator.generate(
      runsScored: 58,
      ballsFaced: 39,
      seasonBatAvg: stats.battingAverage,
      seasonBatSR: stats.strikeRate,
      wicketsTaken: 3,
      runsConceeded: 24,
      oversBowled: 4,
      seasonEconomy: stats.economy,
      ovrChange: 2.1,
      runsToMilestone: 13,
      milestoneLabel: '500 this season',
    );

    return Scaffold(
      backgroundColor: CrickRiseColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Result header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      CrickRiseColors.primary.withOpacity(0.15),
                      CrickRiseColors.primary.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: CrickRiseColors.primary.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    const Text(
                      '✓  MATCH COMPLETE',
                      style: TextStyle(
                        color: CrickRiseColors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      winnerName,
                      style: GoogleFonts.spaceGrotesk(
                        color: CrickRiseColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'beat $loserName by $margin',
                      style: GoogleFonts.inter(
                        color: CrickRiseColors.textSecondary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 16),

              // Scorecard summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CrickRiseColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _ScoreRow(
                      teamName: state.teamAName,
                      score: state.innings1Runs != null
                          ? '${state.innings1Runs}/${state.innings1Wickets} (${state.totalOvers} ov)'
                          : '${state.runs}/${state.wickets} (${state.totalOvers} ov)',
                      isWinner: !chasingTeamWon,
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: CrickRiseColors.surfaceElevated),
                    const SizedBox(height: 12),
                    _ScoreRow(
                      teamName: state.teamBName,
                      score: state.innings1Runs != null
                          ? '${state.runs}/${state.wickets} (${state.oversDisplay})'
                          : '—',
                      isWinner: chasingTeamWon,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 16),

              // THE VERDICT card — shown for current player
              _VerdictCard(
                playerName: player.name,
                verdictText: verdictText,
              ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.06),
              const SizedBox(height: 16),

              // OVR update banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: CrickRiseColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CrickRiseColors.gold.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OVR UPDATING',
                            style: GoogleFonts.inter(
                              color: CrickRiseColors.gold,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Confirm result to update all player ratings',
                            style: GoogleFonts.inter(
                              color: CrickRiseColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 260.ms),
              const SizedBox(height: 16),

              // MVP suggestion
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CrickRiseColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: CrickRiseColors.gold, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SUGGESTED MVP',
                            style: GoogleFonts.inter(
                              color: CrickRiseColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '#7 ROSHAN KC',
                            style: GoogleFonts.inter(
                              color: CrickRiseColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '58*(39)  ·  3/24',
                            style: GoogleFonts.inter(
                              color: CrickRiseColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Change',
                          style: TextStyle(color: CrickRiseColors.textSecondary)),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 320.ms),
              const SizedBox(height: 32),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text('EDIT'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('CONFIRM + UPDATE OVR'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Verdict Card ─────────────────────────────────────────────────────────────

class _VerdictCard extends StatelessWidget {
  final String playerName;
  final String verdictText;

  const _VerdictCard({
    required this.playerName,
    required this.verdictText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(color: CR.green, width: 3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: CR.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'THE VERDICT',
                  style: GoogleFonts.inter(
                    color: CR.text3,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Text(
                  playerName.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: CR.text3,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              verdictText,
              style: GoogleFonts.inter(
                color: CR.text1,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String teamName;
  final String score;
  final bool isWinner;

  const _ScoreRow({
    required this.teamName,
    required this.score,
    this.isWinner = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (isWinner) ...[
              const Icon(Icons.emoji_events_rounded,
                  color: CrickRiseColors.gold, size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              teamName,
              style: GoogleFonts.inter(
                color: isWinner
                    ? CrickRiseColors.textPrimary
                    : CrickRiseColors.textSecondary,
                fontSize: 15,
                fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          score,
          style: GoogleFonts.spaceGrotesk(
            color: isWinner
                ? CrickRiseColors.textPrimary
                : CrickRiseColors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
