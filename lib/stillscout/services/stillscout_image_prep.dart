import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

import '../domain/stillscout_constants.dart';

/// Resizes + re-encodes extracted frames for vision-LLM upload.
///
/// Designed to run inside an isolate via `compute()` so JPEG decode/encode
/// for a whole batch never blocks the UI thread — a single hop for the
/// entire pending list, rather than one isolate spawn per frame.
class StillScoutImagePrep {
  StillScoutImagePrep._();

  /// Returns a map of original file path → base64-encoded, downsized JPEG
  /// ready to embed as a data URI. Paths that fail to decode are omitted
  /// (caller treats a missing entry as "needs heuristic fallback").
  static Map<String, String> prepareUploadPayloads(List<String> filePaths) {
    final payloads = <String, String>{};
    for (final path in filePaths) {
      final payload = _prepareOne(path);
      if (payload != null) payloads[path] = payload;
    }
    return payloads;
  }

  static String? _prepareOne(String path) {
    try {
      final bytes = File(path).readAsBytesSync();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final resized = decoded.width > StillScoutConstants.llmUploadWidth
          ? img.copyResize(
              decoded,
              width: StillScoutConstants.llmUploadWidth,
              interpolation: img.Interpolation.average,
            )
          : decoded;

      final jpg = img.encodeJpg(
        resized,
        quality: StillScoutConstants.llmUploadJpegQuality,
      );
      return base64Encode(jpg);
    } catch (_) {
      return null;
    }
  }
}
