#!/usr/bin/env dart
// Pre-flight: verify secrets.local.dart is safe for an App Store archive.
// Usage: dart run tool/check_release_secrets.dart
//
// Only Supabase + RevenueCat public keys belong in store builds.
// The Gemini API key must be empty — it lives as a Supabase Secret on the edge.

import 'dart:io';

void main() {
  final file = File('lib/config/secrets.local.dart');
  if (!file.existsSync()) {
    stderr.writeln(
      'ERROR: lib/config/secrets.local.dart missing. '
      'Copy secrets.local.example.dart and fill Supabase + RevenueCat only.',
    );
    exit(1);
  }

  final text = file.readAsStringSync();

  // geminiApiKey must be empty in store builds — key lives in Supabase Secret.
  final geminiMatch = RegExp(
    r"static const String geminiApiKey\s*=\s*'([^']*)'",
  ).firstMatch(text);
  final geminiValue = geminiMatch?.group(1)?.trim() ?? '';

  final supabaseUrl = RegExp(
    r"static const String supabaseUrl\s*=\s*'([^']*)'",
  ).firstMatch(text)?.group(1)?.trim() ?? '';
  final supabaseAnon = RegExp(
    r"static const String supabaseAnonKey\s*=\s*'([^']*)'",
  ).firstMatch(text)?.group(1)?.trim() ?? '';
  final rcApple = RegExp(
    r"static const String revenueCatAppleApiKey\s*=\s*'([^']*)'",
  ).firstMatch(text)?.group(1)?.trim() ?? '';

  var failed = false;

  if (geminiValue.isNotEmpty) {
    stderr.writeln(
      'ERROR: geminiApiKey must be empty in store builds — '
      'it must live as a Supabase Secret, never in the binary.',
    );
    failed = true;
  }
  if (!supabaseUrl.startsWith('https://') || !supabaseUrl.contains('supabase')) {
    stderr.writeln('ERROR: supabaseUrl must be a real https://….supabase.co URL.');
    failed = true;
  }
  if (supabaseAnon.isEmpty || supabaseAnon.contains('YOUR_')) {
    stderr.writeln('ERROR: supabaseAnonKey is required for production scoring.');
    failed = true;
  }
  if (!rcApple.startsWith('appl_')) {
    stderr.writeln(
      'ERROR: revenueCatAppleApiKey must be a production appl_… public SDK key.',
    );
    failed = true;
  }

  if (failed) {
    stderr.writeln(
      'Fix secrets.local.dart (see secrets.local.example.dart), then re-run.',
    );
    exit(1);
  }

  stdout.writeln('OK: secrets.local.dart is ready for an App Store archive.');
}
