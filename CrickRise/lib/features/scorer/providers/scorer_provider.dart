import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/match.dart';
import '../../../core/models/player.dart';
import '../../../core/models/enums.dart';

const _uuid = Uuid();

class ScorerNotifier extends StateNotifier<MatchState?> {
  ScorerNotifier() : super(null);

  void initMatch({
    required String teamAName,
    required String teamBName,
    required int totalOvers,
    required MatchType matchType,
    required MatchFormat format,
    required List<Player> battingTeamPlayers,
    required List<Player> fieldingTeamPlayers,
  }) {
    state = MatchState.initial(
      matchId: _uuid.v4(),
      teamAName: teamAName,
      teamBName: teamBName,
      totalOvers: totalOvers,
      matchType: matchType,
      format: format,
      battingTeamPlayers: battingTeamPlayers,
      fieldingTeamPlayers: fieldingTeamPlayers,
    );
  }

  void setOpeners(Player striker, Player nonStriker) {
    if (state == null) return;
    state = state!.copyWith(
      striker: BatterState(player: striker, isOnStrike: true),
      nonStriker: BatterState(player: nonStriker, isOnStrike: false),
      availableBatters: state!.battingTeamPlayers
          .where((p) => p.id != striker.id && p.id != nonStriker.id)
          .toList(),
    );
  }

  void setBowler(Player bowler) {
    if (state == null) return;
    state = state!.copyWith(
      currentBowler: BowlerState(player: bowler),
    );
  }

  void recordRuns(int runs) {
    if (state == null) return;
    final s = state!;
    if (s.striker == null || s.nonStriker == null || s.currentBowler == null) {
      return;
    }

    final delivery = DeliveryRecord(
      id: _uuid.v4(),
      matchId: s.matchId,
      inningsNumber: s.currentInnings,
      overNumber: s.completedOvers,
      ballNumber: s.currentBall,
      batsmanId: s.striker!.player.id,
      bowlerId: s.currentBowler!.player.id,
      runsOffBat: runs,
    );

    final newStriker = s.striker!.copyWith(
      runs: s.striker!.runs + runs,
      balls: s.striker!.balls + 1,
      fours: runs == 4 ? s.striker!.fours + 1 : s.striker!.fours,
      sixes: runs == 6 ? s.striker!.sixes + 1 : s.striker!.sixes,
    );

    final newBowler = s.currentBowler!.copyWith(
      runsConceded: s.currentBowler!.runsConceded + runs,
      ballsBowled: s.currentBowler!.ballsBowled + 1,
    );

    final newLog = [...s.deliveryLog, delivery];
    final newRuns = s.runs + runs;
    final newBall = s.currentBall + 1;
    final overComplete = newBall >= 6;

    // Rotate strike on odd runs
    final shouldSwapStrike = runs % 2 == 1;

    MatchState newState;
    if (overComplete) {
      // End of over — swap strike, reset ball, check for new bowler needed
      newState = s.copyWith(
        runs: newRuns,
        completedOvers: s.completedOvers + 1,
        currentBall: 0,
        striker: shouldSwapStrike ? s.nonStriker : newStriker,
        nonStriker: shouldSwapStrike ? newStriker : s.nonStriker,
        currentBowler: newBowler,
        deliveryLog: newLog,
      );
    } else {
      newState = s.copyWith(
        runs: newRuns,
        currentBall: newBall,
        striker: shouldSwapStrike ? s.nonStriker!.copyWith() : newStriker,
        nonStriker: shouldSwapStrike ? newStriker : s.nonStriker,
        currentBowler: newBowler,
        deliveryLog: newLog,
      );
      if (shouldSwapStrike) {
        newState = newState.copyWith(
          striker: s.nonStriker!.copyWith(isOnStrike: true),
          nonStriker: newStriker.copyWith(isOnStrike: false),
        );
      }
    }

    state = newState;
  }

  void recordExtra(ExtraType extraType, {int extraRuns = 1}) {
    if (state == null) return;
    final s = state!;
    if (s.striker == null || s.nonStriker == null || s.currentBowler == null) {
      return;
    }

    final isLegal = extraType != ExtraType.wide && extraType != ExtraType.noBall;

    final delivery = DeliveryRecord(
      id: _uuid.v4(),
      matchId: s.matchId,
      inningsNumber: s.currentInnings,
      overNumber: s.completedOvers,
      ballNumber: s.currentBall,
      batsmanId: s.striker!.player.id,
      bowlerId: s.currentBowler!.player.id,
      extraType: extraType,
      extraRuns: extraRuns,
    );

    final newBowler = s.currentBowler!.copyWith(
      runsConceded: s.currentBowler!.runsConceded + extraRuns,
      ballsBowled: isLegal ? s.currentBowler!.ballsBowled + 1 : s.currentBowler!.ballsBowled,
    );

    final newLog = [...s.deliveryLog, delivery];
    final newRuns = s.runs + extraRuns;
    final newBall = isLegal ? s.currentBall + 1 : s.currentBall;
    final overComplete = isLegal && newBall >= 6;

    MatchState newState;
    if (overComplete) {
      newState = s.copyWith(
        runs: newRuns,
        completedOvers: s.completedOvers + 1,
        currentBall: 0,
        currentBowler: newBowler,
        deliveryLog: newLog,
      );
    } else {
      newState = s.copyWith(
        runs: newRuns,
        currentBall: newBall,
        currentBowler: newBowler,
        deliveryLog: newLog,
      );
    }

    state = newState;
  }

  void recordWicket(WicketInfo wicket) {
    if (state == null) return;
    final s = state!;
    if (s.striker == null || s.nonStriker == null || s.currentBowler == null) {
      return;
    }

    final isDismissedStriker = wicket.dismissedPlayerId == s.striker!.player.id;
    final dismissedBatter = isDismissedStriker ? s.striker! : s.nonStriker!;

    final delivery = DeliveryRecord(
      id: _uuid.v4(),
      matchId: s.matchId,
      inningsNumber: s.currentInnings,
      overNumber: s.completedOvers,
      ballNumber: s.currentBall,
      batsmanId: s.striker!.player.id,
      bowlerId: s.currentBowler!.player.id,
      wicketType: wicket.type,
      dismissedPlayerId: wicket.dismissedPlayerId,
      fielderPlayerId: wicket.fielderPlayerId,
    );

    final isWicketToBowler = wicket.type != WicketType.runOut &&
        wicket.type != WicketType.retired &&
        wicket.type != WicketType.other;

    final newBowler = s.currentBowler!.copyWith(
      wickets: isWicketToBowler
          ? s.currentBowler!.wickets + 1
          : s.currentBowler!.wickets,
      ballsBowled: s.currentBowler!.ballsBowled + 1,
    );

    final newLog = [...s.deliveryLog, delivery];
    final newBall = s.currentBall + 1;
    final overComplete = newBall >= 6;
    final newWickets = s.wickets + 1;

    // Bring in the new batter
    Player? newBatterPlayer;
    List<Player> newAvailable = List.from(s.availableBatters);
    if (wicket.newBatterId != null) {
      newBatterPlayer = s.availableBatters
          .where((p) => p.id == wicket.newBatterId)
          .firstOrNull;
      newAvailable = newAvailable
          .where((p) => p.id != wicket.newBatterId)
          .toList();
    } else if (s.availableBatters.isNotEmpty) {
      newBatterPlayer = s.availableBatters.first;
      newAvailable = s.availableBatters.skip(1).toList();
    }

    final newBatterState = newBatterPlayer != null
        ? BatterState(
            player: newBatterPlayer,
            isOnStrike: isDismissedStriker,
          )
        : null;

    BatterState? newStriker;
    BatterState? newNonStriker;
    if (isDismissedStriker) {
      newStriker = newBatterState;
      newNonStriker = s.nonStriker;
    } else {
      newStriker = s.striker;
      newNonStriker = newBatterState;
    }

    final newDismissed = [
      ...s.dismissedBatters,
      dismissedBatter.player,
    ];

    MatchState newState;
    if (overComplete) {
      newState = s.copyWith(
        currentBall: 0,
        completedOvers: s.completedOvers + 1,
        wickets: newWickets,
        striker: newStriker,
        nonStriker: newNonStriker,
        currentBowler: newBowler,
        deliveryLog: newLog,
        dismissedBatters: newDismissed,
        availableBatters: newAvailable,
      );
    } else {
      newState = s.copyWith(
        currentBall: newBall,
        wickets: newWickets,
        striker: newStriker,
        nonStriker: newNonStriker,
        currentBowler: newBowler,
        deliveryLog: newLog,
        dismissedBatters: newDismissed,
        availableBatters: newAvailable,
      );
    }

    state = newState;
  }

  void undoLastDelivery() {
    if (state == null || state!.deliveryLog.isEmpty) return;
    final s = state!;
    final lastDelivery = s.deliveryLog.last;
    final newLog = s.deliveryLog.sublist(0, s.deliveryLog.length - 1);

    // Recalculate state from the beginning (simpler but correct)
    // For now, simple reversal of last ball
    final totalRuns = lastDelivery.totalRuns;
    final newRuns = s.runs - totalRuns;

    int newBall = s.currentBall;
    int newOvers = s.completedOvers;
    if (lastDelivery.isLegalDelivery) {
      if (s.currentBall == 0) {
        newOvers = s.completedOvers - 1;
        newBall = 5;
      } else {
        newBall = s.currentBall - 1;
      }
    }

    int newWickets = s.wickets;
    if (lastDelivery.isWicket) {
      newWickets = s.wickets - 1;
    }

    state = s.copyWith(
      runs: newRuns,
      wickets: newWickets,
      currentBall: newBall,
      completedOvers: newOvers,
      deliveryLog: newLog,
    );
  }

  void changeBowler(Player newBowler) {
    if (state == null) return;
    state = state!.copyWith(
      currentBowler: BowlerState(player: newBowler),
    );
  }

  DeliveryRecord? get lastDelivery {
    if (state == null || state!.deliveryLog.isEmpty) return null;
    return state!.deliveryLog.last;
  }
}

final scorerProvider =
    StateNotifierProvider<ScorerNotifier, MatchState?>((ref) {
  return ScorerNotifier();
});
