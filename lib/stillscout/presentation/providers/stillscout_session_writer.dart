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
  }) async {
    if (scored.isEmpty) return;
    final capped = StillScoutGalleryCap.cap(scored);
    final best = capped.first;
    try {
      final topSnapshots = capped
          .map((frame) => StillScoutAccessPolicy.toPersistedJson(frame: frame))
          .toList(growable: false);
      final session = StillScoutSession(
        id: sessionId,
        videoPath: videoPath,
        createdAt: DateTime.now(),
        frameCount: capped.length,
        topScore: best.score,
        topFrameThumbPath: best.frame.filePath,
        videoDurationMs: videoDurationMs,
        processingTimeMs: processingTimeMs,
        topFrameSnapshots: topSnapshots,
        exportsUsed: exportsUsedThisSession,
        topPickFrameIds:
            topPicks.map((f) => f.frame.id).toList(growable: false),
        usedFirstScoutBonus: usedFirstScoutBonus,
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
