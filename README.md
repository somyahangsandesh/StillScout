# StillScout

**Shipathon 2026** · iOS-only Flutter app for creators

AI-powered frame scouting for creators. Extract, rank, polish, and export the best stills from any video clip.

> **This is the canonical StillScout codebase.**  
> **Platform:** iOS only (iPhone + iPad). No Android / Play Store target.  
> **Path:** `/Users/sandeshsomyahang/stillscout`  
> **Bundle ID:** `com.stillscout.stillscout`

## Setup

1. Install Flutter 3.24+ and run `flutter pub get`.
2. Copy secrets template:
   ```bash
   cp lib/config/secrets.local.example.dart lib/config/secrets.local.dart
   ```
3. Fill in `StillScoutSecrets` in `secrets.local.dart` (gitignored):
   - **Supabase** URL + anon key for the `vision-score` Edge Function (required for AI Pro in release).
   - **RevenueCat** `appl_…` public SDK key for AI Pro subscriptions.
   - Optional direct Gemini key for **debug only** — never ship in App Store builds.

## Run (iOS)

```bash
flutter run
```

Optional dart-defines:

```bash
flutter run \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=RC_APPLE_KEY=appl_...
```

## Architecture

| Stage | Behavior |
|-------|----------|
| **Extract** | `video_thumbnail` every **1 second** (max **180** frames per clip, 4 parallel workers) |
| **Dedup** | Perceptual hash in isolate — drops near-duplicate frames |
| **On-device** | Apple **Vision** face/eye analysis — gates obvious rejects before cloud spend |
| **Score (free)** | Vision + heuristics — no network |
| **Score (AI Pro)** | Supabase `vision-score` → Gemini batch (release-safe; keys server-side) |
| **Rank** | Context-weighted scores (portrait / action / landscape / event) |
| **Persist** | Full gallery + frame files in Hive history (`stillscout_cache/<sessionId>/`) |
| **Export** | Auto Polish, crop ratios, Photos save (`gal`), share sheet |

**AI Pro** requires Supabase cloud scoring. Release builds never embed Gemini keys — the edge proxy is the only production path.

## Monetization

| | Free | AI Pro |
|---|------|--------|
| Scouts | **5 / day** (UTC) | Unlimited |
| Cloud AI | **1×** complimentary Gemini scout (needs internet; not consumed if Gemini never reaches) | Unlimited Gemini via Supabase |
| Visible keepers | Top **5** ranks (**8** on first successful free scout) | **20** ranks |
| AI Auto Polish | Locked | Unlocked |
| Polished exports / scout | **3** | Unlimited |
| Timestamps | Hidden (rank labels) | Exact timecodes |
| Timeline view | Locked | Unlocked |
| Export quality | Thumbnail res | Native **4K** re-extract |

No watermarks on exports. Free AI trial unlocks Gemini scoring only — polish stays Pro.

RevenueCat entitlement: `pro` · Products: `stillscout_pro_monthly`, `stillscout_pro_yearly`

## Quotas & cache

- **Cloud AI:** up to **20** keeper picks/scout; **48** frames sent per Gemini batch; **200** picks/device/day server cap (UTC)
- **Session history:** max **20** scouts in Hive; LRU eviction
- **Frame cache:** max **512 MB** on disk — oldest sessions evicted when over budget

## Supabase proxy

AI Pro scoring runs through the `vision-score` Edge Function (`supabase/functions/vision-score/`). Deploy to your Supabase project; the app only needs the public anon key.

```bash
supabase functions deploy vision-score
supabase secrets set GEMINI_API_KEY=...
```

Supports single-frame `{ image }` and batch `{ images, pick_count }` for AI Pro.

## App Store compliance

Before submitting to App Store Connect:

1. **Hosted legal pages** — defaults in `stillscout_config.dart` point to GitHub Pages (`somyahangsandesh.github.io/StillScout/legal/*.html`). Paste the same URLs into ASC (see `docs/legal/HOSTED_URLS.txt`).
2. **In-app legal links** — Privacy Policy + Terms on empty state and paywall (Guideline 3.1.2).
3. **Release secrets** — `secrets.local.dart` must include Supabase + RevenueCat `appl_` only. No direct AI keys in release.
   ```bash
   dart run tool/check_release_secrets.dart
   ```
   See `docs/TESTFLIGHT.md` for the TestFlight upload path.
4. **App Privacy nutrition labels** — Photos/Videos, Device ID, Purchase History (not tracking).
5. **Privacy Manifest** — `ios/Runner/PrivacyInfo.xcprivacy` bundled with Runner.
6. **Subscriptions** — ASC products + RevenueCat entitlement `pro` + Paid Apps Agreement.

See `docs/APP_STORE_LAUNCH.md` for the remaining RevenueCat / ASC checklist.

## iOS notes

- Portrait-locked on iPhone and iPad
- `ITSAppUsesNonExemptEncryption = false` — standard HTTPS only
- Photo library usage string covers **importing videos** and **saving exports**
- No background execution — `WakelockPlus` keeps the screen awake during a scout
- On-device face analysis uses a native **Vision** plugin (`VisionFaceDetectorPlugin.swift`)
- Branded app icon + launch screen: `tool/generate_branding_assets.py`

### Signing

Open `ios/Runner.xcworkspace` in Xcode, select your **Team** under Signing & Capabilities for Runner (and RunnerTests if needed). After that, `flutter run --release` and TestFlight builds work normally.

## Tests

```bash
flutter analyze lib/
flutter test
```

## Key paths

```
lib/stillscout/domain/stillscout_constants.dart
lib/stillscout/services/frame_scoring_service.dart
lib/stillscout/services/vision/providers/supabase_vision_client.dart
lib/stillscout/presentation/providers/stillscout_notifier.dart
lib/config/stillscout_config.dart
supabase/functions/vision-score/index.ts
ios/Runner/VisionFaceDetectorPlugin.swift
lib/config/secrets.local.dart          # Gitignored keys
```
