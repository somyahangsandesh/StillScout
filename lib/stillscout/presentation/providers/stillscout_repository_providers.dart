import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/scoring_repository_impl.dart';
import '../../data/repositories/session_repository_impl.dart';
import '../../data/repositories/video_repository_impl.dart';
import '../../domain/repositories/scoring_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/repositories/video_repository.dart';
import '../../services/face_quality_detector.dart';

/// DI wiring for StillScout repositories.
///
/// All providers are `lazy` (Riverpod default) — no cost until first use.
/// Override these in tests via `ProviderScope(overrides: [...])` to inject
/// fake implementations without touching the production code.

/// Singleton face detector shared across the scoring session.
///
/// StillScout is **iOS-only** — always uses [VisionFaceQualityDetector]
/// (Apple Vision via native method channel).
final faceDetectorProvider = Provider<FaceQualityDetector>(
  (ref) {
    final detector = VisionFaceQualityDetector();
    ref.onDispose(detector.close);
    return detector;
  },
);

final videoRepositoryProvider = Provider<VideoRepository>(
  (ref) => VideoRepositoryImpl(),
);

final scoringRepositoryProvider = Provider<ScoringRepository>(
  (ref) => ScoringRepositoryImpl(
    faceDetector: ref.watch(faceDetectorProvider),
  ),
);

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepositoryImpl(),
);
