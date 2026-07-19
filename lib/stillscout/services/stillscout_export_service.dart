import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../data/models/scored_frame.dart';
import '../domain/stillscout_constants.dart';
import '../presentation/widgets/stillscout_crop_picker.dart';
import 'face_quality_detector.dart';
import 'stillscout_auto_polish.dart';
import 'stillscout_permissions.dart';

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
    bool applyPolish = false,
    FaceQualityDetector? faceDetector,
    String? precomputedPolishPath,
    BuildContext? permissionContext,
  }) async {
    try {
      if (!await _ensureGalleryAccess(permissionContext)) {
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

      if (!await File(path).exists()) {
        return ExportResult.failure('Could not prepare the export file.');
      }

      try {
        // Save the file directly — no Dart decode/re-encode, so colour
        // profiles (Display P3) and original JPEG quality are preserved.
        await _putFileInGallery(path);
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
    bool applyPolish = false,
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
        text: 'Scouted with StillScout — score ${frame.score >= 10.0 ? '10' : frame.score.toStringAsFixed(1)}/10',
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
    bool applyPolish = false,
    FaceQualityDetector? faceDetector,
    BuildContext? permissionContext,
  }) async {
    var succeeded = 0;
    var failed = 0;

    if (!await _ensureGalleryAccess(permissionContext)) {
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
        // Access already ensured for the batch.
        permissionContext: null,
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
    bool applyPolish = false,
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

  /// Save a file directly from its path — bypasses Dart decode/re-encode so
  /// the original JPEG bytes (including any Display-P3 ICC profile) reach the
  /// Photos library untouched. iOS handles EXIF orientation natively.
  static Future<void> _putFileInGallery(String filePath) async {
    try {
      await Gal.putImage(filePath, album: 'StillScout');
    } on GalException catch (e) {
      if (e.type == GalExceptionType.accessDenied) rethrow;
      // Album creation may fail on older iOS — retry without album name.
      await Gal.putImage(filePath);
    }
  }

  static Future<bool> _ensureGalleryAccess([BuildContext? context]) async {
    if (context != null && context.mounted) {
      return StillScoutPermissions.ensureGalleryWrite(context);
    }

    // Gal owns write access — READ_MEDIA_* / photos alone is not enough to save.
    if (await Gal.hasAccess(toAlbum: true)) return true;

    if (await Gal.requestAccess(toAlbum: true)) return true;
    return false;
  }

  static Future<({String path, bool nativeRes})> _resolveExportPath(
    ScoredFrame frame, {
    required bool isPro,
    StillScoutCropRatio? cropRatio,
    bool applyPolish = false,
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
      // Never reuse a preview polish cache when exporting Pro native-res
      // or after a crop — that would discard the higher-quality / cropped path.
      final cropApplied = targetRatio != null;
      final cached = precomputedPolishPath;
      final canUseCached = !isPro &&
          !cropApplied &&
          cached != null &&
          await File(cached).exists();
      if (canUseCached) {
        path = cached;
      } else {
        final polished = await StillScoutAutoPolish.polishWithFaceDetection(
          path,
          faceDetector: faceDetector,
        );
        if (polished != null && await File(polished).exists()) path = polished;
      }
    }
    // No re-encode for orientation baking — iOS Photos handles EXIF orientation
    // natively via Gal.putImage(path), and re-encoding via Dart's image library
    // strips Display-P3 ICC profiles causing the saved image to look different.

    return (path: path, nativeRes: nativeRes);
  }

  /// Copies the source file to a stable temp path for the share sheet.
  /// Raw bytes are copied without decode/re-encode to preserve the original
  /// colour profile (Display P3) and JPEG quality.
  static Future<String?> _writeShareableFile(
    String path,
    ScoredFrame frame,
  ) async {
    try {
      if (!await File(path).exists()) return null;
      final bytes = await File(path).readAsBytes();
      if (bytes.isEmpty) return null;
      final tempDir = await getTemporaryDirectory();
      final out =
          '${tempDir.path}/stillscout_share_${frame.frame.id}_${frame.frame.timestampMs}.jpg';
      await File(out).writeAsBytes(bytes, flush: true);
      return out;
    } catch (e) {
      if (kDebugMode) debugPrint('[Export] share file prep failed: $e');
      return null;
    }
  }

  static Future<({String path, bool nativeRes})> _sourcePath(
    ScoredFrame frame, {
    required bool isPro,
  }) async {
    if (!await File(frame.frame.filePath).exists()) {
      throw StateError('Frame file missing at ${frame.frame.filePath}');
    }
    if (!isPro) return (path: frame.frame.filePath, nativeRes: false);

    final videoPath = frame.frame.sourceVideoPath;
    if (videoPath.isEmpty || !await File(videoPath).exists()) {
      // Source video was moved/deleted since scouting — fall back to the
      // cached preview frame. Callers surface this via [nativeRes] so the
      // user isn't told they got a native-resolution export they didn't.
      return (path: frame.frame.filePath, nativeRes: false);
    }

    try {
      final tempDir = await getTemporaryDirectory();
      // Use a unique full file path so the iOS plugin doesn't map all exports
      // to the same video-name-based filename in the temp directory.
      final exportPath =
          '${tempDir.path}/stillscout_export_${frame.frame.id}_${frame.frame.timestampMs}.jpg';
      final highRes = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: exportPath,
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
