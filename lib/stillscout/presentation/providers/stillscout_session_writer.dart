import 'package:flutter/foundation.dart';

import '../../data/models/scored_frame.dart';
import '../../data/models/stillscout_session.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/stillscout_access_policy.dart';
import '../../services/stillscout_gallery_cap.dart';

/// Persists a completed (or re-scored) scout as a [StillScoutSession].
class StillScoutSessionWriter {
  const StillScoutSessionWriter(this._sessionRepo);

  final SessionRepository _sessionRepo;

  Future<void> persistSession({
    required String sessionId,
    required String videoPath,
    required List<ScoredFrame> scored,
    required List<ScoredFrame> topPicks,
    required int processingTimeMs,
    required int? videoDurationMs,
    required int exportsUsedThisSession,
    bool usedFirstScoutBonus = false,
    bool isPro = false,
    bool isFirstScout = false,
  }) async {
    if (scored.isEmpty) return;
    final capped = StillScoutGalleryCap.cap(scored);
    final best = capped.first;
    try {
      final existing = await _sessionRepo.getSession(sessionId);
      final effectiveFirstScout = isPro
          ? false
          : (isFirstScout ||
              usedFirstScoutBonus ||
              (existing?.usedFirstScoutBonus ?? false));
      final topSnapshots = capped
          .asMap()
          .entries
          .map(
            (entry) => StillScoutAccessPolicy.toPersistedJson(
              frame: entry.value,
              rank: entry.key,
              isPro: isPro,
              isFirstScout: effectiveFirstScout,
            ),
          )
          .toList(growable: false);
      final session = StillScoutSession(
        id: sessionId,
        videoPath: videoPath,
        createdAt: existing?.createdAt ?? DateTime.now(),
        frameCount: capped.length,
        topScore: best.score,
        topFrameThumbPath: best.frame.filePath,
        videoDurationMs: videoDurationMs,
        processingTimeMs: processingTimeMs,
        topFrameSnapshots: topSnapshots,
        exportsUsed: exportsUsedThisSession,
        topPickFrameIds:
            topPicks.map((f) => f.frame.id).toList(growable: false),
        usedFirstScoutBonus: effectiveFirstScout,
      );
      await _sessionRepo.saveSession(session);
      await _sessionRepo.evictOldSessions();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[StillScout] Session persist failed: $e\n$st');
      }
    }
  }
}
