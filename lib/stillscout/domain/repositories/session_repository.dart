import '../../data/models/stillscout_session.dart';

/// Contract for persisting and retrieving StillScout sessions.
abstract interface class SessionRepository {
  /// Returns all sessions, most recent first.
  Future<List<StillScoutSession>> getSessions();

  /// Persists [session]. Overwrites if [StillScoutSession.id] already exists.
  Future<void> saveSession(StillScoutSession session);

  /// Returns a single session by [id], or null if missing.
  Future<StillScoutSession?> getSession(String id);

  /// Removes the session with [id] and its associated cached frames.
  Future<void> deleteSession(String id);

  /// Removes sessions that exceed the LRU cap
  /// ([StillScoutConstants.maxCachedSessions]).
  Future<void> evictOldSessions();
}
