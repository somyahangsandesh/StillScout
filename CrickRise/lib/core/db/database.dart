import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

// ─── Tables ───────────────────────────────────────────────────────────────────

class Players extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get role => text()();
  IntColumn get jerseyNumber => integer().nullable()();
  TextColumn get teamId => text().nullable()();
  TextColumn get teamName => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Teams extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get leagueId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Matches extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get teamAId => text()();
  TextColumn get teamBId => text()();
  TextColumn get teamAName => text()();
  TextColumn get teamBName => text()();
  TextColumn get venueNote => text().nullable()();
  DateTimeColumn get playedAt => dateTime()();
  IntColumn get totalOvers => integer().withDefault(const Constant(20))();
  TextColumn get tossWinnerId => text().nullable()();
  BoolColumn get tossWinnerBattedFirst => boolean().nullable()();
  TextColumn get status => text()();
  TextColumn get format => text().withDefault(const Constant('t20'))();
  BoolColumn get syncedToServer =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Deliveries extends Table {
  TextColumn get id => text()();
  TextColumn get matchId => text()();
  IntColumn get inningsNumber => integer()();
  IntColumn get overNumber => integer()();
  IntColumn get ballNumber => integer()();
  TextColumn get batsmanId => text()();
  TextColumn get nonStrikerId => text()();
  TextColumn get bowlerId => text()();
  IntColumn get runsOffBat => integer().withDefault(const Constant(0))();
  TextColumn get extraType => text().nullable()();
  IntColumn get extraRuns => integer().withDefault(const Constant(0))();
  TextColumn get wicketType => text().nullable()();
  TextColumn get dismissedPlayerId => text().nullable()();
  TextColumn get fielderPlayerId => text().nullable()();
  BoolColumn get isAdminCorrection =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get syncedToServer =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class PlayerRatings extends Table {
  TextColumn get playerId => text()();
  RealColumn get ovr => real()();
  RealColumn get bat => real()();
  RealColumn get bowl => real()();
  RealColumn get field => real()();
  IntColumn get matchesPlayed => integer()();
  IntColumn get hotStreakCount =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get computedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {playerId};
}

// ─── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [Players, Teams, Matches, Deliveries, PlayerRatings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'crickrise_db');
  }

  // ── Players ──────────────────────────────────────────────────────────────

  Future<List<Player>> getAllPlayers() => select(players).get();

  Future<Player?> getPlayerById(String id) =>
      (select(players)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<int> upsertPlayer(PlayersCompanion player) =>
      into(players).insertOnConflictUpdate(player);

  // ── Matches ──────────────────────────────────────────────────────────────

  Future<List<Matche>> getAllMatches() =>
      (select(matches)
            ..orderBy([(m) => OrderingTerm.desc(m.playedAt)]))
          .get();

  Future<Matche?> getMatchById(String id) =>
      (select(matches)..where((m) => m.id.equals(id))).getSingleOrNull();

  Future<int> upsertMatch(MatchesCompanion match) =>
      into(matches).insertOnConflictUpdate(match);

  // ── Deliveries ────────────────────────────────────────────────────────────

  Future<List<Delivery>> getDeliveriesForMatch(String matchId) =>
      (select(deliveries)
            ..where((d) => d.matchId.equals(matchId))
            ..orderBy([
              (d) => OrderingTerm.asc(d.inningsNumber),
              (d) => OrderingTerm.asc(d.overNumber),
              (d) => OrderingTerm.asc(d.ballNumber),
            ]))
          .get();

  Future<List<Delivery>> getDeliveriesForPlayer(String playerId) =>
      (select(deliveries)
            ..where((d) =>
                d.batsmanId.equals(playerId) | d.bowlerId.equals(playerId)))
          .get();

  Future<int> insertDelivery(DeliveriesCompanion delivery) =>
      into(deliveries).insertOnConflictUpdate(delivery);

  Future<int> deleteLastDeliveryInInnings(
      String matchId, int inningsNumber) async {
    final all = await (select(deliveries)
          ..where((d) =>
              d.matchId.equals(matchId) &
              d.inningsNumber.equals(inningsNumber))
          ..orderBy([
            (d) => OrderingTerm.desc(d.overNumber),
            (d) => OrderingTerm.desc(d.ballNumber),
          ])
          ..limit(1))
        .get();

    if (all.isEmpty) return 0;
    return (delete(deliveries)..where((d) => d.id.equals(all.first.id))).go();
  }

  Future<List<Delivery>> getUnsyncedDeliveries() =>
      (select(deliveries)
            ..where((d) => d.syncedToServer.equals(false)))
          .get();

  // ── Player Ratings ────────────────────────────────────────────────────────

  Future<PlayerRating?> getRatingForPlayer(String playerId) =>
      (select(playerRatings)
            ..where((r) => r.playerId.equals(playerId)))
          .getSingleOrNull();

  Future<int> upsertRating(PlayerRatingsCompanion rating) =>
      into(playerRatings).insertOnConflictUpdate(rating);
}
