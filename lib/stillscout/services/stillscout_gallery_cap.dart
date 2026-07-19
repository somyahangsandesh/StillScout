import '../data/models/scored_frame.dart';
import '../domain/stillscout_constants.dart';

/// Caps the gallery/persistence list to [max] while always preferring
/// Gemini `isTopScout` frames over lower-ranked score fillers.
class StillScoutGalleryCap {
  StillScoutGalleryCap._();

  static List<ScoredFrame> cap(
    List<ScoredFrame> frames, {
    int max = StillScoutConstants.maxGalleryFrames,
  }) {
    if (frames.length <= max) {
      return List<ScoredFrame>.of(frames)
        ..sort((a, b) => b.score.compareTo(a.score));
    }

    final byScore = List<ScoredFrame>.of(frames)
      ..sort((a, b) => b.score.compareTo(a.score));
    final selected = <ScoredFrame>[];
    final selectedIds = <String>{};

    for (final frame in byScore) {
      if (!frame.isTopScout) continue;
      if (selected.length >= max) break;
      selected.add(frame);
      selectedIds.add(frame.frame.id);
    }

    for (final frame in byScore) {
      if (selected.length >= max) break;
      if (selectedIds.add(frame.frame.id)) {
        selected.add(frame);
      }
    }

    selected.sort((a, b) => b.score.compareTo(a.score));
    return selected;
  }
}
