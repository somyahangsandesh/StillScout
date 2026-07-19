import '../stillscout_constants.dart';

/// Typed failure hierarchy for the StillScout pipeline.
///
/// Every error that surfaces to the UI is expressed as a [StillScoutFailure]
/// subtype rather than a raw exception string, so:
/// - The notifier has a single `catch (StillScoutFailure f)` clause (no dual
///   exception-type handling).
/// - The UI maps `displayMessage` exhaustively — no string guessing at the
///   call site.
/// - Tests can assert on the concrete type, not on fragile message strings.
sealed class StillScoutFailure {
  const StillScoutFailure();

  String get displayMessage;
  String get debugTag;
}

final class VideoNotFoundFailure extends StillScoutFailure {
  const VideoNotFoundFailure();

  @override
  String get displayMessage => 'The video file could not be found. It may have been moved or deleted.';

  @override
  String get debugTag => 'video_not_found';
}

final class VideoTooShortFailure extends StillScoutFailure {
  const VideoTooShortFailure();

  @override
  String get displayMessage =>
      'That clip is too short to scout — try something at least half a second long.';

  @override
  String get debugTag => 'video_too_short';
}

final class VideoTooLongFailure extends StillScoutFailure {
  const VideoTooLongFailure();

  @override
  String get displayMessage =>
      'That clip is longer than 10 minutes. Trim it to 10 minutes or less, then try again.';

  @override
  String get debugTag => 'video_too_long';
}

final class VideoUnreadableFailure extends StillScoutFailure {
  const VideoUnreadableFailure();

  @override
  String get displayMessage =>
      'Could not read this video. Try a different file or format.';

  @override
  String get debugTag => 'video_unreadable';
}

final class VideoReadTimeoutFailure extends StillScoutFailure {
  const VideoReadTimeoutFailure();

  @override
  String get displayMessage =>
      'Timed out reading this video — it may be corrupted.';

  @override
  String get debugTag => 'video_read_timeout';
}

final class ExtractionFailure extends StillScoutFailure {
  const ExtractionFailure(this.reason);

  final String reason;

  @override
  String get displayMessage => reason;

  @override
  String get debugTag => 'extraction_failed';
}

final class MemoryPressureFailure extends StillScoutFailure {
  const MemoryPressureFailure();

  @override
  String get displayMessage =>
      'Too many frames failed to decode — the device may be low on memory. Try a shorter clip.';

  @override
  String get debugTag => 'memory_pressure';
}

final class ScoringFailure extends StillScoutFailure {
  const ScoringFailure(this.reason);

  final String reason;

  @override
  String get displayMessage => reason;

  @override
  String get debugTag => 'scoring_failed';
}

final class ScoutQuotaExhaustedFailure extends StillScoutFailure {
  const ScoutQuotaExhaustedFailure();

  @override
  String get displayMessage =>
      'You\'ve used all ${StillScoutConstants.freeScoutsPerDay} free scouts for today. '
      'Upgrade to Pro for unlimited scouting, or try again tomorrow.';

  @override
  String get debugTag => 'scout_quota_exhausted';
}

final class OfflineFailure extends StillScoutFailure {
  const OfflineFailure();

  @override
  String get displayMessage =>
      'Gemini scoring needs a working internet connection. '
      'Connect to Wi‑Fi or mobile data, then try again. '
      'Later free scouts (on-device Vision) work offline.';

  @override
  String get debugTag => 'offline';
}

final class CancelledFailure extends StillScoutFailure {
  const CancelledFailure();

  @override
  String get displayMessage => 'Scout cancelled.';

  @override
  String get debugTag => 'cancelled';
}

final class UnknownFailure extends StillScoutFailure {
  const UnknownFailure([this.error]);

  final Object? error;

  @override
  String get displayMessage => 'Something went wrong while processing your video.';

  @override
  String get debugTag => 'unknown';
}
