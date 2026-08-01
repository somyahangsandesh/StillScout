# Aug 1, 2026 launch run

**Status: BLOCKED — not submitted**

Manual release was the plan. Full ASC API inspection on **2026-08-01 (launch day)** shows version **1.0** is still **PREPARE_FOR_SUBMISSION**. Submit was **not** triggered because required blockers remain (placeholder review phone + App Privacy not set via API or browser).

---

## ASC snapshot (2026-08-01 launch run)

| Check | Result |
|-------|--------|
| Version | **1.0** |
| App Store state | **PREPARE_FOR_SUBMISSION** |
| Attached build | **26** (`VALID`, uploaded 2026-07-28) |
| Release type | **MANUAL** |
| Review phone | **Placeholder** `+977 980-000-0000` |
| Review email | `stillscout.support@gmail.com` |
| App Privacy labels | **Not settable via API** (all `appDataUsage*` / `dataUsages` endpoints → 404); **ASC browser login wall** (`authResult=FAILED`) |
| Subscriptions API | `stillscout_pro_monthly` / `stillscout_pro_yearly` → **READY_TO_SUBMIT** |
| Legacy IAP API | same products → `CREATED` (stale surface; use subscriptions API) |
| Subtitles (en-US / en-GB) | “Best stills from any video” |
| `check_release_secrets.dart` | **OK** (2026-08-01) |
| `reviewSubmissions` | **0** existing (never submitted) |

**Commands:** `deno run --allow-read --allow-net --allow-env tool/asc_ops.ts` · `dart run tool/check_release_secrets.dart`

**IDs (for API submit when unblocked):**

| Resource | ID |
|----------|-----|
| App | `6790234719` |
| Version 1.0 | `0676e217-a370-4728-ab95-39a65ce42515` |
| Review detail | `c4685cc0-a698-42ab-a5a6-9fc042ae0e2d` |
| Sub monthly | `6792454070` |
| Sub yearly | `6792454034` |

---

## What we completed today

1. **ASC inspect** — build 26 attached, MANUAL release confirmed, subscriptions READY_TO_SUBMIT.
2. **App Privacy research** — official ASC API has **no** nutrition-label endpoints (`/appDataUsages`, `/apps/{id}/dataUsages`, `/appDataUsageCategories`, etc. all **404**). Fastlane’s `AppDataUsage` uses an undocumented path not available with API-key JWT auth.
3. **Browser ASC** — navigated to App Privacy; **login required** (not logged in). Stopped per policy.
4. **Review phone search** — repo, secrets, and agent history contain **no real number**; ASC still shows placeholder. Did **not** invent a number.
5. **Submit for Review** — **intentionally skipped** (placeholder phone + privacy incomplete).
6. **Release** — not applicable (`PREPARE_FOR_SUBMISSION`, not approved).

---

## Why Submit was skipped

Per launch policy: do not submit with a placeholder review phone or incomplete App Privacy.

1. **Review phone** — still `+977 980-000-0000`. No real number found anywhere in workspace.
2. **App Privacy** — cannot be automated via API; browser blocked by login.

Everything else for binary/metadata looks ready: build 26 attached, MANUAL release type, subscriptions ready, secrets preflight green.

---

## Unblock and ship (≈15 minutes)

### Step 1 — App Privacy (required) — **YOU in ASC UI**

**App Store Connect → Apps → StillScout → App Privacy → Get Started / Edit**

Declare data for **App Functionality** (not tracking), aligned with `ios/Runner/PrivacyInfo.xcprivacy` and [privacy.html](https://somyahangsandesh.github.io/StillScout/legal/privacy.html):

- Photos / Videos  
- Purchase History (subscriptions)  
- Device ID (if shown in questionnaire)  

Publish / Save. Confirm **not used for tracking**.

### Step 2 — Review phone (required)

**Option A — paste your number in chat** so the agent can set it via API (`PATCH /appStoreReviewDetails/{id}`) and submit immediately.

**Option B — ASC UI:** **StillScout → iOS App → 1.0 → App Review Information → Phone**

Replace `+977 980-000-0000` with a **real number you will answer** during review (Aug 1–3).

### Step 3 — Submit for Review

**ASC UI:** **StillScout → 1.0 → Add for Review → Submit for Review** (include both subscriptions). Keep **“Manually release this version”**.

**Or API (3-step, when phone + privacy done):**

1. `POST /v1/reviewSubmissions` — `platform: IOS`, app `6790234719`
2. `POST /v1/reviewSubmissionItems` — version `0676e217-a370-4728-ab95-39a65ce42515` + subscriptions `6792454070`, `6792454034`
3. `PATCH /v1/reviewSubmissions/{id}` — `submitted: true`

Apple review typically **24–48 hours** (sometimes same day). Aug 1 **store** release only happens if already approved **or** you get fast review today.

### Step 4 — After approval (manual release)

**App Store Connect → StillScout → 1.0 → Release This Version**

Do **not** use “Release automatically.” Only when state is **PENDING_DEVELOPER_RELEASE** / approved.

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
| 2026-08-01 | App Privacy API probe → all endpoints 404; browser → login wall |
| 2026-08-01 | Subscriptions API → monthly + yearly **READY_TO_SUBMIT** |
| 2026-08-01 | **Submit skipped** — phone + App Privacy blockers |
