import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/repositories/session_repository.dart';
import '../../domain/stillscout_constants.dart';
import '../../services/stillscout_cache_janitor.dart';
import '../models/stillscout_session.dart';

/// Hive-backed session store. Uses a plain dynamic box (no codegen) keyed
/// by [StillScoutSession.id], consistent with [StillScoutScoreCache].
class SessionRepositoryImpl implements SessionRepository {
  Box get _box => Hive.box(StillScoutConstants.sessionCacheBoxName);

  @override
  Future<List<StillScoutSession>> getSessions() async {
    final sessions = <StillScoutSession>[];
    for (final key in _box.keys) {
      try {
        final raw = _box.get(key);
        if (raw is Map) {
          sessions.add(StillScoutSession.fromJson(raw));
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[SessionRepo] Failed to parse session $key: $e');
        }
      }
    }
    sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sessions;
  }

  @override
  Future<void> saveSession(StillScoutSession session) async {
    await _box.put(session.id, session.toJson());
  }

  @override
  Future<StillScoutSession?> getSession(String id) async {
    try {
      final raw = _box.get(id);
      if (raw is Map) return StillScoutSession.fromJson(raw);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SessionRepo] Failed to parse session $id: $e');
      }
    }
    return null;
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
