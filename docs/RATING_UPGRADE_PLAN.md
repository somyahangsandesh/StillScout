# StillScout — Rating Upgrade Plan

**Date:** 2026-07-29  
**Baseline:** `docs/FINAL_REVIEW.md` — **8.1 / 10** overall  
**Target ship:** Manual App Store release **Aug 1, 2026**  
**Build target:** `1.0.0+25` (StillScout AI branding on binary)

This document is the ordered work plan to raise every review dimension from current scores toward launch-ready **9.0+** where realistic before Aug 1. Work is split into **code** (agent/repo) vs **user-manual** (ASC clicks, filming, phone number).

---

## Summary table

| # | Area | Current | Target | Primary owner |
|---|------|--------:|-------:|---------------|
| 1 | Architecture & code quality | 8.5 | 9.0 | Code |
| 2 | Core UX flows | 8.0 | 8.8 | Code |
| 3 | AI / StillScout AI | 9.0 | 9.2 | Code + manual smoke |
| 4 | Monetization | 8.0 | 8.8 | Code + ASC submit |
| 5 | Server security | 8.5 | 8.8 | Code (docs/CI) |
| 6 | Privacy / legal | 8.5 | 9.0 | User-manual labels |
| 7 | App Store Connect readiness | 7.5 | 8.8 | Code (build) + user |
| 8 | Secrets / leak risk | 9.0 | 9.0 | Maintain |
| 9 | Test health | 9.0 | 9.2 | Code (CI) |
| 10 | Marketing | 7.5 | 8.0 | User (video) |
| 11 | Shipaton Aug 1 | 7.0 | 8.0 | User + code polish |
| **Overall** | **8.1** | **8.7–8.9** | Both |

**Honest post-work estimate:** **8.7–8.9** if user completes App Privacy, real phone, Submit for Review, and films Shipaton video. Code alone caps around **8.5** without ASC manual steps.

---

## 1. Architecture & code quality (8.5 → 9.0)

### Gaps
- README security section stale (claims no RC webhook entitlements).
- CI omits `revenuecat-webhook` Deno tests.
- Minor Pro naming drift across surfaces.

### P0 (code)
| Item | Acceptance criteria |
|------|---------------------|
| Sync README security with shipped webhook + `pro_entitlements` | README describes RC webhook, server-side Pro lookup, global cap; links `docs/REVENUECAT_WEBHOOK_SETUP.md` |
| Add `revenuecat-webhook/lib_test.ts` to CI | `.github/workflows/ci.yml` runs all three Deno suites green |

### P1 (code)
| Item | Acceptance criteria |
|------|---------------------|
| Unify user-facing Pro name → **StillScout AI Pro** | Paywall footer, gallery lock CTA, settings where easy; no user-visible "StillScout Pro" without "AI" |
| `docs/APP_STORE_LAUNCH.md` subtitle note | Doc matches API truth (subtitle was null at review) |

### P2
- Optional custom domain for legal URLs.
- iPad screenshot set (low priority — portrait + full-screen opt-out).

---

## 2. Core UX flows (8.0 → 8.8)

### Gaps
- TF build 24 still shows "Gemini Flash" in UI; HEAD uses StillScout AI.
- Score/reason buried below polish on frame detail.
- On-the-beat audio boost invisible to users.
- Compare mode not shareable.

### P0 (code)
| Item | Acceptance criteria |
|------|---------------------|
| Ship **build 25+** from HEAD | `pubspec.yaml` `1.0.0+25`; TF binary shows StillScout AI strings |
| Kill user-facing Gemini strings | Presentation layer uses `StillScoutConfig.geminiModelDisplayName` / StillScout AI only; legal HTML may still name Google Gemini |

### P1 (code) — prioritize A, B, D
| Item | Acceptance criteria |
|------|---------------------|
| **A.** On-the-beat badge | Frames within ±400 ms of audio peak show "On the beat" badge in gallery + frame detail |
| **B.** Score + reason prominence | Frame detail shows large score + AI reason above fold, before polish controls |
| **D.** Shareable compare export | Compare sheet exports side-by-side PNG via share sheet |
| **E.** Paywall/onboarding microcopy | Consistent StillScout AI Pro voice; trial step mentions StillScout AI |

### P2
- Timeline scrubber polish.
- Haptic on compare winner.

---

## 3. AI / StillScout AI (9.0 → 9.2)

### Gaps
- `VNGenerateImageAestheticsScores` stubbed at -1 in Swift plugin.
- TF24 binary marketing mismatch.

### P0
| Item | Owner | Acceptance criteria |
|------|-------|---------------------|
| Upload build 25 | Code + user | Device paywall/completion hero says StillScout AI |

### P1 (code)
| Item | Acceptance criteria |
|------|---------------------|
| Wire aesthetics scores (iOS 17+) | Swift returns 0–1 aesthetics when available; blended into composition in Vision path; -1 fallback unchanged on older OS |
| Smoke: live `vision-score` 200 | `check_release_secrets` PASS; Supabase batch returns scores |

### P2
- Signed device attestation header (post-launch abuse hardening).

---

## 4. Monetization (8.0 → 8.8)

### Gaps
- Stale TF paywall copy.
- Sandbox purchase → webhook → `pro_entitlements` row not verified on device.

### P0
| Item | Owner | Acceptance criteria |
|------|-------|---------------------|
| Build 25 on ASC version 1.0 | Code upload + user attach | Version 1.0 linked to build ≥25 after processing |
| IAPs Ready to Submit | User | Monthly + yearly still READY_TO_SUBMIT at submit time |

### P1
| Item | Owner | Acceptance criteria |
|------|-------|---------------------|
| Sandbox buy + Restore smoke | User | Settings shows StillScout AI Pro active; server sees entitlement |
| Paywall microcopy polish | Code | Hero StillScout AI Pro; subscription footer uses same name |

### P2
- Win-back / intro offer (not in scope for Aug 1).

---

## 5. Server security (8.5 → 8.8)

### Gaps
- README implied no server entitlements.
- CI didn't run webhook tests.

### P0 (code)
| Item | Acceptance criteria |
|------|---------------------|
| README + CI fixes | Documented webhook path; CI runs webhook Deno tests |

### P1 (user-manual)
| Item | Acceptance criteria |
|------|---------------------|
| RC webhook live event | Dashboard test event 200; row in `pro_entitlements` |
| `usage-alert` cron + webhook URL | Optional Slack/Discord per `docs/USAGE_ALERTS_SETUP.md` |

### P2
- Receipt verification on every `vision-score` call (heavy; bounded risk accepted for Shipaton).

---

## 6. Privacy / legal (8.5 → 9.0)

### P0 (user-manual — API unsupported)
| Item | Acceptance criteria |
|------|---------------------|
| App Privacy nutrition labels | Photos/Videos, Device ID, Purchase History; **not** tracking; matches `PrivacyInfo.xcprivacy` + privacy.html |

### P1 (code — done)
- Hosted legal pages 200; in-app links; Privacy manifest bundled.

### P2
- Soften privacy HTML meta "Gemini" (optional; legal transparency OK as-is).

---

## 7. App Store Connect readiness (7.5 → 8.8)

### Gaps
- Build 24 attached; subtitle null in API; placeholder phone.

### P0
| Item | Owner | Acceptance criteria |
|------|-------|---------------------|
| Build 25 upload | Code | `tool/upload_testflight.sh` succeeds |
| Attach build to 1.0 | User | ASC version shows build 25 VALID |
| Subtitle en-GB + en-US | Code script if creds exist | `tool/set_asc_subtitle.ts` sets ~30-char subtitle |

### P0 (user-manual)
| Item | Acceptance criteria |
|------|---------------------|
| Real review phone | Replace `+977 980-000-0000` placeholder |
| App Privacy labels | Complete |
| Submit for Review | App + subscriptions together; **manual** release after approval |

### P1
- Replace synthetic screenshots with real device captures if Apple requests.

---

## 8. Secrets / leak risk (9.0 → 9.0)

### Maintain
- No secrets in git; `check_release_secrets.dart` before TF upload.
- No `ALLOW_DIRECT_AI_KEYS` on App Store path.

**No code changes required** unless regression found.

---

## 9. Test health (9.0 → 9.2)

### P0 (code)
| Item | Acceptance criteria |
|------|---------------------|
| `flutter analyze` clean | 0 errors; fix info if trivial |
| `flutter test` | All pass |
| Deno: vision-score + usage-alert + revenuecat-webhook | All pass locally + CI |

### P1
- Widget test for compare export (optional).

---

## 10. Marketing (7.5 → 8.0)

### P0 (user-manual)
| Item | Acceptance criteria |
|------|---------------------|
| Shipaton / demo vertical video | 15–30 s screen recording from `docs/marketing/instagram_story_ads.md` scripts |
| Story ad HTML screen-record | https://somyahangsandesh.github.io/StillScout/marketing/stillscout_story_ad_animated.html |

### P1 (code — done)
- Playbook + animated HTML + layouts in repo.

### P2
- Paid Meta placements.

---

## 11. Shipaton Aug 1 readiness (7.0 → 8.0)

### Ready (code/product)
- Core scout loop, Pro monetization, legal site, backend caps, marketing HTML.

### P0 blockers (user)
1. App Privacy labels  
2. Real review phone  
3. Submit for Review (allow approval lag before Aug 1 manual release)  
4. Shipaton demo video  

### P0 (code)
- Build 25 with StillScout AI branding  

### P1
- Sandbox purchase proof for contest demo  
- Social post with story ad URL  

---

## Execution phases (this session)

### Phase 0 — This document ✓

### Phase 1 — P0 code
1. `pubspec.yaml` → `1.0.0+25`
2. README security sync
3. `tool/set_asc_subtitle.ts` + run if creds present
4. StillScout AI Pro naming pass
5. CI: revenuecat-webhook Deno tests
6. `flutter analyze` + `flutter test` + deno tests
7. TestFlight upload if signing allows
8. User-facing Gemini string audit

### Phase 2 — P1 polish
- A on-the-beat badge  
- B score/reason prominence  
- C aesthetics scores iOS 17+  
- D compare share export  
- E paywall/onboarding copy  

### Phase 3 — Ship
- `docs/PRE_AUG1_CHECKLIST.md` (user-only)  
- Commit + push `origin/main`  
- Updated rating estimates in session summary  

---

## User-only checklist (see also `docs/PRE_AUG1_CHECKLIST.md`)

1. App Store Connect → App Privacy → complete nutrition labels  
2. Replace review phone with real reachable number  
3. Wait for TF build 25 processing → attach to version 1.0  
4. Submit for Review (app + IAPs); keep **manual** release  
5. Sandbox: purchase → Restore → confirm Pro UI + webhook row  
6. Film Shipaton vertical demo (no Gemini on screen — StillScout AI only)  
7. On approval (≤ Aug 1): **Release This Version** manually  

---

## Evidence commands

```bash
dart run tool/check_release_secrets.dart
flutter analyze && flutter test
deno test --allow-read supabase/functions/vision-score/lib_test.ts
deno test supabase/functions/usage-alert/lib_test.ts
deno test supabase/functions/revenuecat-webhook/lib_test.ts
bash tool/upload_testflight.sh   # when signing + ASC creds ready
deno run --allow-read --allow-net --allow-env tool/set_asc_subtitle.ts
```
