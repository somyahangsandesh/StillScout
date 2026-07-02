// ============================================================================
// secrets.local.example.dart — copy to secrets.local.dart and fill in values
// ============================================================================

// ignore_for_file: unused_field
class StillScoutSecrets {
  // Supabase (P0 vision-score Edge Function proxy)
  static const String supabaseUrl = '';
  static const String supabaseAnonKey = '';

  // Direct provider fallbacks (only when Supabase proxy is unavailable)
  static const String groqApiKey = '';
  static const String geminiApiKey = '';
  static const String grokApiKey = '';
  static const String openAiApiKey = '';

  // RevenueCat public SDK keys (appl_… / goog_… — never sk_ secrets)
  static const String revenueCatAppleApiKey = '';
  static const String revenueCatGoogleApiKey = '';
}
