// ============================================================================
// secrets.local.example.dart — copy to secrets.local.dart and fill in values
// ============================================================================
// App Store release builds:
//   - Fill supabaseUrl + supabaseAnonKey (Gemini Flash proxy on edge)
//   - Fill revenueCatAppleApiKey (appl_…)
//   - LEAVE geminiApiKey EMPTY — release mode never uses it directly.
//     The Gemini key lives as a Supabase Secret and never touches the binary.
// Debug / local testing: fill geminiApiKey for direct AI calls.
// ============================================================================

// ignore_for_file: unused_field
class StillScoutSecrets {
  // Supabase (Gemini Flash proxy Edge Function) — required for store builds
  static const String supabaseUrl = '';
  static const String supabaseAnonKey = '';

  // Direct Gemini key — DEBUG ONLY. Keep empty for App Store builds.
  static const String geminiApiKey = '';

  // RevenueCat public iOS SDK key (appl_… — never sk_ secrets)
  static const String revenueCatAppleApiKey = '';
}
