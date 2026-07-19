// Committed stub — provides empty StillScoutDebugSecrets so the app compiles
// on any fresh checkout.  dart.library.html is false on iOS/Android, so this
// file is always the one imported (see stillscout_config.dart).
//
// To use a real debug Gemini key without --dart-define, add it to the
// gitignored secrets.local.dart (StillScoutSecrets) instead of this stub.
class StillScoutDebugSecrets {
  static const String geminiApiKey = '';
}
