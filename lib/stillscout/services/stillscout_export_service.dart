import 'dart:io';

import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../data/models/scored_frame.dart';
import '../domain/stillscout_constants.dart';
import '../presentation/widgets/stillscout_crop_picker.dart';
import 'face_quality_detector.dart';
import 'stillscout_auto_polish.dart';

enum StillScoutExportAction { saveToGallery, share }

enum ExportOutcome { success, permissionDenied, failure, cancelled }

class ExportResult {
  const ExportResult({
    required this.outcome,
    this.path,
    this.message,
    this.nativeResUsed = true,
  });

  final ExportOutcome outcome;
  final String? path;
  final String? message;

  /// For Pro exports: whether the original source video was still available
  /// to re-sample at full resolution. If false, the export silently fell
  /// back to the (lower-res) cached preview frame — the UI should surface
  /// this so users aren't surprised by a soft-quality "native res" save.
  final bool nativeResUsed;

  bool get isSuccess => outcome == ExportOutcome.success;

  factory ExportResult.success(String path, {bool nativeResUsed = true}) =>
      ExportResult(
        outcome: ExportOutcome.success,
        path: path,
        nativeResUsed: nativeResUsed,
      );

  factory ExportResult.permissionDenied() => const ExportResult(
        outcome: ExportOutcome.permissionDenied,
        message: 'Photo library access is required to save exports.',
      );

  factory ExportResult.failure(String message) =>
      ExportResult(outcome: ExportOutcome.failure, message: message);
}

/// Turns a scored frame into a real exported asset — save to camera roll or
/// hand off to the native share sheet.
class StillScoutExportService {
  StillScoutExportService._();

  static Future<ExportResult> saveToGallery(
    ScoredFrame frame, {
    required bool isPro,
    StillScoutCropRatio? cropRatio,
    bool applyPolish = true,
    FaceQualityDetector? faceDetector,
    String? precomputedPolishPath,
  }) async {
    try {
      if (!await _ensureGalleryAccess()) {
        return ExportResult.permissionDenied();
      }

      final resolved = await _resolveExportPath(
        frame,
        isPro: isPro,
        cropRatio: cropRatio,
        applyPolish: applyPolish,
        faceDetector: faceDetector,
        precomputedPolishPath: precomputedPolishPath,
      );
      final path = resolved.path;

      final bytes = await _materializeJpegBytes(path);
      if (bytes == null || bytes.isEmpty) {
        return ExportResult.failure('Could not prepare the export file.');
      }

      try {
        final name =
            'stillscout_${frame.frame.id}_${frame.frame.timestampMs}';
        await _putBytesInGallery(bytes, name: name);
      } on GalException catch (e) {
        if (e.type == GalExceptionType.accessDenied) {
          return ExportResult.permissionDenied();
        }
        return ExportResult.failure(e.type.message);
      }

      return ExportResult.success(path, nativeResUsed: resolved.nativeRes);
    } on GalException catch (e) {
      if (e.type == GalExceptionType.accessDenied) {
        return ExportResult.permissionDenied();
      }
      return ExportResult.failure(e.type.message);
    } catch (e) {
      if (kDebugMode) debugPrint('[Export] save failed: $e');
      return ExportResult.failure('Could not save to your photo library.');
    }
  }

  static Future<ExportResult> share(
    ScoredFrame frame, {
    required bool isPro,
    StillScoutCropRatio? cropRatio,
    bool applyPolish = true,
    FaceQualityDetector? faceDetector,
    String? precomputedPolishPath,
    Rect? shareOrigin,
  }) async {
    try {
      final resolved = await _resolveExportPath(
        frame,
        isPro: isPro,
        cropRatio: cropRatio,
        applyPolish: applyPolish,
        faceDetector: faceDetector,
        precomputedPolishPath: precomputedPolishPath,
      );
      final path = resolved.path;

      final sharePath = await _writeShareableFile(path, frame);
      if (sharePath == null) {
        return ExportResult.failure('Could not prepare the export file.');
      }

      final result = await Share.shareXFiles(
        [XFile(sharePath, mimeType: 'image/jpeg')],
        text: 'Scouted with StillScout — score ${frame.score}/100',
        sharePositionOrigin: shareOrigin,
      );
      if (result.status == ShareResultStatus.dismissed) {
        return const ExportResult(outcome: ExportOutcome.cancelled);
      }
      return ExportResult.success(path, nativeResUsed: resolved.nativeRes);
    } catch (e) {
      if (kDebugMode) debugPrint('[Export] share failed: $e');
      return ExportResult.failure('Could not open the share sheet.');
    }
  }

  static Future<BatchExportSummary> saveBatchToGallery(
    List<ScoredFrame> frames, {
    required bool isPro,
    bool applyPolish = true,
    FaceQualityDetector? faceDetector,
  }) async {
    var succeeded = 0;
    var failed = 0;

    if (!await _ensureGalleryAccess()) {
      return BatchExportSummary(
        succeeded: 0,
        failed: frames.length,
        permissionDenied: true,
      );
    }

    for (final frame in frames) {
      final result = await saveToGallery(
        frame,
        isPro: isPro,
        applyPolish: applyPolish,
        faceDetector: faceDetector,
      );
      if (result.isSuccess) {
        succeeded++;
      } else {
        failed++;
      }
    }
    return BatchExportSummary(succeeded: succeeded, failed: failed);
  }

  static Future<ExportResult> shareBatch(
    List<ScoredFrame> frames, {
    required bool isPro,
    bool applyPolish = true,
    FaceQualityDetector? faceDetector,
    Rect? shareOrigin,
  }) async {
    try {
      final resolved = await Future.wait(
        frames.map(
          (f) => _resolveExportPath(
            f,
            isPro: isPro,
            applyPolish: applyPolish,
            faceDetector: faceDetector,
          ),
        ),
      );
      final existing = <String>[];
      for (final r in resolved) {
        if (await File(r.path).exists()) existing.add(r.path);
      }
      if (existing.isEmpty) {
        return ExportResult.failure('Could not prepare export files.');
      }
      final result = await Share.shareXFiles(
        existing.map((p) => XFile(p, mimeType: 'image/jpeg')).toList(growable: false),
        text: 'Scouted ${frames.length} frames with StillScout',
        sharePositionOrigin: shareOrigin,
      );
      if (result.status == ShareResultStatus.dismissed) {
        return const ExportResult(outcome: ExportOutcome.cancelled);
      }
      return ExportResult.success(existing.first);
    } catch (e) {
      return ExportResult.failure('Could not open the share sheet.');
    }
  }

  static Future<void> _putBytesInGallery(
    Uint8List bytes, {
    required String name,
  }) async {
    try {
      await Gal.putImageBytes(bytes, album: 'StillScout', name: name);
    } on GalException catch (e) {
      if (e.type == GalExceptionType.accessDenied) rethrow;
      await Gal.putImageBytes(bytes, name: name);
    }
  }

  static Future<bool> _ensureGalleryAccess() async {
    // Gal owns write access — READ_MEDIA_* / photos alone is not enough to save.
    if (await Gal.hasAccess(toAlbum: true)) return true;

    if (Platform.isAndroid) {
      final storage = await Permission.storage.request();
      if (storage.isGranted && await Gal.hasAccess(toAlbum: true)) return true;
    }

    if (await Gal.requestAccess(toAlbum: true)) return true;

    if (Platform.isAndroid) {
      final storage = await Permission.storage.status;
      return storage.isGranted;
    }
    return false;
  }

  static Future<({String path, bool nativeRes})> _resolveExportPath(
    ScoredFrame frame, {
    required bool isPro,
    StillScoutCropRatio? cropRatio,
    bool applyPolish = true,
    FaceQualityDetector? faceDetector,
    String? precomputedPolishPath,
  }) async {
    final source = await _sourcePath(frame, isPro: isPro);
    var path = source.path;
    final nativeRes = source.nativeRes;

    final targetRatio = cropRatio?.ratio;
    if (targetRatio != null) {
      try {
        final bytes = await File(path).readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          final oriented = img.bakeOrientation(img.Image.from(decoded));
          final cropped = centerCropImage(oriented, targetRatio);
          final tempDir = await getTemporaryDirectory();
          path =
              '${tempDir.path}/stillscout_crop_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await File(path).writeAsBytes(
            img.encodeJpg(cropped, quality: 95),
            flush: true,
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[Export] Crop failed, using uncropped frame: $e');
        }
      }
    }

    if (applyPolish) {
      final cached = precomputedPolishPath;
      if (cached != null && await File(cached).exists()) {
        path = cached;
      } else {
        final polished = await StillScoutAutoPolish.polishWithFaceDetection(
          path,
          faceDetector: faceDetector,
        );
        if (polished != null && await File(polished).exists()) path = polished;
      }
    } else {
      path = await _bakeOrientationToFile(path);
    }

    return (path: path, nativeRes: nativeRes);
  }

  /// Re-encodes with EXIF orientation applied so gallery apps show the full frame.
  static Future<String> _bakeOrientationToFile(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return path;
      final oriented = img.bakeOrientation(img.Image.from(decoded));
      final tempDir = await getTemporaryDirectory();
      final out =
          '${tempDir.path}/stillscout_orient_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(out).writeAsBytes(
        img.encodeJpg(oriented, quality: 95),
        flush: true,
      );
      return out;
    } catch (_) {
      return path;
    }
  }

  static Future<Uint8List?> _materializeJpegBytes(String path) async {
    try {
      if (!await File(path).exists()) return null;
      final bytes = await File(path).readAsBytes();
      if (bytes.isEmpty) return null;
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;
      final oriented = img.bakeOrientation(img.Image.from(decoded));
      return Uint8List.fromList(img.encodeJpg(oriented, quality: 95));
    } catch (e) {
      if (kDebugMode) debugPrint('[Export] materialize failed: $e');
      return null;
    }
  }

  static Future<String?> _writeShareableFile(
    String path,
    ScoredFrame frame,
  ) async {
    final bytes = await _materializeJpegBytes(path);
    if (bytes == null || bytes.isEmpty) return null;
    final tempDir = await getTemporaryDirectory();
    final out =
        '${tempDir.path}/stillscout_share_${frame.frame.id}_${frame.frame.timestampMs}.jpg';
    await File(out).writeAsBytes(bytes, flush: true);
    return out;
  }

  static Future<({String path, bool nativeRes})> _sourcePath(
    ScoredFrame frame, {
    required bool isPro,
  }) async {
    if (!await File(frame.frame.filePath).exists()) {
      throw StateError('Frame file missing at ${frame.frame.filePath}');
    }
    if (!isPro) return (path: frame.frame.filePath, nativeRes: true);

    final videoPath = frame.frame.sourceVideoPath;
    if (videoPath.isEmpty || !await File(videoPath).exists()) {
      // Source video was moved/deleted since scouting — fall back to the
      // cached preview frame. Callers surface this via [nativeRes] so the
      // user isn't told they got a native-resolution export they didn't.
      return (path: frame.frame.filePath, nativeRes: false);
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final highRes = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: tempDir.path,
        timeMs: frame.frame.timestampMs,
        imageFormat: ImageFormat.JPEG,
        quality: StillScoutConstants.proExportJpegQuality,
      );
      if (highRes == null) {
        return (path: frame.frame.filePath, nativeRes: false);
      }
      return (path: highRes, nativeRes: true);
    } catch (_) {
      return (path: frame.frame.filePath, nativeRes: false);
    }
  }
}

class BatchExportSummary {
  const BatchExportSummary({
    required this.succeeded,
    required this.failed,
    this.permissionDenied = false,
  });

  final int succeeded;
  final int failed;
  final bool permissionDenied;

  bool get hasAnySuccess => succeeded > 0;
}
