import '../models/enums.dart';
import '../models/match.dart';

class OvrService {
  const OvrService();

  /// Compute BAT rating from delivery records for a player
  double computeBatRating(
    List<DeliveryRecord> allDeliveries,
    String playerId,
    MatchFormat format,
  ) {
    final battingDeliveries = allDeliveries
        .where((d) => d.batsmanId == playerId && !d.isExtra)
        .toList();

    if (battingDeliveries.isEmpty) return 50.0;

    final runsScored = battingDeliveries.fold(0, (sum, d) => sum + d.runsOffBat);
    final ballsFaced = battingDeliveries.where((d) => d.isLegalDelivery).length;
    final dismissals = battingDeliveries.where((d) => d.isWicket && d.dismissedPlayerId == playerId).length;

    if (ballsFaced < 6) return 50.0;

    final battingAverage = dismissals > 0 ? runsScored / dismissals : runsScored.toDouble();
    final strikeRate = ballsFaced > 0 ? (runsScored / ballsFaced) * 100 : 0.0;
    final srRelative = (strikeRate / format.srBenchmark) * 50;

    // Innings with 15+ runs
    final innings = _groupInnings(battingDeliveries, playerId);
    final inningsWith15 = innings.where((inn) => inn >= 15).length;
    final consistency = innings.isNotEmpty ? (inningsWith15 / innings.length) * 99 : 0.0;

    // Big innings (50+, 100+)
    final fifties = innings.where((inn) => inn >= 50 && inn < 100).length;
    final hundreds = innings.where((inn) => inn >= 100).length;
    final bigInningsRate = innings.isNotEmpty
        ? ((fifties + hundreds * 2) / innings.length) * 10
        : 0.0;

    final batRaw = battingAverage * 0.35 +
        srRelative * 0.25 +
        consistency * 0.20 +
        bigInningsRate * 0.15;

    return _normalize(batRaw, 1, 99);
  }

  /// Compute BOWL rating from delivery records for a player
  double computeBowlRating(
    List<DeliveryRecord> allDeliveries,
    String playerId,
    MatchFormat format,
  ) {
    final bowlingDeliveries = allDeliveries.where((d) => d.bowlerId == playerId).toList();
    if (bowlingDeliveries.isEmpty) return 50.0;

    final ballsBowled = bowlingDeliveries.where((d) => d.isLegalDelivery).length;
    final oversBowled = ballsBowled / 6.0;

    if (oversBowled < 1) return 50.0;

    final runsConceded = bowlingDeliveries.fold(0, (sum, d) => sum + d.totalRuns);
    final wickets = bowlingDeliveries.where((d) => d.isWicket).length;

    final bowlingAverage = wickets > 0 ? runsConceded / wickets : runsConceded.toDouble();
    final economy = oversBowled > 0 ? runsConceded / oversBowled : 0.0;
    final economyRelative = economy > 0 ? (format.econBenchmark / economy) * 50 : 50.0;
    final bowlingSr = wickets > 0 ? ballsBowled / wickets.toDouble() : 999.0;
    final bowlingSrScore = _normalize(100 - (bowlingSr / 10), 0, 100);
    final bowlingAvgScore = _normalize(100 - (bowlingAverage / 2), 0, 100);
    final wicketRate = wickets / (oversBowled / format.overs).clamp(1.0, double.infinity);
    final wicketRateScore = _normalize(wicketRate * 10, 0, 100);

    final bowlRaw = bowlingAvgScore * 0.30 +
        economyRelative * 0.25 +
        bowlingSrScore * 0.25 +
        wicketRateScore * 0.15;

    return _normalize(bowlRaw, 1, 99);
  }

  /// Compute FIELD rating from delivery records for a player
  double computeFieldRating(
    List<DeliveryRecord> allDeliveries,
    String playerId,
    PlayerRole role,
    int matchesPlayed,
  ) {
    if (matchesPlayed == 0) return 50.0;

    final catches = allDeliveries
        .where((d) => d.fielderPlayerId == playerId && d.wicketType == WicketType.caught)
        .length;
    final runOuts = allDeliveries
        .where((d) => d.fielderPlayerId == playerId && d.wicketType == WicketType.runOut)
        .length;
    final stumpings = allDeliveries
        .where((d) => d.fielderPlayerId == playerId && d.wicketType == WicketType.stumped)
        .length;

    final catchesPerMatch = catches / matchesPlayed;
    final runOutContrib = runOuts / matchesPlayed;

    double fieldRaw;
    if (role == PlayerRole.wicketkeeperBatter) {
      final stumpingsPerMatch = stumpings / matchesPlayed;
      fieldRaw = catchesPerMatch * 40 + runOutContrib * 35 + stumpingsPerMatch * 25;
    } else {
      fieldRaw = catchesPerMatch * 60 + runOutContrib * 40;
    }

    // Reduce influence for players with <10 matches
    if (matchesPlayed < 10) {
      fieldRaw *= 0.7;
    }

    // Normalize to 1-99 range
    return _normalize(fieldRaw * 30 + 50, 1, 99);
  }

  /// Compute OVR from domain ratings + player role
  double computeOvr(
    double bat,
    double bowl,
    double field,
    PlayerRole role,
  ) {
    switch (role) {
      case PlayerRole.pureBatter:
        return bat * 0.75 + field * 0.20 + bowl * 0.05;
      case PlayerRole.pureBowler:
        return bowl * 0.75 + field * 0.20 + bat * 0.05;
      case PlayerRole.battingAllrounder:
        return bat * 0.55 + bowl * 0.30 + field * 0.15;
      case PlayerRole.bowlingAllrounder:
        return bowl * 0.55 + bat * 0.30 + field * 0.15;
      case PlayerRole.wicketkeeperBatter:
        return bat * 0.50 + field * 0.35 + bowl * 0.15;
    }
  }

  /// Apply Bayesian shrinkage based on match count
  double applyShrinkage(double ovr, int caps) {
    if (caps < 5) return -1; // OVR not yet unlocked
    if (caps < 10) return ovr.clamp(42, 68);
    if (caps < 20) return ovr.clamp(36, 80);
    return ovr.clamp(30, 95);
  }

  /// Compute hot streak — consecutive matches above career average
  int computeHotStreak(
    List<MatchPerformance> matches,
    double careerBattingAvg,
    double careerEconomy,
    PlayerRole role,
  ) {
    int streak = 0;
    for (final match in matches) {
      bool aboveAverage = false;

      if (role == PlayerRole.pureBatter ||
          role == PlayerRole.battingAllrounder ||
          role == PlayerRole.wicketkeeperBatter) {
        if (match.runsScored >= careerBattingAvg && match.ballsFaced >= 6) {
          aboveAverage = true;
        }
      }

      if (role == PlayerRole.pureBowler || role == PlayerRole.bowlingAllrounder) {
        final bowlingAbove = (match.economy <= careerEconomy || match.wickets >= 1) &&
            match.oversBowled >= 1;
        if (bowlingAbove) aboveAverage = true;
      }

      if (role == PlayerRole.battingAllrounder) {
        final bowlingAbove = (match.economy <= careerEconomy || match.wickets >= 1) &&
            match.oversBowled >= 1;
        if (bowlingAbove) aboveAverage = true;
      }

      if (aboveAverage) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  List<int> _groupInnings(List<DeliveryRecord> deliveries, String playerId) {
    final Map<String, int> inningsByMatch = {};
    for (final d in deliveries) {
      if (d.batsmanId == playerId) {
        final key = '${d.matchId}_${d.inningsNumber}';
        inningsByMatch[key] = (inningsByMatch[key] ?? 0) + d.runsOffBat;
      }
    }
    return inningsByMatch.values.toList();
  }

  double _normalize(double value, double min, double max) {
    return value.clamp(min, max);
  }
}

class MatchPerformance {
  final String matchId;
  final int runsScored;
  final int ballsFaced;
  final int wickets;
  final double oversBowled;
  final double economy;

  const MatchPerformance({
    required this.matchId,
    required this.runsScored,
    required this.ballsFaced,
    required this.wickets,
    required this.oversBowled,
    required this.economy,
  });
}
