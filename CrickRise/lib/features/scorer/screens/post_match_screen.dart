import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/verdict_generator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cr_widgets.dart';
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/play');
      });
      return const Scaffold(backgroundColor: CR.bg, body: SizedBox.shrink());
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
      backgroundColor: CR.bg,
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
                      CR.green.withOpacity(0.15),
                      CR.green.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: CR.green.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    const Text(
                      '✓  MATCH COMPLETE',
                      style: TextStyle(
                        color: CR.green,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      winnerName,
                      style: GoogleFonts.spaceGrotesk(
                        color: CR.t1,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'beat $loserName by $margin',
                      style: GoogleFonts.inter(
                        color: CR.t2,
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
                  color: CR.card,
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
                    const Divider(height: 1, color: CR.cardHigh),
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
                  color: CR.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CR.gold.withOpacity(0.3)),
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
                              color: CR.gold,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Confirm result to update all player ratings',
                            style: GoogleFonts.inter(
                              color: CR.t2,
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

              // Awards section
              const _AwardsSection()
                  .animate().fadeIn(delay: 320.ms).slideY(begin: 0.06),
              const SizedBox(height: 16),

              // Share result card
              const _ShareResultCard()
                  .animate().fadeIn(delay: 380.ms),
              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Edit scorecard — coming soon'),
                          behavior: SnackBarBehavior.floating,
                        ));
                      },
                      child: const Text('EDIT'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        // Demo: show milestone toast before navigating to MVP
                        showMilestoneToast(
                          context,
                          '🏏',
                          '500 Career Runs!',
                          'Roshan KC has crossed 500 runs this season',
                        );
                        context.go('/match/mvp');
                      },
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

// ─── Awards Section ───────────────────────────────────────────────────────────

class _AwardsSection extends StatefulWidget {
  const _AwardsSection();

  @override
  State<_AwardsSection> createState() => _AwardsSectionState();
}

class _AwardsSectionState extends State<_AwardsSection> {
  bool _potmConfirmed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // Player of the Match — captain confirms
          // TODO: replace with real MVP derived from match delivery log
          _AwardCard(
            icon: '⭐',
            label: 'PLAYER OF THE MATCH',
            iconColor: CR.gold,
            playerLine: '#7 Roshan KC',   // sample — from top-scorer in log
            statsLine: '58*(39)  ·  3/24',
            isConfirmable: true,
            isConfirmed: _potmConfirmed,
            onConfirm: () => setState(() => _potmConfirmed = true),
            showDivider: true,
          ),
          // Best Batter — auto display
          // TODO: replace with real top-scorer computed from deliveryLog
          const _AwardCard(
            icon: '🏏',
            label: 'BEST BATTER',
            iconColor: CR.green,
            playerLine: '#7 Roshan KC',   // sample
            statsLine: '58*(39)  avg 48.7',
            isConfirmable: false,
            isConfirmed: false,
            showDivider: true,
          ),
          // Best Bowler — auto display
          // TODO: replace with real best-figures computed from deliveryLog
          const _AwardCard(
            icon: '🎳',
            label: 'BEST BOWLER',
            iconColor: CR.blue,
            playerLine: '#23 Bikash Rai', // sample
            statsLine: '3/18  econ 5.1',
            isConfirmable: false,
            isConfirmed: false,
            showDivider: true,
          ),
          // Best Fielder — auto display
          // TODO: replace with real top-catcher computed from deliveryLog
          const _AwardCard(
            icon: '🤝',
            label: 'BEST FIELDER',
            iconColor: CR.orange,
            playerLine: '#18 Sandip',     // sample
            statsLine: '2 catches',
            isConfirmable: false,
            isConfirmed: false,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _AwardCard extends StatelessWidget {
  final String icon;
  final String label;
  final Color iconColor;
  final String playerLine;
  final String statsLine;
  final bool isConfirmable;
  final bool isConfirmed;
  final VoidCallback? onConfirm;
  final bool showDivider;

  const _AwardCard({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.playerLine,
    required this.statsLine,
    required this.isConfirmable,
    required this.isConfirmed,
    this.onConfirm,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        color: iconColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      playerLine,
                      style: GoogleFonts.inter(
                        color: CR.t1,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      statsLine,
                      style: GoogleFonts.inter(
                        color: CR.t2,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isConfirmable)
                isConfirmed
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: CR.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '✓ CONFIRMED',
                          style: GoogleFonts.inter(
                            color: CR.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: onConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CR.gold,
                          minimumSize: const Size(80, 36),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 0),
                        ),
                        child: Text(
                          'CONFIRM',
                          style: GoogleFonts.inter(
                            color: CR.inv,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: CR.cardHigh),
      ],
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
                    color: CR.t3,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Text(
                  playerName.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: CR.t3,
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
                color: CR.t1,
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

// ─── Share Result Card ────────────────────────────────────────────────────────

class _ShareResultCard extends StatelessWidget {
  const _ShareResultCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'SHARE THE RESULT',
            style: GoogleFonts.inter(
              color: CR.t3,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Scorecard link copied'),
                      backgroundColor: CR.cardHigh,
                      behavior: SnackBarBehavior.floating,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CR.t2,
                    side: const BorderSide(color: CR.cardHigh),
                  ),
                  child: const Text('COPY LINK'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Match card ready to share'),
                      backgroundColor: CR.cardHigh,
                      behavior: SnackBarBehavior.floating,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CR.green,
                    foregroundColor: CR.inv,
                  ),
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('SHARE CARD'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Score Row ────────────────────────────────────────────────────────────────

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
                  color: CR.gold, size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              teamName,
              style: GoogleFonts.inter(
                color: isWinner
                    ? CR.t1
                    : CR.t2,
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
                ? CR.t1
                : CR.t2,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
