import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/sunday_story.dart';
import '../../../core/providers/app_context_provider.dart';
import '../../../core/services/verdict_generator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/cr_matchday.dart';
import '../../../core/widgets/sunday_story_card.dart';
import '../../player/providers/player_provider.dart';
import '../providers/scorer_provider.dart';

class PostMatchScreen extends ConsumerWidget {
  const PostMatchScreen({super.key});

  SundayStory _buildStory(WidgetRef ref, dynamic state) {
    final ctx = ref.read(appContextProvider);
    final chasingTeamWon =
        state.currentInnings == 2 && state.runs >= state.targetRuns;
    final winnerName = chasingTeamWon ? state.teamBName : state.teamAName;
    final loserName = chasingTeamWon ? state.teamAName : state.teamBName;
    final margin = chasingTeamWon
        ? '${10 - state.wickets} wickets'
        : '${(state.targetRuns - state.runs - 1).abs()} runs';

    final squadScore = state.innings1Runs != null
        ? '${state.innings1Runs}/${state.innings1Wickets} (${state.totalOvers} ov)'
        : '${state.runs}/${state.wickets} (${state.totalOvers} ov)';
    final opponentScore = state.innings1Runs != null
        ? '${state.runs}/${state.wickets} (${state.oversDisplay})'
        : '—';

    return SundayStory(
      id: 'story-live',
      matchDate: DateTime.now(),
      squadName: ctx.squad.name,
      opponentName: loserName == ctx.squad.name ? winnerName : loserName,
      winnerName: winnerName,
      margin: margin,
      squadScore: squadScore,
      opponentScore: opponentScore,
      playerOfSunday: 'Roshan KC',
      playerStats: '58*(39)',
      captainQuote: 'Proper Sunday. Share it with the group.',
      cityName: ctx.city.name,
      countryName: ctx.country.name,
      countryFlag: ctx.country.flag,
      homeCountryName: ctx.homeCountry.name,
      homeCountryFlag: ctx.homeCountry.flag,
      shareUrl: 'https://crickrise.app/s/${ctx.squad.inviteSlug}',
      storyNumber: 13,
    );
  }

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

    final chasingTeamWon =
        state.currentInnings == 2 && state.runs >= state.targetRuns;
    final winnerName = chasingTeamWon ? state.teamBName : state.teamAName;
    final loserName = chasingTeamWon ? state.teamAName : state.teamBName;
    final margin = chasingTeamWon
        ? '${10 - state.wickets} wickets'
        : '${(state.targetRuns - state.runs - 1).abs()} runs';
    final story = _buildStory(ref, state);

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
      body: CRProgrammeBg(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Match complete', style: CRType.overline(color: CR.mossLight)),
                const SizedBox(height: 6),
                Text('$winnerName won', style: CRType.display(size: 32)),
                Text('by $margin vs $loserName', style: CRType.caption()),
                const SizedBox(height: 24),
                CRPaper(
                  child: Column(
                    children: [
                      _ScoreLine(
                        name: state.teamAName,
                        score: state.innings1Runs != null
                            ? '${state.innings1Runs}/${state.innings1Wickets} (${state.totalOvers} ov)'
                            : '${state.runs}/${state.wickets} (${state.totalOvers} ov)',
                        winner: !chasingTeamWon,
                      ),
                      const SizedBox(height: 12),
                      const CRProgrammeRule(),
                      const SizedBox(height: 12),
                      _ScoreLine(
                        name: state.teamBName,
                        score: state.innings1Runs != null
                            ? '${state.runs}/${state.wickets} (${state.oversDisplay})'
                            : '—',
                        winner: chasingTeamWon,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const CRSectionLabel('Sunday Story preview'),
                const SizedBox(height: 12),
                Center(child: SundayStoryCard(story: story, width: 260)),
                const SizedBox(height: 24),
                CRPaper(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('THE VERDICT · ${player.name.toUpperCase()}', style: CRType.overline(size: 8)),
                      const SizedBox(height: 10),
                      Text(verdictText, style: CRType.body(size: 14, color: CR.ink)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CRPaper(
                  padding: const EdgeInsets.all(14),
                  color: CR.brassDim.withValues(alpha: 0.4),
                  child: Row(
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PLAYER OF SUNDAY', style: CRType.overline(size: 8, color: CR.brass)),
                            Text('Roshan KC · 58*(39)', style: CRType.body(weight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                CRProgrammeButton(
                  label: 'Create & share Sunday Story',
                  onTap: () => context.go('/story'),
                ),
                const SizedBox(height: 12),
                CRProgrammeButton(
                  label: 'Confirm result',
                  primary: false,
                  onTap: () => context.go('/match/mvp'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreLine extends StatelessWidget {
  final String name;
  final String score;
  final bool winner;

  const _ScoreLine({
    required this.name,
    required this.score,
    required this.winner,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (winner) ...[
          const Icon(Icons.emoji_events_outlined, color: CR.brass, size: 16),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            name,
            style: CRType.body(weight: winner ? FontWeight.w600 : FontWeight.w400),
          ),
        ),
        Text(score, style: CRType.score(size: 18, color: winner ? CR.brass : CR.ink)),
      ],
    );
  }
}
