# Aug 1, 2026 launch run

**Status: BLOCKED — not submitted**

Manual release was the plan. ASC API inspection on **2026-08-01** shows version **1.0** is still **PREPARE_FOR_SUBMISSION**. Submit was **not** triggered because required manual blockers remain.

---

## ASC snapshot (2026-08-01)

| Check | Result |
|-------|--------|
| Version | **1.0** |
| App Store state | **PREPARE_FOR_SUBMISSION** |
| Attached build | **26** (`VALID`, uploaded 2026-07-28) |
| Release type | **MANUAL** |
| Review phone | **Placeholder** `+977 980-000-0000` |
| Review email | `stillscout.support@gmail.com` |
| App Privacy labels | **Unknown via API** (no ASC endpoint); checklist still marks **TODO** |
| IAP `stillscout_pro_monthly` | API state `CREATED` |
| IAP `stillscout_pro_yearly` | API state `CREATED` |
| Subtitles (en-US / en-GB) | “Best stills from any video” |
| `check_release_secrets.dart` | **OK** (2026-08-01) |

**Command used:** `deno run --allow-read --allow-net --allow-env tool/asc_ops.ts`

---

## Why we did not Submit for Review

Per launch policy: do not submit with a placeholder review phone or clearly incomplete App Privacy.

1. **Review phone** — still `+977 980-000-0000` (placeholder). No real number found in the repo; we did not invent one.
2. **App Privacy nutrition labels** — ASC API cannot read privacy declarations (404 on `appPrivacy` / `appDataUsages`). Last known status: **not completed** in ASC UI. Confirm manually before submit.

Everything else for binary/metadata looks ready: build 26 attached, MANUAL release type set, secrets preflight green.

---

## Unblock and ship (≈15 minutes)

### Step 1 — App Privacy (required)

**App Store Connect → Apps → StillScout → App Privacy → Get Started / Edit**

Declare data for **App Functionality** (not tracking), aligned with `ios/Runner/PrivacyInfo.xcprivacy` and [privacy.html](https://somyahangsandesh.github.io/StillScout/legal/privacy.html):

- Photos / Videos  
- Purchase History (subscriptions)  
- Device ID (if shown in questionnaire)  

Publish / Save. Confirm **not used for tracking**.

### Step 2 — Review phone (required)

**App Store Connect → StillScout → iOS App → 1.0 Prepare for Submission → App Review Information → Phone**

Replace `+977 980-000-0000` with a **real number you will answer** during review (same timezone as you on Aug 1–3).

### Step 3 — Submit for Review

1. Confirm IAPs show **Ready to Submit** in ASC (Subscriptions → `stillscout_pro_monthly` / `stillscout_pro_yearly`).
2. **App Store Connect → StillScout → 1.0 → Add for Review → Submit for Review** (include subscriptions).
3. Keep **“Manually release this version”** (already **MANUAL** via API).

Apple review typically **24–48 hours** (sometimes same day). Aug 1 **store** release only happens if already approved **or** you get fast review today.

### Step 4 — After approval (manual release)

**App Store Connect → StillScout → 1.0 → Release This Version**

Do **not** use “Release automatically.”

**App Store link (after live):** https://apps.apple.com/app/id6790234719  
Bundle: `com.stillscout.stillscout`

---

## Post-release smoke (5 min)

On a real iPhone with production build:

1. Free scout offline (on-device Vision path).  
2. One cloud AI scout online (trial or Pro).  
3. Subscribe or **Restore Purchases** → confirm **StillScout AI Pro** in Settings.  
4. Pro gallery, Auto Polish, 4K export.  
5. Gallery → select 2 frames → Compare → Share.

---

## Shipaton (Next Gen) — does not block store

| Item | Status |
|------|--------|
| Demo video (15–30 s vertical) | **Still missing** — scripts in `docs/marketing/instagram_story_ads.md` |
| GitHub repo | Public — [StillScout](https://github.com/somyahangsandesh/StillScout) |

Film and upload for contest separately; App Store release does not depend on the video.

---

## Ops log

| Date | Action |
|------|--------|
| 2026-08-01 | ASC inspect: `PREPARE_FOR_SUBMISSION`, build 26, MANUAL, placeholder phone |
| 2026-08-01 | `check_release_secrets.dart` → OK |
| 2026-08-01 | **Submit skipped** — phone + App Privacy blockers |
