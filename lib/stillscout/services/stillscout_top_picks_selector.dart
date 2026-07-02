import '../data/models/scored_frame.dart';
import '../domain/stillscout_constants.dart';

/// Selects up to [count] Top-Pick frames with diversity enforcement.
///
/// Naively taking the top-N scored frames shows the podium filled with
/// near-identical consecutive shots (same expression, same composition)
/// when the source footage has a run of similar frames that all scored high.
///
/// This selector uses a two-constraint diversity filter:
/// 1. **Temporal gap**: each pick must be ≥ [StillScoutConstants.topPicksMinGapMs]
///    apart from every previously selected pick.
/// 2. If the temporal gap can't be satisfied for [count] frames (e.g. a 2s
///    clip), it relaxes to a halved gap so the carousel is still populated.
class StillScoutTopPicksSelector {
  StillScoutTopPicksSelector._();

  /// Returns at most [count] diverse top picks from a pre-ranked [frames]
  /// list (highest score first). [frames] is assumed already sorted.
  static List<ScoredFrame> select(
    List<ScoredFrame> frames, {
    int count = StillScoutConstants.topPicksCount,
  }) {
    if (frames.isEmpty) return [];
    if (frames.length <= count) return List.of(frames);

    final picks = <ScoredFrame>[];

    // Try with the full gap first, relax if we can't fill [count].
    for (final minGap in [
      StillScoutConstants.topPicksMinGapMs,
      StillScoutConstants.topPicksMinGapMs ~/ 2,
      0, // last-resort: no gap constraint
    ]) {
      picks.clear();
      for (final frame in frames) {
        if (picks.length >= count) break;
        if (_satisfiesGap(frame, picks, minGap)) {
          picks.add(frame);
        }
      }
      if (picks.length >= count) break;
    }

    return picks;
  }

  static bool _satisfiesGap(
    ScoredFrame candidate,
    List<ScoredFrame> picks,
    int minGapMs,
  ) {
    if (minGapMs == 0) return true;
    for (final pick in picks) {
      final gap = (candidate.frame.timestampMs - pick.frame.timestampMs).abs();
      if (gap < minGapMs) return false;
    }
    return true;
  }
}
