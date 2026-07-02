import 'dart:io';

import 'package:image/image.dart' as img;

import '../data/models/extracted_frame.dart';
import '../domain/stillscout_constants.dart';

/// Removes near-duplicate frames from an extraction batch using average-hash
/// (aHash) perceptual hashing.
///
/// aHash is deliberately simple (no DCT needed like pHash) but effective at
/// collapsing runs of identical/near-identical frames from static shots or
/// paused playback — which is the main cost driver for both API spend and
/// gallery clutter on long clips.
///
/// Algorithm:
/// 1. Downscale each frame to 8×8 pixels, convert to greyscale.
/// 2. Compute the mean pixel value.
/// 3. Build a 64-bit hash where bit i = pixel[i] >= mean.
/// 4. Two frames are near-duplicates if their Hamming distance is ≤
///    [StillScoutConstants.dedupHammingThreshold].
///
/// Runs via [compute()] — designed to be called from an isolate.
class StillScoutFrameDedup {
  StillScoutFrameDedup._();

  /// Callable from [compute()]. Takes the raw frame list and returns a
  /// de-duplicated list, preserving the highest-quality representative
  /// (first occurrence) of each near-duplicate cluster.
  static List<ExtractedFrame> deduplicate(List<ExtractedFrame> frames) {
    if (frames.length <= 1) return frames;

    // Compute hash for each frame. Null means decoding failed — keep it in.
    final hashes = <String, Uint64?>{};
    for (final frame in frames) {
      hashes[frame.id] = _hashFile(frame.filePath);
    }

    final kept = <ExtractedFrame>[];
    for (int i = 0; i < frames.length; i++) {
      final current = frames[i];
      final currentHash = hashes[current.id];

      // If hashing failed, always keep the frame.
      if (currentHash == null) {
        kept.add(current);
        continue;
      }

      // Check if this frame is a near-duplicate of any already-kept frame
      // that is within the temporal window.
      bool isDuplicate = false;
      for (final candidate in kept.reversed) {
        final timeDiff = (current.timestampMs - candidate.timestampMs).abs();
        // Frames far enough apart in time can't be deduped, so stop early.
        if (timeDiff > StillScoutConstants.dedupWindowMs * 2) break;

        final candidateHash = hashes[candidate.id];
        if (candidateHash == null) continue;

        final distance = _hammingDistance(currentHash, candidateHash);
        if (distance <= StillScoutConstants.dedupHammingThreshold) {
          isDuplicate = true;
          break;
        }
      }

      if (!isDuplicate) kept.add(current);
    }

    return kept;
  }

  static Uint64? _hashFile(String path) {
    try {
      final bytes = File(path).readAsBytesSync();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      return _aHash(decoded);
    } catch (_) {
      return null;
    }
  }

  static Uint64 _aHash(img.Image image) {
    // Resize to 8×8 greyscale.
    final small = img.copyResize(image, width: 8, height: 8);
    final pixels = <int>[];
    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        final p = small.getPixel(x, y);
        pixels.add(_luma(p));
      }
    }

    final mean = pixels.reduce((a, b) => a + b) ~/ pixels.length;

    var hash = Uint64.zero;
    for (int i = 0; i < 64; i++) {
      if (pixels[i] >= mean) {
        hash = hash | Uint64.fromInt(1 << (i % 32), i >= 32 ? 1 : 0);
      }
    }
    return hash;
  }

  static int _luma(img.Pixel p) {
    // BT.601 luma coefficients.
    return (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round();
  }

  static int _hammingDistance(Uint64 a, Uint64 b) {
    final xorLo = a.lo ^ b.lo;
    final xorHi = a.hi ^ b.hi;
    return _popcount(xorLo) + _popcount(xorHi);
  }

  static int _popcount(int x) {
    // Brian Kernighan's algorithm.
    var n = x;
    var count = 0;
    while (n != 0) {
      n &= n - 1;
      count++;
    }
    return count;
  }
}

/// Minimal 64-bit integer helper — Dart's native `int` is 64-bit on VM but
/// we split hi/lo so bitwise ops are unambiguous across platforms.
class Uint64 {
  const Uint64(this.lo, this.hi);
  const Uint64.fromInt(this.lo, [this.hi = 0]);
  static const Uint64 zero = Uint64(0, 0);

  final int lo;
  final int hi;

  Uint64 operator |(Uint64 other) => Uint64(lo | other.lo, hi | other.hi);
}
