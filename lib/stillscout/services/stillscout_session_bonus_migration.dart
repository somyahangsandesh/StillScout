import '../data/models/stillscout_session.dart';
import '../domain/stillscout_constants.dart';
import 'stillscout_scout_quota_tracker.dart';

/// Infers [StillScoutSession.usedFirstScoutBonus] for sessions saved before
/// that field existed, so History reopen keeps ranks 6–8 unlocked.
class StillScoutSessionBonusMigration {
  StillScoutSessionBonusMigration._();

  static int get _bonusTierStart => StillScoutConstants.freeKeeperLimit;

  static int get _bonusTierEndExclusive =>
      StillScoutConstants.freeKeeperLimit +
      StillScoutConstants.firstScoutBonusKeepers;

  /// Resolves the effective first-scout bonus flag for [session].
  ///
  /// Priority:
  /// 1. Explicit `usedFirstScoutBonus` on the session.
  /// 2. Per-frame `persistedLocked` flags saved with newer app versions.
  /// 3. Conservative legacy heuristic (oldest session + device first-scout done).
  static bool resolveUsedFirstScoutBonus({
    required StillScoutSession session,
    required Iterable<StillScoutSession> allSessions,
    bool? firstScoutMarkedDoneOnDevice,
  }) {
    if (session.usedFirstScoutBonus) return true;

    final hasPersistedLockFlags = session.topFrameSnapshots
        .any((snapshot) => snapshot.containsKey('persistedLocked'));
    if (hasPersistedLockFlags) {
      return _bonusTierWasUnlockedAtSave(session);
    }

    return _inferLegacyBonus(
      session: session,
      allSessions: allSessions,
      firstScoutMarkedDoneOnDevice:
          firstScoutMarkedDoneOnDevice ?? StillScoutFirstScoutTracker.isFirstScoutDone,
    );
  }

  /// True when any bonus-tier frame (ranks 5–7) was stored as unlocked.
  static bool _bonusTierWasUnlockedAtSave(StillScoutSession session) {
    for (final entry in session.topFrameSnapshots.asMap().entries) {
      final rank = entry.key;
      if (!_isBonusTierRank(rank)) continue;
      if (entry.value['persistedLocked'] == false) return true;
    }
    return false;
  }

  /// Legacy sessions lack per-frame lock flags; infer only when multiple signals align.
  static bool _inferLegacyBonus({
    required StillScoutSession session,
    required Iterable<StillScoutSession> allSessions,
    required bool firstScoutMarkedDoneOnDevice,
  }) {
    if (!firstScoutMarkedDoneOnDevice) return false;
    if (!_isOldestSession(session, allSessions)) return false;
    if (session.topFrameSnapshots.length <= _bonusTierStart) return false;

    // Corroboration: a top pick or Gemini pick in the bonus tier strongly
    // suggests the user saw those frames unlocked during the live scout.
    return _hasBonusTierTopPick(session) || _hasBonusTierGeminiPick(session);
  }

  static bool _isBonusTierRank(int rank) =>
      rank >= _bonusTierStart && rank < _bonusTierEndExclusive;

  static bool _isOldestSession(
    StillScoutSession session,
    Iterable<StillScoutSession> allSessions,
  ) {
    final sessions = allSessions.toList(growable: false);
    if (sessions.isEmpty) return true;

    final oldestCreatedAt = sessions
        .map((s) => s.createdAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    final tied = sessions
        .where((s) => s.createdAt == oldestCreatedAt)
        .map((s) => s.id)
        .toList(growable: false)
      ..sort();

    if (session.createdAt != oldestCreatedAt) return false;
    return session.id == tied.first;
  }

  static bool _hasBonusTierTopPick(StillScoutSession session) {
    if (session.topPickFrameIds.isEmpty) return false;
    final rankById = _rankByFrameId(session);
    for (final id in session.topPickFrameIds) {
      final rank = rankById[id];
      if (rank != null && _isBonusTierRank(rank)) return true;
    }
    return false;
  }

  static bool _hasBonusTierGeminiPick(StillScoutSession session) {
    for (final entry in session.topFrameSnapshots.asMap().entries) {
      if (!_isBonusTierRank(entry.key)) continue;
      if (entry.value['isTopScout'] == true) return true;
      if (entry.value['geminiPickRank'] != null) return true;
    }
    return false;
  }

  static Map<String, int> _rankByFrameId(StillScoutSession session) {
    final ranks = <String, int>{};
    for (final entry in session.topFrameSnapshots.asMap().entries) {
      final id = entry.value['frameId'];
      if (id is String) ranks[id] = entry.key;
    }
    return ranks;
  }
}
