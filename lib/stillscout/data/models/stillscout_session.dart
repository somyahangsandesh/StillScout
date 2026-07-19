/// A persisted record of a single StillScout run.
///
/// Stored in Hive as a plain JSON map — same pattern as
/// [StillScoutScoreCache] to keep zero dependency on `hive_generator`
/// or `freezed`. All fields are nullable where optional.
class StillScoutSession {
  const StillScoutSession({
    required this.id,
    required this.videoPath,
    required this.createdAt,
    required this.frameCount,
    required this.topScore,
    this.topFrameThumbPath,
    this.videoDurationMs,
    this.processingTimeMs,
    this.topFrameSnapshots = const [],
    this.exportsUsed = 0,
    this.topPickFrameIds = const [],
  });

  /// Unique identifier — also the name of the persistent frame cache dir
  /// under `<appDocs>/stillscout_cache/<id>/`.
  final String id;

  /// Original source video path (may no longer exist if deleted by user).
  final String videoPath;

  final DateTime createdAt;

  /// Total extracted frames after de-duplication.
  final int frameCount;

  /// Composite score of the best frame (0.0–10.0, 1dp).
  final double topScore;

  /// Absolute path to the best frame thumbnail, living in the persistent
  /// cache dir — this is what the History grid renders.
  final String? topFrameThumbPath;

  final int? videoDurationMs;

  /// Wall-clock ms spent in extraction + scoring phases.
  final int? processingTimeMs;

  /// Full ranked [ScoredFrame] snapshots for History reopen (capped at
  /// [StillScoutConstants.maxFramesPerVideo]).
  final List<Map<String, dynamic>> topFrameSnapshots;

  /// Polished exports consumed from this scout (free tier cap).
  final int exportsUsed;

  /// Ordered frame IDs for the Top Picks carousel (matches live scout).
  final List<String> topPickFrameIds;

  StillScoutSession copyWith({
    String? id,
    String? videoPath,
    DateTime? createdAt,
    int? frameCount,
    double? topScore,
    String? topFrameThumbPath,
    int? videoDurationMs,
    int? processingTimeMs,
    List<Map<String, dynamic>>? topFrameSnapshots,
    int? exportsUsed,
    List<String>? topPickFrameIds,
  }) =>
      StillScoutSession(
        id: id ?? this.id,
        videoPath: videoPath ?? this.videoPath,
        createdAt: createdAt ?? this.createdAt,
        frameCount: frameCount ?? this.frameCount,
        topScore: topScore ?? this.topScore,
        topFrameThumbPath: topFrameThumbPath ?? this.topFrameThumbPath,
        videoDurationMs: videoDurationMs ?? this.videoDurationMs,
        processingTimeMs: processingTimeMs ?? this.processingTimeMs,
        topFrameSnapshots: topFrameSnapshots ?? this.topFrameSnapshots,
        exportsUsed: exportsUsed ?? this.exportsUsed,
        topPickFrameIds: topPickFrameIds ?? this.topPickFrameIds,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'videoPath': videoPath,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'frameCount': frameCount,
        'topScore': topScore,
        'topFrameThumbPath': topFrameThumbPath,
        'videoDurationMs': videoDurationMs,
        'processingTimeMs': processingTimeMs,
        'topFrameSnapshots': topFrameSnapshots,
        'exportsUsed': exportsUsed,
        'topPickFrameIds': topPickFrameIds,
      };

  factory StillScoutSession.fromJson(Map<dynamic, dynamic> json) {
    final snapshotsRaw = json['topFrameSnapshots'];
    final snapshots = <Map<String, dynamic>>[];
    if (snapshotsRaw is List) {
      for (final item in snapshotsRaw) {
        if (item is Map) {
          snapshots.add(Map<String, dynamic>.from(item));
        }
      }
    }
    return StillScoutSession(
      id: json['id'] as String? ?? '',
      videoPath: json['videoPath'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        json['createdAt'] as int? ?? 0,
      ),
      frameCount: json['frameCount'] as int? ?? 0,
      topScore: _parseTopScore(json['topScore']),
      topFrameThumbPath: json['topFrameThumbPath'] as String?,
      videoDurationMs: json['videoDurationMs'] as int?,
      processingTimeMs: json['processingTimeMs'] as int?,
      topFrameSnapshots: snapshots,
      exportsUsed: json['exportsUsed'] as int? ?? 0,
      topPickFrameIds: _parseStringList(json['topPickFrameIds']),
    );
  }

  static double _parseTopScore(Object? raw) {
    if (raw is double) return raw.clamp(0.0, 10.0);
    if (raw is int) return raw > 10 ? (raw / 10.0).clamp(0.0, 10.0) : raw.toDouble();
    if (raw is num) return raw > 10 ? (raw.toDouble() / 10.0).clamp(0.0, 10.0) : raw.toDouble();
    return 0.0;
  }

  static List<String> _parseStringList(Object? raw) {
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }
}
