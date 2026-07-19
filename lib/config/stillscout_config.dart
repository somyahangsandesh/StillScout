// ============================================================================
// stillscout_config.dart — Centralized configuration & API keys for StillScout
// ============================================================================
// Pass keys via --dart-define at build time, or create
// lib/config/secrets.local.dart (gitignored) following the template below.
//
// App Store release checklist:
//   - supabaseUrl + supabaseAnonKey (Gemini Flash proxy on edge recommended)
//   - revenueCatAppleApiKey (appl_…)
//   - Leave Gemini EMPTY in release unless ALLOW_DIRECT_AI_KEYS=true
//   - Legal URLs default to GitHub Pages (docs/legal/HOSTED_URLS.txt)
//
// Cloud AI path (AI Pro only): Gemini Flash via optional Supabase proxy
// or direct Gemini key (debug). Free users stay on Vision + heuristics.
// ============================================================================

import 'package:flutter/foundation.dart';

// ignore: uri_does_not_exist
import 'secrets.local.dart' if (dart.library.io) 'secrets.local.dart';
// On iOS/Android dart.library.html is false, so this always resolves to the
// committed stub (empty keys). A developer who wants live debug keys can add
// them to secrets.local.dart (StillScoutSecrets) instead.
// ignore: uri_does_not_exist
import '_secrets_debug_stub.dart' if (dart.library.html) 'secrets.debug.local.dart';

class StillScoutConfig {
  StillScoutConfig._();

  // ── Legal (App Store Guideline 3.1.2 + App Store Connect metadata) ────────
  // Live HTTPS copies of docs/legal/*.html on GitHub Pages.
  // Override with --dart-define when stillscout.app (or another domain) points
  // at the same Pages site.
  // See docs/legal/HOSTED_URLS.txt for the ASC paste list.
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue:
        'https://somyahangsandesh.github.io/StillScout/legal/privacy.html',
  );
  static const String termsOfUseUrl = String.fromEnvironment(
    'TERMS_OF_USE_URL',
    defaultValue:
        'https://somyahangsandesh.github.io/StillScout/legal/terms.html',
  );
  static const String supportUrl = String.fromEnvironment(
    'SUPPORT_URL',
    defaultValue:
        'https://somyahangsandesh.github.io/StillScout/legal/support.html',
  );
  static const String appleStandardEulaUrl =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

  /// Release builds never read client AI key material unless you explicitly
  /// pass `--dart-define=ALLOW_DIRECT_AI_KEYS=true` (emergency hotfix only).
  /// Combined with `kReleaseMode`, Dart AOT dead-code-eliminates secret reads
  /// so provider keys are not pulled into App Store binaries.
  static const bool allowDirectAiKeysInRelease = bool.fromEnvironment(
    'ALLOW_DIRECT_AI_KEYS',
    defaultValue: false,
  );

  static bool get _mayUseDirectAiKeys =>
      !kReleaseMode || allowDirectAiKeysInRelease;

  // ── Gemini Flash (sole cloud AI for AI Pro scoring) ───────────────────────
  static const String _geminiFromEnv =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static bool _isGeminiKey(String k) {
    final t = k.trim();
    if (t.isEmpty || t.contains('YOUR_')) return false;
    // Google AI Studio keys: legacy AIza… or newer AQ.… format.
    return t.startsWith('AIza') || t.startsWith('AQ.');
  }

  static String get geminiApiKey {
    if (!_mayUseDirectAiKeys) return '';
    if (_isGeminiKey(_geminiFromEnv)) return _geminiFromEnv.trim();
    // ignore: undefined_identifier
    const local = StillScoutSecrets.geminiApiKey;
    if (_isGeminiKey(local)) return local.trim();
    // ignore: undefined_identifier
    const debug = StillScoutDebugSecrets.geminiApiKey;
    if (_isGeminiKey(debug)) return debug.trim();
    return 'AIzaYOUR_GEMINI_API_KEY';
  }

  static bool get isGeminiConfigured =>
      _mayUseDirectAiKeys && _isGeminiKey(geminiApiKey);

  // ── RevenueCat (in-app purchases — iOS / App Store only) ──────────────────
  // PUBLIC SDK key only — appl_… or test_… (sandbox).
  // NEVER put sk_ secret keys in the app — those are server-side only.
  static const String _testStoreKey = 'test_zRmNZWtkMgDEoptCavDbAdhMXxw';

  static const String _rcAppleFromEnv =
      String.fromEnvironment('RC_APPLE_KEY', defaultValue: '');

  static bool _isRevenueCatPublicKey(String k) {
    final t = k.trim();
    if (t.isEmpty || t.contains('YOUR_')) return false;
    if (t.startsWith('sk_')) return false;
    return t.startsWith('appl_') || t.startsWith('test_');
  }

  static String get revenueCatAppleApiKey {
    if (_isRevenueCatPublicKey(_rcAppleFromEnv)) return _rcAppleFromEnv.trim();
    // ignore: undefined_identifier
    const local = StillScoutSecrets.revenueCatAppleApiKey;
    if (_isRevenueCatPublicKey(local)) return local.trim();
    // Never ship the shared sandbox key in release builds.
    if (kReleaseMode) return '';
    return _testStoreKey;
  }

  /// True when a real App Store key is configured (not just the test fallback).
  static bool get isRevenueCatConfigured =>
      _isRevenueCatPublicKey(revenueCatAppleApiKey);

  /// True when a production App Store public SDK key (`appl_`) is present.
  static bool get isRevenueCatStoreConfigured {
    final apple = revenueCatAppleApiKey.trim();
    return apple.startsWith('appl_') && !apple.contains('YOUR_');
  }

  /// Call once at startup to surface misconfiguration in debug/TestFlight logs.
  static void assertReleaseReadiness() {
    if (!kReleaseMode) return;

    if (!isSupabaseConfigured) {
      debugPrint(
        '[StillScoutConfig] WARNING: Supabase is not configured — '
        'AI Pro cloud scoring will not work in this release build.',
      );
    }
    if (!isRevenueCatStoreConfigured) {
      debugPrint(
        '[StillScoutConfig] WARNING: RevenueCat production appl_ key missing — '
        'IAP will be unavailable in this release build.',
      );
    }
    if (isGeminiConfigured) {
      debugPrint(
        '[StillScoutConfig] WARNING: Direct Gemini key is present in a release '
        'build. Remove it — use the Supabase edge proxy instead.',
      );
    }
  }

  /// Entitlement identifier — create in RevenueCat dashboard as "pro".
  /// Attach stillscout_pro_monthly + stillscout_pro_yearly products to it.
  /// Product branding in-app is **AI Pro**; the RC id stays `pro`.
  static const String rcEntitlementPro = 'pro';

  /// Alias for [rcEntitlementPro] — use when naming the AI Pro product.
  static const String rcEntitlementAiPro = rcEntitlementPro;

  /// User-facing product name for the Pro entitlement.
  static const String aiProDisplayName = 'AI Pro';

  /// User-facing cloud model name — avoid pinning a patch version in UI copy.
  static const String geminiModelDisplayName = 'Gemini Flash';

  /// Primary offering identifier in RevenueCat (fallback: default, stillscout_main).
  static const String rcOfferingIdentifier = 'stillscout_main';

  // ── App Store / Play Console product IDs ──────────────────────────────────
  static const String rcProMonthlyId = 'stillscout_pro_monthly';
  static const String rcProYearlyId = 'stillscout_pro_yearly';

  static const List<String> allProductIds = [
    rcProMonthlyId,
    rcProYearlyId,
  ];

  // ── Supabase (vision-score Edge Function proxy) ───────────────────────────
  // Project URL and anon/public key — safe to ship in client apps.
  // The Gemini API key lives as a Supabase Secret and never leaves the server.
  //
  // Find both values at: Supabase dashboard → Project Settings → API.
  static const String _supabaseUrlFromEnv =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String _supabaseAnonFromEnv =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static bool _isSupabaseUrl(String v) {
    final t = v.trim();
    return t.startsWith('https://') && t.contains('.supabase.co');
  }

  static bool _isSupabaseAnonKey(String v) {
    final t = v.trim();
    // Supabase anon keys are either long JWTs (eyJ…) or newer sb_publishable_ keys
    return t.isNotEmpty &&
        !t.contains('YOUR_') &&
        (t.startsWith('eyJ') || t.startsWith('sb_publishable_'));
  }

  static String get supabaseUrl {
    if (_isSupabaseUrl(_supabaseUrlFromEnv)) return _supabaseUrlFromEnv.trim();
    // ignore: undefined_identifier
    const local = StillScoutSecrets.supabaseUrl;
    if (_isSupabaseUrl(local)) return local.trim();
    return '';
  }

  static String get supabaseAnonKey {
    if (_isSupabaseAnonKey(_supabaseAnonFromEnv)) {
      return _supabaseAnonFromEnv.trim();
    }
    // ignore: undefined_identifier
    const local = StillScoutSecrets.supabaseAnonKey;
    if (_isSupabaseAnonKey(local)) return local.trim();
    return '';
  }

  /// True when the Supabase proxy is fully configured (URL + anon key present).
  static bool get isSupabaseConfigured =>
      _isSupabaseUrl(supabaseUrl) && _isSupabaseAnonKey(supabaseAnonKey);

  // ── App constants ──────────────────────────────────────────────────────────
  static const String appName = 'StillScout';
  static const String appVersion = '1.0.0';

  /// Must match Xcode + RevenueCat iOS app registration.
  static const String iosBundleId = 'com.stillscout.stillscout';

  /// Apple Developer Team ID (Certificates, Identifiers & Profiles).
  static const String appleTeamId = 'S8WFJFA85T';

  /// App Store Connect API Key ID used for TestFlight uploads
  /// (`tool/upload_testflight.sh` / `secrets.asc.env`).
  static const String appStoreConnectApiKeyId = '725F75L52R';
}
