# StillScout

StillScout is an iOS app I built for Shipathon 2026. You import a short video clip, the app pulls frames from it, scores them, and shows the ones worth keeping. You can polish a pick and save it to Photos.

I made it because I kept scrubbing through clips trying to find one frame that looked good enough to post. StillScout automates that search.

**Platform:** iPhone and iPad only (`com.stillscout.stillscout`). This repo is the Flutter app plus Supabase edge functions for optional cloud scoring.

**Status (Aug 2026):** Version 1.0 (build 26) was submitted to App Store review and was waiting for review at last check. See git history and `docs/APP_STORE_LAUNCH.md` for launch notes.

Site (privacy, terms, support): https://somyahangsandesh.github.io/StillScout/

## What it does

- Import a video from the photo library (or camera where supported).
- Extract frames on a fixed interval, drop near-duplicates, score with on-device Apple Vision and heuristics.
- Optional **AI Pro** subscription: cloud batch scoring through a Supabase `vision-score` function (API keys stay on the server in release builds).
- Rank results, show a gallery, export stills (crop ratios, share sheet, save to Photos). Pro unlocks more ranks, timeline view, timestamps, Auto Polish, and higher export quality.

Free tier: daily scout limit, capped visible ranks, limited polished exports. Details live in `lib/stillscout/domain/stillscout_constants.dart` and the paywall copy.

## Tech stack

- **App:** Flutter, Riverpod, Hive, native Vision plugin (`ios/Runner/VisionFaceDetectorPlugin.swift`)
- **Backend:** Supabase Edge Functions (`vision-score`, `revenuecat-webhook`, `usage-alert`)
- **Subscriptions:** RevenueCat + Apple IAP

## How it works (short)

1. User picks a clip → frames extracted (`video_thumbnail`) in parallel.
2. Dedup + on-device Vision gates bad frames before any cloud call.
3. Free path: local scoring and ranking. Pro path: batches frames to `vision-score`, merges scores, applies quotas.
4. Session stored under app documents; LRU limits on history and disk cache.
5. Export path can re-extract at higher resolution for Pro.

## Run locally

Needs Flutter (recent stable with Dart 3.10+), Xcode, and your own keys.

```bash
flutter pub get
cp lib/config/secrets.local.example.dart lib/config/secrets.local.dart
# Fill Supabase URL/anon key and RevenueCat appl_ key in secrets.local.dart
flutter run
```

Release builds should not embed direct Gemini keys; use the Supabase proxy. Before TestFlight:

```bash
dart run tool/check_release_secrets.dart
```

More detail: `docs/TESTFLIGHT.md`, Supabase deploy notes in `docs/REVENUECAT_WEBHOOK_SETUP.md` and `docs/USAGE_ALERTS_SETUP.md`.

## Tests

```bash
flutter analyze
flutter test
```

Edge function unit tests run in CI under `supabase/functions/*/lib_test.ts`.

## Repo layout

```
lib/stillscout/     app UI, services, domain
ios/                Xcode project + Vision plugin
supabase/           migrations + edge functions
docs/legal/         hosted privacy/terms (GitHub Pages)
test/               Flutter tests
tool/               ASC/TestFlight helpers (optional)
```
