// Legacy match setup — superseded by open_session_screen.dart + team_assignment_screen.dart
// Router redirects /match/setup → /play; this file is retained for reference.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/enums.dart';
import '../../../core/models/player.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/scorer_provider.dart';

class MatchSetupScreen extends ConsumerStatefulWidget {
  const MatchSetupScreen({super.key});

  @override
  ConsumerState<MatchSetupScreen> createState() => _MatchSetupScreenState();
}

class _MatchSetupScreenState extends ConsumerState<MatchSetupScreen> {
  int _step = 0;

  // Step 1 — match type
  MatchType _matchType = MatchType.friendly;

  // Step 2 — teams
  final _teamAController = TextEditingController(text: 'Okinawa Warriors');
  final _teamBController = TextEditingController();

  // Step 3 — format
  MatchFormat _format = MatchFormat.t20;
  int _customOvers = 20;

  // Step 4 — toss
  bool? _tossWonByTeamA;
  bool? _batFirst;

  // Step 5 — players (simplified for now)
  final List<Player> _selectedPlayers = List.from(SampleData.teamPlayers);

  @override
  void dispose() {
    _teamAController.dispose();
    _teamBController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 5) {
      setState(() => _step++);
    } else {
      _startMatch();
    }
  }

  void _startMatch() {
    final overs = _format == MatchFormat.custom ? _customOvers : _format.overs;
    final teamA = _teamAController.text.isEmpty
        ? 'Team A'
        : _teamAController.text;
    final teamB = _teamBController.text.isEmpty
        ? 'Team B'
        : _teamBController.text;

    final battingFirst = _batFirst == true;
    final battingTeam =
        battingFirst ? SampleData.teamPlayers : SampleData.oppositionPlayers;
    final fieldingTeam =
        battingFirst ? SampleData.oppositionPlayers : SampleData.teamPlayers;

    ref.read(scorerProvider.notifier).initMatch(
          teamAName: teamA,
          teamBName: teamB,
          totalOvers: overs,
          matchType: _matchType,
          format: _format,
          battingTeamPlayers: battingTeam,
          fieldingTeamPlayers: fieldingTeam,
        );

    ref.read(scorerProvider.notifier).setOpeners(
          battingTeam[0],
          battingTeam[1],
        );
    ref.read(scorerProvider.notifier).setBowler(fieldingTeam[1]);

    context.go('/match/scorer');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CR.bg,
      appBar: AppBar(
        title: const Text('New Match'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: _step > 0
              ? () => setState(() => _step--)
              : () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (_step + 1) / 6,
            backgroundColor: CR.cardHigh,
            valueColor:
                const AlwaysStoppedAnimation<Color>(CR.green),
            minHeight: 2,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildStep()),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _canProceed() ? _next : null,
                    child:
                        Text(_step < 5 ? 'Continue' : 'START SCORING →'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_step) {
      case 3:
        return _tossWonByTeamA != null && _batFirst != null;
      default:
        return true;
    }
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildMatchTypeStep();
      case 1:
        return _buildTeamsStep();
      case 2:
        return _buildFormatStep();
      case 3:
        return _buildTossStep();
      case 4:
        return _buildPlayingXIStep();
      default:
        return _buildReviewStep();
    }
  }

  // ── Step 1: Match Type ─────────────────────────────────────────────────────

  Widget _buildMatchTypeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What kind of match?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 32),
        _MatchTypeCard(
          type: MatchType.friendly,
          selected: _matchType == MatchType.friendly,
          subtitle: 'Any players · No organizer · 0.5× OVR',
          onTap: () => setState(() => _matchType = MatchType.friendly),
        ),
        const SizedBox(height: 12),
        _MatchTypeCard(
          type: MatchType.league,
          selected: _matchType == MatchType.league,
          subtitle: 'Official · 1.0× OVR · Requires assignment',
          onTap: () => setState(() => _matchType = MatchType.league),
        ),
        const SizedBox(height: 12),
        _MatchTypeCard(
          type: MatchType.tournament,
          selected: _matchType == MatchType.tournament,
          subtitle: 'Official · 1.0×+ OVR · Tournament badges',
          onTap: () => setState(() => _matchType = MatchType.tournament),
        ),
      ],
    );
  }

  // ── Step 2: Teams ──────────────────────────────────────────────────────────

  Widget _buildTeamsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Team names',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Optional — you can skip these',
          style: TextStyle(color: CR.text2),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _teamAController,
          style: const TextStyle(color: CR.text1),
          decoration: const InputDecoration(labelText: 'Your team name'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _teamBController,
          style: const TextStyle(color: CR.text1),
          decoration: const InputDecoration(labelText: 'Opponent team name'),
        ),
      ],
    );
  }

  // ── Step 3: Format ─────────────────────────────────────────────────────────

  Widget _buildFormatStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Match format',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 32),
        ...[
          MatchFormat.t20,
          MatchFormat.tenOver,
          MatchFormat.fiveOver,
          MatchFormat.custom,
        ].map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FormatOption(
                format: f,
                selected: _format == f,
                onTap: () => setState(() => _format = f),
              ),
            )),
        if (_format == MatchFormat.custom) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Overs per side:',
                style: TextStyle(color: CR.text2),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Slider(
                  value: _customOvers.toDouble(),
                  min: 2,
                  max: 50,
                  divisions: 48,
                  label: _customOvers.toString(),
                  activeColor: CR.green,
                  onChanged: (v) => setState(() => _customOvers = v.round()),
                ),
              ),
              Text(
                '$_customOvers',
                style: GoogleFonts.spaceGrotesk(
                  color: CR.text1,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── Step 4: Toss ───────────────────────────────────────────────────────────

  Widget _buildTossStep() {
    final teamAName = _teamAController.text.isEmpty
        ? 'Team A'
        : _teamAController.text;
    final teamBName = _teamBController.text.isEmpty
        ? 'Team B'
        : _teamBController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Toss',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 32),
        const Text(
          'Who won the toss?',
          style: TextStyle(color: CR.text2),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TossButton(
                label: teamAName,
                selected: _tossWonByTeamA == true,
                onTap: () => setState(() => _tossWonByTeamA = true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TossButton(
                label: teamBName,
                selected: _tossWonByTeamA == false,
                onTap: () => setState(() => _tossWonByTeamA = false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Decision?',
          style: TextStyle(color: CR.text2),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TossButton(
                label: 'BAT FIRST',
                selected: _batFirst == true,
                onTap: () => setState(() => _batFirst = true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TossButton(
                label: 'FIELD FIRST',
                selected: _batFirst == false,
                onTap: () => setState(() => _batFirst = false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 5: Playing XI ─────────────────────────────────────────────────────

  Widget _buildPlayingXIStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Playing XI',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          '${_selectedPlayers.length} / 11 selected',
          style: TextStyle(
            color: _selectedPlayers.length == 11
                ? CR.green
                : CR.text2,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: SampleData.teamPlayers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final p = SampleData.teamPlayers[i];
              final isSelected = _selectedPlayers.any((sp) => sp.id == p.id);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedPlayers.removeWhere((sp) => sp.id == p.id);
                    } else {
                      _selectedPlayers.add(p);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? CR.green.withOpacity(0.1)
                        : CR.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? CR.green.withOpacity(0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        p.jerseyDisplay,
                        style: GoogleFonts.spaceGrotesk(
                          color: CR.text3,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          p.name,
                          style: GoogleFonts.inter(
                            color: CR.text1,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        p.role.shortName,
                        style: const TextStyle(
                          color: CR.text3,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: isSelected
                            ? CR.green
                            : CR.text3,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Step 6: Review ─────────────────────────────────────────────────────────

  Widget _buildReviewStep() {
    final overs = _format == MatchFormat.custom ? _customOvers : _format.overs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ready to score',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 32),
        _ReviewRow('Match type', _matchType.displayName),
        _ReviewRow(
            'Format', '$overs overs'),
        _ReviewRow(
            'Your team',
            _teamAController.text.isEmpty ? 'Team A' : _teamAController.text),
        _ReviewRow(
            'Opponent',
            _teamBController.text.isEmpty ? 'Team B' : _teamBController.text),
        _ReviewRow(
            'Toss',
            _tossWonByTeamA == true
                ? '${_teamAController.text} won'
                : _tossWonByTeamA == false
                    ? '${_teamBController.text} won'
                    : 'Not set'),
        _ReviewRow(
            'Decision',
            _batFirst == true
                ? 'Bat first'
                : _batFirst == false
                    ? 'Field first'
                    : 'Not set'),
        _ReviewRow('Players', '${_selectedPlayers.length} selected'),
      ],
    );
  }
}

// ─── Widget helpers ───────────────────────────────────────────────────────────

class _MatchTypeCard extends StatelessWidget {
  final MatchType type;
  final bool selected;
  final String subtitle;
  final VoidCallback onTap;

  const _MatchTypeCard({
    required this.type,
    required this.selected,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? CR.green.withOpacity(0.1)
              : CR.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? CR.green
                : CR.cardHigh,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.displayName.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: selected
                          ? CR.green
                          : CR.text1,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: CR.text2,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle,
                  color: CR.green, size: 20),
          ],
        ),
      ),
    );
  }
}

class _FormatOption extends StatelessWidget {
  final MatchFormat format;
  final bool selected;
  final VoidCallback onTap;

  const _FormatOption({
    required this.format,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? CR.green.withOpacity(0.1)
              : CR.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? CR.green
                : CR.cardHigh,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                format.displayName,
                style: GoogleFonts.inter(
                  color: selected
                      ? CR.green
                      : CR.text1,
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle,
                  color: CR.green, size: 18),
          ],
        ),
      ),
    );
  }
}

class _TossButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TossButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? CR.green.withOpacity(0.15)
              : CR.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? CR.green
                : CR.cardHigh,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: selected
                  ? CR.green
                  : CR.text1,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReviewRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: CR.text2),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: CR.text1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
