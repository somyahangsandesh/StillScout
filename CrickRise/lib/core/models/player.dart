import 'enums.dart';

class Player {
  final String id;
  final String name;
  final PlayerRole role;
  final List<UserRole> roles;
  final int? jerseyNumber;
  final String? teamId;
  final String? teamName;
  final DateTime createdAt;
  // CR Number — permanent cricket identity (e.g. CR-1247)
  final String? crNumber;
  // Seasons played — used for Heritage badge
  final int seasonsPlayed;

  const Player({
    required this.id,
    required this.name,
    required this.role,
    this.roles = const [UserRole.player],
    this.jerseyNumber,
    this.teamId,
    this.teamName,
    required this.createdAt,
    this.crNumber,
    this.seasonsPlayed = 0,
  });

  String get displayName => name.toUpperCase();
  String get jerseyDisplay => jerseyNumber != null ? '#$jerseyNumber' : '';
  String get crDisplay => crNumber ?? 'CR-????';

  // Heritage badge: 3+ seasons
  bool get hasHeritage => seasonsPlayed >= 3;
  // Elder badge: 5+ seasons
  bool get hasElder => seasonsPlayed >= 5;

  bool get isOrganizer => roles.contains(UserRole.organizer);
  bool get canScore =>
      roles.contains(UserRole.scorer) || roles.contains(UserRole.organizer);
  bool get isSpectator =>
      roles.length == 1 && roles.contains(UserRole.spectator);

  Player copyWith({
    String? id,
    String? name,
    PlayerRole? role,
    List<UserRole>? roles,
    int? jerseyNumber,
    String? teamId,
    String? teamName,
    DateTime? createdAt,
    String? crNumber,
    int? seasonsPlayed,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      roles: roles ?? this.roles,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      createdAt: createdAt ?? this.createdAt,
      crNumber: crNumber ?? this.crNumber,
      seasonsPlayed: seasonsPlayed ?? this.seasonsPlayed,
    );
  }
}

class PlayerRating {
  final String playerId;
  final double ovr;
  final double bat;
  final double bowl;
  final double field;
  final int matchesPlayed;
  final int hotStreakCount;
  final DateTime computedAt;

  const PlayerRating({
    required this.playerId,
    required this.ovr,
    required this.bat,
    required this.bowl,
    required this.field,
    required this.matchesPlayed,
    required this.hotStreakCount,
    required this.computedAt,
  });

  bool get hasOvr => matchesPlayed >= 5;

  bool get hasHotStreak => hotStreakCount >= 2;

  String get hotStreakDisplay {
    if (hotStreakCount >= 5) return '🔥 $hotStreakCount-match hot streak';
    if (hotStreakCount >= 3) return '🔥 Hot Streak $hotStreakCount';
    if (hotStreakCount >= 2) return '$hotStreakCount-match streak';
    return '';
  }
}

class PlayerStats {
  final String playerId;
  final int season;
  final int matches;
  final int runsScored;
  final int ballsFaced;
  final int wicketsTaken;
  final int catches;
  final int mvpAwards;
  final int runOuts;
  final int stumpings;
  final int ballsBowled;
  final int runsConceded;
  final int fifties;
  final int hundreds;

  const PlayerStats({
    required this.playerId,
    required this.season,
    required this.matches,
    required this.runsScored,
    required this.ballsFaced,
    required this.wicketsTaken,
    required this.catches,
    required this.mvpAwards,
    required this.runOuts,
    required this.stumpings,
    required this.ballsBowled,
    required this.runsConceded,
    required this.fifties,
    required this.hundreds,
  });

  double get battingAverage =>
      wicketsTaken > 0 ? runsScored / wicketsTaken : runsScored.toDouble();

  double get strikeRate =>
      ballsFaced > 0 ? (runsScored / ballsFaced) * 100 : 0;

  double get bowlingAverage =>
      wicketsTaken > 0 ? runsConceded / wicketsTaken : runsConceded.toDouble();

  double get economy =>
      ballsBowled > 0 ? (runsConceded / ballsBowled) * 6 : 0;
}

/// Sample data for UI development
class SampleData {
  static final Player samplePlayer = Player(
    id: 'player-001',
    name: 'Roshan KC',
    role: PlayerRole.battingAllrounder,
    roles: [UserRole.player, UserRole.organizer, UserRole.scorer],
    jerseyNumber: 7,
    teamId: 'team-001',
    teamName: 'Okinawa Warriors',
    createdAt: DateTime(2024, 1, 15),
    crNumber: 'CR-1247',
    seasonsPlayed: 3,
  );

  static final Player rival = Player(
    id: 'player-002',
    name: 'Bikash Rai',
    role: PlayerRole.pureBatter,
    roles: [UserRole.player],
    jerseyNumber: 23,
    teamId: 'team-002',
    teamName: 'Tokyo Rhinos',
    createdAt: DateTime(2024, 1, 10),
  );

  static final Player below = Player(
    id: 'player-003',
    name: 'Anil Tamang',
    role: PlayerRole.pureBowler,
    roles: [UserRole.player],
    jerseyNumber: 4,
    teamId: 'team-003',
    teamName: 'Osaka Kings',
    createdAt: DateTime(2024, 2, 1),
  );

  static final PlayerRating sampleRating = PlayerRating(
    playerId: 'player-001',
    ovr: 86,
    bat: 89,
    bowl: 78,
    field: 84,
    matchesPlayed: 14,
    hotStreakCount: 5,
    computedAt: DateTime.now(),
  );

  static final PlayerRating rivalRating = PlayerRating(
    playerId: 'player-002',
    ovr: 88,
    bat: 91,
    bowl: 65,
    field: 80,
    matchesPlayed: 16,
    hotStreakCount: 2,
    computedAt: DateTime.now(),
  );

  static final PlayerRating belowRating = PlayerRating(
    playerId: 'player-003',
    ovr: 83,
    bat: 70,
    bowl: 88,
    field: 79,
    matchesPlayed: 12,
    hotStreakCount: 0,
    computedAt: DateTime.now(),
  );

  static const PlayerStats sampleStats = PlayerStats(
    playerId: 'player-001',
    season: 2026,
    matches: 14,
    runsScored: 487,
    ballsFaced: 342,
    wicketsTaken: 21,
    catches: 13,
    mvpAwards: 3,
    runOuts: 2,
    stumpings: 0,
    ballsBowled: 432,
    runsConceded: 490,
    fifties: 6,
    hundreds: 1,
  );

  static final List<Player> teamPlayers = [
    samplePlayer,
    Player(
      id: 'player-011',
      name: 'Sandip Gurung',
      role: PlayerRole.pureBatter,
      jerseyNumber: 18,
      teamId: 'team-001',
      teamName: 'Okinawa Warriors',
      createdAt: DateTime(2024, 1, 15),
    ),
    Player(
      id: 'player-012',
      name: 'Bikash Thapa',
      role: PlayerRole.pureBowler,
      jerseyNumber: 23,
      teamId: 'team-001',
      teamName: 'Okinawa Warriors',
      createdAt: DateTime(2024, 1, 15),
    ),
    Player(
      id: 'player-013',
      name: 'Arjun Magar',
      role: PlayerRole.bowlingAllrounder,
      jerseyNumber: 12,
      teamId: 'team-001',
      teamName: 'Okinawa Warriors',
      createdAt: DateTime(2024, 1, 15),
    ),
    Player(
      id: 'player-014',
      name: 'Suraj Rai',
      role: PlayerRole.pureBatter,
      jerseyNumber: 4,
      teamId: 'team-001',
      teamName: 'Okinawa Warriors',
      createdAt: DateTime(2024, 1, 15),
    ),
    Player(
      id: 'player-015',
      name: 'Dev Limbu',
      role: PlayerRole.wicketkeeperBatter,
      jerseyNumber: 9,
      teamId: 'team-001',
      teamName: 'Okinawa Warriors',
      createdAt: DateTime(2024, 1, 15),
    ),
    Player(
      id: 'player-016',
      name: 'Pradeep Shrestha',
      role: PlayerRole.pureBowler,
      jerseyNumber: 6,
      teamId: 'team-001',
      teamName: 'Okinawa Warriors',
      createdAt: DateTime(2024, 1, 15),
    ),
    Player(
      id: 'player-017',
      name: 'Kumar Tamang',
      role: PlayerRole.pureBowler,
      jerseyNumber: 2,
      teamId: 'team-001',
      teamName: 'Okinawa Warriors',
      createdAt: DateTime(2024, 1, 15),
    ),
    Player(
      id: 'player-018',
      name: 'Hari Rana',
      role: PlayerRole.battingAllrounder,
      jerseyNumber: 15,
      teamId: 'team-001',
      teamName: 'Okinawa Warriors',
      createdAt: DateTime(2024, 1, 15),
    ),
    Player(
      id: 'player-019',
      name: 'Rajan Basnet',
      role: PlayerRole.pureBatter,
      jerseyNumber: 22,
      teamId: 'team-001',
      teamName: 'Okinawa Warriors',
      createdAt: DateTime(2024, 1, 15),
    ),
    Player(
      id: 'player-020',
      name: 'Sagar Poudel',
      role: PlayerRole.pureBowler,
      jerseyNumber: 3,
      teamId: 'team-001',
      teamName: 'Okinawa Warriors',
      createdAt: DateTime(2024, 1, 15),
    ),
  ];

  static final List<Player> oppositionPlayers = [
    rival,
    Player(
      id: 'player-021',
      name: 'Amit Shrestha',
      role: PlayerRole.pureBowler,
      jerseyNumber: 11,
      teamId: 'team-002',
      teamName: 'Tokyo Rhinos',
      createdAt: DateTime(2024, 2, 5),
    ),
    Player(
      id: 'player-022',
      name: 'Suraj KC',
      role: PlayerRole.pureBatter,
      jerseyNumber: 4,
      teamId: 'team-002',
      teamName: 'Tokyo Rhinos',
      createdAt: DateTime(2024, 2, 5),
    ),
    Player(
      id: 'player-023',
      name: 'Dev Thapa',
      role: PlayerRole.bowlingAllrounder,
      jerseyNumber: 9,
      teamId: 'team-002',
      teamName: 'Tokyo Rhinos',
      createdAt: DateTime(2024, 2, 5),
    ),
    Player(
      id: 'player-024',
      name: 'Pradeep Gurung',
      role: PlayerRole.pureBatter,
      jerseyNumber: 6,
      teamId: 'team-002',
      teamName: 'Tokyo Rhinos',
      createdAt: DateTime(2024, 2, 5),
    ),
  ];
}
