# StillScout

**Shipathon 2026** · Standalone Flutter app for creators

**Standalone app** — AI-powered frame scouting for creators.  
Extract, rank, polish, and export the best stills from any video clip.

> **This is the canonical StillScout codebase.**  
> It is **not** part of Dawn Oracle. Shipathon / App Store / Play Store builds use **this repo only**.  
> **Path:** `/Users/sandeshsomyahang/stillscout`  
> **Bundle ID:** `com.stillscout.stillscout` (iOS + Android)

Git: local repo at this path (`.git` present).

## Setup

1. Install Flutter 3.24+ and run `flutter pub get`.
2. Copy secrets template:
   ```bash
   cp lib/config/secrets.local.example.dart lib/config/secrets.local.dart
   ```
3. Fill in `StillScoutSecrets` in `secrets.local.dart` (gitignored):
   - **Supabase** URL + anon key for the `vision-score` Edge Function (production path).
   - Optional direct AI keys as emergency fallbacks when the proxy is down.
   - RevenueCat public SDK keys for Pro subscriptions.

## Run

```bash
flutter run
```

Optional dart-defines:

```bash
flutter run \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=RC_APPLE_KEY=... \
  --dart-define=RC_GOOGLE_KEY=...
```

## Architecture

| Stage | Behavior |
|-------|----------|
| **Extract** | `video_thumbnail` every **1 second** (max **180** frames per clip, 4 parallel workers) |
| **Dedup** | Perceptual hash in isolate — drops near-duplicate frames |
| **Score** | Supabase `vision-score` (P0) → Groq / Gemini / Grok / OpenAI fallback |
| **Eyes** | ML Kit face/eye detection on all frames post-scoring |
| **Rank** | Context-weighted scores (portrait / action / landscape / event) |
| **Persist** | Full gallery + frame files in Hive history (`stillscout_cache/<sessionId>/`) |
| **Export** | Auto Polish, crop ratios, gallery save (`gal`), share sheet |

**Cloud AI is required** for scouting — the app fails clearly when offline or when all providers are unavailable.

## Monetization

| | Free | Pro |
|---|------|-----|
| Scouts | **8 / week** (UTC Monday reset) | Unlimited |
| Visible keepers | Top **3** ranks | **10** ranks |
| Polished exports / scout | **3** | Unlimited |
| Timestamps | Hidden (rank labels) | Exact timecodes |
| Timeline view | Locked | Unlocked |
| Export quality | Thumbnail res | Native **4K** re-extract |

No watermarks on exports.

RevenueCat entitlement: `pro` · Products: `stillscout_pro_monthly`, `stillscout_pro_yearly`

## Quotas & cache

- **Cloud AI:** up to **60** frames/scout sent to LLM; **40** frames/device/day local guard (UTC midnight)
- **Session history:** max **20** scouts in Hive; LRU eviction
- **Frame cache:** max **512 MB** on disk — oldest sessions evicted when over budget

## Supabase proxy

Primary AI scoring runs through a Supabase Edge Function so provider keys never ship in the app binary. Deploy `vision-score` in your Supabase project; the app only needs the public anon key.

## Android notes

- Foreground service keeps scouting alive when the app is backgrounded (`flutter_foreground_task`)
- Gallery **write** permission is required for Save — not just read/media access
- The `video_thumbnail` plugin may require a jcenter workaround on older Gradle setups

### Release signing

Release builds are signed with a dedicated upload keystore, loaded from
`android/key.properties` (gitignored — never commit it or the `.jks` file).
Without that file, release builds fall back to the debug key so `flutter run
--release` still works for anyone cloning the repo.

Generate your own upload key once:

```bash
keytool -genkeypair -v \
  -keystore android/app/upload-keystore.jks \
  -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

Then create `android/key.properties`:

```
storePassword=<store password>
keyPassword=<key password>
keyAlias=upload
storeFile=app/upload-keystore.jks
```

Verify a build is signed with your key (not the debug key) with:

```bash
$ANDROID_HOME/build-tools/<version>/apksigner verify --print-certs \
  build/app/outputs/flutter-apk/app-release.apk
```

**Back up `android/app/upload-keystore.jks` somewhere safe outside this
repo.** Losing it means you can never publish an update to the same Play
Store listing.

## Tests

```bash
flutter analyze lib/
flutter test
```

## Key paths

```
lib/stillscout/domain/stillscout_constants.dart   # Intervals, quotas, limits
lib/stillscout/presentation/theme/stillscout_theme.dart
lib/stillscout/presentation/providers/stillscout_notifier.dart
lib/stillscout/services/frame_scoring_service.dart
lib/stillscout/services/stillscout_export_service.dart
lib/config/secrets.local.dart                      # Gitignored keys
```
