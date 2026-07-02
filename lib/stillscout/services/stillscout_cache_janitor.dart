import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/stillscout_constants.dart';

/// Manages the persistent frame cache under
/// `<appDocs>/stillscout_cache/<sessionId>/`.
///
/// Session deletion is handled by [deleteSession] when the session repository
/// evicts old scouts. This janitor only removes **orphan** cache folders that
/// no longer have a Hive session — it never deletes active session frames.
class StillScoutCacheJanitor {
  StillScoutCacheJanitor._();

  static Future<Directory> get _cacheRoot async {
    final docs = await getApplicationDocumentsDirectory();
    final root = Directory('${docs.path}/stillscout_cache');
    if (!await root.exists()) await root.create(recursive: true);
    return root;
  }

  static Future<Directory> sessionDir(String sessionId) async {
    final root = await _cacheRoot;
    final dir = Directory('${root.path}/$sessionId');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<void> deleteSession(String sessionId) async {
    try {
      final root = await _cacheRoot;
      final dir = Directory('${root.path}/$sessionId');
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CacheJanitor] Failed to delete session $sessionId: $e');
      }
    }
  }

  /// Total bytes used by all session cache folders.
  static Future<int> totalBytes() async {
    try {
      final root = await _cacheRoot;
      if (!await root.exists()) return 0;
      var total = 0;
      await for (final entry in root.list()) {
        if (entry is Directory) {
          total += await _directoryBytes(entry);
        }
      }
      return total;
    } catch (e) {
      if (kDebugMode) debugPrint('[CacheJanitor] totalBytes failed: $e');
      return 0;
    }
  }

  /// Removes cache directories that no longer belong to a saved session.
  /// Active [activeSessions] IDs are always preserved.
  static Future<void> evict({required List<String> activeSessions}) async {
    try {
      final root = await _cacheRoot;
      if (!await root.exists()) return;

      final active = activeSessions.toSet();
      await for (final entry in root.list()) {
        if (entry is! Directory) continue;
        final id = entry.uri.pathSegments.last;
        if (id.isEmpty || active.contains(id)) continue;
        await entry.delete(recursive: true);
        if (kDebugMode) debugPrint('[CacheJanitor] Removed orphan cache $id');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[CacheJanitor] Eviction error: $e');
    }
  }

  /// Deletes the oldest [sessionIdsOldestFirst] cache dirs until total size
  /// is at or below [StillScoutConstants.maxCacheSizeBytes].
  /// Returns session IDs whose on-disk cache was removed (Hive rows still
  /// need deletion by the session repository).
  static Future<List<String>> evictBySizeBudget({
    required List<String> sessionIdsOldestFirst,
    int? maxBytes,
  }) async {
    final budget = maxBytes ?? StillScoutConstants.maxCacheSizeBytes;
    final evicted = <String>[];

    try {
      var total = await totalBytes();
      if (total <= budget) return evicted;

      for (final sessionId in sessionIdsOldestFirst) {
        if (total <= budget) break;

        final root = await _cacheRoot;
        final dir = Directory('${root.path}/$sessionId');
        if (!await dir.exists()) continue;

        final bytes = await _directoryBytes(dir);
        await dir.delete(recursive: true);
        total -= bytes;
        evicted.add(sessionId);
        if (kDebugMode) {
          debugPrint(
            '[CacheJanitor] Size eviction removed $sessionId '
            '(${bytes ~/ 1024} KB, total now ~${total ~/ 1024} KB)',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[CacheJanitor] Size eviction error: $e');
    }

    return evicted;
  }

  static Future<int> _directoryBytes(Directory dir) async {
    var total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (_) {}
      }
    }
    return total;
  }
}
