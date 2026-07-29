# StillScout RC Polish — Build 26 (1.0.0+26)

Final release-candidate polish pass focused on cohesion, interaction quality, and performance — no new product surfaces.

## Polished (by category)

### Visual consistency & branding
- Standardized user-facing Pro copy to **StillScout AI Pro** (or **AI Pro** in tight UI) across quota errors, paywall, locked frames, preflight CTA, settings, completion hero, and batch-export paywall reasons.
- Batch export bar uses theme spacing/radius tokens (`StillScoutSpacing`, `StillScoutRadius`) instead of one-off values.
- Empty-state horizontal padding aligned to `StillScoutSpacing.l`.

### Interaction polish
- Error/cancelled status screens now use shared `StillScoutPrimaryButton` / `StillScoutSecondaryButton` for consistent press-scale + haptics.
- Batch export bar Save/Share actions trigger light haptic feedback.
- Removed duplicate medium haptic on single/batch share export (consolidated in `_showExportFeedback`).

### Performance
- Added `cacheWidth` to gallery preview, top-picks carousel, live processing strip, and compare sheet images — reduces decode memory during scroll without changing displayed quality.

### Reliability / messaging
- Scout quota exhaustion message now names StillScout AI Pro explicitly.
- Settings store-unavailable copy says "AI Pro benefits paused" for clarity.

## Build
- **Version:** 1.0.0+26 (`pubspec.yaml`)

## Test results
- `flutter analyze` — pass (4 pre-existing `prefer_const_declarations` infos)
- `flutter test` — 161 tests passed

## Residual risks (human device QA)
- **Real-device IAP:** Restore, purchase, and subscription lapse with RevenueCat + ASC sandbox.
- **Cloud AI edge cases:** Gemini timeout mid-scout, daily quota exhaustion, offline during AI trial scout.
- **Export paths:** Native 4K when source video deleted; photo-library permission denied; low storage (not programmatically detected).
- **Video edge cases:** Very short clips, 10+ min trim, portrait/landscape, no-face / multi-face clips.
- **Compare share export:** Side-by-side image generation on older devices under memory pressure.
- **TestFlight processing:** Upload script requires local ASC API key + signing identities.

## Not changed (intentional)
- Core scout pipeline, monetization logic, and navigation structure.
- Debug-only `debugPrint` in service layers (already gated or diagnostic).
- Legal copy references to "StillScout Pro" in hosted HTML (ASC/legal docs — separate from in-app branding).
