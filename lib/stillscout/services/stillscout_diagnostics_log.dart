import 'dart:collection';

import 'package:flutter/foundation.dart';

/// In-memory ring buffer for release-safe diagnostics (no third-party SDK).
///
/// Entries are redacted: absolute paths are reduced to basenames.
/// Exposed via Settings → Copy diagnostics.
class StillScoutDiagnosticsLog {
  StillScoutDiagnosticsLog._();

  static const int capacity = 200;
  static final ListQueue<_Entry> _entries = ListQueue<_Entry>();

  /// Append a tagged event. Also mirrors to [debugPrint] in debug builds.
  static void log(String tag, String message) {
    final entry = _Entry(
      at: DateTime.now().toUtc(),
      tag: tag,
      message: _redact(message),
    );
    _entries.addLast(entry);
    while (_entries.length > capacity) {
      _entries.removeFirst();
    }
    if (kDebugMode) {
      debugPrint('[StillScout/$tag] ${entry.message}');
    }
  }

  /// Redacted multiline dump suitable for clipboard share.
  static String dump() {
    if (_entries.isEmpty) {
      return 'StillScout diagnostics (empty)\n';
    }
    final buf = StringBuffer('StillScout diagnostics (${_entries.length})\n');
    for (final e in _entries) {
      buf.writeln('${e.at.toIso8601String()} [${e.tag}] ${e.message}');
    }
    return buf.toString();
  }

  static void clear() => _entries.clear();

  static int get length => _entries.length;

  static String _redact(String message) {
    // Collapse absolute Unix/macOS paths to basename to avoid leaking dirs.
    return message.replaceAllMapped(
      RegExp(r'(?:/Users|/var|/private|/tmp)/[^\s:]+'),
      (m) {
        final full = m.group(0)!;
        final slash = full.lastIndexOf('/');
        return slash >= 0 ? full.substring(slash + 1) : full;
      },
    );
  }
}

class _Entry {
  const _Entry({required this.at, required this.tag, required this.message});
  final DateTime at;
  final String tag;
  final String message;
}
