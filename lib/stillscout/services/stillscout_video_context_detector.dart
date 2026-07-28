import '../domain/stillscout_constants.dart';

/// Shared heuristics for inferring [StillScoutVideoContext] from Vision scores.
///
/// Used before cloud batch scoring (so prompts match footage) and after scoring
/// (to re-rank gallery when the user left the picker on Auto).
class StillScoutVideoContextDetector {
  StillScoutVideoContextDetector._();

  /// Analyses per-frame axis scores to infer the best-fit video context.
  ///
  /// Only returns non-[StillScoutVideoContext.auto] when signals are strong.
  /// Event is never auto-detected — creators must pick it explicitly.
  static StillScoutVideoContext detectFromAxisScores(
    Iterable<({int openEyesScore, int compositionScore, int blurScore})> sample,
  ) {
    final list = sample.toList();
    if (list.isEmpty) return StillScoutVideoContext.auto;
    final n = list.length;

    final meanEyes =
        list.map((f) => f.openEyesScore.toDouble()).reduce((a, b) => a + b) /
            n;
    final meanComposition = list
            .map((f) => f.compositionScore.toDouble())
            .reduce((a, b) => a + b) /
        n;
    final blurValues =
        list.map((f) => f.blurScore.toDouble()).toList(growable: false);
    final meanBlur = blurValues.reduce((a, b) => a + b) / n;
    final blurVariance = blurValues
            .map((b) => (b - meanBlur) * (b - meanBlur))
            .reduce((a, b) => a + b) /
        n;

    // Portrait / selfie: strong face signal across the sample.
    if (meanEyes > 60) return StillScoutVideoContext.portrait;

    // Landscape: good composition + no dominant faces.
    if (meanComposition > 65 && meanEyes < 45) {
      return StillScoutVideoContext.landscape;
    }

    // Action: blur variance signals mixed-motion footage.
    if (blurVariance > 320 && meanBlur < 68) {
      return StillScoutVideoContext.action;
    }

    return StillScoutVideoContext.auto;
  }
}
