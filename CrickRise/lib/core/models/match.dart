import 'enums.dart';
import 'player.dart';

class Team {
  final String id;
  final String name;
  final String? leagueId;
  final List<Player> players;

  const Team({
    required this.id,
    required this.name,
    this.leagueId,
    this.players = const [],
  });
}

class BatterState {
  final Player player;
  int runs;
  int balls;
  int fours;
  int sixes;
  bool isOnStrike;
  bool isOut;

  BatterState({
    required this.player,
    this.runs = 0,
    this.balls = 0,
    this.fours = 0,
    this.sixes = 0,
    this.isOnStrike = false,
    this.isOut = false,
  });

  String get scoreDisplay => '$runs*($balls)';
  String get fullScoreDisplay => isOnStrike ? '● ${player.jerseyDisplay} ${player.displayName}    $runs*($balls)' : '  ${player.jerseyDisplay} ${player.displayName}    $runs*($balls)';

  BatterState copyWith({
    Player? player,
    int? runs,
    int? balls,
    int? fours,
    int? sixes,
    bool? isOnStrike,
    bool? isOut,
  }) {
    return BatterState(
      player: player ?? this.player,
      runs: runs ?? this.runs,
      balls: balls ?? this.balls,
      fours: fours ?? this.fours,
      sixes: sixes ?? this.sixes,
      isOnStrike: isOnStrike ?? this.isOnStrike,
      isOut: isOut ?? this.isOut,
    );
  }
}

class BowlerState {
  final Player player;
  int wickets;
  int runsConceded;
  int ballsBowled;

  BowlerState({
    required this.player,
    this.wickets = 0,
    this.runsConceded = 0,
    this.ballsBowled = 0,
  });

  String get figuresDisplay => '$wickets/$runsConceded';
  String get oversDisplay {
    final completeOvers = ballsBowled ~/ 6;
    final balls = ballsBowled % 6;
    return '$completeOvers.${balls}ov';
  }

  BowlerState copyWith({
    Player? player,
    int? wickets,
    int? runsConceded,
    int? ballsBowled,
  }) {
    return BowlerState(
      player: player ?? this.player,
      wickets: wickets ?? this.wickets,
      runsConceded: runsConceded ?? this.runsConceded,
      ballsBowled: ballsBowled ?? this.ballsBowled,
    );
  }
}

class DeliveryRecord {
  final String id;
  final String matchId;
  final int inningsNumber;
  final int overNumber;
  final int ballNumber;
  final String batsmanId;
  final String bowlerId;
  final int runsOffBat;
  final ExtraType? extraType;
  final int extraRuns;
  final WicketType? wicketType;
  final String? dismissedPlayerId;
  final String? fielderPlayerId;
  final bool isSynced;

  const DeliveryRecord({
    required this.id,
    required this.matchId,
    required this.inningsNumber,
    required this.overNumber,
    required this.ballNumber,
    required this.batsmanId,
    required this.bowlerId,
    this.runsOffBat = 0,
    this.extraType,
    this.extraRuns = 0,
    this.wicketType,
    this.dismissedPlayerId,
    this.fielderPlayerId,
    this.isSynced = false,
  });

  bool get isWicket => wicketType != null;
  bool get isExtra => extraType != null;
  bool get isLegalDelivery => extraType != ExtraType.wide && extraType != ExtraType.noBall;
  int get totalRuns => runsOffBat + extraRuns;

  BallResult get ballResult {
    if (wicketType != null) return BallResult.wicket;
    if (extraType == ExtraType.wide) return BallResult.wide;
    if (extraType == ExtraType.noBall) return BallResult.noBall;
    if (extraType == ExtraType.bye) return BallResult.bye;
    if (extraType == ExtraType.legBye) return BallResult.legBye;
    switch (runsOffBat) {
      case 0:
        return BallResult.dot;
      case 1:
        return BallResult.single;
      case 2:
        return BallResult.two;
      case 3:
        return BallResult.three;
      case 4:
        return BallResult.four;
      case 6:
        return BallResult.six;
      default:
        return BallResult.single;
    }
  }

  String get displayLabel {
    if (wicketType != null) return 'W';
    if (extraType == ExtraType.wide) return 'WD';
    if (extraType == ExtraType.noBall) return 'NB';
    if (extraType == ExtraType.bye) return 'B${extraRuns > 1 ? extraRuns : ''}';
    if (extraType == ExtraType.legBye) return 'LB${extraRuns > 1 ? extraRuns : ''}';
    return runsOffBat == 0 ? '●' : runsOffBat.toString();
  }
}

class MatchState {
  final String matchId;
  final String teamAName;
  final String teamBName;
  final int currentInnings;
  final int targetRuns;

  // Current innings state
  final int runs;
  final int wickets;
  final int completedOvers;
  final int currentBall;
  final int totalOvers;

  final BatterState? striker;
  final BatterState? nonStriker;
  final BowlerState? currentBowler;

  final List<DeliveryRecord> deliveryLog;
  final List<Player> battingTeamPlayers;
  final List<Player> fieldingTeamPlayers;
  final List<Player> dismissedBatters;
  final List<Player> availableBatters;

  // Innings 1 result (for target calculation)
  final int? innings1Runs;
  final int? innings1Wickets;

  final MatchType matchType;
  final MatchFormat format;

  const MatchState({
    required this.matchId,
    required this.teamAName,
    required this.teamBName,
    required this.currentInnings,
    required this.targetRuns,
    required this.runs,
    required this.wickets,
    required this.completedOvers,
    required this.currentBall,
    required this.totalOvers,
    this.striker,
    this.nonStriker,
    this.currentBowler,
    required this.deliveryLog,
    required this.battingTeamPlayers,
    required this.fieldingTeamPlayers,
    required this.dismissedBatters,
    required this.availableBatters,
    this.innings1Runs,
    this.innings1Wickets,
    required this.matchType,
    required this.format,
  });

  factory MatchState.initial({
    required String matchId,
    required String teamAName,
    required String teamBName,
    required int totalOvers,
    required MatchType matchType,
    required MatchFormat format,
    required List<Player> battingTeamPlayers,
    required List<Player> fieldingTeamPlayers,
  }) {
    return MatchState(
      matchId: matchId,
      teamAName: teamAName,
      teamBName: teamBName,
      currentInnings: 1,
      targetRuns: 0,
      runs: 0,
      wickets: 0,
      completedOvers: 0,
      currentBall: 0,
      totalOvers: totalOvers,
      striker: null,
      nonStriker: null,
      currentBowler: null,
      deliveryLog: const [],
      battingTeamPlayers: battingTeamPlayers,
      fieldingTeamPlayers: fieldingTeamPlayers,
      dismissedBatters: const [],
      availableBatters: battingTeamPlayers,
      innings1Runs: null,
      innings1Wickets: null,
      matchType: matchType,
      format: format,
    );
  }

  String get scoreDisplay => '$runs/$wickets';
  String get oversDisplay => '$completedOvers.$currentBall ov';

  String get battingTeamName => currentInnings == 1 ? teamAName : teamBName;
  String get fieldingTeamName => currentInnings == 1 ? teamBName : teamAName;

  List<DeliveryRecord> get last6Deliveries {
    final recent = deliveryLog.reversed.toList();
    return recent.take(6).toList().reversed.toList();
  }

  bool get isInningsComplete {
    return wickets >= battingTeamPlayers.length - 1 ||
        completedOvers >= totalOvers;
  }

  bool get isMatchComplete {
    if (currentInnings == 1) return false;
    if (isInningsComplete) return true;
    if (targetRuns > 0 && runs >= targetRuns) return true;
    return false;
  }

  MatchState copyWith({
    String? matchId,
    String? teamAName,
    String? teamBName,
    int? currentInnings,
    int? targetRuns,
    int? runs,
    int? wickets,
    int? completedOvers,
    int? currentBall,
    int? totalOvers,
    BatterState? striker,
    BatterState? nonStriker,
    BowlerState? currentBowler,
    List<DeliveryRecord>? deliveryLog,
    List<Player>? battingTeamPlayers,
    List<Player>? fieldingTeamPlayers,
    List<Player>? dismissedBatters,
    List<Player>? availableBatters,
    int? innings1Runs,
    int? innings1Wickets,
    MatchType? matchType,
    MatchFormat? format,
  }) {
    return MatchState(
      matchId: matchId ?? this.matchId,
      teamAName: teamAName ?? this.teamAName,
      teamBName: teamBName ?? this.teamBName,
      currentInnings: currentInnings ?? this.currentInnings,
      targetRuns: targetRuns ?? this.targetRuns,
      runs: runs ?? this.runs,
      wickets: wickets ?? this.wickets,
      completedOvers: completedOvers ?? this.completedOvers,
      currentBall: currentBall ?? this.currentBall,
      totalOvers: totalOvers ?? this.totalOvers,
      striker: striker ?? this.striker,
      nonStriker: nonStriker ?? this.nonStriker,
      currentBowler: currentBowler ?? this.currentBowler,
      deliveryLog: deliveryLog ?? this.deliveryLog,
      battingTeamPlayers: battingTeamPlayers ?? this.battingTeamPlayers,
      fieldingTeamPlayers: fieldingTeamPlayers ?? this.fieldingTeamPlayers,
      dismissedBatters: dismissedBatters ?? this.dismissedBatters,
      availableBatters: availableBatters ?? this.availableBatters,
      innings1Runs: innings1Runs ?? this.innings1Runs,
      innings1Wickets: innings1Wickets ?? this.innings1Wickets,
      matchType: matchType ?? this.matchType,
      format: format ?? this.format,
    );
  }
}

class WicketInfo {
  final WicketType type;
  final String dismissedPlayerId;
  final String? fielderPlayerId;
  final String? newBatterId;

  const WicketInfo({
    required this.type,
    required this.dismissedPlayerId,
    this.fielderPlayerId,
    this.newBatterId,
  });
}
