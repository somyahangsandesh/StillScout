import 'package:flutter/foundation.dart';

import '../../data/models/scored_frame.dart';
import '../../data/models/stillscout_session.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/stillscout_access_policy.dart';
import '../../domain/stillscout_constants.dart';

/// Persists a completed (or re-scored) scout as a [StillScoutSession].
///
/// Extracted from [StillScoutNotifier._persistSession] (W3.1) — behavior is
/// unchanged: best-effort persistence capped at
/// [StillScoutConstants.maxGalleryFrames], never throws.
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
  }) async {
    if (scored.isEmpty) return;
    final best = scored.first;
    try {
      // Persist full frame data; UI/access policy gates visibility at read time.
      // Capped to maxGalleryFrames (W2.7) — the gallery never shows more than
      // this, so there's no reason to persist beyond it.
      final topSnapshots = scored
          .take(StillScoutConstants.maxGalleryFrames)
          .map((frame) => StillScoutAccessPolicy.toPersistedJson(frame: frame))
          .toList(growable: false);
      final session = StillScoutSession(
        id: sessionId,
        videoPath: videoPath,
        createdAt: DateTime.now(),
        frameCount: scored.length,
        topScore: best.score,
        topFrameThumbPath: best.frame.filePath,
        videoDurationMs: videoDurationMs,
        processingTimeMs: processingTimeMs,
        topFrameSnapshots: topSnapshots,
        exportsUsed: exportsUsedThisSession,
        topPickFrameIds:
            topPicks.map((f) => f.frame.id).toList(growable: false),
      );
      await _sessionRepo.saveSession(session);
      await _sessionRepo.evictOldSessions();
    } catch (e, st) {
      // Session persistence is best-effort; never fail the UI over it.
      if (kDebugMode) {
        debugPrint('[StillScout] Session persist failed: $e\n$st');
      }
    }
  }
}
