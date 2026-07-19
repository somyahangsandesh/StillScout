import 'package:flutter_test/flutter_test.dart';
import 'package:stillscout/stillscout/data/models/stillscout_session.dart';
import 'package:stillscout/stillscout/domain/stillscout_constants.dart';
import 'package:stillscout/stillscout/services/stillscout_session_bonus_migration.dart';

StillScoutSession _session({
  required String id,
  DateTime? createdAt,
  bool usedFirstScoutBonus = false,
  List<Map<String, dynamic>> snapshots = const [],
  List<String> topPickFrameIds = const [],
}) {
  return StillScoutSession(
    id: id,
    videoPath: '/fake/$id.mp4',
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    frameCount: snapshots.length,
    topScore: 8.0,
    topFrameSnapshots: snapshots,
    topPickFrameIds: topPickFrameIds,
    usedFirstScoutBonus: usedFirstScoutBonus,
  );
}

Map<String, dynamic> _snapshot({
  required String frameId,
  bool? persistedLocked,
  bool isTopScout = false,
  int? geminiPickRank,
}) {
  return {
    'frameId': frameId,
    'filePath': '/cache/$frameId.jpg',
    'timestampMs': 1000,
    'score': 8.0,
    if (persistedLocked != null) 'persistedLocked': persistedLocked,
    if (isTopScout) 'isTopScout': true,
    if (geminiPickRank != null) 'geminiPickRank': geminiPickRank,
  };
}

List<Map<String, dynamic>> _legacyRankedSnapshots(int count) {
  return [
    for (var i = 0; i < count; i++) _snapshot(frameId: 'f$i'),
  ];
}

List<Map<String, dynamic>> _rankedSnapshots(int count) {
  return [
    for (var i = 0; i < count; i++)
      _snapshot(
        frameId: 'f$i',
        persistedLocked: i >= StillScoutConstants.freeKeeperLimit,
      ),
  ];
}

void main() {
  group('StillScoutSessionBonusMigration', () {
    test('explicit usedFirstScoutBonus always wins', () {
      final session = _session(
        id: 'explicit',
        usedFirstScoutBonus: true,
        snapshots: _legacyRankedSnapshots(3),
      );

      expect(
        StillScoutSessionBonusMigration.resolveUsedFirstScoutBonus(
          session: session,
          allSessions: [session],
          firstScoutMarkedDoneOnDevice: false,
        ),
        isTrue,
      );
    });

    test('persistedLocked false in bonus tier implies bonus was used', () {
      final snapshots = _rankedSnapshots(8);
      snapshots[5] = _snapshot(frameId: 'f5', persistedLocked: false);

      final session = _session(id: 'flags', snapshots: snapshots);

      expect(
        StillScoutSessionBonusMigration.resolveUsedFirstScoutBonus(
          session: session,
          allSessions: [session],
          firstScoutMarkedDoneOnDevice: false,
        ),
        isTrue,
      );
    });

    test('persistedLocked true in bonus tier blocks inference', () {
      final snapshots = _rankedSnapshots(8);
      snapshots[5] = _snapshot(frameId: 'f5', persistedLocked: true);

      final session = _session(
        id: 'locked',
        snapshots: snapshots,
        topPickFrameIds: const ['f5'],
      );

      expect(
        StillScoutSessionBonusMigration.resolveUsedFirstScoutBonus(
          session: session,
          allSessions: [session],
          firstScoutMarkedDoneOnDevice: true,
        ),
        isFalse,
      );
    });

    test('legacy oldest session with bonus-tier top pick infers bonus', () {
      final oldest = _session(
        id: 'a',
        createdAt: DateTime(2026, 1, 1),
        snapshots: _legacyRankedSnapshots(10),
        topPickFrameIds: const ['f6'],
      );
      final newer = _session(
        id: 'b',
        createdAt: DateTime(2026, 2, 1),
        snapshots: _legacyRankedSnapshots(10),
      );

      expect(
        StillScoutSessionBonusMigration.resolveUsedFirstScoutBonus(
          session: oldest,
          allSessions: [oldest, newer],
          firstScoutMarkedDoneOnDevice: true,
        ),
        isTrue,
      );
      expect(
        StillScoutSessionBonusMigration.resolveUsedFirstScoutBonus(
          session: newer,
          allSessions: [oldest, newer],
          firstScoutMarkedDoneOnDevice: true,
        ),
        isFalse,
      );
    });

    test('legacy oldest session without corroboration stays locked', () {
      final oldest = _session(
        id: 'a',
        createdAt: DateTime(2026, 1, 1),
        snapshots: _legacyRankedSnapshots(10),
        topPickFrameIds: const ['f0', 'f1', 'f2'],
      );

      expect(
        StillScoutSessionBonusMigration.resolveUsedFirstScoutBonus(
          session: oldest,
          allSessions: [oldest],
          firstScoutMarkedDoneOnDevice: true,
        ),
        isFalse,
      );
    });

    test('legacy bonus-tier Gemini pick corroborates oldest session', () {
      final snapshots = _legacyRankedSnapshots(10);
      snapshots[6] = _snapshot(
        frameId: 'f6',
        isTopScout: true,
      );

      final oldest = _session(
        id: 'a',
        createdAt: DateTime(2026, 1, 1),
        snapshots: snapshots,
      );

      expect(
        StillScoutSessionBonusMigration.resolveUsedFirstScoutBonus(
          session: oldest,
          allSessions: [oldest],
          firstScoutMarkedDoneOnDevice: true,
        ),
        isTrue,
      );
    });

    test('does not infer when device first scout is not done', () {
      final oldest = _session(
        id: 'a',
        createdAt: DateTime(2026, 1, 1),
        snapshots: _legacyRankedSnapshots(10),
        topPickFrameIds: const ['f6'],
      );

      expect(
        StillScoutSessionBonusMigration.resolveUsedFirstScoutBonus(
          session: oldest,
          allSessions: [oldest],
          firstScoutMarkedDoneOnDevice: false,
        ),
        isFalse,
      );
    });
  });
}
