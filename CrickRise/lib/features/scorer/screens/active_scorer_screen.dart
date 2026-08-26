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
      backgroundColor: CrickRiseColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _ConnectivityBanner(status: _connectivity),
            Expanded(
              flex: 45,
              child: _ZoneA(state: matchState),
            ),
            const Divider(height: 1, color: CrickRiseColors.surfaceElevated),
            Expanded(
              flex: 35,
              child: _ZoneB(
                state: matchState,
                onRuns: (r) => _handleRuns(r, matchState),
                onExtra: (e) => _handleExtra(e, matchState),
                onWicket: () => _showWicketModal(matchState),
              ),
            ),
            const Divider(height: 1, color: CrickRiseColors.surfaceElevated),
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
    HapticFeedback.lightImpact();
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
        backgroundColor: CrickRiseColors.surface,
        title: Text(
          'Undo last delivery?',
          style: GoogleFonts.inter(
            color: CrickRiseColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Over ${state.completedOvers}.${state.currentBall} · '
          '${last.displayLabel} · '
          '${state.striker?.player.jerseyDisplay} ${state.striker?.player.name} batting · '
          '${state.currentBowler?.player.jerseyDisplay} ${state.currentBowler?.player.name} bowling',
          style: const TextStyle(color: CrickRiseColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: CrickRiseColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(scorerProvider.notifier).undoLastDelivery();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CrickRiseColors.warning,
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
    HapticFeedback.mediumImpact();
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
    showModalBottomSheet(
      context: context,
      backgroundColor: CrickRiseColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MoreMenuItem(
              icon: Icons.swap_horiz,
              label: 'Fix batter — swap crease positions',
              onTap: () => Navigator.pop(ctx),
            ),
            _MoreMenuItem(
              icon: Icons.sports_cricket,
              label: 'Fix this over\'s bowler',
              onTap: () => Navigator.pop(ctx),
            ),
            _MoreMenuItem(
              icon: Icons.accessible_forward,
              label: 'Retired hurt',
              onTap: () => Navigator.pop(ctx),
            ),
            _MoreMenuItem(
              icon: Icons.electric_bolt,
              label: 'Powerplay',
              onTap: () => Navigator.pop(ctx),
            ),
            _MoreMenuItem(
              icon: Icons.replay,
              label: 'Super over',
              onTap: () => Navigator.pop(ctx),
            ),
            _MoreMenuItem(
              icon: Icons.note_add,
              label: 'Add note',
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Zone A — Match State ────────────────────────────────────────────────────
// Broadcast overlay aesthetic: dark green panel, crisp numbers, real ball dots

class _ZoneA extends StatelessWidget {
  final MatchState state;
  const _ZoneA({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
                    Text(
                      state.battingTeamName.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: CrickRiseColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Large score — broadcast-size
                    Text(
                      state.scoreDisplay,
                      style: GoogleFonts.spaceGrotesk(
                        color: CrickRiseColors.textPrimary,
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
                      color: CrickRiseColors.textSecondary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'OVERS',
                    style: GoogleFonts.inter(
                      color: CrickRiseColors.textMuted,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: CrickRiseColors.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: CrickRiseColors.gold.withOpacity(0.25)),
              ),
              child: Text(
                'Need ${state.targetRuns - state.runs} off '
                '${(state.totalOvers - state.completedOvers) * 6 - state.currentBall} balls',
                style: GoogleFonts.inter(
                  color: CrickRiseColors.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
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
                  CrickRiseColors.primary.withOpacity(0.5),
                  CrickRiseColors.primary.withOpacity(0.05),
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
          const SizedBox(height: 10),
          // Recent balls — circular dots styled like cricket balls
          _RecentBalls(deliveries: state.last6Deliveries),
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
                    color: CrickRiseColors.primary,
                    boxShadow: [
                      BoxShadow(
                        color: CrickRiseColors.primary.withOpacity(0.6),
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
            color: CrickRiseColors.textMuted,
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
                  ? CrickRiseColors.textPrimary
                  : CrickRiseColors.textSecondary,
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
                ? CrickRiseColors.textPrimary
                : CrickRiseColors.textSecondary,
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
        const Icon(Icons.sports_cricket, color: CrickRiseColors.textMuted, size: 14),
        const SizedBox(width: 8),
        Text(
          bowler.player.jerseyDisplay,
          style: GoogleFonts.spaceGrotesk(
            color: CrickRiseColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            bowler.player.displayName,
            style: GoogleFonts.inter(
              color: CrickRiseColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '${bowler.figuresDisplay}  ${bowler.oversDisplay}',
          style: GoogleFonts.spaceGrotesk(
            color: CrickRiseColors.textSecondary,
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
        border: Border.all(color: CrickRiseColors.textMuted, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: CrickRiseColors.textMuted,
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
      case BallResult.dot:      return CrickRiseColors.ballDot;
      case BallResult.single:
      case BallResult.two:
      case BallResult.three:   return CrickRiseColors.ballRuns;
      case BallResult.four:    return CrickRiseColors.ballFour;
      case BallResult.six:     return CrickRiseColors.ballSix;
      case BallResult.wicket:  return CrickRiseColors.ballWicket;
      case BallResult.wide:
      case BallResult.noBall:  return CrickRiseColors.ballExtra;
      case BallResult.bye:
      case BallResult.legBye:  return const Color(0xFF3B1E0E);
    }
  }

  Color _chipText(DeliveryRecord d) {
    switch (d.ballResult) {
      case BallResult.four:   return CrickRiseColors.primary;
      case BallResult.six:    return CrickRiseColors.gold;
      case BallResult.wicket: return CrickRiseColors.danger;
      case BallResult.wide:
      case BallResult.noBall: return CrickRiseColors.warning;
      default:                return CrickRiseColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'LAST 6',
          style: GoogleFonts.inter(
            color: CrickRiseColors.textMuted,
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
              color: CrickRiseColors.textMuted,
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
      color: CrickRiseColors.background,
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
                  textColor: CrickRiseColors.danger,
                  borderColor: CrickRiseColors.danger.withOpacity(0.4),
                  onTap: onWicket,
                ),
                _EventButton(
                  label: 'WD',
                  bgColor: CR.extra,
                  textColor: CrickRiseColors.warning,
                  borderColor: CrickRiseColors.warning.withOpacity(0.3),
                  onTap: () => onExtra(ExtraType.wide),
                ),
                _EventButton(
                  label: 'NB',
                  bgColor: CR.extra,
                  textColor: CrickRiseColors.warning,
                  borderColor: CrickRiseColors.warning.withOpacity(0.3),
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
      color: CrickRiseColors.background,
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
        ? CrickRiseColors.primary.withOpacity(0.3)
        : CrickRiseColors.surfaceElevated;
    final iconColor = highlighted
        ? CrickRiseColors.primary
        : CrickRiseColors.textSecondary;

    return compact
        ? GestureDetector(
            onTap: onTap,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: CrickRiseColors.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CrickRiseColors.surfaceElevated),
              ),
              child: Icon(icon, color: CrickRiseColors.textMuted, size: 20),
            ),
          )
        : Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: highlighted
                      ? CrickRiseColors.primary.withOpacity(0.07)
                      : CrickRiseColors.surfaceCard,
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
      ConnectivityStatus.offline => (CrickRiseColors.danger, '🔴 OFFLINE — All scoring saved locally'),
      ConnectivityStatus.syncing => (CrickRiseColors.gold, '🟡 SYNCING...'),
      ConnectivityStatus.online => (CrickRiseColors.primary, '🟢 Live'),
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
        color: CrickRiseColors.surface,
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
                  color: CrickRiseColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'WICKET — ${widget.state.striker?.player.jerseyDisplay} ${widget.state.striker?.player.displayName}',
              style: GoogleFonts.inter(
                color: CrickRiseColors.danger,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'How out?',
              style: TextStyle(color: CrickRiseColors.textSecondary, fontSize: 13),
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
                          ? CrickRiseColors.danger.withOpacity(0.2)
                          : CrickRiseColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? CrickRiseColors.danger
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      type.displayName,
                      style: GoogleFonts.inter(
                        color: isSelected
                            ? CrickRiseColors.danger
                            : CrickRiseColors.textPrimary,
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
                style: const TextStyle(color: CrickRiseColors.textSecondary, fontSize: 13),
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
                            ? CrickRiseColors.primary.withOpacity(0.2)
                            : CrickRiseColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? CrickRiseColors.primary : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            p.jerseyDisplay,
                            style: GoogleFonts.spaceGrotesk(
                              color: CrickRiseColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            p.name.split(' ').first.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: isSelected
                                  ? CrickRiseColors.primary
                                  : CrickRiseColors.textPrimary,
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
              style: TextStyle(color: CrickRiseColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 10),
            if (widget.state.availableBatters.isEmpty)
              const Text(
                'No more batters',
                style: TextStyle(color: CrickRiseColors.textMuted),
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
                            ? CrickRiseColors.primary.withOpacity(0.15)
                            : CrickRiseColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? CrickRiseColors.primary : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '${p.jerseyDisplay} ${p.name.split(' ').first}',
                        style: GoogleFonts.inter(
                          color: isSelected
                              ? CrickRiseColors.primary
                              : CrickRiseColors.textPrimary,
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
                      ? CrickRiseColors.danger
                      : CrickRiseColors.surfaceElevated,
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: Text(
                  'CONFIRM WICKET',
                  style: GoogleFonts.inter(
                    color: _selectedType != null
                        ? Colors.white
                        : CrickRiseColors.textMuted,
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
        color: CrickRiseColors.surface,
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
                color: CrickRiseColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Who is bowling next?',
            style: GoogleFonts.inter(
              color: CrickRiseColors.textPrimary,
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
                    color: CrickRiseColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: CrickRiseColors.textMuted.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        p.jerseyDisplay,
                        style: GoogleFonts.spaceGrotesk(
                          color: CrickRiseColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p.name.split(' ').first.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: CrickRiseColors.textPrimary,
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
      leading: Icon(icon, color: CrickRiseColors.textSecondary, size: 20),
      title: Text(
        label,
        style: GoogleFonts.inter(
          color: CrickRiseColors.textPrimary,
          fontSize: 14,
        ),
      ),
      onTap: onTap,
      dense: true,
    );
  }
}
