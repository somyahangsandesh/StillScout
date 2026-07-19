import 'dart:io';

import 'package:stillscout/stillscout/data/models/stillscout_session.dart';
import 'package:stillscout/stillscout/data/repositories/session_repository_impl.dart';
import 'package:stillscout/stillscout/domain/stillscout_constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

// ── helpers ──────────────────────────────────────────────────────────────────

StillScoutSession _session(String id, {double topScore = 8.0}) => StillScoutSession(
      id: id,
      videoPath: '/fake/$id.mp4',
      createdAt: DateTime.now(),
      frameCount: 10,
      topScore: topScore.toDouble(),
    );

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  late Directory tmpDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tmpDir = await Directory.systemTemp.createTemp('hive_session_test_');
    Hive.init(tmpDir.path);
    await Hive.openBox(StillScoutConstants.sessionCacheBoxName);
  });

  setUp(() async {
    final box = Hive.box(StillScoutConstants.sessionCacheBoxName);
    await box.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    await tmpDir.delete(recursive: true);
  });

  test('getSessions returns empty list on first run', () async {
    final repo = SessionRepositoryImpl();
    expect(await repo.getSessions(), isEmpty);
  });

  test('saveSession persists and getSessions returns it', () async {
    final repo = SessionRepositoryImpl();
    final s = _session('s1');
    await repo.saveSession(s);
    final sessions = await repo.getSessions();
    expect(sessions, hasLength(1));
    expect(sessions.first.id, 's1');
  });

  test('getSessions returns newest first', () async {
    final repo = SessionRepositoryImpl();
    await repo.saveSession(
      _session('old').copyWith(
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    );
    await repo.saveSession(_session('new'));
    final sessions = await repo.getSessions();
    expect(sessions.first.id, 'new');
    expect(sessions.last.id, 'old');
  });

  test('deleteSession removes from box', () async {
    final repo = SessionRepositoryImpl();
    await repo.saveSession(_session('del'));
    await repo.deleteSession('del');
    expect(await repo.getSessions(), isEmpty);
  });

  test('saveSession overwrites existing entry with same id', () async {
    final repo = SessionRepositoryImpl();
    await repo.saveSession(_session('overwrite', topScore: 7.0));
    await repo.saveSession(_session('overwrite', topScore: 9.5));
    final sessions = await repo.getSessions();
    expect(sessions, hasLength(1));
    expect(sessions.first.topScore, 9.5);
  });

  test('exportsUsed round-trips through Hive', () async {
    final repo = SessionRepositoryImpl();
    await repo.saveSession(_session('exports').copyWith(exportsUsed: 2));
    final sessions = await repo.getSessions();
    expect(sessions.single.exportsUsed, 2);
  });

  test('evictOldSessions keeps only maxCachedSessions', () async {
    final repo = SessionRepositoryImpl();
    // Seed more sessions than the limit.
    for (int i = 0; i < StillScoutConstants.maxCachedSessions + 5; i++) {
      await repo.saveSession(
        _session('s$i').copyWith(
          createdAt: DateTime.now().subtract(Duration(minutes: i)),
        ),
      );
    }
    await repo.evictOldSessions();
    final remaining = await repo.getSessions();
    expect(remaining.length, lessThanOrEqualTo(StillScoutConstants.maxCachedSessions));
  });
}
