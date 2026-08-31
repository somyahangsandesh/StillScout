import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LEAGUE SETUP WIZARD — 4 steps
// ─────────────────────────────────────────────────────────────────────────────

class LeagueSetupScreen extends StatefulWidget {
  const LeagueSetupScreen({super.key});

  @override
  State<LeagueSetupScreen> createState() => _LeagueSetupScreenState();
}

class _LeagueSetupScreenState extends State<LeagueSetupScreen> {
  int _step = 0; // 0–3
  final PageController _pageCtrl = PageController();

  // Step 1
  final _leagueNameCtrl = TextEditingController();
  final _seasonNameCtrl = TextEditingController();
  String _format = 'T20'; // 'T20' | '10-over' | 'Custom'
  final _customOversCtrl = TextEditingController(text: '20');

  // Step 2
  final List<String> _teams = [];
  final _teamInputCtrl = TextEditingController();

  // Step 3 — for each team: list of {name, jersey, role}
  final Map<String, List<_PlayerDraft>> _teamPlayers = {};
  final Map<String, bool> _teamExpanded = {};
  String? _addingForTeam;
  final _playerNameCtrl = TextEditingController();
  final _playerJerseyCtrl = TextEditingController();
  String _playerRole = 'BATTER';

  // Step 4
  final _startDateCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  bool _autoGenerate = true;

  @override
  void initState() {
    super.initState();
    _seasonNameCtrl.text = '${DateTime.now().year} Season';
  }

  @override
  void dispose() {
    _leagueNameCtrl.dispose();
    _seasonNameCtrl.dispose();
    _customOversCtrl.dispose();
    _teamInputCtrl.dispose();
    _playerNameCtrl.dispose();
    _playerJerseyCtrl.dispose();
    _startDateCtrl.dispose();
    _venueCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  int get _totalMatches {
    final n = _teams.length;
    return n * (n - 1) ~/ 2;
  }

  bool get _step1Valid => _leagueNameCtrl.text.trim().length > 2;
  bool get _step2Valid => _teams.length >= 2;

  void _addTeam() {
    final name = _teamInputCtrl.text.trim();
    if (name.isEmpty || _teams.length >= 12) return;
    setState(() {
      _teams.add(name);
      _teamPlayers[name] = [];
      _teamExpanded[name] = false;
      _teamInputCtrl.clear();
    });
  }

  void _removeTeam(String name) {
    setState(() {
      _teams.remove(name);
      _teamPlayers.remove(name);
      _teamExpanded.remove(name);
    });
  }

  void _addPlayer(String team) {
    final name = _playerNameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _teamPlayers[team]!.add(_PlayerDraft(
        name: name,
        jersey: _playerJerseyCtrl.text.trim(),
        role: _playerRole,
      ));
      _playerNameCtrl.clear();
      _playerJerseyCtrl.clear();
      _addingForTeam = null;
    });
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _pageCtrl.animateToPage(step,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _finish() {
    // Navigate to organizer dashboard after setup
    context.go('/organizer');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CR.bg,
      body: SafeArea(
        child: Column(
          children: [
            _WizardHeader(step: _step, onBack: () {
              if (_step == 0) {
                context.pop();
              } else {
                _goTo(_step - 1);
              }
            }),
            _StepProgress(current: _step),
            const SizedBox(height: 24),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Step1Identity(
                    leagueNameCtrl: _leagueNameCtrl,
                    seasonNameCtrl: _seasonNameCtrl,
                    format: _format,
                    customOversCtrl: _customOversCtrl,
                    onFormatChanged: (f) => setState(() => _format = f),
                    onNext: _step1Valid ? () => _goTo(1) : null,
                  ),
                  _Step2Teams(
                    teams: _teams,
                    inputCtrl: _teamInputCtrl,
                    totalMatches: _totalMatches,
                    onAdd: _addTeam,
                    onRemove: _removeTeam,
                    onNext: _step2Valid ? () => _goTo(2) : null,
                  ),
                  _Step3Players(
                    teams: _teams,
                    teamPlayers: _teamPlayers,
                    teamExpanded: _teamExpanded,
                    addingForTeam: _addingForTeam,
                    playerNameCtrl: _playerNameCtrl,
                    playerJerseyCtrl: _playerJerseyCtrl,
                    playerRole: _playerRole,
                    onExpandTeam: (t) => setState(() {
                      _teamExpanded[t] = !(_teamExpanded[t] ?? false);
                      _addingForTeam = null;
                    }),
                    onStartAdding: (t) => setState(() {
                      _addingForTeam = t;
                      _teamExpanded[t] = true;
                    }),
                    onRoleChanged: (r) => setState(() => _playerRole = r),
                    onAddPlayer: _addPlayer,
                    onCancelAdd: () => setState(() => _addingForTeam = null),
                    onNext: () => _goTo(3),
                    onSkip: () => _goTo(3),
                  ),
                  _Step4Fixtures(
                    teams: _teams,
                    totalMatches: _totalMatches,
                    autoGenerate: _autoGenerate,
                    startDateCtrl: _startDateCtrl,
                    venueCtrl: _venueCtrl,
                    onAutoGenChanged: (v) => setState(() => _autoGenerate = v),
                    onGenerate: _finish,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _WizardHeader extends StatelessWidget {
  final int step;
  final VoidCallback onBack;
  const _WizardHeader({required this.step, required this.onBack});

  static const _titles = [
    'League Identity',
    'Add Teams',
    'Add Players',
    'Generate Fixtures',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: const Icon(Icons.arrow_back_ios, color: CR.t3, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SETUP LEAGUE  ·  STEP ${step + 1} OF 4',
                  style: GoogleFonts.oswald(
                    color: CR.gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  _titles[step],
                  style: GoogleFonts.oswald(
                    color: CR.t1,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }
}

// ─── Step Progress ────────────────────────────────────────────────────────────

class _StepProgress extends StatelessWidget {
  final int current;
  const _StepProgress({required this.current});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: List.generate(4, (i) {
          final done = i < current;
          final active = i == current;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      color: done
                          ? CR.green
                          : active
                              ? CR.green.withOpacity(0.5)
                              : CR.cardHigh,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (i < 3) const SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Step 1: Identity ─────────────────────────────────────────────────────────

class _Step1Identity extends StatefulWidget {
  final TextEditingController leagueNameCtrl;
  final TextEditingController seasonNameCtrl;
  final String format;
  final TextEditingController customOversCtrl;
  final ValueChanged<String> onFormatChanged;
  final VoidCallback? onNext;

  const _Step1Identity({
    required this.leagueNameCtrl,
    required this.seasonNameCtrl,
    required this.format,
    required this.customOversCtrl,
    required this.onFormatChanged,
    required this.onNext,
  });

  @override
  State<_Step1Identity> createState() => _Step1IdentityState();
}

class _Step1IdentityState extends State<_Step1Identity> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        // League name
        Text('LEAGUE NAME',
            style: GoogleFonts.oswald(
                color: CR.t3, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        TextField(
          controller: widget.leagueNameCtrl,
          autofocus: true,
          style: GoogleFonts.inter(color: CR.t1, fontSize: 20, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: 'e.g. Okinawa Nepali Cricket League',
            hintStyle: GoogleFonts.inter(color: CR.t3, fontSize: 16),
            filled: true,
            fillColor: CR.card,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: CR.green, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 28),

        // Format
        Text('FORMAT',
            style: GoogleFonts.oswald(
                color: CR.t3, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Row(
          children: ['T20', '10-over', 'Custom'].map((f) {
            final selected = widget.format == f;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => widget.onFormatChanged(f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected ? CR.green : CR.card,
                      borderRadius: BorderRadius.circular(12),
                      border: selected ? null : Border.all(color: CR.cardHigh),
                    ),
                    child: Center(
                      child: Text(
                        f,
                        style: GoogleFonts.oswald(
                          color: selected ? CR.inv : CR.t2,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        if (widget.format == 'Custom') ...[
          const SizedBox(height: 16),
          Text('OVERS PER INNINGS',
              style: GoogleFonts.oswald(
                  color: CR.t3, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          SizedBox(
            width: 100,
            child: TextField(
              controller: widget.customOversCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.spaceGrotesk(
                  color: CR.t1, fontSize: 22, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                filled: true,
                fillColor: CR.card,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: CR.green, width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixText: 'overs',
                suffixStyle: GoogleFonts.inter(color: CR.t3, fontSize: 13),
              ),
            ),
          ),
        ],

        const SizedBox(height: 28),

        // Season name
        Text('SEASON NAME',
            style: GoogleFonts.oswald(
                color: CR.t3, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        TextField(
          controller: widget.seasonNameCtrl,
          style: GoogleFonts.inter(color: CR.t1, fontSize: 16),
          decoration: InputDecoration(
            hintText: '2026 Season',
            hintStyle: GoogleFonts.inter(color: CR.t3, fontSize: 15),
            filled: true,
            fillColor: CR.card,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: CR.green, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          ),
        ),

        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: widget.onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.onNext != null ? CR.green : CR.cardHigh,
              foregroundColor: CR.inv,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text(
              'NEXT: ADD TEAMS →',
              style: GoogleFonts.oswald(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: widget.onNext != null ? CR.inv : CR.t3,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    ).animate().fadeIn(duration: 280.ms);
  }
}

// ─── Step 2: Teams ────────────────────────────────────────────────────────────

class _Step2Teams extends StatelessWidget {
  final List<String> teams;
  final TextEditingController inputCtrl;
  final int totalMatches;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  final VoidCallback? onNext;

  const _Step2Teams({
    required this.teams,
    required this.inputCtrl,
    required this.totalMatches,
    required this.onAdd,
    required this.onRemove,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        // Input row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: inputCtrl,
                style: GoogleFonts.inter(color: CR.t1, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Team name…',
                  hintStyle: GoogleFonts.inter(color: CR.t3, fontSize: 15),
                  filled: true,
                  fillColor: CR.card,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: CR.green, width: 2)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onSubmitted: (_) => onAdd(),
                textInputAction: TextInputAction.go,
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: CR.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add, color: CR.inv, size: 24),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          teams.length < 2
              ? 'Add at least 2 teams to continue. Max 12.'
              : 'You have ${teams.length} teams — generates $totalMatches matches',
          style: GoogleFonts.inter(
            color: teams.length >= 2 ? CR.green : CR.t3,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),

        // Team chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: teams.map((t) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: CR.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CR.cardHigh),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t,
                      style: GoogleFonts.inter(
                          color: CR.t1, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => onRemove(t),
                    child: const Icon(Icons.close, color: CR.t3, size: 16),
                  ),
                ],
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: onNext != null ? CR.green : CR.cardHigh,
              foregroundColor: CR.inv,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text(
              'NEXT: ADD PLAYERS →',
              style: GoogleFonts.oswald(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: onNext != null ? CR.inv : CR.t3,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    ).animate().fadeIn(duration: 280.ms);
  }
}

// ─── Step 3: Players ──────────────────────────────────────────────────────────

class _PlayerDraft {
  final String name;
  final String jersey;
  final String role;
  const _PlayerDraft({required this.name, required this.jersey, required this.role});
}

class _Step3Players extends StatelessWidget {
  final List<String> teams;
  final Map<String, List<_PlayerDraft>> teamPlayers;
  final Map<String, bool> teamExpanded;
  final String? addingForTeam;
  final TextEditingController playerNameCtrl;
  final TextEditingController playerJerseyCtrl;
  final String playerRole;
  final ValueChanged<String> onExpandTeam;
  final ValueChanged<String> onStartAdding;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<String> onAddPlayer;
  final VoidCallback onCancelAdd;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _Step3Players({
    required this.teams,
    required this.teamPlayers,
    required this.teamExpanded,
    required this.addingForTeam,
    required this.playerNameCtrl,
    required this.playerJerseyCtrl,
    required this.playerRole,
    required this.onExpandTeam,
    required this.onStartAdding,
    required this.onRoleChanged,
    required this.onAddPlayer,
    required this.onCancelAdd,
    required this.onNext,
    required this.onSkip,
  });

  static const _roles = ['BATTER', 'BOWLER', 'ALL-ROUNDER', 'KEEPER'];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        Text(
          'Optional but encouraged. You can always add players later.',
          style: GoogleFonts.inter(color: CR.t2, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 20),

        ...teams.map((team) {
          final players = teamPlayers[team] ?? [];
          final expanded = teamExpanded[team] ?? false;
          final isAdding = addingForTeam == team;

          return Column(
            children: [
              // Team header
              GestureDetector(
                onTap: () => onExpandTeam(team),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: CR.card,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: Radius.circular(expanded ? 0 : 12),
                      bottomRight: Radius.circular(expanded ? 0 : 12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(team,
                          style: GoogleFonts.inter(
                              color: CR.t1, fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Text(
                        '${players.length} players',
                        style: GoogleFonts.inter(color: CR.t3, fontSize: 12),
                      ),
                      const Spacer(),
                      Icon(expanded ? Icons.expand_less : Icons.expand_more,
                          color: CR.t3, size: 20),
                    ],
                  ),
                ),
              ),

              // Expanded body
              if (expanded) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: CR.card.withOpacity(0.6),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    children: [
                      ...players.map((p) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                if (p.jersey.isNotEmpty)
                                  Text('#${p.jersey}  ',
                                      style: GoogleFonts.spaceGrotesk(
                                          color: CR.t3, fontSize: 12)),
                                Text(p.name,
                                    style: GoogleFonts.inter(
                                        color: CR.t1,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: CR.greenDim,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(p.role,
                                      style: GoogleFonts.oswald(
                                          color: CR.green, fontSize: 9, letterSpacing: 0.5)),
                                ),
                              ],
                            ),
                          )),

                      // Add player inline form
                      if (isAdding) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: playerNameCtrl,
                                autofocus: true,
                                style: GoogleFonts.inter(color: CR.t1, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Player name',
                                  hintStyle: GoogleFonts.inter(color: CR.t3, fontSize: 13),
                                  filled: true,
                                  fillColor: CR.overlay,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 60,
                              child: TextField(
                                controller: playerJerseyCtrl,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.spaceGrotesk(
                                    color: CR.t1, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: '#',
                                  hintStyle: GoogleFonts.inter(color: CR.t3, fontSize: 13),
                                  filled: true,
                                  fillColor: CR.overlay,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Role chips
                        Wrap(
                          spacing: 6,
                          children: _roles.map((r) {
                            final sel = playerRole == r;
                            return GestureDetector(
                              onTap: () => onRoleChanged(r),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: sel ? CR.green : CR.cardHigh,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(r,
                                    style: GoogleFonts.oswald(
                                      color: sel ? CR.inv : CR.t3,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    )),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => onAddPlayer(team),
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: CR.green,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text('ADD',
                                        style: GoogleFonts.oswald(
                                            color: CR.inv,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: onCancelAdd,
                              child: Container(
                                height: 40,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: CR.cardHigh,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text('CANCEL',
                                      style: GoogleFonts.oswald(
                                          color: CR.t3,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else
                        GestureDetector(
                          onTap: () => onStartAdding(team),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.add_circle_outline, color: CR.t3, size: 16),
                                const SizedBox(width: 6),
                                Text('Add player',
                                    style: GoogleFonts.inter(
                                        color: CR.t3, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
            ],
          );
        }),

        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: CR.green,
              foregroundColor: CR.inv,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text(
              'NEXT: GENERATE FIXTURES →',
              style: GoogleFonts.oswald(
                  fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 1, color: CR.inv),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: onSkip,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Skip for now — add players later',
                style: GoogleFonts.inter(color: CR.t3, fontSize: 13),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    ).animate().fadeIn(duration: 280.ms);
  }
}

// ─── Step 4: Fixtures ─────────────────────────────────────────────────────────

class _Step4Fixtures extends StatelessWidget {
  final List<String> teams;
  final int totalMatches;
  final bool autoGenerate;
  final TextEditingController startDateCtrl;
  final TextEditingController venueCtrl;
  final ValueChanged<bool> onAutoGenChanged;
  final VoidCallback onGenerate;

  const _Step4Fixtures({
    required this.teams,
    required this.totalMatches,
    required this.autoGenerate,
    required this.startDateCtrl,
    required this.venueCtrl,
    required this.onAutoGenChanged,
    required this.onGenerate,
  });

  int get _rounds => teams.length > 1 ? teams.length - 1 : 1;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        // Auto-generate toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: autoGenerate ? CR.greenDim : CR.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: autoGenerate ? CR.green.withOpacity(0.3) : CR.cardHigh,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto-generate round-robin fixtures',
                      style: GoogleFonts.inter(
                          color: CR.t1, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This will create $totalMatches matches across $_rounds rounds',
                      style: GoogleFonts.inter(color: CR.t2, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Switch(
                value: autoGenerate,
                onChanged: onAutoGenChanged,
                activeColor: CR.green,
                activeTrackColor: CR.greenDim,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Preview
        if (autoGenerate && teams.length >= 2) ...[
          Text('FIXTURE PREVIEW',
              style: GoogleFonts.oswald(
                  color: CR.t3, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CR.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: List.generate(
                (teams.length / 2).ceil().clamp(0, 3),
                (r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: CR.cardHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('R${r + 1}',
                            style: GoogleFonts.oswald(
                                color: CR.t3, fontSize: 10, letterSpacing: 1)),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        r < teams.length ~/ 2
                            ? '${teams[r * 2 % teams.length]} vs ${teams[(r * 2 + 1) % teams.length]}'
                            : '…',
                        style: GoogleFonts.inter(color: CR.t2, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )..add(
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      '+ ${(totalMatches - 3).clamp(0, 999)} more matches',
                      style: GoogleFonts.inter(color: CR.t3, fontSize: 12),
                    ),
                  ),
                ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Start date
        Text('START DATE (OPTIONAL)',
            style: GoogleFonts.oswald(
                color: CR.t3, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: startDateCtrl,
          style: GoogleFonts.inter(color: CR.t1, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'e.g. Sep 1, 2026',
            hintStyle: GoogleFonts.inter(color: CR.t3, fontSize: 14),
            filled: true,
            fillColor: CR.card,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: CR.green, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: const Icon(Icons.calendar_today_outlined, color: CR.t3, size: 18),
          ),
        ),
        const SizedBox(height: 16),

        // Venue
        Text('DEFAULT VENUE (OPTIONAL)',
            style: GoogleFonts.oswald(
                color: CR.t3, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: venueCtrl,
          style: GoogleFonts.inter(color: CR.t1, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'e.g. Okinawa Sports Park',
            hintStyle: GoogleFonts.inter(color: CR.t3, fontSize: 14),
            filled: true,
            fillColor: CR.card,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: CR.green, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: const Icon(Icons.location_on_outlined, color: CR.t3, size: 18),
          ),
        ),

        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: onGenerate,
            style: ElevatedButton.styleFrom(
              backgroundColor: CR.green,
              foregroundColor: CR.inv,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text(
              'GENERATE FIXTURES →',
              style: GoogleFonts.oswald(
                  fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: CR.inv),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    ).animate().fadeIn(duration: 280.ms);
  }
}
