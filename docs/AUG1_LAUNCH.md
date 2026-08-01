# Aug 1, 2026 launch run

**Status: SUBMITTED — waiting for review**

Version **1.0** submitted for App Store review on **2026-08-01** after App Privacy was published in ASC UI. State is **WAITING_FOR_REVIEW**. Release type **MANUAL** — do not release until **PENDING_DEVELOPER_RELEASE**.

---

## Result

| Outcome | Detail |
|---------|--------|
| **SUBMITTED** | Yes — `2026-08-01` via ASC API |
| **RELEASED** | No (not approved yet) |
| **FAILED** | No |

### Final state

| Field | Value |
|-------|-------|
| App Store state | **WAITING_FOR_REVIEW** |
| Review submission | `4e8ec146-4676-44e7-be7a-a821c5bda25c` → **WAITING_FOR_REVIEW** |
| Version item | `NGU4ZWMxNDYtNDY3Ni00NGU3LWJlN2EtYTgyMWM1YmRhMjVjfDZ8ODg4MjA0NzI0` |
| Build | **26** (attached) |
| Release type | **MANUAL** |
| Review phone | Placeholder `+977 980-000-0000` (did not block submit) |
| Review email | `stillscout.support@gmail.com` |

### Privacy blocker — resolved

`POST /v1/reviewSubmissionItems` (app version) succeeded — **no** `APP_DATA_USAGES_REQUIRED`. App Privacy published in ASC UI.

### Subscription IAPs — API limitation

Both subscriptions remain **READY_TO_SUBMIT** but could not be attached via API:

```
409 ENTITY_ERROR.RELATIONSHIP.UNKNOWN
'subscription' is not a relationship on the resource 'reviewSubmissionItems'
```

App version was submitted anyway. **If subscriptions are not in the review queue**, add them in ASC UI:

**StillScout → Subscriptions → AI Pro Monthly / Yearly → Submit for Review** (or include when editing the in-review submission if ASC allows).

---

## ASC snapshot (submit run, 2026-08-01)

| Check | Result |
|-------|--------|
| Version | **1.0** |
| App Store state | **WAITING_FOR_REVIEW** |
| Attached build | **26** (`VALID`, uploaded 2026-07-28) |
| Release type | **MANUAL** |
| Review phone | **Placeholder** `+977 980-000-0000` |
| Review email | `stillscout.support@gmail.com` |
| Primary category | **PHOTO_AND_VIDEO** |
| App pricing | **Free ($0.00)** |
| iPad 12.9" screenshots | **Uploaded** (10 total) |
| iPhone 6.7" screenshots | **Present** |
| App Privacy | **Published** (UI) |
| Subscriptions API | `stillscout_pro_monthly` / `stillscout_pro_yearly` → **READY_TO_SUBMIT** (not attached via API) |

**Commands:**

- `deno run --allow-read --allow-net --allow-env tool/asc_submit.ts` (inspect)
- `deno run --allow-read --allow-net --allow-env tool/asc_submit.ts --submit`

**IDs:**

| Resource | ID |
|----------|-----|
| App | `6790234719` |
| Version 1.0 | `0676e217-a370-4728-ab95-39a65ce42515` |
| App info | `29c5b16f-aa14-4ab4-90b9-1d77be68a237` |
| Review detail | `c4685cc0-a698-42ab-a5a6-9fc042ae0e2d` |
| Review submission (active) | `4e8ec146-4676-44e7-be7a-a821c5bda25c` |
| Sub monthly (subscriptions API) | `6792454070` |
| Sub yearly (subscriptions API) | `6792454034` |
| IAP monthly (legacy) | `ebfcdd34-137b-4f9e-8b74-2c3cbeb17083` |
| IAP yearly (legacy) | `f1941616-140b-46d0-8580-6d3bf6d8b839` |

---

## What we completed this run

1. **App Privacy** — user confirmed published in ASC UI.
2. **Privacy probe** — `addVersion` to review submission succeeded (no `APP_DATA_USAGES_REQUIRED`).
3. **Submit for Review** — created submission `4e8ec146…`, attached version 1.0, `PATCH submitted: true` → **WAITING_FOR_REVIEW**.
4. **Subscriptions** — API attach failed (`subscription` relationship unknown); app submitted without them.
5. **Phone** — placeholder unchanged; did not block submission.
6. **Release** — N/A until approval (`MANUAL` release after **PENDING_DEVELOPER_RELEASE**).

---

## Next steps

### 1. Verify subscriptions in review (optional, ~2 min)

In [App Store Connect](https://appstoreconnect.apple.com/) check whether **AI Pro Monthly** and **AI Pro Yearly** are included in the current review. If not:

**StillScout → Subscriptions → [product] → Submit for Review**

### 2. Review phone — recommended

Replace `+977 980-000-0000` if Apple contacts you during review:

**StillScout → iOS App → 1.0 → App Review Information → Phone**

Or API: `PATCH /appStoreReviewDetails/c4685cc0-a698-42ab-a5a6-9fc042ae0e2d`

### 3. After approval (manual release only)

When state is **PENDING_DEVELOPER_RELEASE**, click **Release This Version**. Do not auto-release.

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
| 2026-08-01 | User published App Privacy in ASC UI |
| 2026-08-01 | **SUBMITTED** — version 1.0 → **WAITING_FOR_REVIEW** (`4e8ec146…`) |
