// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $PlayersTable extends Players with TableInfo<$PlayersTable, Player> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _jerseyNumberMeta =
      const VerificationMeta('jerseyNumber');
  @override
  late final GeneratedColumn<int> jerseyNumber = GeneratedColumn<int>(
      'jersey_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _teamIdMeta = const VerificationMeta('teamId');
  @override
  late final GeneratedColumn<String> teamId = GeneratedColumn<String>(
      'team_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _teamNameMeta =
      const VerificationMeta('teamName');
  @override
  late final GeneratedColumn<String> teamName = GeneratedColumn<String>(
      'team_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, role, jerseyNumber, teamId, teamName, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'players';
  @override
  VerificationContext validateIntegrity(Insertable<Player> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('jersey_number')) {
      context.handle(
          _jerseyNumberMeta,
          jerseyNumber.isAcceptableOrUnknown(
              data['jersey_number']!, _jerseyNumberMeta));
    }
    if (data.containsKey('team_id')) {
      context.handle(_teamIdMeta,
          teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta));
    }
    if (data.containsKey('team_name')) {
      context.handle(_teamNameMeta,
          teamName.isAcceptableOrUnknown(data['team_name']!, _teamNameMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Player map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Player(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      jerseyNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}jersey_number']),
      teamId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}team_id']),
      teamName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}team_name']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PlayersTable createAlias(String alias) {
    return $PlayersTable(attachedDatabase, alias);
  }
}

class Player extends DataClass implements Insertable<Player> {
  final String id;
  final String name;
  final String role;
  final int? jerseyNumber;
  final String? teamId;
  final String? teamName;
  final DateTime createdAt;
  const Player(
      {required this.id,
      required this.name,
      required this.role,
      this.jerseyNumber,
      this.teamId,
      this.teamName,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || jerseyNumber != null) {
      map['jersey_number'] = Variable<int>(jerseyNumber);
    }
    if (!nullToAbsent || teamId != null) {
      map['team_id'] = Variable<String>(teamId);
    }
    if (!nullToAbsent || teamName != null) {
      map['team_name'] = Variable<String>(teamName);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PlayersCompanion toCompanion(bool nullToAbsent) {
    return PlayersCompanion(
      id: Value(id),
      name: Value(name),
      role: Value(role),
      jerseyNumber: jerseyNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(jerseyNumber),
      teamId:
          teamId == null && nullToAbsent ? const Value.absent() : Value(teamId),
      teamName: teamName == null && nullToAbsent
          ? const Value.absent()
          : Value(teamName),
      createdAt: Value(createdAt),
    );
  }

  factory Player.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Player(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      role: serializer.fromJson<String>(json['role']),
      jerseyNumber: serializer.fromJson<int?>(json['jerseyNumber']),
      teamId: serializer.fromJson<String?>(json['teamId']),
      teamName: serializer.fromJson<String?>(json['teamName']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'role': serializer.toJson<String>(role),
      'jerseyNumber': serializer.toJson<int?>(jerseyNumber),
      'teamId': serializer.toJson<String?>(teamId),
      'teamName': serializer.toJson<String?>(teamName),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Player copyWith(
          {String? id,
          String? name,
          String? role,
          Value<int?> jerseyNumber = const Value.absent(),
          Value<String?> teamId = const Value.absent(),
          Value<String?> teamName = const Value.absent(),
          DateTime? createdAt}) =>
      Player(
        id: id ?? this.id,
        name: name ?? this.name,
        role: role ?? this.role,
        jerseyNumber:
            jerseyNumber.present ? jerseyNumber.value : this.jerseyNumber,
        teamId: teamId.present ? teamId.value : this.teamId,
        teamName: teamName.present ? teamName.value : this.teamName,
        createdAt: createdAt ?? this.createdAt,
      );
  Player copyWithCompanion(PlayersCompanion data) {
    return Player(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      role: data.role.present ? data.role.value : this.role,
      jerseyNumber: data.jerseyNumber.present
          ? data.jerseyNumber.value
          : this.jerseyNumber,
      teamId: data.teamId.present ? data.teamId.value : this.teamId,
      teamName: data.teamName.present ? data.teamName.value : this.teamName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Player(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('jerseyNumber: $jerseyNumber, ')
          ..write('teamId: $teamId, ')
          ..write('teamName: $teamName, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, role, jerseyNumber, teamId, teamName, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Player &&
          other.id == this.id &&
          other.name == this.name &&
          other.role == this.role &&
          other.jerseyNumber == this.jerseyNumber &&
          other.teamId == this.teamId &&
          other.teamName == this.teamName &&
          other.createdAt == this.createdAt);
}

class PlayersCompanion extends UpdateCompanion<Player> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> role;
  final Value<int?> jerseyNumber;
  final Value<String?> teamId;
  final Value<String?> teamName;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PlayersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.jerseyNumber = const Value.absent(),
    this.teamId = const Value.absent(),
    this.teamName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlayersCompanion.insert({
    required String id,
    required String name,
    required String role,
    this.jerseyNumber = const Value.absent(),
    this.teamId = const Value.absent(),
    this.teamName = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        role = Value(role),
        createdAt = Value(createdAt);
  static Insertable<Player> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? role,
    Expression<int>? jerseyNumber,
    Expression<String>? teamId,
    Expression<String>? teamName,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (jerseyNumber != null) 'jersey_number': jerseyNumber,
      if (teamId != null) 'team_id': teamId,
      if (teamName != null) 'team_name': teamName,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlayersCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? role,
      Value<int?>? jerseyNumber,
      Value<String?>? teamId,
      Value<String?>? teamName,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return PlayersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (jerseyNumber.present) {
      map['jersey_number'] = Variable<int>(jerseyNumber.value);
    }
    if (teamId.present) {
      map['team_id'] = Variable<String>(teamId.value);
    }
    if (teamName.present) {
      map['team_name'] = Variable<String>(teamName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('jerseyNumber: $jerseyNumber, ')
          ..write('teamId: $teamId, ')
          ..write('teamName: $teamName, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TeamsTable extends Teams with TableInfo<$TeamsTable, Team> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TeamsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _leagueIdMeta =
      const VerificationMeta('leagueId');
  @override
  late final GeneratedColumn<String> leagueId = GeneratedColumn<String>(
      'league_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, name, leagueId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'teams';
  @override
  VerificationContext validateIntegrity(Insertable<Team> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('league_id')) {
      context.handle(_leagueIdMeta,
          leagueId.isAcceptableOrUnknown(data['league_id']!, _leagueIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Team map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Team(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      leagueId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}league_id']),
    );
  }

  @override
  $TeamsTable createAlias(String alias) {
    return $TeamsTable(attachedDatabase, alias);
  }
}

class Team extends DataClass implements Insertable<Team> {
  final String id;
  final String name;
  final String? leagueId;
  const Team({required this.id, required this.name, this.leagueId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || leagueId != null) {
      map['league_id'] = Variable<String>(leagueId);
    }
    return map;
  }

  TeamsCompanion toCompanion(bool nullToAbsent) {
    return TeamsCompanion(
      id: Value(id),
      name: Value(name),
      leagueId: leagueId == null && nullToAbsent
          ? const Value.absent()
          : Value(leagueId),
    );
  }

  factory Team.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Team(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      leagueId: serializer.fromJson<String?>(json['leagueId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'leagueId': serializer.toJson<String?>(leagueId),
    };
  }

  Team copyWith(
          {String? id,
          String? name,
          Value<String?> leagueId = const Value.absent()}) =>
      Team(
        id: id ?? this.id,
        name: name ?? this.name,
        leagueId: leagueId.present ? leagueId.value : this.leagueId,
      );
  Team copyWithCompanion(TeamsCompanion data) {
    return Team(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      leagueId: data.leagueId.present ? data.leagueId.value : this.leagueId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Team(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('leagueId: $leagueId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, leagueId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Team &&
          other.id == this.id &&
          other.name == this.name &&
          other.leagueId == this.leagueId);
}

class TeamsCompanion extends UpdateCompanion<Team> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> leagueId;
  final Value<int> rowid;
  const TeamsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.leagueId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TeamsCompanion.insert({
    required String id,
    required String name,
    this.leagueId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<Team> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? leagueId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (leagueId != null) 'league_id': leagueId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TeamsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? leagueId,
      Value<int>? rowid}) {
    return TeamsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      leagueId: leagueId ?? this.leagueId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (leagueId.present) {
      map['league_id'] = Variable<String>(leagueId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TeamsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('leagueId: $leagueId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MatchesTable extends Matches with TableInfo<$MatchesTable, Matche> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _teamAIdMeta =
      const VerificationMeta('teamAId');
  @override
  late final GeneratedColumn<String> teamAId = GeneratedColumn<String>(
      'team_a_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _teamBIdMeta =
      const VerificationMeta('teamBId');
  @override
  late final GeneratedColumn<String> teamBId = GeneratedColumn<String>(
      'team_b_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _teamANameMeta =
      const VerificationMeta('teamAName');
  @override
  late final GeneratedColumn<String> teamAName = GeneratedColumn<String>(
      'team_a_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _teamBNameMeta =
      const VerificationMeta('teamBName');
  @override
  late final GeneratedColumn<String> teamBName = GeneratedColumn<String>(
      'team_b_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _venueNoteMeta =
      const VerificationMeta('venueNote');
  @override
  late final GeneratedColumn<String> venueNote = GeneratedColumn<String>(
      'venue_note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _playedAtMeta =
      const VerificationMeta('playedAt');
  @override
  late final GeneratedColumn<DateTime> playedAt = GeneratedColumn<DateTime>(
      'played_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _totalOversMeta =
      const VerificationMeta('totalOvers');
  @override
  late final GeneratedColumn<int> totalOvers = GeneratedColumn<int>(
      'total_overs', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(20));
  static const VerificationMeta _tossWinnerIdMeta =
      const VerificationMeta('tossWinnerId');
  @override
  late final GeneratedColumn<String> tossWinnerId = GeneratedColumn<String>(
      'toss_winner_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tossWinnerBattedFirstMeta =
      const VerificationMeta('tossWinnerBattedFirst');
  @override
  late final GeneratedColumn<bool> tossWinnerBattedFirst =
      GeneratedColumn<bool>('toss_winner_batted_first', aliasedName, true,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("toss_winner_batted_first" IN (0, 1))'));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
      'format', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('t20'));
  static const VerificationMeta _syncedToServerMeta =
      const VerificationMeta('syncedToServer');
  @override
  late final GeneratedColumn<bool> syncedToServer = GeneratedColumn<bool>(
      'synced_to_server', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("synced_to_server" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        type,
        teamAId,
        teamBId,
        teamAName,
        teamBName,
        venueNote,
        playedAt,
        totalOvers,
        tossWinnerId,
        tossWinnerBattedFirst,
        status,
        format,
        syncedToServer
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'matches';
  @override
  VerificationContext validateIntegrity(Insertable<Matche> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('team_a_id')) {
      context.handle(_teamAIdMeta,
          teamAId.isAcceptableOrUnknown(data['team_a_id']!, _teamAIdMeta));
    } else if (isInserting) {
      context.missing(_teamAIdMeta);
    }
    if (data.containsKey('team_b_id')) {
      context.handle(_teamBIdMeta,
          teamBId.isAcceptableOrUnknown(data['team_b_id']!, _teamBIdMeta));
    } else if (isInserting) {
      context.missing(_teamBIdMeta);
    }
    if (data.containsKey('team_a_name')) {
      context.handle(
          _teamANameMeta,
          teamAName.isAcceptableOrUnknown(
              data['team_a_name']!, _teamANameMeta));
    } else if (isInserting) {
      context.missing(_teamANameMeta);
    }
    if (data.containsKey('team_b_name')) {
      context.handle(
          _teamBNameMeta,
          teamBName.isAcceptableOrUnknown(
              data['team_b_name']!, _teamBNameMeta));
    } else if (isInserting) {
      context.missing(_teamBNameMeta);
    }
    if (data.containsKey('venue_note')) {
      context.handle(_venueNoteMeta,
          venueNote.isAcceptableOrUnknown(data['venue_note']!, _venueNoteMeta));
    }
    if (data.containsKey('played_at')) {
      context.handle(_playedAtMeta,
          playedAt.isAcceptableOrUnknown(data['played_at']!, _playedAtMeta));
    } else if (isInserting) {
      context.missing(_playedAtMeta);
    }
    if (data.containsKey('total_overs')) {
      context.handle(
          _totalOversMeta,
          totalOvers.isAcceptableOrUnknown(
              data['total_overs']!, _totalOversMeta));
    }
    if (data.containsKey('toss_winner_id')) {
      context.handle(
          _tossWinnerIdMeta,
          tossWinnerId.isAcceptableOrUnknown(
              data['toss_winner_id']!, _tossWinnerIdMeta));
    }
    if (data.containsKey('toss_winner_batted_first')) {
      context.handle(
          _tossWinnerBattedFirstMeta,
          tossWinnerBattedFirst.isAcceptableOrUnknown(
              data['toss_winner_batted_first']!, _tossWinnerBattedFirstMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('format')) {
      context.handle(_formatMeta,
          format.isAcceptableOrUnknown(data['format']!, _formatMeta));
    }
    if (data.containsKey('synced_to_server')) {
      context.handle(
          _syncedToServerMeta,
          syncedToServer.isAcceptableOrUnknown(
              data['synced_to_server']!, _syncedToServerMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Matche map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Matche(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      teamAId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}team_a_id'])!,
      teamBId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}team_b_id'])!,
      teamAName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}team_a_name'])!,
      teamBName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}team_b_name'])!,
      venueNote: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}venue_note']),
      playedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}played_at'])!,
      totalOvers: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_overs'])!,
      tossWinnerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}toss_winner_id']),
      tossWinnerBattedFirst: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}toss_winner_batted_first']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      format: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}format'])!,
      syncedToServer: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced_to_server'])!,
    );
  }

  @override
  $MatchesTable createAlias(String alias) {
    return $MatchesTable(attachedDatabase, alias);
  }
}

class Matche extends DataClass implements Insertable<Matche> {
  final String id;
  final String type;
  final String teamAId;
  final String teamBId;
  final String teamAName;
  final String teamBName;
  final String? venueNote;
  final DateTime playedAt;
  final int totalOvers;
  final String? tossWinnerId;
  final bool? tossWinnerBattedFirst;
  final String status;
  final String format;
  final bool syncedToServer;
  const Matche(
      {required this.id,
      required this.type,
      required this.teamAId,
      required this.teamBId,
      required this.teamAName,
      required this.teamBName,
      this.venueNote,
      required this.playedAt,
      required this.totalOvers,
      this.tossWinnerId,
      this.tossWinnerBattedFirst,
      required this.status,
      required this.format,
      required this.syncedToServer});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['team_a_id'] = Variable<String>(teamAId);
    map['team_b_id'] = Variable<String>(teamBId);
    map['team_a_name'] = Variable<String>(teamAName);
    map['team_b_name'] = Variable<String>(teamBName);
    if (!nullToAbsent || venueNote != null) {
      map['venue_note'] = Variable<String>(venueNote);
    }
    map['played_at'] = Variable<DateTime>(playedAt);
    map['total_overs'] = Variable<int>(totalOvers);
    if (!nullToAbsent || tossWinnerId != null) {
      map['toss_winner_id'] = Variable<String>(tossWinnerId);
    }
    if (!nullToAbsent || tossWinnerBattedFirst != null) {
      map['toss_winner_batted_first'] = Variable<bool>(tossWinnerBattedFirst);
    }
    map['status'] = Variable<String>(status);
    map['format'] = Variable<String>(format);
    map['synced_to_server'] = Variable<bool>(syncedToServer);
    return map;
  }

  MatchesCompanion toCompanion(bool nullToAbsent) {
    return MatchesCompanion(
      id: Value(id),
      type: Value(type),
      teamAId: Value(teamAId),
      teamBId: Value(teamBId),
      teamAName: Value(teamAName),
      teamBName: Value(teamBName),
      venueNote: venueNote == null && nullToAbsent
          ? const Value.absent()
          : Value(venueNote),
      playedAt: Value(playedAt),
      totalOvers: Value(totalOvers),
      tossWinnerId: tossWinnerId == null && nullToAbsent
          ? const Value.absent()
          : Value(tossWinnerId),
      tossWinnerBattedFirst: tossWinnerBattedFirst == null && nullToAbsent
          ? const Value.absent()
          : Value(tossWinnerBattedFirst),
      status: Value(status),
      format: Value(format),
      syncedToServer: Value(syncedToServer),
    );
  }

  factory Matche.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Matche(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      teamAId: serializer.fromJson<String>(json['teamAId']),
      teamBId: serializer.fromJson<String>(json['teamBId']),
      teamAName: serializer.fromJson<String>(json['teamAName']),
      teamBName: serializer.fromJson<String>(json['teamBName']),
      venueNote: serializer.fromJson<String?>(json['venueNote']),
      playedAt: serializer.fromJson<DateTime>(json['playedAt']),
      totalOvers: serializer.fromJson<int>(json['totalOvers']),
      tossWinnerId: serializer.fromJson<String?>(json['tossWinnerId']),
      tossWinnerBattedFirst:
          serializer.fromJson<bool?>(json['tossWinnerBattedFirst']),
      status: serializer.fromJson<String>(json['status']),
      format: serializer.fromJson<String>(json['format']),
      syncedToServer: serializer.fromJson<bool>(json['syncedToServer']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'teamAId': serializer.toJson<String>(teamAId),
      'teamBId': serializer.toJson<String>(teamBId),
      'teamAName': serializer.toJson<String>(teamAName),
      'teamBName': serializer.toJson<String>(teamBName),
      'venueNote': serializer.toJson<String?>(venueNote),
      'playedAt': serializer.toJson<DateTime>(playedAt),
      'totalOvers': serializer.toJson<int>(totalOvers),
      'tossWinnerId': serializer.toJson<String?>(tossWinnerId),
      'tossWinnerBattedFirst': serializer.toJson<bool?>(tossWinnerBattedFirst),
      'status': serializer.toJson<String>(status),
      'format': serializer.toJson<String>(format),
      'syncedToServer': serializer.toJson<bool>(syncedToServer),
    };
  }

  Matche copyWith(
          {String? id,
          String? type,
          String? teamAId,
          String? teamBId,
          String? teamAName,
          String? teamBName,
          Value<String?> venueNote = const Value.absent(),
          DateTime? playedAt,
          int? totalOvers,
          Value<String?> tossWinnerId = const Value.absent(),
          Value<bool?> tossWinnerBattedFirst = const Value.absent(),
          String? status,
          String? format,
          bool? syncedToServer}) =>
      Matche(
        id: id ?? this.id,
        type: type ?? this.type,
        teamAId: teamAId ?? this.teamAId,
        teamBId: teamBId ?? this.teamBId,
        teamAName: teamAName ?? this.teamAName,
        teamBName: teamBName ?? this.teamBName,
        venueNote: venueNote.present ? venueNote.value : this.venueNote,
        playedAt: playedAt ?? this.playedAt,
        totalOvers: totalOvers ?? this.totalOvers,
        tossWinnerId:
            tossWinnerId.present ? tossWinnerId.value : this.tossWinnerId,
        tossWinnerBattedFirst: tossWinnerBattedFirst.present
            ? tossWinnerBattedFirst.value
            : this.tossWinnerBattedFirst,
        status: status ?? this.status,
        format: format ?? this.format,
        syncedToServer: syncedToServer ?? this.syncedToServer,
      );
  Matche copyWithCompanion(MatchesCompanion data) {
    return Matche(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      teamAId: data.teamAId.present ? data.teamAId.value : this.teamAId,
      teamBId: data.teamBId.present ? data.teamBId.value : this.teamBId,
      teamAName: data.teamAName.present ? data.teamAName.value : this.teamAName,
      teamBName: data.teamBName.present ? data.teamBName.value : this.teamBName,
      venueNote: data.venueNote.present ? data.venueNote.value : this.venueNote,
      playedAt: data.playedAt.present ? data.playedAt.value : this.playedAt,
      totalOvers:
          data.totalOvers.present ? data.totalOvers.value : this.totalOvers,
      tossWinnerId: data.tossWinnerId.present
          ? data.tossWinnerId.value
          : this.tossWinnerId,
      tossWinnerBattedFirst: data.tossWinnerBattedFirst.present
          ? data.tossWinnerBattedFirst.value
          : this.tossWinnerBattedFirst,
      status: data.status.present ? data.status.value : this.status,
      format: data.format.present ? data.format.value : this.format,
      syncedToServer: data.syncedToServer.present
          ? data.syncedToServer.value
          : this.syncedToServer,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Matche(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('teamAId: $teamAId, ')
          ..write('teamBId: $teamBId, ')
          ..write('teamAName: $teamAName, ')
          ..write('teamBName: $teamBName, ')
          ..write('venueNote: $venueNote, ')
          ..write('playedAt: $playedAt, ')
          ..write('totalOvers: $totalOvers, ')
          ..write('tossWinnerId: $tossWinnerId, ')
          ..write('tossWinnerBattedFirst: $tossWinnerBattedFirst, ')
          ..write('status: $status, ')
          ..write('format: $format, ')
          ..write('syncedToServer: $syncedToServer')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      type,
      teamAId,
      teamBId,
      teamAName,
      teamBName,
      venueNote,
      playedAt,
      totalOvers,
      tossWinnerId,
      tossWinnerBattedFirst,
      status,
      format,
      syncedToServer);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Matche &&
          other.id == this.id &&
          other.type == this.type &&
          other.teamAId == this.teamAId &&
          other.teamBId == this.teamBId &&
          other.teamAName == this.teamAName &&
          other.teamBName == this.teamBName &&
          other.venueNote == this.venueNote &&
          other.playedAt == this.playedAt &&
          other.totalOvers == this.totalOvers &&
          other.tossWinnerId == this.tossWinnerId &&
          other.tossWinnerBattedFirst == this.tossWinnerBattedFirst &&
          other.status == this.status &&
          other.format == this.format &&
          other.syncedToServer == this.syncedToServer);
}

class MatchesCompanion extends UpdateCompanion<Matche> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> teamAId;
  final Value<String> teamBId;
  final Value<String> teamAName;
  final Value<String> teamBName;
  final Value<String?> venueNote;
  final Value<DateTime> playedAt;
  final Value<int> totalOvers;
  final Value<String?> tossWinnerId;
  final Value<bool?> tossWinnerBattedFirst;
  final Value<String> status;
  final Value<String> format;
  final Value<bool> syncedToServer;
  final Value<int> rowid;
  const MatchesCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.teamAId = const Value.absent(),
    this.teamBId = const Value.absent(),
    this.teamAName = const Value.absent(),
    this.teamBName = const Value.absent(),
    this.venueNote = const Value.absent(),
    this.playedAt = const Value.absent(),
    this.totalOvers = const Value.absent(),
    this.tossWinnerId = const Value.absent(),
    this.tossWinnerBattedFirst = const Value.absent(),
    this.status = const Value.absent(),
    this.format = const Value.absent(),
    this.syncedToServer = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MatchesCompanion.insert({
    required String id,
    required String type,
    required String teamAId,
    required String teamBId,
    required String teamAName,
    required String teamBName,
    this.venueNote = const Value.absent(),
    required DateTime playedAt,
    this.totalOvers = const Value.absent(),
    this.tossWinnerId = const Value.absent(),
    this.tossWinnerBattedFirst = const Value.absent(),
    required String status,
    this.format = const Value.absent(),
    this.syncedToServer = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        type = Value(type),
        teamAId = Value(teamAId),
        teamBId = Value(teamBId),
        teamAName = Value(teamAName),
        teamBName = Value(teamBName),
        playedAt = Value(playedAt),
        status = Value(status);
  static Insertable<Matche> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? teamAId,
    Expression<String>? teamBId,
    Expression<String>? teamAName,
    Expression<String>? teamBName,
    Expression<String>? venueNote,
    Expression<DateTime>? playedAt,
    Expression<int>? totalOvers,
    Expression<String>? tossWinnerId,
    Expression<bool>? tossWinnerBattedFirst,
    Expression<String>? status,
    Expression<String>? format,
    Expression<bool>? syncedToServer,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (teamAId != null) 'team_a_id': teamAId,
      if (teamBId != null) 'team_b_id': teamBId,
      if (teamAName != null) 'team_a_name': teamAName,
      if (teamBName != null) 'team_b_name': teamBName,
      if (venueNote != null) 'venue_note': venueNote,
      if (playedAt != null) 'played_at': playedAt,
      if (totalOvers != null) 'total_overs': totalOvers,
      if (tossWinnerId != null) 'toss_winner_id': tossWinnerId,
      if (tossWinnerBattedFirst != null)
        'toss_winner_batted_first': tossWinnerBattedFirst,
      if (status != null) 'status': status,
      if (format != null) 'format': format,
      if (syncedToServer != null) 'synced_to_server': syncedToServer,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MatchesCompanion copyWith(
      {Value<String>? id,
      Value<String>? type,
      Value<String>? teamAId,
      Value<String>? teamBId,
      Value<String>? teamAName,
      Value<String>? teamBName,
      Value<String?>? venueNote,
      Value<DateTime>? playedAt,
      Value<int>? totalOvers,
      Value<String?>? tossWinnerId,
      Value<bool?>? tossWinnerBattedFirst,
      Value<String>? status,
      Value<String>? format,
      Value<bool>? syncedToServer,
      Value<int>? rowid}) {
    return MatchesCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      teamAId: teamAId ?? this.teamAId,
      teamBId: teamBId ?? this.teamBId,
      teamAName: teamAName ?? this.teamAName,
      teamBName: teamBName ?? this.teamBName,
      venueNote: venueNote ?? this.venueNote,
      playedAt: playedAt ?? this.playedAt,
      totalOvers: totalOvers ?? this.totalOvers,
      tossWinnerId: tossWinnerId ?? this.tossWinnerId,
      tossWinnerBattedFirst:
          tossWinnerBattedFirst ?? this.tossWinnerBattedFirst,
      status: status ?? this.status,
      format: format ?? this.format,
      syncedToServer: syncedToServer ?? this.syncedToServer,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (teamAId.present) {
      map['team_a_id'] = Variable<String>(teamAId.value);
    }
    if (teamBId.present) {
      map['team_b_id'] = Variable<String>(teamBId.value);
    }
    if (teamAName.present) {
      map['team_a_name'] = Variable<String>(teamAName.value);
    }
    if (teamBName.present) {
      map['team_b_name'] = Variable<String>(teamBName.value);
    }
    if (venueNote.present) {
      map['venue_note'] = Variable<String>(venueNote.value);
    }
    if (playedAt.present) {
      map['played_at'] = Variable<DateTime>(playedAt.value);
    }
    if (totalOvers.present) {
      map['total_overs'] = Variable<int>(totalOvers.value);
    }
    if (tossWinnerId.present) {
      map['toss_winner_id'] = Variable<String>(tossWinnerId.value);
    }
    if (tossWinnerBattedFirst.present) {
      map['toss_winner_batted_first'] =
          Variable<bool>(tossWinnerBattedFirst.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (syncedToServer.present) {
      map['synced_to_server'] = Variable<bool>(syncedToServer.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MatchesCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('teamAId: $teamAId, ')
          ..write('teamBId: $teamBId, ')
          ..write('teamAName: $teamAName, ')
          ..write('teamBName: $teamBName, ')
          ..write('venueNote: $venueNote, ')
          ..write('playedAt: $playedAt, ')
          ..write('totalOvers: $totalOvers, ')
          ..write('tossWinnerId: $tossWinnerId, ')
          ..write('tossWinnerBattedFirst: $tossWinnerBattedFirst, ')
          ..write('status: $status, ')
          ..write('format: $format, ')
          ..write('syncedToServer: $syncedToServer, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeliveriesTable extends Deliveries
    with TableInfo<$DeliveriesTable, Delivery> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeliveriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _matchIdMeta =
      const VerificationMeta('matchId');
  @override
  late final GeneratedColumn<String> matchId = GeneratedColumn<String>(
      'match_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _inningsNumberMeta =
      const VerificationMeta('inningsNumber');
  @override
  late final GeneratedColumn<int> inningsNumber = GeneratedColumn<int>(
      'innings_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _overNumberMeta =
      const VerificationMeta('overNumber');
  @override
  late final GeneratedColumn<int> overNumber = GeneratedColumn<int>(
      'over_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _ballNumberMeta =
      const VerificationMeta('ballNumber');
  @override
  late final GeneratedColumn<int> ballNumber = GeneratedColumn<int>(
      'ball_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _batsmanIdMeta =
      const VerificationMeta('batsmanId');
  @override
  late final GeneratedColumn<String> batsmanId = GeneratedColumn<String>(
      'batsman_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nonStrikerIdMeta =
      const VerificationMeta('nonStrikerId');
  @override
  late final GeneratedColumn<String> nonStrikerId = GeneratedColumn<String>(
      'non_striker_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bowlerIdMeta =
      const VerificationMeta('bowlerId');
  @override
  late final GeneratedColumn<String> bowlerId = GeneratedColumn<String>(
      'bowler_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _runsOffBatMeta =
      const VerificationMeta('runsOffBat');
  @override
  late final GeneratedColumn<int> runsOffBat = GeneratedColumn<int>(
      'runs_off_bat', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _extraTypeMeta =
      const VerificationMeta('extraType');
  @override
  late final GeneratedColumn<String> extraType = GeneratedColumn<String>(
      'extra_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _extraRunsMeta =
      const VerificationMeta('extraRuns');
  @override
  late final GeneratedColumn<int> extraRuns = GeneratedColumn<int>(
      'extra_runs', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _wicketTypeMeta =
      const VerificationMeta('wicketType');
  @override
  late final GeneratedColumn<String> wicketType = GeneratedColumn<String>(
      'wicket_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dismissedPlayerIdMeta =
      const VerificationMeta('dismissedPlayerId');
  @override
  late final GeneratedColumn<String> dismissedPlayerId =
      GeneratedColumn<String>('dismissed_player_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fielderPlayerIdMeta =
      const VerificationMeta('fielderPlayerId');
  @override
  late final GeneratedColumn<String> fielderPlayerId = GeneratedColumn<String>(
      'fielder_player_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isAdminCorrectionMeta =
      const VerificationMeta('isAdminCorrection');
  @override
  late final GeneratedColumn<bool> isAdminCorrection = GeneratedColumn<bool>(
      'is_admin_correction', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_admin_correction" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _syncedToServerMeta =
      const VerificationMeta('syncedToServer');
  @override
  late final GeneratedColumn<bool> syncedToServer = GeneratedColumn<bool>(
      'synced_to_server', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("synced_to_server" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        matchId,
        inningsNumber,
        overNumber,
        ballNumber,
        batsmanId,
        nonStrikerId,
        bowlerId,
        runsOffBat,
        extraType,
        extraRuns,
        wicketType,
        dismissedPlayerId,
        fielderPlayerId,
        isAdminCorrection,
        syncedToServer,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deliveries';
  @override
  VerificationContext validateIntegrity(Insertable<Delivery> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('match_id')) {
      context.handle(_matchIdMeta,
          matchId.isAcceptableOrUnknown(data['match_id']!, _matchIdMeta));
    } else if (isInserting) {
      context.missing(_matchIdMeta);
    }
    if (data.containsKey('innings_number')) {
      context.handle(
          _inningsNumberMeta,
          inningsNumber.isAcceptableOrUnknown(
              data['innings_number']!, _inningsNumberMeta));
    } else if (isInserting) {
      context.missing(_inningsNumberMeta);
    }
    if (data.containsKey('over_number')) {
      context.handle(
          _overNumberMeta,
          overNumber.isAcceptableOrUnknown(
              data['over_number']!, _overNumberMeta));
    } else if (isInserting) {
      context.missing(_overNumberMeta);
    }
    if (data.containsKey('ball_number')) {
      context.handle(
          _ballNumberMeta,
          ballNumber.isAcceptableOrUnknown(
              data['ball_number']!, _ballNumberMeta));
    } else if (isInserting) {
      context.missing(_ballNumberMeta);
    }
    if (data.containsKey('batsman_id')) {
      context.handle(_batsmanIdMeta,
          batsmanId.isAcceptableOrUnknown(data['batsman_id']!, _batsmanIdMeta));
    } else if (isInserting) {
      context.missing(_batsmanIdMeta);
    }
    if (data.containsKey('non_striker_id')) {
      context.handle(
          _nonStrikerIdMeta,
          nonStrikerId.isAcceptableOrUnknown(
              data['non_striker_id']!, _nonStrikerIdMeta));
    } else if (isInserting) {
      context.missing(_nonStrikerIdMeta);
    }
    if (data.containsKey('bowler_id')) {
      context.handle(_bowlerIdMeta,
          bowlerId.isAcceptableOrUnknown(data['bowler_id']!, _bowlerIdMeta));
    } else if (isInserting) {
      context.missing(_bowlerIdMeta);
    }
    if (data.containsKey('runs_off_bat')) {
      context.handle(
          _runsOffBatMeta,
          runsOffBat.isAcceptableOrUnknown(
              data['runs_off_bat']!, _runsOffBatMeta));
    }
    if (data.containsKey('extra_type')) {
      context.handle(_extraTypeMeta,
          extraType.isAcceptableOrUnknown(data['extra_type']!, _extraTypeMeta));
    }
    if (data.containsKey('extra_runs')) {
      context.handle(_extraRunsMeta,
          extraRuns.isAcceptableOrUnknown(data['extra_runs']!, _extraRunsMeta));
    }
    if (data.containsKey('wicket_type')) {
      context.handle(
          _wicketTypeMeta,
          wicketType.isAcceptableOrUnknown(
              data['wicket_type']!, _wicketTypeMeta));
    }
    if (data.containsKey('dismissed_player_id')) {
      context.handle(
          _dismissedPlayerIdMeta,
          dismissedPlayerId.isAcceptableOrUnknown(
              data['dismissed_player_id']!, _dismissedPlayerIdMeta));
    }
    if (data.containsKey('fielder_player_id')) {
      context.handle(
          _fielderPlayerIdMeta,
          fielderPlayerId.isAcceptableOrUnknown(
              data['fielder_player_id']!, _fielderPlayerIdMeta));
    }
    if (data.containsKey('is_admin_correction')) {
      context.handle(
          _isAdminCorrectionMeta,
          isAdminCorrection.isAcceptableOrUnknown(
              data['is_admin_correction']!, _isAdminCorrectionMeta));
    }
    if (data.containsKey('synced_to_server')) {
      context.handle(
          _syncedToServerMeta,
          syncedToServer.isAcceptableOrUnknown(
              data['synced_to_server']!, _syncedToServerMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Delivery map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Delivery(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      matchId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}match_id'])!,
      inningsNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}innings_number'])!,
      overNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}over_number'])!,
      ballNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ball_number'])!,
      batsmanId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}batsman_id'])!,
      nonStrikerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}non_striker_id'])!,
      bowlerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bowler_id'])!,
      runsOffBat: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}runs_off_bat'])!,
      extraType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}extra_type']),
      extraRuns: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}extra_runs'])!,
      wicketType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}wicket_type']),
      dismissedPlayerId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}dismissed_player_id']),
      fielderPlayerId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}fielder_player_id']),
      isAdminCorrection: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}is_admin_correction'])!,
      syncedToServer: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced_to_server'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $DeliveriesTable createAlias(String alias) {
    return $DeliveriesTable(attachedDatabase, alias);
  }
}

class Delivery extends DataClass implements Insertable<Delivery> {
  final String id;
  final String matchId;
  final int inningsNumber;
  final int overNumber;
  final int ballNumber;
  final String batsmanId;
  final String nonStrikerId;
  final String bowlerId;
  final int runsOffBat;
  final String? extraType;
  final int extraRuns;
  final String? wicketType;
  final String? dismissedPlayerId;
  final String? fielderPlayerId;
  final bool isAdminCorrection;
  final bool syncedToServer;
  final DateTime createdAt;
  const Delivery(
      {required this.id,
      required this.matchId,
      required this.inningsNumber,
      required this.overNumber,
      required this.ballNumber,
      required this.batsmanId,
      required this.nonStrikerId,
      required this.bowlerId,
      required this.runsOffBat,
      this.extraType,
      required this.extraRuns,
      this.wicketType,
      this.dismissedPlayerId,
      this.fielderPlayerId,
      required this.isAdminCorrection,
      required this.syncedToServer,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['match_id'] = Variable<String>(matchId);
    map['innings_number'] = Variable<int>(inningsNumber);
    map['over_number'] = Variable<int>(overNumber);
    map['ball_number'] = Variable<int>(ballNumber);
    map['batsman_id'] = Variable<String>(batsmanId);
    map['non_striker_id'] = Variable<String>(nonStrikerId);
    map['bowler_id'] = Variable<String>(bowlerId);
    map['runs_off_bat'] = Variable<int>(runsOffBat);
    if (!nullToAbsent || extraType != null) {
      map['extra_type'] = Variable<String>(extraType);
    }
    map['extra_runs'] = Variable<int>(extraRuns);
    if (!nullToAbsent || wicketType != null) {
      map['wicket_type'] = Variable<String>(wicketType);
    }
    if (!nullToAbsent || dismissedPlayerId != null) {
      map['dismissed_player_id'] = Variable<String>(dismissedPlayerId);
    }
    if (!nullToAbsent || fielderPlayerId != null) {
      map['fielder_player_id'] = Variable<String>(fielderPlayerId);
    }
    map['is_admin_correction'] = Variable<bool>(isAdminCorrection);
    map['synced_to_server'] = Variable<bool>(syncedToServer);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DeliveriesCompanion toCompanion(bool nullToAbsent) {
    return DeliveriesCompanion(
      id: Value(id),
      matchId: Value(matchId),
      inningsNumber: Value(inningsNumber),
      overNumber: Value(overNumber),
      ballNumber: Value(ballNumber),
      batsmanId: Value(batsmanId),
      nonStrikerId: Value(nonStrikerId),
      bowlerId: Value(bowlerId),
      runsOffBat: Value(runsOffBat),
      extraType: extraType == null && nullToAbsent
          ? const Value.absent()
          : Value(extraType),
      extraRuns: Value(extraRuns),
      wicketType: wicketType == null && nullToAbsent
          ? const Value.absent()
          : Value(wicketType),
      dismissedPlayerId: dismissedPlayerId == null && nullToAbsent
          ? const Value.absent()
          : Value(dismissedPlayerId),
      fielderPlayerId: fielderPlayerId == null && nullToAbsent
          ? const Value.absent()
          : Value(fielderPlayerId),
      isAdminCorrection: Value(isAdminCorrection),
      syncedToServer: Value(syncedToServer),
      createdAt: Value(createdAt),
    );
  }

  factory Delivery.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Delivery(
      id: serializer.fromJson<String>(json['id']),
      matchId: serializer.fromJson<String>(json['matchId']),
      inningsNumber: serializer.fromJson<int>(json['inningsNumber']),
      overNumber: serializer.fromJson<int>(json['overNumber']),
      ballNumber: serializer.fromJson<int>(json['ballNumber']),
      batsmanId: serializer.fromJson<String>(json['batsmanId']),
      nonStrikerId: serializer.fromJson<String>(json['nonStrikerId']),
      bowlerId: serializer.fromJson<String>(json['bowlerId']),
      runsOffBat: serializer.fromJson<int>(json['runsOffBat']),
      extraType: serializer.fromJson<String?>(json['extraType']),
      extraRuns: serializer.fromJson<int>(json['extraRuns']),
      wicketType: serializer.fromJson<String?>(json['wicketType']),
      dismissedPlayerId:
          serializer.fromJson<String?>(json['dismissedPlayerId']),
      fielderPlayerId: serializer.fromJson<String?>(json['fielderPlayerId']),
      isAdminCorrection: serializer.fromJson<bool>(json['isAdminCorrection']),
      syncedToServer: serializer.fromJson<bool>(json['syncedToServer']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'matchId': serializer.toJson<String>(matchId),
      'inningsNumber': serializer.toJson<int>(inningsNumber),
      'overNumber': serializer.toJson<int>(overNumber),
      'ballNumber': serializer.toJson<int>(ballNumber),
      'batsmanId': serializer.toJson<String>(batsmanId),
      'nonStrikerId': serializer.toJson<String>(nonStrikerId),
      'bowlerId': serializer.toJson<String>(bowlerId),
      'runsOffBat': serializer.toJson<int>(runsOffBat),
      'extraType': serializer.toJson<String?>(extraType),
      'extraRuns': serializer.toJson<int>(extraRuns),
      'wicketType': serializer.toJson<String?>(wicketType),
      'dismissedPlayerId': serializer.toJson<String?>(dismissedPlayerId),
      'fielderPlayerId': serializer.toJson<String?>(fielderPlayerId),
      'isAdminCorrection': serializer.toJson<bool>(isAdminCorrection),
      'syncedToServer': serializer.toJson<bool>(syncedToServer),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Delivery copyWith(
          {String? id,
          String? matchId,
          int? inningsNumber,
          int? overNumber,
          int? ballNumber,
          String? batsmanId,
          String? nonStrikerId,
          String? bowlerId,
          int? runsOffBat,
          Value<String?> extraType = const Value.absent(),
          int? extraRuns,
          Value<String?> wicketType = const Value.absent(),
          Value<String?> dismissedPlayerId = const Value.absent(),
          Value<String?> fielderPlayerId = const Value.absent(),
          bool? isAdminCorrection,
          bool? syncedToServer,
          DateTime? createdAt}) =>
      Delivery(
        id: id ?? this.id,
        matchId: matchId ?? this.matchId,
        inningsNumber: inningsNumber ?? this.inningsNumber,
        overNumber: overNumber ?? this.overNumber,
        ballNumber: ballNumber ?? this.ballNumber,
        batsmanId: batsmanId ?? this.batsmanId,
        nonStrikerId: nonStrikerId ?? this.nonStrikerId,
        bowlerId: bowlerId ?? this.bowlerId,
        runsOffBat: runsOffBat ?? this.runsOffBat,
        extraType: extraType.present ? extraType.value : this.extraType,
        extraRuns: extraRuns ?? this.extraRuns,
        wicketType: wicketType.present ? wicketType.value : this.wicketType,
        dismissedPlayerId: dismissedPlayerId.present
            ? dismissedPlayerId.value
            : this.dismissedPlayerId,
        fielderPlayerId: fielderPlayerId.present
            ? fielderPlayerId.value
            : this.fielderPlayerId,
        isAdminCorrection: isAdminCorrection ?? this.isAdminCorrection,
        syncedToServer: syncedToServer ?? this.syncedToServer,
        createdAt: createdAt ?? this.createdAt,
      );
  Delivery copyWithCompanion(DeliveriesCompanion data) {
    return Delivery(
      id: data.id.present ? data.id.value : this.id,
      matchId: data.matchId.present ? data.matchId.value : this.matchId,
      inningsNumber: data.inningsNumber.present
          ? data.inningsNumber.value
          : this.inningsNumber,
      overNumber:
          data.overNumber.present ? data.overNumber.value : this.overNumber,
      ballNumber:
          data.ballNumber.present ? data.ballNumber.value : this.ballNumber,
      batsmanId: data.batsmanId.present ? data.batsmanId.value : this.batsmanId,
      nonStrikerId: data.nonStrikerId.present
          ? data.nonStrikerId.value
          : this.nonStrikerId,
      bowlerId: data.bowlerId.present ? data.bowlerId.value : this.bowlerId,
      runsOffBat:
          data.runsOffBat.present ? data.runsOffBat.value : this.runsOffBat,
      extraType: data.extraType.present ? data.extraType.value : this.extraType,
      extraRuns: data.extraRuns.present ? data.extraRuns.value : this.extraRuns,
      wicketType:
          data.wicketType.present ? data.wicketType.value : this.wicketType,
      dismissedPlayerId: data.dismissedPlayerId.present
          ? data.dismissedPlayerId.value
          : this.dismissedPlayerId,
      fielderPlayerId: data.fielderPlayerId.present
          ? data.fielderPlayerId.value
          : this.fielderPlayerId,
      isAdminCorrection: data.isAdminCorrection.present
          ? data.isAdminCorrection.value
          : this.isAdminCorrection,
      syncedToServer: data.syncedToServer.present
          ? data.syncedToServer.value
          : this.syncedToServer,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Delivery(')
          ..write('id: $id, ')
          ..write('matchId: $matchId, ')
          ..write('inningsNumber: $inningsNumber, ')
          ..write('overNumber: $overNumber, ')
          ..write('ballNumber: $ballNumber, ')
          ..write('batsmanId: $batsmanId, ')
          ..write('nonStrikerId: $nonStrikerId, ')
          ..write('bowlerId: $bowlerId, ')
          ..write('runsOffBat: $runsOffBat, ')
          ..write('extraType: $extraType, ')
          ..write('extraRuns: $extraRuns, ')
          ..write('wicketType: $wicketType, ')
          ..write('dismissedPlayerId: $dismissedPlayerId, ')
          ..write('fielderPlayerId: $fielderPlayerId, ')
          ..write('isAdminCorrection: $isAdminCorrection, ')
          ..write('syncedToServer: $syncedToServer, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      matchId,
      inningsNumber,
      overNumber,
      ballNumber,
      batsmanId,
      nonStrikerId,
      bowlerId,
      runsOffBat,
      extraType,
      extraRuns,
      wicketType,
      dismissedPlayerId,
      fielderPlayerId,
      isAdminCorrection,
      syncedToServer,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Delivery &&
          other.id == this.id &&
          other.matchId == this.matchId &&
          other.inningsNumber == this.inningsNumber &&
          other.overNumber == this.overNumber &&
          other.ballNumber == this.ballNumber &&
          other.batsmanId == this.batsmanId &&
          other.nonStrikerId == this.nonStrikerId &&
          other.bowlerId == this.bowlerId &&
          other.runsOffBat == this.runsOffBat &&
          other.extraType == this.extraType &&
          other.extraRuns == this.extraRuns &&
          other.wicketType == this.wicketType &&
          other.dismissedPlayerId == this.dismissedPlayerId &&
          other.fielderPlayerId == this.fielderPlayerId &&
          other.isAdminCorrection == this.isAdminCorrection &&
          other.syncedToServer == this.syncedToServer &&
          other.createdAt == this.createdAt);
}

class DeliveriesCompanion extends UpdateCompanion<Delivery> {
  final Value<String> id;
  final Value<String> matchId;
  final Value<int> inningsNumber;
  final Value<int> overNumber;
  final Value<int> ballNumber;
  final Value<String> batsmanId;
  final Value<String> nonStrikerId;
  final Value<String> bowlerId;
  final Value<int> runsOffBat;
  final Value<String?> extraType;
  final Value<int> extraRuns;
  final Value<String?> wicketType;
  final Value<String?> dismissedPlayerId;
  final Value<String?> fielderPlayerId;
  final Value<bool> isAdminCorrection;
  final Value<bool> syncedToServer;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DeliveriesCompanion({
    this.id = const Value.absent(),
    this.matchId = const Value.absent(),
    this.inningsNumber = const Value.absent(),
    this.overNumber = const Value.absent(),
    this.ballNumber = const Value.absent(),
    this.batsmanId = const Value.absent(),
    this.nonStrikerId = const Value.absent(),
    this.bowlerId = const Value.absent(),
    this.runsOffBat = const Value.absent(),
    this.extraType = const Value.absent(),
    this.extraRuns = const Value.absent(),
    this.wicketType = const Value.absent(),
    this.dismissedPlayerId = const Value.absent(),
    this.fielderPlayerId = const Value.absent(),
    this.isAdminCorrection = const Value.absent(),
    this.syncedToServer = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeliveriesCompanion.insert({
    required String id,
    required String matchId,
    required int inningsNumber,
    required int overNumber,
    required int ballNumber,
    required String batsmanId,
    required String nonStrikerId,
    required String bowlerId,
    this.runsOffBat = const Value.absent(),
    this.extraType = const Value.absent(),
    this.extraRuns = const Value.absent(),
    this.wicketType = const Value.absent(),
    this.dismissedPlayerId = const Value.absent(),
    this.fielderPlayerId = const Value.absent(),
    this.isAdminCorrection = const Value.absent(),
    this.syncedToServer = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        matchId = Value(matchId),
        inningsNumber = Value(inningsNumber),
        overNumber = Value(overNumber),
        ballNumber = Value(ballNumber),
        batsmanId = Value(batsmanId),
        nonStrikerId = Value(nonStrikerId),
        bowlerId = Value(bowlerId),
        createdAt = Value(createdAt);
  static Insertable<Delivery> custom({
    Expression<String>? id,
    Expression<String>? matchId,
    Expression<int>? inningsNumber,
    Expression<int>? overNumber,
    Expression<int>? ballNumber,
    Expression<String>? batsmanId,
    Expression<String>? nonStrikerId,
    Expression<String>? bowlerId,
    Expression<int>? runsOffBat,
    Expression<String>? extraType,
    Expression<int>? extraRuns,
    Expression<String>? wicketType,
    Expression<String>? dismissedPlayerId,
    Expression<String>? fielderPlayerId,
    Expression<bool>? isAdminCorrection,
    Expression<bool>? syncedToServer,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (matchId != null) 'match_id': matchId,
      if (inningsNumber != null) 'innings_number': inningsNumber,
      if (overNumber != null) 'over_number': overNumber,
      if (ballNumber != null) 'ball_number': ballNumber,
      if (batsmanId != null) 'batsman_id': batsmanId,
      if (nonStrikerId != null) 'non_striker_id': nonStrikerId,
      if (bowlerId != null) 'bowler_id': bowlerId,
      if (runsOffBat != null) 'runs_off_bat': runsOffBat,
      if (extraType != null) 'extra_type': extraType,
      if (extraRuns != null) 'extra_runs': extraRuns,
      if (wicketType != null) 'wicket_type': wicketType,
      if (dismissedPlayerId != null) 'dismissed_player_id': dismissedPlayerId,
      if (fielderPlayerId != null) 'fielder_player_id': fielderPlayerId,
      if (isAdminCorrection != null) 'is_admin_correction': isAdminCorrection,
      if (syncedToServer != null) 'synced_to_server': syncedToServer,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeliveriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? matchId,
      Value<int>? inningsNumber,
      Value<int>? overNumber,
      Value<int>? ballNumber,
      Value<String>? batsmanId,
      Value<String>? nonStrikerId,
      Value<String>? bowlerId,
      Value<int>? runsOffBat,
      Value<String?>? extraType,
      Value<int>? extraRuns,
      Value<String?>? wicketType,
      Value<String?>? dismissedPlayerId,
      Value<String?>? fielderPlayerId,
      Value<bool>? isAdminCorrection,
      Value<bool>? syncedToServer,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return DeliveriesCompanion(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      inningsNumber: inningsNumber ?? this.inningsNumber,
      overNumber: overNumber ?? this.overNumber,
      ballNumber: ballNumber ?? this.ballNumber,
      batsmanId: batsmanId ?? this.batsmanId,
      nonStrikerId: nonStrikerId ?? this.nonStrikerId,
      bowlerId: bowlerId ?? this.bowlerId,
      runsOffBat: runsOffBat ?? this.runsOffBat,
      extraType: extraType ?? this.extraType,
      extraRuns: extraRuns ?? this.extraRuns,
      wicketType: wicketType ?? this.wicketType,
      dismissedPlayerId: dismissedPlayerId ?? this.dismissedPlayerId,
      fielderPlayerId: fielderPlayerId ?? this.fielderPlayerId,
      isAdminCorrection: isAdminCorrection ?? this.isAdminCorrection,
      syncedToServer: syncedToServer ?? this.syncedToServer,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (matchId.present) {
      map['match_id'] = Variable<String>(matchId.value);
    }
    if (inningsNumber.present) {
      map['innings_number'] = Variable<int>(inningsNumber.value);
    }
    if (overNumber.present) {
      map['over_number'] = Variable<int>(overNumber.value);
    }
    if (ballNumber.present) {
      map['ball_number'] = Variable<int>(ballNumber.value);
    }
    if (batsmanId.present) {
      map['batsman_id'] = Variable<String>(batsmanId.value);
    }
    if (nonStrikerId.present) {
      map['non_striker_id'] = Variable<String>(nonStrikerId.value);
    }
    if (bowlerId.present) {
      map['bowler_id'] = Variable<String>(bowlerId.value);
    }
    if (runsOffBat.present) {
      map['runs_off_bat'] = Variable<int>(runsOffBat.value);
    }
    if (extraType.present) {
      map['extra_type'] = Variable<String>(extraType.value);
    }
    if (extraRuns.present) {
      map['extra_runs'] = Variable<int>(extraRuns.value);
    }
    if (wicketType.present) {
      map['wicket_type'] = Variable<String>(wicketType.value);
    }
    if (dismissedPlayerId.present) {
      map['dismissed_player_id'] = Variable<String>(dismissedPlayerId.value);
    }
    if (fielderPlayerId.present) {
      map['fielder_player_id'] = Variable<String>(fielderPlayerId.value);
    }
    if (isAdminCorrection.present) {
      map['is_admin_correction'] = Variable<bool>(isAdminCorrection.value);
    }
    if (syncedToServer.present) {
      map['synced_to_server'] = Variable<bool>(syncedToServer.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeliveriesCompanion(')
          ..write('id: $id, ')
          ..write('matchId: $matchId, ')
          ..write('inningsNumber: $inningsNumber, ')
          ..write('overNumber: $overNumber, ')
          ..write('ballNumber: $ballNumber, ')
          ..write('batsmanId: $batsmanId, ')
          ..write('nonStrikerId: $nonStrikerId, ')
          ..write('bowlerId: $bowlerId, ')
          ..write('runsOffBat: $runsOffBat, ')
          ..write('extraType: $extraType, ')
          ..write('extraRuns: $extraRuns, ')
          ..write('wicketType: $wicketType, ')
          ..write('dismissedPlayerId: $dismissedPlayerId, ')
          ..write('fielderPlayerId: $fielderPlayerId, ')
          ..write('isAdminCorrection: $isAdminCorrection, ')
          ..write('syncedToServer: $syncedToServer, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlayerRatingsTable extends PlayerRatings
    with TableInfo<$PlayerRatingsTable, PlayerRating> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayerRatingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playerIdMeta =
      const VerificationMeta('playerId');
  @override
  late final GeneratedColumn<String> playerId = GeneratedColumn<String>(
      'player_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ovrMeta = const VerificationMeta('ovr');
  @override
  late final GeneratedColumn<double> ovr = GeneratedColumn<double>(
      'ovr', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _batMeta = const VerificationMeta('bat');
  @override
  late final GeneratedColumn<double> bat = GeneratedColumn<double>(
      'bat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _bowlMeta = const VerificationMeta('bowl');
  @override
  late final GeneratedColumn<double> bowl = GeneratedColumn<double>(
      'bowl', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _fieldMeta = const VerificationMeta('field');
  @override
  late final GeneratedColumn<double> field = GeneratedColumn<double>(
      'field', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _matchesPlayedMeta =
      const VerificationMeta('matchesPlayed');
  @override
  late final GeneratedColumn<int> matchesPlayed = GeneratedColumn<int>(
      'matches_played', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _hotStreakCountMeta =
      const VerificationMeta('hotStreakCount');
  @override
  late final GeneratedColumn<int> hotStreakCount = GeneratedColumn<int>(
      'hot_streak_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _computedAtMeta =
      const VerificationMeta('computedAt');
  @override
  late final GeneratedColumn<DateTime> computedAt = GeneratedColumn<DateTime>(
      'computed_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        playerId,
        ovr,
        bat,
        bowl,
        field,
        matchesPlayed,
        hotStreakCount,
        computedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'player_ratings';
  @override
  VerificationContext validateIntegrity(Insertable<PlayerRating> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('player_id')) {
      context.handle(_playerIdMeta,
          playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta));
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('ovr')) {
      context.handle(
          _ovrMeta, ovr.isAcceptableOrUnknown(data['ovr']!, _ovrMeta));
    } else if (isInserting) {
      context.missing(_ovrMeta);
    }
    if (data.containsKey('bat')) {
      context.handle(
          _batMeta, bat.isAcceptableOrUnknown(data['bat']!, _batMeta));
    } else if (isInserting) {
      context.missing(_batMeta);
    }
    if (data.containsKey('bowl')) {
      context.handle(
          _bowlMeta, bowl.isAcceptableOrUnknown(data['bowl']!, _bowlMeta));
    } else if (isInserting) {
      context.missing(_bowlMeta);
    }
    if (data.containsKey('field')) {
      context.handle(
          _fieldMeta, field.isAcceptableOrUnknown(data['field']!, _fieldMeta));
    } else if (isInserting) {
      context.missing(_fieldMeta);
    }
    if (data.containsKey('matches_played')) {
      context.handle(
          _matchesPlayedMeta,
          matchesPlayed.isAcceptableOrUnknown(
              data['matches_played']!, _matchesPlayedMeta));
    } else if (isInserting) {
      context.missing(_matchesPlayedMeta);
    }
    if (data.containsKey('hot_streak_count')) {
      context.handle(
          _hotStreakCountMeta,
          hotStreakCount.isAcceptableOrUnknown(
              data['hot_streak_count']!, _hotStreakCountMeta));
    }
    if (data.containsKey('computed_at')) {
      context.handle(
          _computedAtMeta,
          computedAt.isAcceptableOrUnknown(
              data['computed_at']!, _computedAtMeta));
    } else if (isInserting) {
      context.missing(_computedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playerId};
  @override
  PlayerRating map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayerRating(
      playerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}player_id'])!,
      ovr: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}ovr'])!,
      bat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}bat'])!,
      bowl: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}bowl'])!,
      field: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}field'])!,
      matchesPlayed: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}matches_played'])!,
      hotStreakCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}hot_streak_count'])!,
      computedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}computed_at'])!,
    );
  }

  @override
  $PlayerRatingsTable createAlias(String alias) {
    return $PlayerRatingsTable(attachedDatabase, alias);
  }
}

class PlayerRating extends DataClass implements Insertable<PlayerRating> {
  final String playerId;
  final double ovr;
  final double bat;
  final double bowl;
  final double field;
  final int matchesPlayed;
  final int hotStreakCount;
  final DateTime computedAt;
  const PlayerRating(
      {required this.playerId,
      required this.ovr,
      required this.bat,
      required this.bowl,
      required this.field,
      required this.matchesPlayed,
      required this.hotStreakCount,
      required this.computedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['player_id'] = Variable<String>(playerId);
    map['ovr'] = Variable<double>(ovr);
    map['bat'] = Variable<double>(bat);
    map['bowl'] = Variable<double>(bowl);
    map['field'] = Variable<double>(field);
    map['matches_played'] = Variable<int>(matchesPlayed);
    map['hot_streak_count'] = Variable<int>(hotStreakCount);
    map['computed_at'] = Variable<DateTime>(computedAt);
    return map;
  }

  PlayerRatingsCompanion toCompanion(bool nullToAbsent) {
    return PlayerRatingsCompanion(
      playerId: Value(playerId),
      ovr: Value(ovr),
      bat: Value(bat),
      bowl: Value(bowl),
      field: Value(field),
      matchesPlayed: Value(matchesPlayed),
      hotStreakCount: Value(hotStreakCount),
      computedAt: Value(computedAt),
    );
  }

  factory PlayerRating.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayerRating(
      playerId: serializer.fromJson<String>(json['playerId']),
      ovr: serializer.fromJson<double>(json['ovr']),
      bat: serializer.fromJson<double>(json['bat']),
      bowl: serializer.fromJson<double>(json['bowl']),
      field: serializer.fromJson<double>(json['field']),
      matchesPlayed: serializer.fromJson<int>(json['matchesPlayed']),
      hotStreakCount: serializer.fromJson<int>(json['hotStreakCount']),
      computedAt: serializer.fromJson<DateTime>(json['computedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playerId': serializer.toJson<String>(playerId),
      'ovr': serializer.toJson<double>(ovr),
      'bat': serializer.toJson<double>(bat),
      'bowl': serializer.toJson<double>(bowl),
      'field': serializer.toJson<double>(field),
      'matchesPlayed': serializer.toJson<int>(matchesPlayed),
      'hotStreakCount': serializer.toJson<int>(hotStreakCount),
      'computedAt': serializer.toJson<DateTime>(computedAt),
    };
  }

  PlayerRating copyWith(
          {String? playerId,
          double? ovr,
          double? bat,
          double? bowl,
          double? field,
          int? matchesPlayed,
          int? hotStreakCount,
          DateTime? computedAt}) =>
      PlayerRating(
        playerId: playerId ?? this.playerId,
        ovr: ovr ?? this.ovr,
        bat: bat ?? this.bat,
        bowl: bowl ?? this.bowl,
        field: field ?? this.field,
        matchesPlayed: matchesPlayed ?? this.matchesPlayed,
        hotStreakCount: hotStreakCount ?? this.hotStreakCount,
        computedAt: computedAt ?? this.computedAt,
      );
  PlayerRating copyWithCompanion(PlayerRatingsCompanion data) {
    return PlayerRating(
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      ovr: data.ovr.present ? data.ovr.value : this.ovr,
      bat: data.bat.present ? data.bat.value : this.bat,
      bowl: data.bowl.present ? data.bowl.value : this.bowl,
      field: data.field.present ? data.field.value : this.field,
      matchesPlayed: data.matchesPlayed.present
          ? data.matchesPlayed.value
          : this.matchesPlayed,
      hotStreakCount: data.hotStreakCount.present
          ? data.hotStreakCount.value
          : this.hotStreakCount,
      computedAt:
          data.computedAt.present ? data.computedAt.value : this.computedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayerRating(')
          ..write('playerId: $playerId, ')
          ..write('ovr: $ovr, ')
          ..write('bat: $bat, ')
          ..write('bowl: $bowl, ')
          ..write('field: $field, ')
          ..write('matchesPlayed: $matchesPlayed, ')
          ..write('hotStreakCount: $hotStreakCount, ')
          ..write('computedAt: $computedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(playerId, ovr, bat, bowl, field,
      matchesPlayed, hotStreakCount, computedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerRating &&
          other.playerId == this.playerId &&
          other.ovr == this.ovr &&
          other.bat == this.bat &&
          other.bowl == this.bowl &&
          other.field == this.field &&
          other.matchesPlayed == this.matchesPlayed &&
          other.hotStreakCount == this.hotStreakCount &&
          other.computedAt == this.computedAt);
}

class PlayerRatingsCompanion extends UpdateCompanion<PlayerRating> {
  final Value<String> playerId;
  final Value<double> ovr;
  final Value<double> bat;
  final Value<double> bowl;
  final Value<double> field;
  final Value<int> matchesPlayed;
  final Value<int> hotStreakCount;
  final Value<DateTime> computedAt;
  final Value<int> rowid;
  const PlayerRatingsCompanion({
    this.playerId = const Value.absent(),
    this.ovr = const Value.absent(),
    this.bat = const Value.absent(),
    this.bowl = const Value.absent(),
    this.field = const Value.absent(),
    this.matchesPlayed = const Value.absent(),
    this.hotStreakCount = const Value.absent(),
    this.computedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlayerRatingsCompanion.insert({
    required String playerId,
    required double ovr,
    required double bat,
    required double bowl,
    required double field,
    required int matchesPlayed,
    this.hotStreakCount = const Value.absent(),
    required DateTime computedAt,
    this.rowid = const Value.absent(),
  })  : playerId = Value(playerId),
        ovr = Value(ovr),
        bat = Value(bat),
        bowl = Value(bowl),
        field = Value(field),
        matchesPlayed = Value(matchesPlayed),
        computedAt = Value(computedAt);
  static Insertable<PlayerRating> custom({
    Expression<String>? playerId,
    Expression<double>? ovr,
    Expression<double>? bat,
    Expression<double>? bowl,
    Expression<double>? field,
    Expression<int>? matchesPlayed,
    Expression<int>? hotStreakCount,
    Expression<DateTime>? computedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playerId != null) 'player_id': playerId,
      if (ovr != null) 'ovr': ovr,
      if (bat != null) 'bat': bat,
      if (bowl != null) 'bowl': bowl,
      if (field != null) 'field': field,
      if (matchesPlayed != null) 'matches_played': matchesPlayed,
      if (hotStreakCount != null) 'hot_streak_count': hotStreakCount,
      if (computedAt != null) 'computed_at': computedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlayerRatingsCompanion copyWith(
      {Value<String>? playerId,
      Value<double>? ovr,
      Value<double>? bat,
      Value<double>? bowl,
      Value<double>? field,
      Value<int>? matchesPlayed,
      Value<int>? hotStreakCount,
      Value<DateTime>? computedAt,
      Value<int>? rowid}) {
    return PlayerRatingsCompanion(
      playerId: playerId ?? this.playerId,
      ovr: ovr ?? this.ovr,
      bat: bat ?? this.bat,
      bowl: bowl ?? this.bowl,
      field: field ?? this.field,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      hotStreakCount: hotStreakCount ?? this.hotStreakCount,
      computedAt: computedAt ?? this.computedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playerId.present) {
      map['player_id'] = Variable<String>(playerId.value);
    }
    if (ovr.present) {
      map['ovr'] = Variable<double>(ovr.value);
    }
    if (bat.present) {
      map['bat'] = Variable<double>(bat.value);
    }
    if (bowl.present) {
      map['bowl'] = Variable<double>(bowl.value);
    }
    if (field.present) {
      map['field'] = Variable<double>(field.value);
    }
    if (matchesPlayed.present) {
      map['matches_played'] = Variable<int>(matchesPlayed.value);
    }
    if (hotStreakCount.present) {
      map['hot_streak_count'] = Variable<int>(hotStreakCount.value);
    }
    if (computedAt.present) {
      map['computed_at'] = Variable<DateTime>(computedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayerRatingsCompanion(')
          ..write('playerId: $playerId, ')
          ..write('ovr: $ovr, ')
          ..write('bat: $bat, ')
          ..write('bowl: $bowl, ')
          ..write('field: $field, ')
          ..write('matchesPlayed: $matchesPlayed, ')
          ..write('hotStreakCount: $hotStreakCount, ')
          ..write('computedAt: $computedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PlayersTable players = $PlayersTable(this);
  late final $TeamsTable teams = $TeamsTable(this);
  late final $MatchesTable matches = $MatchesTable(this);
  late final $DeliveriesTable deliveries = $DeliveriesTable(this);
  late final $PlayerRatingsTable playerRatings = $PlayerRatingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [players, teams, matches, deliveries, playerRatings];
}

typedef $$PlayersTableCreateCompanionBuilder = PlayersCompanion Function({
  required String id,
  required String name,
  required String role,
  Value<int?> jerseyNumber,
  Value<String?> teamId,
  Value<String?> teamName,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$PlayersTableUpdateCompanionBuilder = PlayersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> role,
  Value<int?> jerseyNumber,
  Value<String?> teamId,
  Value<String?> teamName,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$PlayersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlayersTable,
    Player,
    $$PlayersTableFilterComposer,
    $$PlayersTableOrderingComposer,
    $$PlayersTableCreateCompanionBuilder,
    $$PlayersTableUpdateCompanionBuilder> {
  $$PlayersTableTableManager(_$AppDatabase db, $PlayersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$PlayersTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$PlayersTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<int?> jerseyNumber = const Value.absent(),
            Value<String?> teamId = const Value.absent(),
            Value<String?> teamName = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlayersCompanion(
            id: id,
            name: name,
            role: role,
            jerseyNumber: jerseyNumber,
            teamId: teamId,
            teamName: teamName,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String role,
            Value<int?> jerseyNumber = const Value.absent(),
            Value<String?> teamId = const Value.absent(),
            Value<String?> teamName = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PlayersCompanion.insert(
            id: id,
            name: name,
            role: role,
            jerseyNumber: jerseyNumber,
            teamId: teamId,
            teamName: teamName,
            createdAt: createdAt,
            rowid: rowid,
          ),
        ));
}

class $$PlayersTableFilterComposer
    extends FilterComposer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get role => $state.composableBuilder(
      column: $state.table.role,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get jerseyNumber => $state.composableBuilder(
      column: $state.table.jerseyNumber,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get teamId => $state.composableBuilder(
      column: $state.table.teamId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get teamName => $state.composableBuilder(
      column: $state.table.teamName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$PlayersTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get role => $state.composableBuilder(
      column: $state.table.role,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get jerseyNumber => $state.composableBuilder(
      column: $state.table.jerseyNumber,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get teamId => $state.composableBuilder(
      column: $state.table.teamId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get teamName => $state.composableBuilder(
      column: $state.table.teamName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$TeamsTableCreateCompanionBuilder = TeamsCompanion Function({
  required String id,
  required String name,
  Value<String?> leagueId,
  Value<int> rowid,
});
typedef $$TeamsTableUpdateCompanionBuilder = TeamsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> leagueId,
  Value<int> rowid,
});

class $$TeamsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TeamsTable,
    Team,
    $$TeamsTableFilterComposer,
    $$TeamsTableOrderingComposer,
    $$TeamsTableCreateCompanionBuilder,
    $$TeamsTableUpdateCompanionBuilder> {
  $$TeamsTableTableManager(_$AppDatabase db, $TeamsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$TeamsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$TeamsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> leagueId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TeamsCompanion(
            id: id,
            name: name,
            leagueId: leagueId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> leagueId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TeamsCompanion.insert(
            id: id,
            name: name,
            leagueId: leagueId,
            rowid: rowid,
          ),
        ));
}

class $$TeamsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $TeamsTable> {
  $$TeamsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get leagueId => $state.composableBuilder(
      column: $state.table.leagueId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$TeamsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $TeamsTable> {
  $$TeamsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get leagueId => $state.composableBuilder(
      column: $state.table.leagueId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$MatchesTableCreateCompanionBuilder = MatchesCompanion Function({
  required String id,
  required String type,
  required String teamAId,
  required String teamBId,
  required String teamAName,
  required String teamBName,
  Value<String?> venueNote,
  required DateTime playedAt,
  Value<int> totalOvers,
  Value<String?> tossWinnerId,
  Value<bool?> tossWinnerBattedFirst,
  required String status,
  Value<String> format,
  Value<bool> syncedToServer,
  Value<int> rowid,
});
typedef $$MatchesTableUpdateCompanionBuilder = MatchesCompanion Function({
  Value<String> id,
  Value<String> type,
  Value<String> teamAId,
  Value<String> teamBId,
  Value<String> teamAName,
  Value<String> teamBName,
  Value<String?> venueNote,
  Value<DateTime> playedAt,
  Value<int> totalOvers,
  Value<String?> tossWinnerId,
  Value<bool?> tossWinnerBattedFirst,
  Value<String> status,
  Value<String> format,
  Value<bool> syncedToServer,
  Value<int> rowid,
});

class $$MatchesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MatchesTable,
    Matche,
    $$MatchesTableFilterComposer,
    $$MatchesTableOrderingComposer,
    $$MatchesTableCreateCompanionBuilder,
    $$MatchesTableUpdateCompanionBuilder> {
  $$MatchesTableTableManager(_$AppDatabase db, $MatchesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$MatchesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$MatchesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> teamAId = const Value.absent(),
            Value<String> teamBId = const Value.absent(),
            Value<String> teamAName = const Value.absent(),
            Value<String> teamBName = const Value.absent(),
            Value<String?> venueNote = const Value.absent(),
            Value<DateTime> playedAt = const Value.absent(),
            Value<int> totalOvers = const Value.absent(),
            Value<String?> tossWinnerId = const Value.absent(),
            Value<bool?> tossWinnerBattedFirst = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> format = const Value.absent(),
            Value<bool> syncedToServer = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MatchesCompanion(
            id: id,
            type: type,
            teamAId: teamAId,
            teamBId: teamBId,
            teamAName: teamAName,
            teamBName: teamBName,
            venueNote: venueNote,
            playedAt: playedAt,
            totalOvers: totalOvers,
            tossWinnerId: tossWinnerId,
            tossWinnerBattedFirst: tossWinnerBattedFirst,
            status: status,
            format: format,
            syncedToServer: syncedToServer,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String type,
            required String teamAId,
            required String teamBId,
            required String teamAName,
            required String teamBName,
            Value<String?> venueNote = const Value.absent(),
            required DateTime playedAt,
            Value<int> totalOvers = const Value.absent(),
            Value<String?> tossWinnerId = const Value.absent(),
            Value<bool?> tossWinnerBattedFirst = const Value.absent(),
            required String status,
            Value<String> format = const Value.absent(),
            Value<bool> syncedToServer = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MatchesCompanion.insert(
            id: id,
            type: type,
            teamAId: teamAId,
            teamBId: teamBId,
            teamAName: teamAName,
            teamBName: teamBName,
            venueNote: venueNote,
            playedAt: playedAt,
            totalOvers: totalOvers,
            tossWinnerId: tossWinnerId,
            tossWinnerBattedFirst: tossWinnerBattedFirst,
            status: status,
            format: format,
            syncedToServer: syncedToServer,
            rowid: rowid,
          ),
        ));
}

class $$MatchesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $MatchesTable> {
  $$MatchesTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get teamAId => $state.composableBuilder(
      column: $state.table.teamAId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get teamBId => $state.composableBuilder(
      column: $state.table.teamBId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get teamAName => $state.composableBuilder(
      column: $state.table.teamAName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get teamBName => $state.composableBuilder(
      column: $state.table.teamBName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get venueNote => $state.composableBuilder(
      column: $state.table.venueNote,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get playedAt => $state.composableBuilder(
      column: $state.table.playedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get totalOvers => $state.composableBuilder(
      column: $state.table.totalOvers,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get tossWinnerId => $state.composableBuilder(
      column: $state.table.tossWinnerId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get tossWinnerBattedFirst => $state.composableBuilder(
      column: $state.table.tossWinnerBattedFirst,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get format => $state.composableBuilder(
      column: $state.table.format,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get syncedToServer => $state.composableBuilder(
      column: $state.table.syncedToServer,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$MatchesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $MatchesTable> {
  $$MatchesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get teamAId => $state.composableBuilder(
      column: $state.table.teamAId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get teamBId => $state.composableBuilder(
      column: $state.table.teamBId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get teamAName => $state.composableBuilder(
      column: $state.table.teamAName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get teamBName => $state.composableBuilder(
      column: $state.table.teamBName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get venueNote => $state.composableBuilder(
      column: $state.table.venueNote,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get playedAt => $state.composableBuilder(
      column: $state.table.playedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get totalOvers => $state.composableBuilder(
      column: $state.table.totalOvers,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get tossWinnerId => $state.composableBuilder(
      column: $state.table.tossWinnerId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get tossWinnerBattedFirst => $state.composableBuilder(
      column: $state.table.tossWinnerBattedFirst,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get format => $state.composableBuilder(
      column: $state.table.format,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get syncedToServer => $state.composableBuilder(
      column: $state.table.syncedToServer,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$DeliveriesTableCreateCompanionBuilder = DeliveriesCompanion Function({
  required String id,
  required String matchId,
  required int inningsNumber,
  required int overNumber,
  required int ballNumber,
  required String batsmanId,
  required String nonStrikerId,
  required String bowlerId,
  Value<int> runsOffBat,
  Value<String?> extraType,
  Value<int> extraRuns,
  Value<String?> wicketType,
  Value<String?> dismissedPlayerId,
  Value<String?> fielderPlayerId,
  Value<bool> isAdminCorrection,
  Value<bool> syncedToServer,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$DeliveriesTableUpdateCompanionBuilder = DeliveriesCompanion Function({
  Value<String> id,
  Value<String> matchId,
  Value<int> inningsNumber,
  Value<int> overNumber,
  Value<int> ballNumber,
  Value<String> batsmanId,
  Value<String> nonStrikerId,
  Value<String> bowlerId,
  Value<int> runsOffBat,
  Value<String?> extraType,
  Value<int> extraRuns,
  Value<String?> wicketType,
  Value<String?> dismissedPlayerId,
  Value<String?> fielderPlayerId,
  Value<bool> isAdminCorrection,
  Value<bool> syncedToServer,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$DeliveriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DeliveriesTable,
    Delivery,
    $$DeliveriesTableFilterComposer,
    $$DeliveriesTableOrderingComposer,
    $$DeliveriesTableCreateCompanionBuilder,
    $$DeliveriesTableUpdateCompanionBuilder> {
  $$DeliveriesTableTableManager(_$AppDatabase db, $DeliveriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$DeliveriesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$DeliveriesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> matchId = const Value.absent(),
            Value<int> inningsNumber = const Value.absent(),
            Value<int> overNumber = const Value.absent(),
            Value<int> ballNumber = const Value.absent(),
            Value<String> batsmanId = const Value.absent(),
            Value<String> nonStrikerId = const Value.absent(),
            Value<String> bowlerId = const Value.absent(),
            Value<int> runsOffBat = const Value.absent(),
            Value<String?> extraType = const Value.absent(),
            Value<int> extraRuns = const Value.absent(),
            Value<String?> wicketType = const Value.absent(),
            Value<String?> dismissedPlayerId = const Value.absent(),
            Value<String?> fielderPlayerId = const Value.absent(),
            Value<bool> isAdminCorrection = const Value.absent(),
            Value<bool> syncedToServer = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DeliveriesCompanion(
            id: id,
            matchId: matchId,
            inningsNumber: inningsNumber,
            overNumber: overNumber,
            ballNumber: ballNumber,
            batsmanId: batsmanId,
            nonStrikerId: nonStrikerId,
            bowlerId: bowlerId,
            runsOffBat: runsOffBat,
            extraType: extraType,
            extraRuns: extraRuns,
            wicketType: wicketType,
            dismissedPlayerId: dismissedPlayerId,
            fielderPlayerId: fielderPlayerId,
            isAdminCorrection: isAdminCorrection,
            syncedToServer: syncedToServer,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String matchId,
            required int inningsNumber,
            required int overNumber,
            required int ballNumber,
            required String batsmanId,
            required String nonStrikerId,
            required String bowlerId,
            Value<int> runsOffBat = const Value.absent(),
            Value<String?> extraType = const Value.absent(),
            Value<int> extraRuns = const Value.absent(),
            Value<String?> wicketType = const Value.absent(),
            Value<String?> dismissedPlayerId = const Value.absent(),
            Value<String?> fielderPlayerId = const Value.absent(),
            Value<bool> isAdminCorrection = const Value.absent(),
            Value<bool> syncedToServer = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DeliveriesCompanion.insert(
            id: id,
            matchId: matchId,
            inningsNumber: inningsNumber,
            overNumber: overNumber,
            ballNumber: ballNumber,
            batsmanId: batsmanId,
            nonStrikerId: nonStrikerId,
            bowlerId: bowlerId,
            runsOffBat: runsOffBat,
            extraType: extraType,
            extraRuns: extraRuns,
            wicketType: wicketType,
            dismissedPlayerId: dismissedPlayerId,
            fielderPlayerId: fielderPlayerId,
            isAdminCorrection: isAdminCorrection,
            syncedToServer: syncedToServer,
            createdAt: createdAt,
            rowid: rowid,
          ),
        ));
}

class $$DeliveriesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $DeliveriesTable> {
  $$DeliveriesTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get matchId => $state.composableBuilder(
      column: $state.table.matchId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get inningsNumber => $state.composableBuilder(
      column: $state.table.inningsNumber,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get overNumber => $state.composableBuilder(
      column: $state.table.overNumber,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get ballNumber => $state.composableBuilder(
      column: $state.table.ballNumber,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get batsmanId => $state.composableBuilder(
      column: $state.table.batsmanId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get nonStrikerId => $state.composableBuilder(
      column: $state.table.nonStrikerId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get bowlerId => $state.composableBuilder(
      column: $state.table.bowlerId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get runsOffBat => $state.composableBuilder(
      column: $state.table.runsOffBat,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get extraType => $state.composableBuilder(
      column: $state.table.extraType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get extraRuns => $state.composableBuilder(
      column: $state.table.extraRuns,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get wicketType => $state.composableBuilder(
      column: $state.table.wicketType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get dismissedPlayerId => $state.composableBuilder(
      column: $state.table.dismissedPlayerId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get fielderPlayerId => $state.composableBuilder(
      column: $state.table.fielderPlayerId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isAdminCorrection => $state.composableBuilder(
      column: $state.table.isAdminCorrection,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get syncedToServer => $state.composableBuilder(
      column: $state.table.syncedToServer,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$DeliveriesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $DeliveriesTable> {
  $$DeliveriesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get matchId => $state.composableBuilder(
      column: $state.table.matchId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get inningsNumber => $state.composableBuilder(
      column: $state.table.inningsNumber,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get overNumber => $state.composableBuilder(
      column: $state.table.overNumber,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get ballNumber => $state.composableBuilder(
      column: $state.table.ballNumber,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get batsmanId => $state.composableBuilder(
      column: $state.table.batsmanId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get nonStrikerId => $state.composableBuilder(
      column: $state.table.nonStrikerId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get bowlerId => $state.composableBuilder(
      column: $state.table.bowlerId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get runsOffBat => $state.composableBuilder(
      column: $state.table.runsOffBat,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get extraType => $state.composableBuilder(
      column: $state.table.extraType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get extraRuns => $state.composableBuilder(
      column: $state.table.extraRuns,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get wicketType => $state.composableBuilder(
      column: $state.table.wicketType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get dismissedPlayerId => $state.composableBuilder(
      column: $state.table.dismissedPlayerId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get fielderPlayerId => $state.composableBuilder(
      column: $state.table.fielderPlayerId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isAdminCorrection => $state.composableBuilder(
      column: $state.table.isAdminCorrection,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get syncedToServer => $state.composableBuilder(
      column: $state.table.syncedToServer,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$PlayerRatingsTableCreateCompanionBuilder = PlayerRatingsCompanion
    Function({
  required String playerId,
  required double ovr,
  required double bat,
  required double bowl,
  required double field,
  required int matchesPlayed,
  Value<int> hotStreakCount,
  required DateTime computedAt,
  Value<int> rowid,
});
typedef $$PlayerRatingsTableUpdateCompanionBuilder = PlayerRatingsCompanion
    Function({
  Value<String> playerId,
  Value<double> ovr,
  Value<double> bat,
  Value<double> bowl,
  Value<double> field,
  Value<int> matchesPlayed,
  Value<int> hotStreakCount,
  Value<DateTime> computedAt,
  Value<int> rowid,
});

class $$PlayerRatingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlayerRatingsTable,
    PlayerRating,
    $$PlayerRatingsTableFilterComposer,
    $$PlayerRatingsTableOrderingComposer,
    $$PlayerRatingsTableCreateCompanionBuilder,
    $$PlayerRatingsTableUpdateCompanionBuilder> {
  $$PlayerRatingsTableTableManager(_$AppDatabase db, $PlayerRatingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$PlayerRatingsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$PlayerRatingsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> playerId = const Value.absent(),
            Value<double> ovr = const Value.absent(),
            Value<double> bat = const Value.absent(),
            Value<double> bowl = const Value.absent(),
            Value<double> field = const Value.absent(),
            Value<int> matchesPlayed = const Value.absent(),
            Value<int> hotStreakCount = const Value.absent(),
            Value<DateTime> computedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlayerRatingsCompanion(
            playerId: playerId,
            ovr: ovr,
            bat: bat,
            bowl: bowl,
            field: field,
            matchesPlayed: matchesPlayed,
            hotStreakCount: hotStreakCount,
            computedAt: computedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String playerId,
            required double ovr,
            required double bat,
            required double bowl,
            required double field,
            required int matchesPlayed,
            Value<int> hotStreakCount = const Value.absent(),
            required DateTime computedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PlayerRatingsCompanion.insert(
            playerId: playerId,
            ovr: ovr,
            bat: bat,
            bowl: bowl,
            field: field,
            matchesPlayed: matchesPlayed,
            hotStreakCount: hotStreakCount,
            computedAt: computedAt,
            rowid: rowid,
          ),
        ));
}

class $$PlayerRatingsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $PlayerRatingsTable> {
  $$PlayerRatingsTableFilterComposer(super.$state);
  ColumnFilters<String> get playerId => $state.composableBuilder(
      column: $state.table.playerId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get ovr => $state.composableBuilder(
      column: $state.table.ovr,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get bat => $state.composableBuilder(
      column: $state.table.bat,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get bowl => $state.composableBuilder(
      column: $state.table.bowl,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get field => $state.composableBuilder(
      column: $state.table.field,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get matchesPlayed => $state.composableBuilder(
      column: $state.table.matchesPlayed,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get hotStreakCount => $state.composableBuilder(
      column: $state.table.hotStreakCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get computedAt => $state.composableBuilder(
      column: $state.table.computedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$PlayerRatingsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $PlayerRatingsTable> {
  $$PlayerRatingsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get playerId => $state.composableBuilder(
      column: $state.table.playerId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get ovr => $state.composableBuilder(
      column: $state.table.ovr,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get bat => $state.composableBuilder(
      column: $state.table.bat,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get bowl => $state.composableBuilder(
      column: $state.table.bowl,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get field => $state.composableBuilder(
      column: $state.table.field,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get matchesPlayed => $state.composableBuilder(
      column: $state.table.matchesPlayed,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get hotStreakCount => $state.composableBuilder(
      column: $state.table.hotStreakCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get computedAt => $state.composableBuilder(
      column: $state.table.computedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PlayersTableTableManager get players =>
      $$PlayersTableTableManager(_db, _db.players);
  $$TeamsTableTableManager get teams =>
      $$TeamsTableTableManager(_db, _db.teams);
  $$MatchesTableTableManager get matches =>
      $$MatchesTableTableManager(_db, _db.matches);
  $$DeliveriesTableTableManager get deliveries =>
      $$DeliveriesTableTableManager(_db, _db.deliveries);
  $$PlayerRatingsTableTableManager get playerRatings =>
      $$PlayerRatingsTableTableManager(_db, _db.playerRatings);
}
