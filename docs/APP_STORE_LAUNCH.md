# App Store launch — remaining ops

Code + legal defaults are ready. Paid Apps Agreement, banking, and W-8BEN are **Active** (confirmed in App Store Connect UI).

Much of the listing metadata was applied via the App Store Connect API (2026-07-29). Finish only the manual items below before **Submit for Review**.

## Done in this project / via ASC API

### Legal + code

- In-app Privacy Policy + Terms (paywall + empty state + Settings)
- Canonical hosted legal URLs (live on GitHub Pages, HTTP 200):
  - Privacy: https://somyahangsandesh.github.io/StillScout/legal/privacy.html
  - Terms: https://somyahangsandesh.github.io/StillScout/legal/terms.html
  - Support: https://somyahangsandesh.github.io/StillScout/legal/support.html
  - Index: https://somyahangsandesh.github.io/StillScout/
- Source HTML: `docs/legal/*.html` (also listed in `docs/legal/HOSTED_URLS.txt`)
- Privacy manifest, Info.plist purpose strings, release AI-key gate
- TestFlight upload defaults to **Supabase-only** AI (no client Gemini keys)
- Preflight: `dart run tool/check_release_secrets.dart`

### App Store Connect (API-confirmed)

| Item | Status |
|------|--------|
| Privacy Policy URL (en-GB + en-US App Information) | Set |
| Support URL + marketing URL (version 1.0 en-GB + en-US) | Set |
| Subtitle, description, keywords, promotional text, copyright | Set |
| Terms URL | Included in App Store description |
| Age rating questionnaire | Set → **4+** |
| Content rights | `DOES_NOT_USE_THIRD_PARTY_CONTENT` |
| App Review contact + notes (Restore on paywall/Settings) | Set (phone is placeholder — update) |
| Version 1.0 build | Attached **build 26** (`VALID`) |
| iPhone 6.7" screenshots (5×, en-GB + en-US) | `COMPLETE` — premium redesign in `docs/asc_assets/screenshots_67/` |
| IAP `stillscout_pro_monthly` | **READY_TO_SUBMIT** (review screenshot `COMPLETE`) |
| IAP `stillscout_pro_yearly` | **READY_TO_SUBMIT** (review screenshot `COMPLETE`) |
| Paid Apps Agreement / bank / W-8BEN | **Active** (UI) |

Generated assets (safe to keep in repo): `docs/asc_assets/`. Regenerate 6.7" screenshots:

```bash
deno run --allow-read --allow-write --allow-run --allow-env --allow-ffi --allow-net tool/render_asc_screenshots.ts
deno run --allow-read --allow-write --allow-net --allow-env tool/upload_asc_screenshots.ts
```

Source artboard: `docs/asc_assets/screenshot_studio.html`.

## You must finish (manual clicks / account work)

### 1. App Privacy nutrition labels (API unsupported)

In **App Store Connect → StillScout → App Privacy**:

Declare data types used (not for tracking), e.g.:

- Photos / Videos (App Functionality)
- Device ID / Purchase History if applicable via Apple/RevenueCat (App Functionality)
- Contact info only if you collect email for support outside the store

Confirm **not used for tracking**.

### 2. Review contact phone

API set contact phone to a **placeholder** (`+977 980-000-0000`). Replace with your real number:

**App Store Connect → version 1.0 → App Review Information → Phone**

### 3. RevenueCat production Apple key

Your `secrets.local.dart` still needs a production key for store builds:

1. Open [RevenueCat](https://app.revenuecat.com) → StillScout iOS app (`com.stillscout.stillscout`)
2. Copy the **public** Apple SDK key (`appl_…`)
3. Paste into `secrets.local.dart` → `revenueCatAppleApiKey`
4. Confirm entitlement `pro`, offering `stillscout_main`, products `stillscout_pro_monthly` / `stillscout_pro_yearly`

Then re-run:

```bash
dart run tool/check_release_secrets.dart
```

### 4. Submit for Review

When privacy labels + phone + RevenueCat key are done:

1. Confirm IAPs still show **Ready to Submit**
2. **Submit for Review** on version 1.0 (subscriptions submit with the app)

Optional: replace marketing screenshots with real device captures later — current set is premium generated 6.7" art under `docs/asc_assets/screenshots_67/`.

### 5. Supabase

Project ref: `zyadgkgumdgussvkgtsr` (must match `secrets.local.dart` and
`tool/deploy_vision_score.sh`).

Deploy order matters — push migrations **before** the new edge functions:

```bash
export PATH="$HOME/.local/share/supabase:$HOME/.local/bin:$PATH"
supabase login   # or export SUPABASE_ACCESS_TOKEN=sbp_…
supabase link --project-ref zyadgkgumdgussvkgtsr --yes
supabase db push --linked --yes
bash tool/deploy_vision_score.sh
supabase functions deploy revenuecat-webhook --project-ref zyadgkgumdgussvkgtsr --no-verify-jwt
supabase functions deploy usage-alert --project-ref zyadgkgumdgussvkgtsr
# Only if GEMINI_API_KEY is not already set:
# supabase secrets set GEMINI_API_KEY='your_key' --project-ref zyadgkgumdgussvkgtsr
```

Then finish webhook + optional alerts:

- `docs/REVENUECAT_WEBHOOK_SETUP.md`
- `docs/USAGE_ALERTS_SETUP.md`

Confirm `supabaseUrl` / anon key in `secrets.local.dart` match the dashboard.

### 6. Custom domain (optional later)

Legal pages are already live on GitHub Pages. When ready, point `stillscout.app` at Pages and override defaults with `--dart-define=PRIVACY_POLICY_URL=…` (etc.), or update `StillScoutConfig` + `HOSTED_URLS.txt`.

### 7. TestFlight emergency direct keys (optional)

Only if Supabase is down during internal testing:

```bash
STILLSCOUT_ALLOW_DIRECT_AI_KEYS=1 bash tool/upload_testflight.sh
```

Never use that flag for App Store submission builds.
