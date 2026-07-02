import 'dart:typed_data';

/// A single frame pulled from a source video at a specific timestamp.
class ExtractedFrame {
  const ExtractedFrame({
    required this.id,
    required this.filePath,
    required this.timestampMs,
    required this.width,
    required this.height,
    required this.sourceVideoPath,
    this.bytes,
  });

  final String id;
  final String filePath;
  final int timestampMs;
  final int width;
  final int height;

  /// Original video this frame was sampled from — needed at export time to
  /// re-extract a full-resolution still for Pro users.
  final String sourceVideoPath;
  final Uint8List? bytes;

  double get timestampSeconds => timestampMs / 1000.0;

  String get formattedTimestamp {
    final totalSeconds = timestampMs ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final tenths = (timestampMs % 1000) ~/ 100;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.$tenths';
  }

  ExtractedFrame copyWith({
    String? id,
    String? filePath,
    int? timestampMs,
    int? width,
    int? height,
    String? sourceVideoPath,
    Uint8List? bytes,
  }) {
    return ExtractedFrame(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      timestampMs: timestampMs ?? this.timestampMs,
      width: width ?? this.width,
      height: height ?? this.height,
      sourceVideoPath: sourceVideoPath ?? this.sourceVideoPath,
      bytes: bytes ?? this.bytes,
    );
  }
}
