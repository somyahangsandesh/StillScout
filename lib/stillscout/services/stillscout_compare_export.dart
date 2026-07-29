import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models/scored_frame.dart';

/// Builds a shareable side-by-side PNG from two compared frames.
class StillScoutCompareExport {
  StillScoutCompareExport._();

  static String _scoreLabel(double score) =>
      score >= 10.0 ? '10' : score.toStringAsFixed(1);

  /// Renders frames A|B with scores and opens the native share sheet.
  /// Returns false when image decode or share fails.
  static Future<bool> shareSideBySide({
    required ScoredFrame frameA,
    required ScoredFrame frameB,
  }) async {
    try {
      final bytes = await _renderPng(frameA: frameA, frameB: frameB);
      if (bytes == null) return false;

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/stillscout_compare_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(path).writeAsBytes(bytes, flush: true);

      await Share.shareXFiles(
        [XFile(path)],
        text: 'StillScout compare — Frame A ${_scoreLabel(frameA.score)} vs '
            'Frame B ${_scoreLabel(frameB.score)}',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<Uint8List?> _renderPng({
    required ScoredFrame frameA,
    required ScoredFrame frameB,
  }) async {
    final decodedA = img.decodeImage(File(frameA.frame.filePath).readAsBytesSync());
    final decodedB = img.decodeImage(File(frameB.frame.filePath).readAsBytesSync());
    if (decodedA == null || decodedB == null) return null;

    const panelW = 540;
    const panelH = 960;
    const headerH = 56;
    const footerH = 72;
    const gap = 12;
    const pad = 16;
    final a = img.copyResize(decodedA, width: panelW, height: panelH);
    final b = img.copyResize(decodedB, width: panelW, height: panelH);

    final canvasW = pad * 2 + panelW * 2 + gap;
    final canvasH = pad * 2 + headerH + panelH + footerH;
    final canvas = img.Image(width: canvasW, height: canvasH);
    img.fill(canvas, color: img.ColorRgb8(8, 8, 10));

    _drawHeader(canvas, pad: pad, width: canvasW, headerH: headerH);
    final topY = pad + headerH;
    img.compositeImage(canvas, a, dstX: pad, dstY: topY);
    img.compositeImage(canvas, b, dstX: pad + panelW + gap, dstY: topY);

    final footerY = topY + panelH;
    _drawFooter(
      canvas,
      pad: pad,
      y: footerY,
      panelW: panelW,
      gap: gap,
      labelA: 'A · ${_scoreLabel(frameA.score)}',
      labelB: 'B · ${_scoreLabel(frameB.score)}',
      winner: frameA.score == frameB.score
          ? null
          : (frameA.score > frameB.score ? 'A' : 'B'),
    );

    return Uint8List.fromList(img.encodePng(canvas));
  }

  static void _drawHeader(img.Image canvas, {required int pad, required int width, required int headerH}) {
    img.drawString(
      canvas,
      'StillScout Compare',
      font: img.arial24,
      x: pad,
      y: pad + 12,
      color: img.ColorRgb8(245, 245, 247),
    );
  }

  static void _drawFooter(
    img.Image canvas, {
    required int pad,
    required int y,
    required int panelW,
    required int gap,
    required String labelA,
    required String labelB,
    required String? winner,
  }) {
    img.drawString(
      canvas,
      labelA,
      font: img.arial24,
      x: pad,
      y: y + 20,
      color: img.ColorRgb8(212, 175, 55),
    );
    img.drawString(
      canvas,
      labelB,
      font: img.arial24,
      x: pad + panelW + gap,
      y: y + 20,
      color: img.ColorRgb8(212, 175, 55),
    );
    if (winner != null) {
      img.drawString(
        canvas,
        'Frame $winner wins',
        font: img.arial24,
        x: pad,
        y: y + 44,
        color: img.ColorRgb8(160, 160, 170),
      );
    }
  }
}
