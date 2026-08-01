# Aug 1, 2026 launch run

**Status: FAILED — not submitted**

Authorized submit was attempted on **2026-08-01**. ASC API fixed several metadata gaps (pricing, category, iPad screenshots) but **Submit for Review still blocked** by **App Privacy** (`STATE_ERROR.APP_DATA_USAGES_REQUIRED`). Version **1.0** remains **PREPARE_FOR_SUBMISSION**. Manual release unchanged.

---

## Result

| Outcome | Detail |
|---------|--------|
| **SUBMITTED** | No |
| **RELEASED** | No (not approved) |
| **FAILED** | Yes — App Privacy questionnaire not published |

### Exact ASC errors (final submit attempt)

**Adding app version to review submission (`POST /v1/reviewSubmissionItems`):**

```
409 STATE_ERROR.ENTITY_STATE_INVALID
appStoreVersions '0676e217-a370-4728-ab95-39a65ce42515' is not in valid state.

associatedErrors:
  /v1/appDataUsages/
    409 STATE_ERROR.APP_DATA_USAGES_REQUIRED
    "You must have published answers to your app's data usages."
```

**Final commit (`PATCH /v1/reviewSubmissions/{id}` `submitted: true`):**

```
409 ENTITY_ERROR.RELATIONSHIP.REQUIRED
App 6790234719 must have an approved appStoreVersions for platform IOS,
or an appStoreVersions must be included in this review submission.
```

**IAP items (`inAppPurchases` / `subscription` relationship on `reviewSubmissionItems`):**

```
409 ENTITY_ERROR.RELATIONSHIP.UNKNOWN
'inAppPurchases' / 'subscription' is not a relationship on reviewSubmissionItems
```

Subscriptions are **READY_TO_SUBMIT** via `/v1/subscriptions/{id}` but must be included at submit time (UI or correct API relationship once app version is attachable).

---

## ASC snapshot (post-fix run, 2026-08-01)

| Check | Result |
|-------|--------|
| Version | **1.0** |
| App Store state | **PREPARE_FOR_SUBMISSION** |
| Attached build | **26** (`VALID`, uploaded 2026-07-28) |
| Release type | **MANUAL** |
| Review phone | **Placeholder** `+977 980-000-0000` (unchanged; no real number in repo or ASC account API) |
| Review email | `stillscout.support@gmail.com` |
| Primary category | **PHOTO_AND_VIDEO** (set via API this run) |
| App pricing | **Free ($0.00)** — `POST /v1/appPriceSchedules` succeeded |
| iPad 12.9" screenshots | **Uploaded** — 5× en-US + 5× en-GB (`APP_IPAD_PRO_3GEN_129`) |
| iPhone 6.7" screenshots | **Present** (prior run) |
| App Privacy labels | **BLOCKER** — all read/write API paths → 404; browser → **login required** (`authResult=FAILED`) |
| Subscriptions API | `stillscout_pro_monthly` / `stillscout_pro_yearly` → **READY_TO_SUBMIT** |
| Legacy IAP API | same products → `CREATED` |
| `reviewSubmissions` | Draft `dd9233a1-c0af-47df-81c6-644f53948647` — **READY_FOR_REVIEW**, `submittedDate: null` (0 items attached) |

**Commands:**

- `deno run --allow-read --allow-net --allow-env tool/asc_ops.ts`
- `deno run --allow-read --allow-net --allow-env tool/asc_submit.ts` (inspect)
- `deno run --allow-read --allow-net --allow-env tool/asc_submit.ts --submit`

**IDs:**

| Resource | ID |
|----------|-----|
| App | `6790234719` |
| Version 1.0 | `0676e217-a370-4728-ab95-39a65ce42515` |
| App info | `29c5b16f-aa14-4ab4-90b9-1d77be68a237` |
| Review detail | `c4685cc0-a698-42ab-a5a6-9fc042ae0e2d` |
| Review submission (draft) | `dd9233a1-c0af-47df-81c6-644f53948647` |
| Sub monthly (subscriptions API) | `6792454070` |
| Sub yearly (subscriptions API) | `6792454034` |
| IAP monthly (legacy) | `ebfcdd34-137b-4f9e-8b74-2c3cbeb17083` |
| IAP yearly (legacy) | `f1941616-140b-46d0-8580-6d3bf6d8b839` |

---

## What we completed this run (authorized)

1. **ASC inspect** — build 26 attached, MANUAL release, subscriptions READY_TO_SUBMIT.
2. **Fixed via API** — free app pricing; primary category PHOTO_AND_VIDEO; iPad Pro 12.9" screenshots (10 total).
3. **App Privacy** — all probed API paths 404; ASC browser session not logged in → skipped.
4. **Phone search** — ASC users/review detail/workspace: only placeholder `+977 980-000-0000`; did not invent a number.
5. **Submit for Review** — attempted; blocked by App Privacy (see errors above).
6. **Release** — N/A (`PREPARE_FOR_SUBMISSION`).

---

## What you must click (≈10 min)

### 1. App Privacy — **required** (blocks submit)

Log in at [App Store Connect](https://appstoreconnect.apple.com/) → **StillScout** → **App Privacy** → **Get Started / Edit**.

Declare for **App Functionality** (not tracking), aligned with `ios/Runner/PrivacyInfo.xcprivacy`:

- Photos / Videos  
- Purchase History  
- Device ID (if prompted)  

**Save / Publish.**

### 2. Review phone — **recommended**

**StillScout → iOS App → 1.0 → App Review Information → Phone**

Replace `+977 980-000-0000` with a number you will answer during review.  
Or paste your number in chat for API `PATCH /appStoreReviewDetails/c4685cc0-a698-42ab-a5a6-9fc042ae0e2d`.

### 3. Submit for Review

**ASC UI:** **StillScout → 1.0 → Add for Review → Submit for Review** (include both subscriptions). Keep **“Manually release this version”**.

**Or re-run API after privacy is published:**

```bash
deno run --allow-read --allow-net --allow-env tool/asc_submit.ts --submit
```

### 4. After approval (manual release only)

**Release This Version** when state is **PENDING_DEVELOPER_RELEASE**. Do not auto-release.

**App Store link (after live):** https://apps.apple.com/app/id6790234719

---

## Ops log

| Date | Action |
|------|--------|
| 2026-08-01 | ASC inspect: PREPARE_FOR_SUBMISSION, build 26, MANUAL, placeholder phone |
| 2026-08-01 | App Privacy API → 404; browser → login wall |
| 2026-08-01 | **Authorized submit** — fixed pricing, category, iPad screenshots via API |
| 2026-08-01 | **Submit FAILED** — `APP_DATA_USAGES_REQUIRED` (App Privacy) |
| 2026-08-01 | Draft review submission created (`dd9233a1…`) — not committed |
