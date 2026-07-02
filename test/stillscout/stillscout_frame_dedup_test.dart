import 'dart:io';

import 'package:stillscout/stillscout/data/models/extracted_frame.dart';
import 'package:stillscout/stillscout/services/stillscout_frame_dedup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

// ── helpers ──────────────────────────────────────────────────────────────────

Directory? _tmpDir;

Future<Directory> get tmpDir async {
  _tmpDir ??= await Directory.systemTemp.createTemp('dedup_test_');
  return _tmpDir!;
}

/// Writes a gradient JPEG and returns its path.
/// Two images with opposite gradients will have very different aHash values.
Future<String> _writeGradientJpeg(
  String name, {
  required bool leftToRight, // true = bright left / dark right; false = inverted
}) async {
  final dir = await tmpDir;
  final image = img.Image(width: 32, height: 32);
  for (int y = 0; y < 32; y++) {
    for (int x = 0; x < 32; x++) {
      final v = leftToRight ? (x * 8).clamp(0, 255) : ((31 - x) * 8).clamp(0, 255);
      image.setPixel(x, y, img.ColorRgb8(v, v, v));
    }
  }
  final bytes = img.encodeJpg(image, quality: 90);
  final file = File('${dir.path}/$name.jpg')..writeAsBytesSync(bytes);
  return file.path;
}

ExtractedFrame _frame(String path, int timestampMs) => ExtractedFrame(
      id: 'id_$timestampMs',
      filePath: path,
      timestampMs: timestampMs,
      width: 32,
      height: 32,
      sourceVideoPath: '/fake/video.mp4',
    );

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  tearDownAll(() async => _tmpDir?.delete(recursive: true));

  test('empty list returns empty', () {
    expect(StillScoutFrameDedup.deduplicate([]), isEmpty);
  });

  test('single frame always kept', () async {
    final path = await _writeGradientJpeg('single', leftToRight: true);
    final frames = [_frame(path, 0)];
    final result = StillScoutFrameDedup.deduplicate(frames);
    expect(result, hasLength(1));
  });

  test('two identical frames (same file) collapse to one', () async {
    // Exact same file → hamming distance 0 → deduped.
    final path = await _writeGradientJpeg('dup_a', leftToRight: true);
    final frames = [
      _frame(path, 0),
      _frame(path, 300), // within the dedup window
    ];
    final result = StillScoutFrameDedup.deduplicate(frames);
    expect(result, hasLength(1));
    expect(result.first.timestampMs, 0, reason: 'first occurrence is kept');
  });

  test('two visually very different frames are both kept', () async {
    // Opposite gradients → very different bits set → hamming distance >> threshold.
    final brightPath = await _writeGradientJpeg('diff_bright', leftToRight: true);
    final darkPath = await _writeGradientJpeg('diff_dark', leftToRight: false);
    final frames = [
      _frame(brightPath, 0),
      _frame(darkPath, 500),
    ];
    final result = StillScoutFrameDedup.deduplicate(frames);
    expect(result, hasLength(2));
  });

  test('frames outside the temporal window are NOT deduped even if similar', () async {
    // Use the same gradient file (identical hash) but far apart in time.
    final path = await _writeGradientJpeg('window', leftToRight: true);
    // Gap > dedupWindowMs * 2 (2000ms) → early break in the inner loop
    final frames = [
      _frame(path, 0),
      _frame(path, 5000), // far outside window
    ];
    // The dedup loop stops checking candidates far away, so both are kept.
    // (This is the designed tradeoff: we never dedup shots that are far apart,
    // because two identical static shots at 0s and 5s are likely intentional.)
    final result = StillScoutFrameDedup.deduplicate(frames);
    expect(result, hasLength(2));
  });

  test('corrupt file path is kept (graceful)', () {
    final frames = [
      _frame('/no/such/file.jpg', 0),
      _frame('/also/missing.jpg', 500),
    ];
    // Should not throw; both frames retained since hashing fails for both.
    final result = StillScoutFrameDedup.deduplicate(frames);
    expect(result, hasLength(2));
  });
}
