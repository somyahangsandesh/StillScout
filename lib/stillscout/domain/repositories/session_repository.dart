import '../../data/models/stillscout_session.dart';

/// Contract for persisting and retrieving StillScout sessions.
abstract interface class SessionRepository {
  /// Returns all sessions, most recent first.
  Future<List<StillScoutSession>> getSessions();

  /// Persists [session]. Overwrites if [StillScoutSession.id] already exists.
  Future<void> saveSession(StillScoutSession session);

  /// Removes the session with [id] and its associated cached frames.
  Future<void> deleteSession(String id);

  /// Removes sessions that exceed the LRU cap
  /// ([StillScoutConstants.maxCachedSessions]).
  Future<void> evictOldSessions();
}
