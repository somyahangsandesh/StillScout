# Pre–Aug 1 launch checklist (user actions only)

**Target:** Manual App Store release **Aug 1, 2026**  
**Binary:** `1.0.0+26` (StillScout AI branding — RC polish)  
**Do not** click Submit for Review or Release until each item below is done.

This list is **only** what you must do in App Store Connect, on a real device, or for Shipaton. Code/CI work is tracked in `docs/RATING_UPGRADE_PLAN.md`.

---

## Ops log (automated / agent)

| Date | Item | Status |
|------|------|--------|
| 2026-07-29 | `dart run tool/check_release_secrets.dart` | **OK** — Supabase + `appl_` RevenueCat, no client Gemini key |
| 2026-07-29 | TestFlight build **26** processing | **VALID** (uploaded 2026-07-29, commit ce1747d) |
| 2026-07-29 | Version **1.0** build attachment | **Build 26 attached** (replaced build 25) via ASC API |
| 2026-07-29 | Subtitle (en-GB + en-US) | **Set** — “Best stills from any video” |
| 2026-07-29 | Release type | **MANUAL** (was `AFTER_APPROVAL`; set via API) |
| 2026-07-29 | IAP API state | `stillscout_pro_monthly` / `stillscout_pro_yearly` → API `CREATED` — **confirm UI shows Ready to Submit** |
| 2026-07-29 | iPhone 6.7" screenshots (5×, en-US + en-GB) | **COMPLETE** — premium redesign in `docs/asc_assets/screenshots_67/` |
| — | Review phone | **Placeholder** `+977 980-000-0000` — user must replace |
| — | App Privacy labels | **Not done** — user manual in ASC |
| — | Submit for Review | **Not done** — waiting on privacy + phone + optional sandbox smoke |

**ASC ops tool:** `deno run --allow-read --allow-net --allow-env tool/asc_ops.ts` (read-only) · `--attach` to swap build on version 1.0.

---

## Before Submit for Review

### 1. App Privacy nutrition labels (required) — **YOU**

**App Store Connect → StillScout → App Privacy**

Declare data collected for **App Functionality** (not tracking), aligned with `ios/Runner/PrivacyInfo.xcprivacy` and [privacy.html](https://somyahangsandesh.github.io/StillScout/legal/privacy.html):

- Photos / Videos  
- Device ID (if declared)  
- Purchase History (subscriptions via Apple / RevenueCat)  

Confirm **not used for tracking**.

### 2. Review contact phone (required) — **YOU**

Replace the placeholder (`+977 980-000-0000`):

**App Store Connect → version 1.0 → App Review Information → Phone**

Use a **real, reachable** number you will answer during review. Do not invent a number.

### 3. TestFlight build 26 (required)

- [x] **2026-07-29** — TestFlight build **26** is **VALID** (ASC API)
- [x] **2026-07-29** — Version **1.0** has build **26** attached (build 25 detached)
- [ ] On a **real iPhone**, verify paywall/completion hero say **StillScout AI** (not Gemini Flash)

### 4. RevenueCat + secrets (required)

- [x] **2026-07-29** — `dart run tool/check_release_secrets.dart` → **OK**

```bash
dart run tool/check_release_secrets.dart
```

Must show **OK** (Supabase + `appl_` RevenueCat key, no client Gemini key).

### 5. Sandbox purchase smoke (strongly recommended) — **YOU**

On a real device with a Sandbox Apple ID:

1. Complete a scout → open paywall → subscribe (sandbox)  
2. **Restore Purchases** in Settings  
3. Confirm **StillScout AI Pro** active in app  
4. In RevenueCat / Supabase, confirm webhook fired and `pro_entitlements` has a row  

### 6. Submit for Review (required — allow approval time) — **YOU, when 1–5 done**

When 1–5 are done:

1. IAPs `stillscout_pro_monthly` / `stillscout_pro_yearly` still **Ready to Submit** (confirm in ASC UI)  
2. **Submit for Review** — app **and** subscriptions together  
3. Keep release type **manual** (`After approval, manually release this version`) — already **MANUAL** via API

**Do not** use “Release automatically.” Plan for Apple review lag before Aug 1.

---

## Shipaton / marketing

### 7. Demo video (contest-facing) — **YOU**

Film a **15–30 s vertical** cut using scripts in `docs/marketing/instagram_story_ads.md`:

- Show StillScout AI / StillScout AI Pro on screen — **never** “Gemini” in UI  
- Hook: scroll trap → scout → top pick → export  
- Optional B-roll: screen-record [animated story ad](https://somyahangsandesh.github.io/StillScout/marketing/stillscout_story_ad_animated.html)

### 8. Optional announce assets

- Story layouts: [instagram_story_layouts.html](https://somyahangsandesh.github.io/StillScout/marketing/instagram_story_layouts.html)  
- 6.7" App Store screenshots: premium generated set in `docs/asc_assets/screenshots_67/` (regenerate via `tool/render_asc_screenshots.ts`)  
- Optional: replace with real device captures if Apple requests  

---

## On approval day (≤ Aug 1)

### 9. Manual release — **YOU**

**App Store Connect → StillScout → version 1.0 → Release This Version**

Only after **Approved** status.

### 10. Post-release smoke (5 minutes)

- Free scout offline  
- One cloud trial scout online  
- Restore → Pro gallery / polish / 4K export  
- Share compare image from gallery (select 2 frames → Compare → Share)

---

## Quick reference

| Item | Where | Status |
|------|--------|--------|
| Privacy labels | ASC → App Privacy | **TODO** |
| Phone | ASC → 1.0 → App Review Information | **TODO** (placeholder) |
| Build 26 | TestFlight → attach to 1.0 | **Done** 2026-07-29 |
| Secrets preflight | `check_release_secrets.dart` | **OK** 2026-07-29 |
| Release type | Version 1.0 | **MANUAL** 2026-07-29 |
| Submit | ASC → 1.0 → Add for Review | **Not yet** |
| Manual release | ASC after approval | After approval |
| Shipaton video | Film from `docs/marketing/` | **TODO** |

**Not in this checklist (already in repo):** legal URLs, Privacy manifest, webhook code, CI tests, `docs/RATING_UPGRADE_PLAN.md`.
