enum UserRole {
  player,
  organizer,
  scorer,
  spectator;

  String get displayName {
    switch (this) {
      case UserRole.player:
        return 'Player';
      case UserRole.organizer:
        return 'Organizer';
      case UserRole.scorer:
        return 'Scorer';
      case UserRole.spectator:
        return 'Spectator';
    }
  }
}

enum PlayerRole {
  pureBatter,
  pureBowler,
  battingAllrounder,
  bowlingAllrounder,
  wicketkeeperBatter;

  String get displayName {
    switch (this) {
      case PlayerRole.pureBatter:
        return 'Pure Batter';
      case PlayerRole.pureBowler:
        return 'Pure Bowler';
      case PlayerRole.battingAllrounder:
        return 'Batting All-rounder';
      case PlayerRole.bowlingAllrounder:
        return 'Bowling All-rounder';
      case PlayerRole.wicketkeeperBatter:
        return 'Wicketkeeper-Batter';
    }
  }

  String get shortName {
    switch (this) {
      case PlayerRole.pureBatter:
        return 'PB';
      case PlayerRole.pureBowler:
        return 'PBOW';
      case PlayerRole.battingAllrounder:
        return 'BAR';
      case PlayerRole.bowlingAllrounder:
        return 'BOAR';
      case PlayerRole.wicketkeeperBatter:
        return 'WKB';
    }
  }
}

enum MatchType {
  friendly,
  league,
  tournament;

  String get displayName {
    switch (this) {
      case MatchType.friendly:
        return 'Friendly';
      case MatchType.league:
        return 'League Match';
      case MatchType.tournament:
        return 'Tournament';
    }
  }

  double get ovrWeight {
    switch (this) {
      case MatchType.friendly:
        return 0.5;
      case MatchType.league:
        return 1.0;
      case MatchType.tournament:
        return 1.0;
    }
  }
}

enum MatchStatus {
  setup,
  live,
  pendingConfirmation,
  complete;
}

enum ExtraType {
  wide,
  noBall,
  bye,
  legBye;

  String get displayName {
    switch (this) {
      case ExtraType.wide:
        return 'WD';
      case ExtraType.noBall:
        return 'NB';
      case ExtraType.bye:
        return 'BYE';
      case ExtraType.legBye:
        return 'LBY';
    }
  }
}

enum WicketType {
  bowled,
  caught,
  lbw,
  runOut,
  stumped,
  hitWicket,
  retired,
  other;

  String get displayName {
    switch (this) {
      case WicketType.bowled:
        return 'BOWLED';
      case WicketType.caught:
        return 'CAUGHT';
      case WicketType.lbw:
        return 'LBW';
      case WicketType.runOut:
        return 'RUN OUT';
      case WicketType.stumped:
        return 'STUMPED';
      case WicketType.hitWicket:
        return 'HIT WKT';
      case WicketType.retired:
        return 'RETIRED';
      case WicketType.other:
        return 'OTHER';
    }
  }

  bool get requiresFielder {
    return this == WicketType.caught || this == WicketType.stumped;
  }

  bool get requiresRunOutDetails {
    return this == WicketType.runOut;
  }
}

enum MatchFormat {
  t20,
  tenOver,
  fiveOver,
  odi,
  custom;

  int get overs {
    switch (this) {
      case MatchFormat.t20:
        return 20;
      case MatchFormat.tenOver:
        return 10;
      case MatchFormat.fiveOver:
        return 5;
      case MatchFormat.odi:
        return 50;
      case MatchFormat.custom:
        return 20;
    }
  }

  double get srBenchmark {
    switch (this) {
      case MatchFormat.t20:
        return 120;
      case MatchFormat.tenOver:
        return 130;
      case MatchFormat.fiveOver:
        return 150;
      case MatchFormat.odi:
        return 80;
      case MatchFormat.custom:
        return 120;
    }
  }

  double get econBenchmark {
    switch (this) {
      case MatchFormat.t20:
        return 8.0;
      case MatchFormat.tenOver:
        return 9.0;
      case MatchFormat.fiveOver:
        return 10.0;
      case MatchFormat.odi:
        return 5.5;
      case MatchFormat.custom:
        return 8.0;
    }
  }

  String get displayName {
    switch (this) {
      case MatchFormat.t20:
        return 'T20 — 20 overs';
      case MatchFormat.tenOver:
        return '10 overs';
      case MatchFormat.fiveOver:
        return '5 overs';
      case MatchFormat.odi:
        return 'ODI — 50 overs';
      case MatchFormat.custom:
        return 'Custom';
    }
  }
}

enum ConnectivityStatus {
  online,
  offline,
  syncing;
}

enum BallResult {
  dot,
  single,
  two,
  three,
  four,
  six,
  wicket,
  wide,
  noBall,
  bye,
  legBye;
}
