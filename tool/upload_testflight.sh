#!/usr/bin/env bash
# Build StillScout IPA and upload to TestFlight only (never submits for App Store release).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ENV_FILE="${ASC_ENV_FILE:-$ROOT/secrets.asc.env}"
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  set -a
  source "$ENV_FILE"
  set +a
fi

ASC_KEY_ID="${ASC_KEY_ID:-725F75L52R}"
ASC_ISSUER_ID="${ASC_ISSUER_ID:-}"
ASC_KEY_PATH="${ASC_KEY_PATH:-}"

echo "==> StillScout TestFlight upload"
echo "    Bundle: com.stillscout.stillscout"
echo "    Team:   S8WFJFA85T"
echo "    Key ID: $ASC_KEY_ID"
echo "    Mode:   TestFlight ONLY — will NOT submit or release on the App Store"

# Safety: never run App Store "submit for review" / release commands from this script.
if [[ "${FORCE_APP_STORE_RELEASE:-}" == "1" ]]; then
  echo "Refusing FORCE_APP_STORE_RELEASE — this script is TestFlight-only."
  exit 1
fi

if [[ -z "$ASC_ISSUER_ID" || -z "$ASC_KEY_PATH" ]]; then
  cat <<EOF

ERROR: Missing App Store Connect API credentials.

1. App Store Connect → Users and Access → Integrations → App Store Connect API
2. Create a key with App Manager (or Admin) access
3. Download AuthKey_${ASC_KEY_ID}.p8 (only shown once)
4. Copy secrets.asc.example.env → secrets.asc.env and set:
     ASC_KEY_ID=$ASC_KEY_ID
     ASC_ISSUER_ID=<Issuer ID UUID from that page>
     ASC_KEY_PATH=/absolute/path/to/AuthKey_${ASC_KEY_ID}.p8

Also open ios/Runner.xcworkspace in Xcode once, select Team S8WFJFA85T,
and ensure a valid Apple Development / Distribution certificate exists
(Xcode → Settings → Accounts → Manage Certificates).

EOF
  exit 1
fi

if [[ ! -f "$ASC_KEY_PATH" ]]; then
  echo "ERROR: ASC_KEY_PATH not found: $ASC_KEY_PATH"
  exit 1
fi

IDENTITIES="$(security find-identity -v -p codesigning 2>/dev/null | grep -c 'iPhone Distribution\|Apple Distribution\|iPhone Developer\|Apple Development' || true)"
if [[ "${IDENTITIES:-0}" == "0" ]]; then
  cat <<EOF

ERROR: No Apple code-signing identities in the keychain.

Open Xcode → Settings → Accounts → add your Apple ID for team S8WFJFA85T
→ Manage Certificates → "+" → Apple Distribution (and Apple Development).
Then re-run this script.

EOF
  exit 1
fi

echo "==> flutter pub get"
flutter pub get

echo "==> pod install"
export PATH="${HOME}/.gem/ruby/2.6.0/bin:${PATH}"
(cd ios && pod install)

echo "==> flutter build ipa (TestFlight / App Store Connect export)"
# Default: Supabase proxy only (release-safe). Opt-in client Gemini keys:
#   STILLSCOUT_ALLOW_DIRECT_AI_KEYS=1 bash tool/upload_testflight.sh
BUILD_ARGS=( build ipa --release --export-options-plist=ios/ExportOptions-TestFlight.plist )
if [[ "${STILLSCOUT_ALLOW_DIRECT_AI_KEYS:-}" == "1" ]]; then
  echo "    AI keys: DIRECT (ALLOW_DIRECT_AI_KEYS=true) — debug/emergency only"
  BUILD_ARGS+=( --dart-define=ALLOW_DIRECT_AI_KEYS=true )
else
  echo "    AI keys: Supabase proxy only (set STILLSCOUT_ALLOW_DIRECT_AI_KEYS=1 to override)"
fi
flutter "${BUILD_ARGS[@]}"

IPA="$(ls -1 build/ios/ipa/*.ipa 2>/dev/null | head -1 || true)"
if [[ -z "$IPA" ]]; then
  echo "ERROR: No IPA found under build/ios/ipa/"
  exit 1
fi
echo "==> IPA: $IPA"

# Place API key where altool/Transporter expect it (or pass via env)
KEY_DIR="$HOME/.appstoreconnect/private_keys"
mkdir -p "$KEY_DIR"
KEY_DEST="$KEY_DIR/AuthKey_${ASC_KEY_ID}.p8"
if [[ "$(cd "$(dirname "$ASC_KEY_PATH")" && pwd)/$(basename "$ASC_KEY_PATH")" != "$KEY_DEST" ]]; then
  cp -f "$ASC_KEY_PATH" "$KEY_DEST"
fi
chmod 600 "$KEY_DEST"

echo "==> Uploading to App Store Connect (TestFlight processing — not submitting for release)"
xcrun altool --upload-app \
  --type ios \
  --file "$IPA" \
  --apiKey "$ASC_KEY_ID" \
  --apiIssuer "$ASC_ISSUER_ID"

cat <<EOF

OK — build uploaded.

Next in App Store Connect (do NOT click "Add for Review" / "Release"):
1. Apps → StillScout → TestFlight
2. Wait for processing to finish
3. Add internal testers (or external + Beta App Review if needed)
4. Leave the iOS version in "Prepare for Submission" — do not release to the App Store

EOF
