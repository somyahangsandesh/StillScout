import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/enums.dart';
import '../../../core/models/match.dart';
import '../../../core/models/player.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/scorer_provider.dart';

class ActiveScorerScreen extends ConsumerStatefulWidget {
  const ActiveScorerScreen({super.key});

  @override
  ConsumerState<ActiveScorerScreen> createState() => _ActiveScorerScreenState();
}

class _ActiveScorerScreenState extends ConsumerState<ActiveScorerScreen> {
  final ConnectivityStatus _connectivity = ConnectivityStatus.online;
  bool _isDemoMatch = false;

  @override
  void initState() {
    super.initState();
    // Initialize with sample data if no match in progress
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(scorerProvider);
      if (state == null) {
        _initSampleMatch();
      }
    });
  }

  void _initSampleMatch() {
    setState(() => _isDemoMatch = true);
    ref.read(scorerProvider.notifier).initMatch(
      teamAName: 'Okinawa Warriors',
      teamBName: 'Tokyo Rhinos',
      totalOvers: 20,
      matchType: MatchType.friendly,
      format: MatchFormat.t20,
      battingTeamPlayers: SampleData.teamPlayers,
      fieldingTeamPlayers: SampleData.oppositionPlayers,
    );

    final notifier = ref.read(scorerProvider.notifier);
    notifier.setOpeners(SampleData.teamPlayers[0], SampleData.teamPlayers[1]);
    notifier.setBowler(SampleData.oppositionPlayers[1]);

    // Simulate some deliveries to show a live state
    for (final runs in [1, 0, 4, 6, 1, 2]) {
      notifier.recordRuns(runs);
    }
    for (final runs in [0, 1, 3, 4, 0, 1]) {
      notifier.recordRuns(runs);
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchState = ref.watch(scorerProvider);

    if (matchState == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: CR.bg,
      body: SafeArea(
        child: Column(
          children: [
            _ConnectivityBanner(status: _connectivity),
            Expanded(
              flex: 45,
              child: _ZoneA(state: matchState, isDemoMatch: _isDemoMatch),
            ),
            const Divider(height: 1, color: CR.cardHigh),
            Expanded(
              flex: 35,
              child: _ZoneB(
                state: matchState,
                onRuns: (r) => _handleRuns(r, matchState),
                onExtra: (e) => _handleExtra(e, matchState),
                onWicket: () => _showWicketModal(matchState),
              ),
            ),
            const Divider(height: 1, color: CR.cardHigh),
            Expanded(
              flex: 20,
              child: _ZoneC(
                state: matchState,
                onUndo: () => _handleUndo(matchState),
                onBowlChg: () => _showBowlingChangeModal(matchState),
                onMore: () => _showMoreMenu(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleRuns(int runs, MatchState state) {
    if (runs == 4 || runs == 6) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    ref.read(scorerProvider.notifier).recordRuns(runs);
    _checkInningsComplete();
  }

  void _handleExtra(ExtraType extraType, MatchState state) {
    HapticFeedback.lightImpact();
    ref.read(scorerProvider.notifier).recordExtra(extraType);
    _checkInningsComplete();
  }

  void _handleUndo(MatchState state) {
    final last = ref.read(scorerProvider.notifier).lastDelivery;
    if (last == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CR.card,
        title: Text(
          'Undo last delivery?',
          style: GoogleFonts.inter(
            color: CR.text1,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Over ${state.completedOvers}.${state.currentBall} · '
          '${last.displayLabel} · '
          '${state.striker?.player.jerseyDisplay} ${state.striker?.player.name} batting · '
          '${state.currentBowler?.player.jerseyDisplay} ${state.currentBowler?.player.name} bowling',
          style: const TextStyle(color: CR.text2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: CR.text2)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(scorerProvider.notifier).undoLastDelivery();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CR.orange,
            ),
            child: const Text('UNDO', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _checkInningsComplete() {
    final state = ref.read(scorerProvider);
    if (state == null) return;

    if (state.isMatchComplete) {
      Future.microtask(() => context.go('/match/witness'));
    } else if (state.isInningsComplete && state.currentInnings == 1) {
      Future.microtask(() => context.go('/match/innings-transition'));
    }
  }

  void _showWicketModal(MatchState state) {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _WicketModal(
        state: state,
        onConfirm: (wicket) {
          Navigator.pop(ctx);
          ref.read(scorerProvider.notifier).recordWicket(wicket);
          _checkInningsComplete();
        },
      ),
    );
  }

  void _showBowlingChangeModal(MatchState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BowlingChangeModal(
        state: state,
        onSelect: (bowler) {
          Navigator.pop(ctx);
          ref.read(scorerProvider.notifier).changeBowler(bowler);
        },
      ),
    );
  }

  void _showMoreMenu() {
    final state = ref.read(scorerProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: CR.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MoreMenuItem(
              icon: Icons.table_chart_rounded,
              label: 'View full scorecard',
              onTap: () {
                Navigator.pop(ctx);
                if (state != null) _showFullScorecard(state);
              },
            ),
            _MoreMenuItem(
              icon: Icons.swap_horiz,
              label: 'Fix batter — swap crease positions',
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Swap crease positions — coming soon'),
                  behavior: SnackBarBehavior.floating,
                ));
              },
            ),
            _MoreMenuItem(
              icon: Icons.sports_cricket,
              label: 'Fix this over\'s bowler',
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Fix bowler — coming soon'),
                  behavior: SnackBarBehavior.floating,
                ));
              },
            ),
            _MoreMenuItem(
              icon: Icons.accessible_forward,
              label: 'Retired hurt',
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Retired hurt — coming soon'),
                  behavior: SnackBarBehavior.floating,
                ));
              },
            ),
            _MoreMenuItem(
              icon: Icons.electric_bolt,
              label: 'Powerplay',
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Powerplay toggle — coming soon'),
                  behavior: SnackBarBehavior.floating,
                ));
              },
            ),
            _MoreMenuItem(
              icon: Icons.replay,
              label: 'Super over',
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Super over — coming soon'),
                  behavior: SnackBarBehavior.floating,
                ));
              },
            ),
            _MoreMenuItem(
              icon: Icons.note_add,
              label: 'Add note',
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Match notes — coming soon'),
                  behavior: SnackBarBehavior.floating,
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScorecard(MatchState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FullScorecardSheet(state: state),
    );
  }
}

// ─── Zone A — Match State ────────────────────────────────────────────────────
// Broadcast overlay aesthetic: dark green panel, crisp numbers, real ball dots

class _ZoneA extends StatelessWidget {
  final MatchState state;
  final bool isDemoMatch;
  const _ZoneA({required this.state, this.isDemoMatch = false});

  int get _partnershipRuns {
    if (state.striker == null || state.nonStriker == null) return 0;
    // Sum runs from current delivery log since last wicket
    int runs = 0;
    for (final d in state.deliveryLog.reversed) {
      if (d.isWicket) break;
      runs += d.runsOffBat + d.extraRuns;
    }
    return runs;
  }

  int get _partnershipBalls {
    if (state.striker == null || state.nonStriker == null) return 0;
    int balls = 0;
    for (final d in state.deliveryLog.reversed) {
      if (d.isWicket) break;
      if (d.isLegalDelivery) balls++;
    }
    return balls;
  }

  double get _currentRunRate {
    final totalBalls = state.completedOvers * 6 + state.currentBall;
    if (totalBalls == 0) return 0;
    return (state.runs / totalBalls) * 6;
  }

  double get _requiredRunRate {
    final ballsLeft = (state.totalOvers - state.completedOvers) * 6 - state.currentBall;
    if (ballsLeft <= 0) return 0;
    final runsNeeded = state.targetRuns - state.runs;
    return (runsNeeded / ballsLeft) * 6;
  }

  int get _fours => state.deliveryLog.where((d) => d.runsOffBat == 4).length;
  int get _sixes => state.deliveryLog.where((d) => d.runsOffBat == 6).length;

  @override
  Widget build(BuildContext context) {
    final pBalls = _partnershipBalls;
    final pOvers = '${pBalls ~/ 6}.${pBalls % 6}';
    final crr = _currentRunRate;
    final isChasing = state.currentInnings == 2 && state.targetRuns > 0;
    final rrr = isChasing ? _requiredRunRate : 0.0;
    final runsNeeded = isChasing ? state.targetRuns - state.runs : 0;
    final ballsLeft = isChasing
        ? (state.totalOvers - state.completedOvers) * 6 - state.currentBall
        : 0;

    return Container(
      width: double.infinity,
      // Slightly brighter than CR.bg for broadcast-panel contrast
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Team + score line — the broadcast hero
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          state.battingTeamName.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: CR.text3,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Ball type badge (defaults to LEATHER for now)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: CR.red.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                            border:
                                Border.all(color: CR.red.withOpacity(0.25)),
                          ),
                          child: Text(
                            '🔴 LEATHER',
                            style: GoogleFonts.inter(
                              color: CR.red,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (isDemoMatch) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: CR.text3.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: CR.text3.withOpacity(0.2)),
                            ),
                            child: Text(
                              'DEMO',
                              style: GoogleFonts.inter(
                                color: CR.text3,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Large score — broadcast-size
                    Text(
                      state.scoreDisplay,
                      style: GoogleFonts.spaceGrotesk(
                        color: CR.text1,
                        fontSize: 52,
                        fontWeight: FontWeight.w800,
                        height: 0.95,
                      ),
                    ),
                  ],
                ),
              ),
              // Overs
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    state.oversDisplay,
                    style: GoogleFonts.spaceGrotesk(
                      color: CR.text2,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'OVERS',
                    style: GoogleFonts.inter(
                      color: CR.text3,
                      fontSize: 9,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (state.currentInnings == 2 && state.targetRuns > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: CR.gold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: CR.gold.withOpacity(0.25)),
                  ),
                  child: Text(
                    'Need $runsNeeded off $ballsLeft balls  •  RRR ${rrr.toStringAsFixed(1)}',
                    style: GoogleFonts.inter(
                      color: CR.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (state.wickets == 9) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: CR.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'LAST PAIR',
                      style: GoogleFonts.inter(
                        color: CR.red,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ] else if (state.wickets == 9) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: CR.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'LAST PAIR',
                style: GoogleFonts.inter(
                  color: CR.red,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          // Thin green separator line
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  CR.green.withOpacity(0.5),
                  CR.green.withOpacity(0.05),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Batters
          if (state.striker != null)
            _BatterRow(batter: state.striker!, isStriker: true)
          else
            const _EmptyPlayerRow(label: 'SET STRIKER'),
          const SizedBox(height: 5),
          if (state.nonStriker != null)
            _BatterRow(batter: state.nonStriker!, isStriker: false)
          else
            const _EmptyPlayerRow(label: 'SET NON-STRIKER'),
          const SizedBox(height: 8),
          // Bowler
          if (state.currentBowler != null)
            _BowlerRow(bowler: state.currentBowler!)
          else
            const _EmptyPlayerRow(label: 'SET BOWLER'),
          const SizedBox(height: 6),
          // Partnership + run rate line
          if (state.striker != null && state.nonStriker != null)
            Row(
              children: [
                Text(
                  'Partnership: $_partnershipRuns runs ($pOvers ov)',
                  style: GoogleFonts.inter(
                    color: CR.text3,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(width: 1, height: 10, color: CR.text3),
                const SizedBox(width: 8),
                if (isChasing) ...[
                  Text(
                    'RRR: ${rrr.toStringAsFixed(1)}',
                    style: GoogleFonts.inter(
                      color: rrr > crr ? CR.red : CR.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '· CRR: ${crr.toStringAsFixed(1)}',
                    style: GoogleFonts.inter(
                      color: CR.text3,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else
                  Text(
                    'CRR: ${crr.toStringAsFixed(1)}',
                    style: GoogleFonts.inter(
                      color: CR.text3,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 6),
          // Recent balls + boundary counter
          Row(
            children: [
              Expanded(child: _RecentBalls(deliveries: state.last6Deliveries)),
              const SizedBox(width: 8),
              Text(
                '4s: $_fours  ·  6s: $_sixes',
                style: GoogleFonts.inter(
                  color: CR.text3,
                  fontSize: 10,
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

class _BatterRow extends StatelessWidget {
  final BatterState batter;
  final bool isStriker;

  const _BatterRow({required this.batter, required this.isStriker});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: isStriker
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CR.green,
                    boxShadow: [
                      BoxShadow(
                        color: CR.green.withOpacity(0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                )
              : null,
        ),
        Text(
          batter.player.jerseyDisplay,
          style: GoogleFonts.spaceGrotesk(
            color: CR.text3,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            batter.player.displayName,
            style: GoogleFonts.inter(
              color: isStriker
                  ? CR.text1
                  : CR.text2,
              fontSize: 15,
              fontWeight: isStriker ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        // Score — larger for striker
        Text(
          '${batter.runs}*(${batter.balls})',
          style: GoogleFonts.spaceGrotesk(
            color: isStriker
                ? CR.text1
                : CR.text2,
            fontSize: isStriker ? 17 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _BowlerRow extends StatelessWidget {
  final BowlerState bowler;

  const _BowlerRow({required this.bowler});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.sports_cricket, color: CR.text3, size: 14),
        const SizedBox(width: 8),
        Text(
          bowler.player.jerseyDisplay,
          style: GoogleFonts.spaceGrotesk(
            color: CR.text3,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            bowler.player.displayName,
            style: GoogleFonts.inter(
              color: CR.text2,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '${bowler.figuresDisplay}  ${bowler.oversDisplay}',
          style: GoogleFonts.spaceGrotesk(
            color: CR.text2,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EmptyPlayerRow extends StatelessWidget {
  final String label;
  const _EmptyPlayerRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: CR.text3, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: CR.text3,
            fontSize: 11,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _RecentBalls extends StatelessWidget {
  final List<DeliveryRecord> deliveries;
  const _RecentBalls({required this.deliveries});

  Color _chipBg(DeliveryRecord d) {
    switch (d.ballResult) {
      case BallResult.dot:      return CR.bDot;
      case BallResult.single:
      case BallResult.two:
      case BallResult.three:   return CR.bRuns;
      case BallResult.four:    return CR.bFour;
      case BallResult.six:     return CR.bSix;
      case BallResult.wicket:  return CR.bWicket;
      case BallResult.wide:
      case BallResult.noBall:  return CR.bExtra;
      case BallResult.bye:
      // Warm brown tint for bye/leg-bye — distinct from extra orange
      case BallResult.legBye:  return const Color(0xFF3B1E0E);
    }
  }

  Color _chipText(DeliveryRecord d) {
    switch (d.ballResult) {
      case BallResult.four:   return CR.green;
      case BallResult.six:    return CR.gold;
      case BallResult.wicket: return CR.red;
      case BallResult.wide:
      case BallResult.noBall: return CR.orange;
      default:                return CR.text2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'LAST 6',
          style: GoogleFonts.inter(
            color: CR.text3,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 10),
        ...deliveries.map((d) => Padding(
          padding: const EdgeInsets.only(right: 7),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _chipBg(d),
              shape: BoxShape.circle,
              border: Border.all(
                color: _chipText(d).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                d.displayLabel,
                style: GoogleFonts.spaceGrotesk(
                  color: _chipText(d),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        )),
        if (deliveries.isEmpty)
          Text(
            'no balls yet',
            style: GoogleFonts.inter(
              color: CR.text3,
              fontSize: 11,
            ),
          ),
      ],
    );
  }
}

// ─── Zone B — Primary Actions ────────────────────────────────────────────────

class _ZoneB extends StatelessWidget {
  final MatchState state;
  final void Function(int) onRuns;
  final void Function(ExtraType) onExtra;
  final VoidCallback onWicket;

  const _ZoneB({
    required this.state,
    required this.onRuns,
    required this.onExtra,
    required this.onWicket,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CR.bg,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        children: [
          // Top row: 0, 1, 2, 3
          Expanded(
            flex: 3,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RunButton(runs: 0, onTap: () => onRuns(0)),
                _RunButton(runs: 1, onTap: () => onRuns(1)),
                _RunButton(runs: 2, onTap: () => onRuns(2)),
                _RunButton(runs: 3, onTap: () => onRuns(3)),
              ],
            ),
          ),
          // Bottom row: 4 and 6 — each half the width, enormous
          Expanded(
            flex: 3,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RunButton(runs: 4, onTap: () => onRuns(4), hero: true),
                _RunButton(runs: 6, onTap: () => onRuns(6), hero: true),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Event buttons
          Expanded(
            flex: 2,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EventButton(
                  label: 'W',
                  bgColor: CR.wicket,
                  textColor: CR.red,
                  borderColor: CR.red.withOpacity(0.4),
                  onTap: onWicket,
                ),
                _EventButton(
                  label: 'WD',
                  bgColor: CR.extra,
                  textColor: CR.orange,
                  borderColor: CR.orange.withOpacity(0.3),
                  onTap: () => onExtra(ExtraType.wide),
                ),
                _EventButton(
                  label: 'NB',
                  bgColor: CR.extra,
                  textColor: CR.orange,
                  borderColor: CR.orange.withOpacity(0.3),
                  onTap: () => onExtra(ExtraType.noBall),
                ),
                _EventButton(
                  label: 'BYE',
                  bgColor: CR.card,
                  textColor: CR.text2,
                  borderColor: CR.cardHigh,
                  onTap: () => onExtra(ExtraType.bye),
                ),
                _EventButton(
                  label: 'LBY',
                  bgColor: CR.card,
                  textColor: CR.text2,
                  borderColor: CR.cardHigh,
                  onTap: () => onExtra(ExtraType.legBye),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RunButton extends StatefulWidget {
  final int runs;
  final VoidCallback onTap;
  final bool hero; // 4 and 6 are larger hero buttons

  const _RunButton({required this.runs, required this.onTap, this.hero = false});

  @override
  State<_RunButton> createState() => _RunButtonState();
}

class _RunButtonState extends State<_RunButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 70),
      reverseDuration: const Duration(milliseconds: 110),
      lowerBound: 0.88,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  Color get _bgColor {
    switch (widget.runs) {
      case 4:  return CR.four;
      case 6:  return CR.six;
      default: return CR.card;
    }
  }

  Color get _textColor {
    switch (widget.runs) {
      case 4: return CR.green;
      case 6: return CR.gold;
      default: return CR.text1;
    }
  }

  List<BoxShadow>? get _glow {
    if (widget.runs == 4) {
      return [BoxShadow(color: CR.green.withOpacity(0.25), blurRadius: 10)];
    }
    if (widget.runs == 6) {
      return [BoxShadow(color: CR.gold.withOpacity(0.25), blurRadius: 10)];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => _pressCtrl.reverse(),
        onTapUp: (_) {
          _pressCtrl.forward();
          widget.onTap();
        },
        onTapCancel: () => _pressCtrl.forward(),
        child: ScaleTransition(
          scale: _pressCtrl,
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: _glow,
            ),
            child: Center(
              child: Text(
                widget.runs.toString(),
                style: GoogleFonts.spaceGrotesk(
                  color: _textColor,
                  fontSize: widget.hero ? 34 : 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EventButton extends StatefulWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _EventButton({
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  State<_EventButton> createState() => _EventButtonState();
}

class _EventButtonState extends State<_EventButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 70),
      reverseDuration: const Duration(milliseconds: 110),
      lowerBound: 0.88,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => _pressCtrl.reverse(),
        onTapUp: (_) {
          _pressCtrl.forward();
          widget.onTap();
        },
        onTapCancel: () => _pressCtrl.forward(),
        child: ScaleTransition(
          scale: _pressCtrl,
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: widget.bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                widget.label,
                style: GoogleFonts.spaceGrotesk(
                  color: widget.textColor,
                  fontSize: widget.label.length > 2 ? 13 : 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Zone C — Secondary Actions ──────────────────────────────────────────────

class _ZoneC extends StatelessWidget {
  final MatchState state;
  final VoidCallback onUndo;
  final VoidCallback onBowlChg;
  final VoidCallback onMore;

  const _ZoneC({
    required this.state,
    required this.onUndo,
    required this.onBowlChg,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CR.bg,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Row(
        children: [
          _ActionBtn(
            icon: Icons.undo_rounded,
            label: 'UNDO',
            onTap: onUndo,
          ),
          const SizedBox(width: 8),
          _ActionBtn(
            icon: Icons.swap_horiz_rounded,
            label: 'BOWL CHG',
            onTap: onBowlChg,
            highlighted: true,
          ),
          const SizedBox(width: 8),
          _ActionBtn(
            icon: Icons.more_horiz_rounded,
            label: '',
            onTap: onMore,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;
  final bool compact;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = highlighted
        ? CR.green.withOpacity(0.3)
        : CR.cardHigh;
    final iconColor = highlighted
        ? CR.green
        : CR.text2;

    return compact
        ? GestureDetector(
            onTap: onTap,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: CR.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CR.cardHigh),
              ),
              child: Icon(icon, color: CR.text3, size: 20),
            ),
          )
        : Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: highlighted
                      ? CR.green.withOpacity(0.07)
                      : CR.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: iconColor, size: 16),
                    if (label.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          color: iconColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
  }
}

// ─── Connectivity Banner ─────────────────────────────────────────────────────

class _ConnectivityBanner extends StatelessWidget {
  final ConnectivityStatus status;
  const _ConnectivityBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == ConnectivityStatus.online) return const SizedBox.shrink();

    final (color, text) = switch (status) {
      ConnectivityStatus.offline => (CR.red, '🔴 OFFLINE — All scoring saved locally'),
      ConnectivityStatus.syncing => (CR.gold, '🟡 SYNCING...'),
      ConnectivityStatus.online => (CR.green, '🟢 Live'),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      color: color.withOpacity(0.15),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Wicket Modal ─────────────────────────────────────────────────────────────

class _WicketModal extends StatefulWidget {
  final MatchState state;
  final void Function(WicketInfo) onConfirm;

  const _WicketModal({required this.state, required this.onConfirm});

  @override
  State<_WicketModal> createState() => _WicketModalState();
}

class _WicketModalState extends State<_WicketModal> {
  WicketType? _selectedType;
  String? _selectedFielderId;
  String? _selectedNewBatterId;
  String? _dismissedPlayerId;

  @override
  void initState() {
    super.initState();
    _dismissedPlayerId = widget.state.striker?.player.id;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: CR.text3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'WICKET — ${widget.state.striker?.player.jerseyDisplay} ${widget.state.striker?.player.displayName}',
              style: GoogleFonts.inter(
                color: CR.red,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'How out?',
              style: TextStyle(color: CR.text2, fontSize: 13),
            ),
            const SizedBox(height: 10),
            // Dismissal type chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: WicketType.values.map((type) {
                final isSelected = _selectedType == type;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedType = type;
                    _selectedFielderId = null;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? CR.red.withOpacity(0.2)
                          : CR.cardHigh,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? CR.red
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      type.displayName,
                      style: GoogleFonts.inter(
                        color: isSelected
                            ? CR.red
                            : CR.text1,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            // Fielder picker (for CAUGHT, STUMPED, RUN OUT)
            if (_selectedType != null &&
                (_selectedType!.requiresFielder || _selectedType!.requiresRunOutDetails)) ...[
              const SizedBox(height: 20),
              Text(
                _selectedType!.requiresRunOutDetails ? 'Who effected the run out?' : 'Who fielded?',
                style: const TextStyle(color: CR.text2, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.state.fieldingTeamPlayers.map((p) {
                  final isSelected = _selectedFielderId == p.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFielderId = p.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? CR.green.withOpacity(0.2)
                            : CR.cardHigh,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? CR.green : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            p.jerseyDisplay,
                            style: GoogleFonts.spaceGrotesk(
                              color: CR.text3,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            p.name.split(' ').first.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: isSelected
                                  ? CR.green
                                  : CR.text1,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            // Next batter
            const SizedBox(height: 20),
            const Text(
              'Next batter coming in:',
              style: TextStyle(color: CR.text2, fontSize: 13),
            ),
            const SizedBox(height: 10),
            if (widget.state.availableBatters.isEmpty)
              const Text(
                'No more batters',
                style: TextStyle(color: CR.text3),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.state.availableBatters.take(6).map((p) {
                  final isSelected = _selectedNewBatterId == p.id ||
                      (_selectedNewBatterId == null &&
                          p.id == widget.state.availableBatters.first.id);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedNewBatterId = p.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? CR.green.withOpacity(0.15)
                            : CR.cardHigh,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? CR.green : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '${p.jerseyDisplay} ${p.name.split(' ').first}',
                        style: GoogleFonts.inter(
                          color: isSelected
                              ? CR.green
                              : CR.text1,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),

            // Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedType == null
                    ? null
                    : () {
                        widget.onConfirm(WicketInfo(
                          type: _selectedType!,
                          dismissedPlayerId: _dismissedPlayerId ??
                              widget.state.striker!.player.id,
                          fielderPlayerId: _selectedFielderId,
                          newBatterId: _selectedNewBatterId ??
                              widget.state.availableBatters.firstOrNull?.id,
                        ));
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedType != null
                      ? CR.red
                      : CR.cardHigh,
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: Text(
                  'CONFIRM WICKET',
                  style: GoogleFonts.inter(
                    color: _selectedType != null
                        ? Colors.white
                        : CR.text3,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Bowling Change Modal ────────────────────────────────────────────────────

class _BowlingChangeModal extends StatelessWidget {
  final MatchState state;
  final void Function(Player) onSelect;

  const _BowlingChangeModal({required this.state, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final availableBowlers = state.fieldingTeamPlayers.where((p) {
      final isStriker = state.striker?.player.id == p.id;
      final isNonStriker = state.nonStriker?.player.id == p.id;
      final isCurrentBowler = state.currentBowler?.player.id == p.id;
      return !isStriker && !isNonStriker && !isCurrentBowler;
    }).toList();

    return Container(
      decoration: const BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CR.text3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Who is bowling next?',
            style: GoogleFonts.inter(
              color: CR.text1,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: availableBowlers.map((p) {
              return GestureDetector(
                onTap: () => onSelect(p),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: CR.cardHigh,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: CR.text3.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        p.jerseyDisplay,
                        style: GoogleFonts.spaceGrotesk(
                          color: CR.text3,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p.name.split(' ').first.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: CR.text1,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── More Menu Item ───────────────────────────────────────────────────────────

class _MoreMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MoreMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: CR.text2, size: 20),
      title: Text(
        label,
        style: GoogleFonts.inter(
          color: CR.text1,
          fontSize: 14,
        ),
      ),
      onTap: onTap,
      dense: true,
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

int _computeMaidens(List<DeliveryRecord> deliveries, String bowlerId) {
  int maidens = 0;
  final Map<int, List<DeliveryRecord>> overs = {};
  for (final d in deliveries.where((d) => d.bowlerId == bowlerId)) {
    overs.putIfAbsent(d.overNumber, () => []).add(d);
  }
  for (final over in overs.values) {
    final legalBalls = over
        .where((d) =>
            d.extraType != ExtraType.wide && d.extraType != ExtraType.noBall)
        .toList();
    if (legalBalls.length >= 6 && legalBalls.every((d) => d.runsOffBat == 0)) {
      maidens++;
    }
  }
  return maidens;
}

// ─── Full Scorecard Bottom Sheet ──────────────────────────────────────────────

class _FullScorecardSheet extends StatelessWidget {
  final MatchState state;
  const _FullScorecardSheet({required this.state});

  @override
  Widget build(BuildContext context) {
    // Build batting scorecard from delivery log
    final Map<String, _ScorecardBatterEntry> batters = {};
    for (final p in state.battingTeamPlayers) {
      batters[p.id] = _ScorecardBatterEntry(name: '${p.jerseyDisplay} ${p.displayName}');
    }
    for (final d in state.deliveryLog) {
      if (batters.containsKey(d.batsmanId)) {
        final b = batters[d.batsmanId]!;
        b.runs += d.runsOffBat;
        if (d.isLegalDelivery) b.balls++;
        if (d.runsOffBat == 4) b.fours++;
        if (d.runsOffBat == 6) b.sixes++;
        if (d.isWicket && d.dismissedPlayerId == d.batsmanId) b.isOut = true;
      }
    }

    // Build bowling scorecard
    final Map<String, _ScorecardBowlerEntry> bowlers = {};
    for (final p in state.fieldingTeamPlayers) {
      bowlers[p.id] = _ScorecardBowlerEntry(name: '${p.jerseyDisplay} ${p.displayName}');
    }
    for (final d in state.deliveryLog) {
      if (bowlers.containsKey(d.bowlerId)) {
        final b = bowlers[d.bowlerId]!;
        b.runs += d.totalRuns;
        if (d.isLegalDelivery) b.balls++;
        if (d.isWicket) b.wickets++;
      }
    }
    for (final entry in bowlers.entries) {
      entry.value.maidens = _computeMaidens(state.deliveryLog, entry.key);
    }

    final activeBatters = batters.values.where((b) => b.balls > 0 || b.runs > 0).toList();
    final activeBowlers = bowlers.values.where((b) => b.balls > 0).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: CR.text3, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'SCORECARD',
                  style: GoogleFonts.inter(
                    color: CR.text1, fontSize: 16, fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  state.battingTeamName,
                  style: GoogleFonts.inter(color: CR.text3, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Batting section
                  const _ScorecardSectionHeader(label: 'BATTING'),
                  const SizedBox(height: 4),
                  _ScorecardBattingHeader(),
                  ...activeBatters.map((b) => _ScorecardBattingRow(entry: b)),
                  if (state.striker != null && !activeBatters.any((b) => b.name.contains(state.striker!.player.jerseyDisplay))) ...[
                    _ScorecardBattingRow(
                      entry: _ScorecardBatterEntry(
                        name: '${state.striker!.player.jerseyDisplay} ${state.striker!.player.displayName}',
                      )
                        ..runs = state.striker!.runs
                        ..balls = state.striker!.balls
                        ..fours = state.striker!.fours
                        ..sixes = state.striker!.sixes,
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Bowling section
                  const _ScorecardSectionHeader(label: 'BOWLING'),
                  const SizedBox(height: 4),
                  _ScorecardBowlingHeader(),
                  ...activeBowlers.map((b) => _ScorecardBowlingRow(entry: b)),
                  _WormChart(deliveries: state.deliveryLog),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorecardBatterEntry {
  final String name;
  int runs = 0;
  int balls = 0;
  int fours = 0;
  int sixes = 0;
  bool isOut = false;
  _ScorecardBatterEntry({required this.name});

  double get sr => balls == 0 ? 0 : (runs / balls) * 100;
}

class _ScorecardBowlerEntry {
  final String name;
  int runs = 0;
  int balls = 0;
  int wickets = 0;
  int maidens = 0;
  _ScorecardBowlerEntry({required this.name});

  String get oversDisplay => '${balls ~/ 6}.${balls % 6}';
  double get econ => balls == 0 ? 0 : (runs / balls) * 6;
}

class _ScorecardSectionHeader extends StatelessWidget {
  final String label;
  const _ScorecardSectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 3, height: 12,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: CR.green)),
        Text(
          label,
          style: GoogleFonts.inter(
            color: CR.green, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _ScorecardBattingHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: const Row(
        children: [
          Expanded(child: SizedBox()),
          _SCellH('R'), _SCellH('B'), _SCellH('4s'), _SCellH('6s'), _SCellH('SR'),
        ],
      ),
    );
  }
}

class _ScorecardBowlingHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: const Row(
        children: [
          Expanded(child: SizedBox()),
          _SCellH('O'), _SCellH('M'), _SCellH('R'), _SCellH('W'), _SCellH('ECO'),
        ],
      ),
    );
  }
}

class _SCellH extends StatelessWidget {
  final String text;
  const _SCellH(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(color: CR.text3, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ScorecardBattingRow extends StatelessWidget {
  final _ScorecardBatterEntry entry;
  const _ScorecardBattingRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CR.cardHigh, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: GoogleFonts.inter(
                    color: entry.isOut ? CR.text2 : CR.text1,
                    fontSize: 12, fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (!entry.isOut)
                  Text('not out',
                      style: GoogleFonts.inter(color: CR.green, fontSize: 10)),
              ],
            ),
          ),
          _SCell('${entry.runs}${entry.isOut ? '' : '*'}', bold: true),
          _SCell(entry.balls.toString()),
          _SCell(entry.fours.toString()),
          _SCell(entry.sixes.toString()),
          _SCell(entry.sr.toStringAsFixed(1)),
        ],
      ),
    );
  }
}

class _ScorecardBowlingRow extends StatelessWidget {
  final _ScorecardBowlerEntry entry;
  const _ScorecardBowlingRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CR.cardHigh, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              entry.name,
              style: GoogleFonts.inter(color: CR.text1, fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _SCell(entry.oversDisplay),
          _SCell(entry.maidens.toString(), bold: entry.maidens > 0, color: entry.maidens > 0 ? CR.green : null),
          _SCell(entry.runs.toString()),
          _SCell(entry.wickets.toString(), bold: entry.wickets > 0, color: entry.wickets > 0 ? CR.red : null),
          _SCell(entry.econ.toStringAsFixed(1)),
        ],
      ),
    );
  }
}

class _SCell extends StatelessWidget {
  final String text;
  final bool bold;
  final Color? color;
  const _SCell(this.text, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.spaceGrotesk(
          color: color ?? CR.text2,
          fontSize: 12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

// ─── Worm Chart ───────────────────────────────────────────────────────────────

class _WormChart extends StatelessWidget {
  final List<DeliveryRecord> deliveries;
  const _WormChart({required this.deliveries});

  @override
  Widget build(BuildContext context) {
    if (deliveries.length < 3) return const SizedBox.shrink();

    final spots = <FlSpot>[];
    int total = 0;
    for (int i = 0; i < deliveries.length; i++) {
      total += deliveries[i].runsOffBat + deliveries[i].extraRuns;
      spots.add(FlSpot(i.toDouble(), total.toDouble()));
    }

    final maxY = (total + 10).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'INNINGS PROGRESSION',
          style: GoogleFonts.inter(
            color: CR.t3,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (deliveries.length - 1).toDouble(),
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 40 ? 20 : 10,
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: CR.cardHigh,
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: maxY > 40 ? 20 : 10,
                    getTitlesWidget: (v, _) => Text(
                      '${v.toInt()}',
                      style: GoogleFonts.spaceGrotesk(
                        color: CR.t3,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: CR.green,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: CR.green.withOpacity(0.06),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
