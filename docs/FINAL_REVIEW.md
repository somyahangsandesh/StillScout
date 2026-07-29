# StillScout — Final Whole-Product Review

**Date:** 2026-07-29  
**Workspace:** `/Users/sandeshsomyahang/stillscout`  
**Branch tip reviewed:** `main` @ `c20e5b8` (+ this review commit)  
**Review type:** Report only (no feature work). Evidence from code paths, App Store Connect API, live HTTP probes, `flutter test` / `flutter analyze`, and Deno edge-function tests.

---

## Executive verdict

StillScout is **shippable for an Aug 1 manual-release plan** if you close a short, ordered ops list: App Privacy nutrition labels, real review phone, upload **build 25+** (HEAD paywall/AI branding is ahead of TestFlight **build 24**), Submit for Review with IAPs, and produce Shipaton video creatives.

Product/engineering quality is strong: clean Flutter layered architecture, soft-degrade cloud AI, server-verified Pro entitlements, global spend circuit-breaker, live Gemini via Supabase (HTTP 200), and a green test suite (**161** Flutter + **62** Deno). The largest launch risks are **stale TF binary vs HEAD copy**, **manual ASC leftovers**, and **marketing/demo video gaps** — not core pipeline correctness.

**Overall score: 8.1 / 10** (go-live ready with the checklist below; not “submit tonight” without build 25 + privacy labels + phone).

---

## Ratings table

| Area | Score | Notes |
|------|------:|-------|
| 1. Architecture & code quality | **8.5** | Clear domain/data/presentation/services split; constants + access policy as SSOT; minor docs drift |
| 2. Core UX flows | **8.0** | Onboarding → scout → gallery → export → paywall is coherent; naming mix (AI Pro / StillScout Pro) |
| 3. AI / Gemini / StillScout AI | **9.0** | Live proxy 200; soft-degrade + quota outcomes; intents wired; release keys server-side |
| 4. Monetization | **8.0** | Paywall + Restore solid on HEAD; TF24 stale (“Gemini Flash”); RC `appl_` present locally |
| 5. Server security | **8.5** | Webhook + entitlements + global cap deployed; residual anon-key proxy risk bounded |
| 6. Privacy / legal | **8.5** | Hosted pages 200; in-app copy; PrivacyInfo; ASC App Privacy still manual |
| 7. App Store Connect readiness | **7.5** | IAPs READY_TO_SUBMIT; build 24 attached; privacy labels + phone + subtitle gap |
| 8. Secrets / leak risk | **9.0** | Gitignored secrets; release gate script PASS; no committed private keys found |
| 9. Test health | **9.0** | 161 Flutter pass; 1 analyze info; 62 Deno pass (incl. webhook helpers) |
| 10. Marketing | **7.5** | Story playbook + animated HTML ad live; no filmed Shipaton/App Preview video |
| 11. Shipaton Aug 1 readiness | **7.0** | Product+ASC mostly ready; contest video / social proof incomplete |
| **Overall** | **8.1** | |

---

## Area-by-area review (detailed)

### 1. Architecture & code quality — 8.5

**What’s in place**

- Flutter iOS-only app (`com.stillscout.stillscout`), Riverpod, Hive persistence.
- Layering under `lib/stillscout/`:
  - `domain/` — `stillscout_constants.dart`, `stillscout_access_policy.dart`, repositories, failures
  - `data/` — models + repository impls
  - `services/` — extract / dedup / Vision / scoring / export / quotas
  - `presentation/` — screens, notifier, widgets, theme
- Cloud AI cascade: `VisionCascadeOrchestrator` → Supabase `vision-score` first, direct Gemini only when `ALLOW_DIRECT_AI_KEYS` / debug (`lib/stillscout/services/vision/vision_cascade_orchestrator.dart`).
- Bootstrap: Hive + maintenance + RevenueCat (`lib/bootstrap/app_bootstrap.dart`).
- Edge functions: `vision-score`, `revenuecat-webhook`, `usage-alert` under `supabase/functions/`, with pure `lib.ts` helpers for Deno unit tests.
- CI: `.github/workflows/ci.yml` runs Flutter analyze/test + Deno tests for vision-score + usage-alert.

**Evidence of polish**

- Access policy centralizes keepers / exports / cloud AI / polish gates.
- Quota coordinator consumes free scout / trial / first-scout bonus only when Gemini actually reaches (covered in notifier tests).
- Diagnostics path redaction tested (`StillScoutDiagnosticsLog`).

**Gaps**

- `README.md` security section is **stale**: still claims “No RevenueCat receipt verification server-side” and lists webhook as a future step — that work shipped in `6f5acca` / `docs/REVENUECAT_WEBHOOK_SETUP.md`.
- Brand naming inconsistency across surfaces: **AI Pro** / **StillScout AI Pro** / **StillScout Pro** (paywall footer, legal, gallery).
- CI does not yet run `supabase/functions/revenuecat-webhook/lib_test.ts` (tests exist and pass locally).

---

### 2. Core UX flows — 8.0

| Flow | Path | Status |
|------|------|--------|
| Splash → onboarding | `stillscout_splash_screen.dart`, `stillscout_onboarding_screen.dart` | Present; step 4 Pro upsell + “Try AI Pro” |
| Import / record → preflight → scout | `stillscout_screen.dart`, `stillscout_preflight_card.dart`, notifier `processVideo` | Free offline scouts; Pro/trial need network |
| Gallery / top picks | `stillscout_results_gallery.dart`, `stillscout_top_picks_carousel.dart` | Free 5 keepers (8 first scout); Pro 20; locked teasers |
| Detail / polish / export | frame detail sheet, export service, `gal` / share | Free 3 exports/scout; Pro unlimited + 4K re-extract |
| History | `stillscout_history_screen.dart`, Hive sessions | Cap 20 sessions / 512 MB |
| Settings / Restore / legal | `stillscout_settings_screen.dart`, legal screen | Restore + hosted legal links |
| Paywall | `stillscout_paywall_sheet.dart` | Monthly/yearly toggle, Restore, pending-payment banner |

**Soft-degrade UX:** `CloudScoringOutcome` (`full` / `degraded` / `quotaExceeded`) drives completion hero + snacks — Retry only when degraded, not when quota exhausted (`stillscout_screen.dart`, `stillscout_completion_hero.dart`).

**Minor UX debt:** product display name mix; gallery still has “Unlock… with StillScout Pro” while paywall hero says “StillScout AI Pro”.

---

### 3. AI / Gemini / StillScout AI — 9.0

**Client**

- User-facing model brand on HEAD: `StillScoutConfig.geminiModelDisplayName = 'StillScout AI'` (`lib/config/stillscout_config.dart`).
- Score source label: `ScoreSource.llm => 'StillScout AI'`.
- Intents / contexts: `StillScoutVideoContext` (auto/portrait/action/landscape/event) with weight maps; sent as `context` on Supabase batch.
- Pipeline: extract 1s interval (max 180) → perceptual dedup → on-device Vision reject → (Pro/trial) batch up to 48 grid thumbs → top 20 keepers.

**Live probe (2026-07-29)**

- Host: `zyadgkgumdgussvkgtsr.supabase.co`
- Unauthenticated `POST vision-score` → **401**
- Authenticated empty body → **400** `missing_images`
- Authenticated 1×1 JPEG batch → **200** with `scores` + `picks` (Gemini path live)

**Soft-degrade**

- `frame_scoring_service.dart` soft-degrades to Vision when cloud batch unavailable.
- Notifier distinguishes quota vs degrade; trial not consumed if Gemini never runs (tests green).

**TF vs HEAD branding (critical for store binary)**

| | TestFlight build 24 tip (`b85b5f6`, version `1.0.0+24`) | HEAD |
|--|--|--|
| `geminiModelDisplayName` | **`Gemini Flash`** | **`StillScout AI`** |
| Free scouts/day | 5 | 5 |

Do **not** submit build 24 if you want marketing/legal UI to say StillScout AI.

---

### 4. Monetization — 8.0

**Product rules (code SSOT)**

- Free: 5 scouts/day UTC, 5 keepers (8 first), 3 exports/scout, on-device scoring (+ 1 complimentary cloud trial).
- Pro (`pro` entitlement): unlimited scouts (UI), StillScout AI, Auto Polish, 20 keepers, timecodes, timeline, 4K export.
- Products: `stillscout_pro_monthly`, `stillscout_pro_yearly`; offering `stillscout_main`.

**Paywall copy (HEAD)** — `stillscout_paywall_sheet.dart`

- Hero: **StillScout AI Pro**
- Bullets include **StillScout AI judgment**, **Unlimited AI scouts · native 4K saves**
- **Restore Purchases** + payment-pending restore path
- Legal links expected for Guideline 3.1.2

**RevenueCat**

- Local `secrets.local.dart`: production `appl_` key present; `dart run tool/check_release_secrets.dart` → **OK**
- Client sends `app_user_id` from `Purchases.appUserID` into `vision-score` for entitlement lookup

**ASC subscriptions (API)**

- Group: **StillScout AI Pro**
- `stillscout_pro_monthly` / `stillscout_pro_yearly`: **READY_TO_SUBMIT**
- Review screenshots: **COMPLETE** (1242×2688)
- Localizations en-GB + en-US: PREPARE_FOR_SUBMISSION (submit with app)

**Gap:** TF **+24** still shows Gemini Flash in UI strings → ship **+25** from HEAD before review.

---

### 5. Server security — 8.5

| Control | Evidence | Live |
|---------|----------|------|
| Anon JWT required on functions | 401 without auth | Yes |
| Webhook bearer + timing-safe compare | `revenuecat-webhook/lib.ts`; 401 without auth | Deployed |
| `pro_entitlements` fail-closed | `isVerifiedProEntitlement` / Deno tests | Code + migration present |
| Per-device caps | FREE 400 / PRO 5000 picks/day | Code |
| Global ceiling | default 20_000; `GLOBAL_CAP_REACHED` → 429 | `usage-alert` live returns `ceiling:20000` |
| IP rate limit | soft-block ≥90/min | Unit tested |
| Reserve-before-Gemini | Deno asserts order in `index.ts` | Pass |
| usage-alert | Deployed; auth’d POST **200** `ok:true, total:0` | Yes |

**Residual risks (honest)**

- `vision-score` is still an **anon-key proxy**: anyone with the shipped anon key can call it; spend is bounded by device + global caps + IP throttle, not by Apple receipt on every call.
- Until RC webhook has fired for a subscriber, Pro users get **free cap** server-side (fail-safe) — verify a real purchase/test event before launch day demos.
- `usage-alert` Slack/Discord webhook + pg_cron schedule are **ops-config**; function is live but schedule/webhook URL not verified from this review.

**Docs:** follow `docs/REVENUECAT_WEBHOOK_SETUP.md` + `docs/USAGE_ALERTS_SETUP.md`. Update `README.md` security bullets.

---

### 6. Privacy / legal — 8.5

**Hosted (HTTP 200 verified)**

- https://somyahangsandesh.github.io/StillScout/legal/privacy.html
- https://somyahangsandesh.github.io/StillScout/legal/terms.html
- https://somyahangsandesh.github.io/StillScout/legal/support.html
- https://somyahangsandesh.github.io/StillScout/

**In-app:** `stillscout_legal_copy.dart`, legal screen, paywall/empty-state links; defaults in `StillScoutConfig`.

**iOS**

- Purpose strings: Photos, Photos Add, Camera, Mic (`ios/Runner/Info.plist`)
- `PrivacyInfo.xcprivacy`: tracking false; Photos/Videos, Device ID, Purchase History; required-reason APIs
- `ITSAppUsesNonExemptEncryption = false`

**ASC App Information:** privacy URL set (en-GB + en-US).

**Still manual:** App Store Connect **App Privacy** nutrition labels (API unsupported) — must match PrivacyInfo + privacy.html.

**Note:** Legal HTML correctly names Google Gemini for transparency; marketing/UI should keep saying **StillScout AI** (playbook already says this).

---

### 7. App Store Connect readiness — 7.5

**API-verified 2026-07-29**

| Item | Status |
|------|--------|
| App | StillScout / `com.stillscout.stillscout` |
| Version 1.0 | `PREPARE_FOR_SUBMISSION`, releaseType `AFTER_APPROVAL` (manual release OK for Aug 1) |
| Attached build | **24** `VALID` |
| Screenshots iPhone 6.7" | 4× en-GB + en-US, asset state **COMPLETE** |
| Support / marketing URLs | Set to GitHub Pages |
| Description / keywords / promo | Present (desc ~923 chars) |
| Content rights | `DOES_NOT_USE_THIRD_PARTY_CONTENT` |
| Age questionnaire | All defaults / none → consistent with **4+** (brazilAgeRating `L`) |
| Subscriptions | **READY_TO_SUBMIT** + review screenshots COMPLETE |
| Review phone | Placeholder `+977 9***0000` — **replace** |
| Review notes | Mentions subscriptions + Restore |
| **Subtitle** | **Missing (`null`)** — docs claimed “Set”; API shows unset |
| App Privacy labels | **Manual** (not API-confirmable here) |
| Paid Apps / bank / W-8BEN | **User-confirmed Active** (agreements API 404 for this key — trust UI) |

**Screenshot quality:** generated assets under `docs/asc_assets/screenshots/` (~36–68 KB PNGs). API-accepted; consider real device captures before or after first review if Apple pushes back.

---

### 8. Secrets / leak risk — 9.0

| Check | Result |
|-------|--------|
| `secrets.asc.env` / `secrets.local.dart` / `*.p8` gitignored | Yes |
| Committed examples only | `secrets.*.example.*`, stub |
| `check_release_secrets.dart` | **PASS** (empty Gemini, real Supabase, `appl_` RC) |
| Release gate | Direct Gemini stripped unless `ALLOW_DIRECT_AI_KEYS` |
| Repo secret pattern scan (excl. gitignored locals) | No private key / sk_ / live AIza committed |

Ship builds only via `tool/upload_testflight.sh` (Supabase-only AI path).

---

### 9. Test health — 9.0

| Suite | Result |
|-------|--------|
| `flutter analyze` | **1 info** (`prefer_const_declarations` in test) — no errors/warnings |
| `flutter test` | **161 passed** |
| Deno `vision-score/lib_test.ts` | **32 passed** |
| Deno `revenuecat-webhook/lib_test.ts` | **14 passed** (not in CI yet) |
| Deno `usage-alert/lib_test.ts` | **16 passed** |

Strong coverage on quotas, soft-degrade, cascade, access policy, legal readiness, notifier flows.

---

### 10. Marketing — 7.5

Present under `docs/marketing/`:

- `instagram_story_ads.md` — playbook, StillScout AI (no Gemini), 5/day free, unlimited Pro
- `instagram_story_layouts.html` — layout deck
- `stillscout_story_ad_animated.html` — animated “Scroll Trap” ad

**Live on Pages (200):**

- https://somyahangsandesh.github.io/StillScout/marketing/stillscout_story_ad_animated.html
- https://somyahangsandesh.github.io/StillScout/marketing/instagram_story_layouts.html

**Missing for full launch/Shipaton:** filmed vertical demo / App Preview, lifestyle B-roll cut, paid Meta placements (optional).

---

### 11. Shipaton Aug 1 — what’s ready vs missing

**Ready**

- Core product loop + Pro monetization code
- Legal site + in-app compliance scaffolding
- ASC listing mostly filled; IAPs ready; build 24 on version (needs refresh)
- Backend security stack deployed; Gemini live
- Story ad creatives (HTML) ready to screen-record

**Missing / weak**

1. Build **25+** with StillScout AI strings
2. ASC App Privacy labels + real review phone (+ optional subtitle)
3. Submit for Review early enough for Aug 1 **manual** release after approval
4. Shipaton **demo video** (contest-facing) — not in repo
5. README security docs sync
6. Optional: real screenshots, iPad screenshots (portrait-only + full-screen opt-out reduces need), custom domain

---

## Critical / High / Medium / Low issues

### Critical (block store binary / honest marketing)

1. **TF build 24 UI still says “Gemini Flash”** — HEAD says “StillScout AI”. Upload **1.0.0+25** (or higher) from current `main` and attach that build before Submit.  
   Evidence: `git show b85b5f6:lib/config/stillscout_config.dart` vs HEAD.

### High (block or seriously risk Aug 1)

2. **App Privacy nutrition labels** not completed in ASC (manual).  
3. **Review contact phone** is placeholder (`+977 980-000-0000`).  
4. **Submit for Review** not done yet — with manual release Aug 1, approval lag is the schedule risk.  
5. **Shipaton demo video** absent — product can ship; contest submission may fail without it.

### Medium

6. ASC **subtitle** unset despite launch doc claiming set — add ~30-char subtitle.  
7. **README.md** security section outdated (implies no webhook entitlements).  
8. Generated **screenshots** are low-weight / synthetic — review risk.  
9. Product naming inconsistency: AI Pro vs StillScout Pro vs StillScout AI Pro.  
10. Confirm RC dashboard webhook test event + first real entitlement row before Pro demos.  
11. Confirm `usage-alert` cron + `USAGE_ALERT_WEBHOOK_URL` if you want spend pages.  
12. CI omits `revenuecat-webhook` Deno tests.

### Low

13. Single `prefer_const_declarations` analyze info in tests.  
14. Privacy HTML meta still says “Gemini” (fine legally; optional soften).  
15. No iPad-specific screenshot set (mitigated by portrait + full-screen).  
16. `main` was **1 commit ahead of origin** at review start — keep docs/review commits pushed.

---

## Aug 1 go-live checklist (ordered)

1. **Fix ASC review phone** to a real reachable number.  
2. **Complete App Privacy** labels (Photos/Videos, Device ID, Purchase History; not tracking).  
3. **Set subtitle** (en-GB + en-US) if you want the listing complete.  
4. Bump to **`1.0.0+25`**, run `dart run tool/check_release_secrets.dart`, upload TestFlight via `tool/upload_testflight.sh` (**no** `STILLSCOUT_ALLOW_DIRECT_AI_KEYS`).  
5. Attach **build 25+** to version 1.0; confirm paywall shows StillScout AI + Unlimited AI scouts on device.  
6. Confirm IAPs still **Ready to Submit**; Submit **app + subscriptions** together.  
7. Leave release as **manual** (`AFTER_APPROVAL` already).  
8. Smoke: free scout offline → trial online → Restore → Pro gallery/polish/export.  
9. Confirm RC webhook test + `pro_entitlements` row after sandbox purchase.  
10. On approval day (≤ Aug 1): **Manual release** in ASC.  
11. Optional same day: announce with story ad URL / filmed cutdown.

---

## Shipaton checklist

| Item | Status |
|------|--------|
| Working iOS app | Ready (TF exists; refresh to +25) |
| AI differentiation (StillScout AI) | Ready on HEAD; **not** on TF24 |
| Monetization | Ready (RC + ASC IAPs) |
| Legal / privacy URLs | Ready (live 200) |
| Store listing | Mostly ready; privacy labels + phone + submit |
| Story / animated ads | Ready (`docs/marketing/`) |
| Demo / pitch video | **Missing** — film from playbook scripts |
| Social proof / waitlist | Optional |
| Backend reliability | Live Gemini + caps + alerts function |

---

## What’s already excellent

- **Honest AI UX:** soft-degrade vs quota, trial not burned on failure, clear completion outcomes.  
- **Release-safe AI keys:** Gemini only on edge; local release preflight script.  
- **Server-side Pro verification + global spend ceiling** with Deno-tested helpers and live `usage-alert`.  
- **Access-policy SSOT** and broad automated tests (161 + 62).  
- **Legal + support site** already live; in-app Restore and subscription copy for 3.1.2.  
- **Marketing kit** (playbook + animated story ad) ahead of most Shipaton apps.  
- **ASC subscriptions** cleared to READY_TO_SUBMIT with review art.

---

## Evidence appendix (commands / probes)

```text
flutter analyze     → 1 info, 0 errors
flutter test        → 161 passed
deno test (3 fns)   → 32 + 14 + 16 passed
check_release_secrets → OK
Legal/marketing URLs → HTTP 200
vision-score        → 401 (no auth), 400 (bad body), 200 (tiny JPEG)
revenuecat-webhook  → 401 (no auth)
usage-alert         → 401 (no auth), 200 (anon) ceiling=20000
ASC API             → build 24 attached; subs READY_TO_SUBMIT; phone placeholder; subtitle null
```

No secrets are recorded in this document.
