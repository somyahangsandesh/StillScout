// ============================================================================
// stillscout_config.dart — Centralized configuration & API keys for StillScout
// ============================================================================
// Pass keys via --dart-define at build time, or create
// lib/config/secrets.local.dart (gitignored) following the template below.
//
// Example secrets.local.dart:
//   class StillScoutSecrets {
//     // AI Vision cascade (add any you have — app uses all free tiers in order)
//     static const String groqApiKey    = 'gsk_...';   // console.groq.com
//     static const String geminiApiKey  = 'AIza...';   // aistudio.google.com
//     static const String grokApiKey    = 'xai-...';   // console.x.ai
//     static const String openAiApiKey  = 'sk-...';    // platform.openai.com
//     // RevenueCat
//     static const String revenueCatAppleApiKey  = 'appl_...';
//     static const String revenueCatGoogleApiKey = 'goog_...';
//   }
//
// The cascade priority is: Groq → Gemini → Grok → OpenAI → on-device ML Kit.
// You only need ONE key to get AI scoring — the rest are optional redundancy.
// ============================================================================

// ignore: uri_does_not_exist
import 'secrets.local.dart' if (dart.library.io) 'secrets.local.dart';

class StillScoutConfig {
  StillScoutConfig._();

  // ── Groq (Priority 1 — free tier, fastest, llama-4-scout vision) ──────────
  static const String _groqFromEnv =
      String.fromEnvironment('GROQ_API_KEY', defaultValue: '');

  static bool _isGroqKey(String k) {
    final t = k.trim();
    return t.isNotEmpty && t.startsWith('gsk_') && !t.contains('YOUR_');
  }

  static String get groqApiKey {
    if (_isGroqKey(_groqFromEnv)) return _groqFromEnv.trim();
    // ignore: undefined_identifier
    const local = StillScoutSecrets.groqApiKey;
    if (_isGroqKey(local)) return local.trim();
    return 'gsk_YOUR_GROQ_API_KEY';
  }

  static bool get isGroqConfigured => _isGroqKey(groqApiKey);

  // ── Gemini Flash (Priority 2 — free tier, most generous quota) ────────────
  static const String _geminiFromEnv =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static bool _isGeminiKey(String k) {
    final t = k.trim();
    if (t.isEmpty || t.contains('YOUR_')) return false;
    // Google AI Studio keys: legacy AIza… or newer AQ.… format.
    return t.startsWith('AIza') || t.startsWith('AQ.');
  }

  static String get geminiApiKey {
    if (_isGeminiKey(_geminiFromEnv)) return _geminiFromEnv.trim();
    // ignore: undefined_identifier
    const local = StillScoutSecrets.geminiApiKey;
    if (_isGeminiKey(local)) return local.trim();
    return 'AIzaYOUR_GEMINI_API_KEY';
  }

  static bool get isGeminiConfigured => _isGeminiKey(geminiApiKey);

  // ── xAI Grok (Priority 3 — free tier, OpenAI-compatible) ─────────────────
  static const String _grokFromEnv =
      String.fromEnvironment('GROK_API_KEY', defaultValue: '');

  static bool _isGrokKey(String k) {
    final t = k.trim();
    return t.isNotEmpty && t.startsWith('xai-') && !t.contains('YOUR_');
  }

  static String get grokApiKey {
    if (_isGrokKey(_grokFromEnv)) return _grokFromEnv.trim();
    // ignore: undefined_identifier
    const local = StillScoutSecrets.grokApiKey;
    if (_isGrokKey(local)) return local.trim();
    return 'xai-YOUR_GROK_API_KEY';
  }

  static bool get isGrokConfigured => _isGrokKey(grokApiKey);

  // ── OpenAI GPT-4o-mini (Priority 4 — paid fallback) ──────────────────────
  static const String _openAiFromEnv =
      String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');

  static bool _isOpenAiKey(String key) {
    final k = key.trim();
    return k.isNotEmpty && k.startsWith('sk-') && !k.contains('YOUR_');
  }

  static String get openAiApiKey {
    if (_isOpenAiKey(_openAiFromEnv)) return _openAiFromEnv.trim();
    // ignore: undefined_identifier
    const local = StillScoutSecrets.openAiApiKey;
    if (_isOpenAiKey(local)) return local.trim();
    return 'sk-YOUR_OPENAI_API_KEY';
  }

  static bool get isOpenAiConfigured => _isOpenAiKey(openAiApiKey);

  /// Vision model used for AI frame scoring.
  static const String visionModel = 'gpt-4o-mini';

  // ── RevenueCat (in-app purchases) ─────────────────────────────────────────
  // PUBLIC SDK keys only — appl_ (iOS), goog_ (Android), test_ (sandbox).
  // NEVER put sk_ secret keys in the app — those are server-side only.
  static const String _testStoreKey = 'test_zRmNZWtkMgDEoptCavDbAdhMXxw';

  static const String _rcAppleFromEnv =
      String.fromEnvironment('RC_APPLE_KEY', defaultValue: '');
  static const String _rcGoogleFromEnv =
      String.fromEnvironment('RC_GOOGLE_KEY', defaultValue: '');

  static bool _isRevenueCatPublicKey(String k) {
    final t = k.trim();
    if (t.isEmpty || t.contains('YOUR_')) return false;
    // Reject secret keys — they must never ship in client binaries.
    if (t.startsWith('sk_')) return false;
    return t.startsWith('appl_') ||
        t.startsWith('goog_') ||
        t.startsWith('amzn_') ||
        t.startsWith('test_');
  }

  static String get revenueCatAppleApiKey {
    if (_isRevenueCatPublicKey(_rcAppleFromEnv)) return _rcAppleFromEnv.trim();
    // ignore: undefined_identifier
    const local = StillScoutSecrets.revenueCatAppleApiKey;
    if (_isRevenueCatPublicKey(local)) return local.trim();
    return _testStoreKey;
  }

  static String get revenueCatGoogleApiKey {
    if (_isRevenueCatPublicKey(_rcGoogleFromEnv)) return _rcGoogleFromEnv.trim();
    // ignore: undefined_identifier
    const local = StillScoutSecrets.revenueCatGoogleApiKey;
    if (_isRevenueCatPublicKey(local)) return local.trim();
    return _testStoreKey;
  }

  /// True when a real store key is configured (not just the test fallback).
  static bool get isRevenueCatConfigured =>
      _isRevenueCatPublicKey(revenueCatAppleApiKey) ||
      _isRevenueCatPublicKey(revenueCatGoogleApiKey);

  /// Entitlement identifier — create in RevenueCat dashboard as "pro".
  /// Attach stillscout_pro_monthly + stillscout_pro_yearly products to it.
  static const String rcEntitlementPro = 'pro';

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
  // The REAL AI provider keys (Groq, Gemini, Grok, OpenAI) live as Supabase
  // Secrets and never leave the server.
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
  static const String androidApplicationId = 'com.stillscout.stillscout';
}
