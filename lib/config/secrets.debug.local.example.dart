// ============================================================================
// secrets.debug.local.example.dart — copy to secrets.debug.local.dart
// ============================================================================
// DEBUG ONLY. Never add this to secrets.local.dart (store builds).
// The Gemini key here is used for direct API calls during local development.
// In production, all Gemini calls go through the Supabase Edge Function proxy.
// ============================================================================

class StillScoutDebugSecrets {
  static const String geminiApiKey = ''; // AIza… or AQ.… from aistudio.google.com
}
