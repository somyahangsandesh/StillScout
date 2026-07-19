import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/models/frame_score_metadata.dart';
import '../domain/stillscout_constants.dart';

/// Caches AI scores by `videoHash:timestampMs` so re-opening a previously
/// scouted video — or re-running a failed batch — never re-spends API calls.
///
/// The video "hash" is sampled (file size + first/last 64 KB), not a full
/// read, so this stays fast even for multi-GB 4K clips.
class StillScoutScoreCache {
  StillScoutScoreCache._();

  static const _sampleBytes = 64 * 1024;

  static Box? _box;

  static Future<Box> _openBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    if (Hive.isBoxOpen(StillScoutConstants.scoreCacheBoxName)) {
      _box = Hive.box(StillScoutConstants.scoreCacheBoxName);
      return _box!;
    }
    _box = await Hive.openBox(StillScoutConstants.scoreCacheBoxName);
    return _box!;
  }

  /// Cheap content fingerprint for a video file — stable across app
  /// restarts and re-picks of the same file, without reading it in full.
  static Future<String> videoHash(String videoPath) async {
    try {
      final file = File(videoPath);
      final length = await file.length();
      final digest = AccumulatorSink<Digest>();
      final input = md5.startChunkedConversion(digest);

      input.add(utf8.encode('len:$length'));

      final raf = await file.open();
      try {
        final headLen = length < _sampleBytes ? length : _sampleBytes;
        final head = await raf.read(headLen);
        input.add(head);

        if (length > _sampleBytes) {
          final tailStart = length - _sampleBytes;
          await raf.setPosition(tailStart);
          final tail = await raf.read(_sampleBytes);
          input.add(tail);
        }
      } finally {
        await raf.close();
      }

      input.close();
      return digest.events.single.toString();
    } catch (e) {
      debugPrint('[StillScoutScoreCache] Hash failed, using path fallback: $e');
      // Still namespaces cache entries sanely even if sampling fails (e.g.
      // restricted file access) — just loses cross-session reuse for this file.
      return md5.convert(utf8.encode(videoPath)).toString();
    }
  }

  static String _key(String videoHash, int timestampMs) =>
      '$videoHash:$timestampMs';

  static Future<FrameScoreMetadata?> get(
    String videoHash,
    int timestampMs,
  ) async {
    try {
      final box = await _openBox();
      final raw = box.get(_key(videoHash, timestampMs));
      if (raw is! Map) return null;
      return FrameScoreMetadata.fromJson(Map<String, dynamic>.from(raw));
    } catch (e) {
      debugPrint('[StillScoutScoreCache] get failed: $e');
      return null;
    }
  }

  static Future<void> put(
    String videoHash,
    int timestampMs,
    FrameScoreMetadata metadata,
  ) async {
    try {
      final box = await _openBox();
      await box.put(_key(videoHash, timestampMs), metadata.toJson());
    } catch (e) {
      debugPrint('[StillScoutScoreCache] put failed: $e');
    }
  }

  /// Clears all cached AI scores (Settings → Clear cache).
  static Future<void> clearAll() async {
    try {
      final box = await _openBox();
      await box.clear();
    } catch (e) {
      debugPrint('[StillScoutScoreCache] clearAll failed: $e');
    }
  }

  /// Bounds unbounded growth over the life of the app install.
  static Future<void> evictIfOversized({int maxEntries = 5000}) async {
    try {
      final box = await _openBox();
      if (box.length <= maxEntries) return;
      final excess = box.length - maxEntries;
      final staleKeys = box.keys.take(excess).toList();
      await box.deleteAll(staleKeys);
    } catch (e) {
      debugPrint('[StillScoutScoreCache] eviction failed: $e');
    }
  }
}

/// Minimal chunked-conversion sink used to MD5-hash sampled byte ranges
/// without holding the whole file in memory.
class AccumulatorSink<T> implements Sink<T> {
  final List<T> events = [];

  @override
  void add(T event) => events.add(event);

  @override
  void close() {}
}
