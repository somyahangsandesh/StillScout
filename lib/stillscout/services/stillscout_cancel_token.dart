/// Cooperative cancellation for the extraction → scoring pipeline.
///
/// Long clips (10+ min) can take a while even with frame caps and
/// concurrency limits — creators should always be able to bail out
/// mid-scout without the app hanging or crashing.
class StillScoutCancelToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;

  void throwIfCancelled() {
    if (_cancelled) throw const StillScoutCancelledException();
  }
}

class StillScoutCancelledException implements Exception {
  const StillScoutCancelledException();

  @override
  String toString() => 'StillScout processing was cancelled.';
}
