import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/repositories/session_repository.dart';
import '../../domain/stillscout_constants.dart';
import '../../services/stillscout_cache_janitor.dart';
import '../../services/stillscout_session_bonus_migration.dart';
import '../models/stillscout_session.dart';

/// Hive-backed session store. Uses a plain dynamic box (no codegen) keyed
/// by [StillScoutSession.id], consistent with [StillScoutScoreCache].
class SessionRepositoryImpl implements SessionRepository {
  Box get _box => Hive.box(StillScoutConstants.sessionCacheBoxName);

  @override
  Future<List<StillScoutSession>> getSessions() async {
    final sessions = await _loadSessions(migrate: true);
    sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sessions;
  }

  @override
  Future<void> saveSession(StillScoutSession session) async {
    await _box.put(session.id, session.toJson());
  }

  @override
  Future<StillScoutSession?> getSession(String id) async {
    final sessions = await _loadSessions(migrate: true);
    for (final session in sessions) {
      if (session.id == id) return session;
    }
    return null;
  }

  Future<List<StillScoutSession>> _loadSessions({required bool migrate}) async {
    final parsed = <StillScoutSession>[];
    for (final key in _box.keys) {
      try {
        final raw = _box.get(key);
        if (raw is Map) {
          parsed.add(StillScoutSession.fromJson(raw));
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[SessionRepo] Failed to parse session $key: $e');
        }
      }
    }

    if (!migrate) return parsed;

    final migrated = parsed
        .map(
          (session) => _migrateSessionIfNeeded(
            session: session,
            allSessions: parsed,
          ),
        )
        .toList(growable: false);

    for (var i = 0; i < migrated.length; i++) {
      final before = parsed[i];
      final after = migrated[i];
      if (after.usedFirstScoutBonus != before.usedFirstScoutBonus) {
        await _box.put(after.id, after.toJson());
      }
    }

    return migrated;
  }

  StillScoutSession _migrateSessionIfNeeded({
    required StillScoutSession session,
    required List<StillScoutSession> allSessions,
  }) {
    final resolved = StillScoutSessionBonusMigration.resolveUsedFirstScoutBonus(
      session: session,
      allSessions: allSessions,
    );
    if (resolved == session.usedFirstScoutBonus) return session;
    return session.copyWith(usedFirstScoutBonus: resolved);
  }

  @override
  Future<void> deleteSession(String id) async {
    await _box.delete(id);
    await StillScoutCacheJanitor.deleteSession(id);
  }

  @override
  Future<void> evictOldSessions() async {
    var sessions = await getSessions();

    if (sessions.length > StillScoutConstants.maxCachedSessions) {
      final toEvict = sessions.skip(StillScoutConstants.maxCachedSessions);
      for (final session in toEvict) {
        await deleteSession(session.id);
      }
      sessions = await getSessions();
    }

    await StillScoutCacheJanitor.evict(
      activeSessions: sessions.map((s) => s.id).toList(),
    );

    final oldestFirst =
        sessions.reversed.map((s) => s.id).toList(growable: false);
    final sizeEvicted =
        await StillScoutCacheJanitor.evictBySizeBudget(
      sessionIdsOldestFirst: oldestFirst,
    );
    for (final id in sizeEvicted) {
      await _box.delete(id);
      if (kDebugMode) {
        debugPrint('[SessionRepo] Evicted session $id (cache size budget)');
      }
    }
  }
}
