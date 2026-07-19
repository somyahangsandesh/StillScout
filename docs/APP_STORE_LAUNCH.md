# App Store launch — remaining ops

Code + legal defaults are ready. Complete these outside the repo before submit.

## Done in this project

- In-app Privacy Policy + Terms (paywall + empty state + Settings)
- Canonical hosted legal URLs (live on GitHub Pages, HTTP 200):
  - Privacy: https://somyahangsandesh.github.io/StillScout/legal/privacy.html
  - Terms: https://somyahangsandesh.github.io/StillScout/legal/terms.html
  - Support: https://somyahangsandesh.github.io/StillScout/legal/support.html
  - Index: https://somyahangsandesh.github.io/StillScout/
- Source HTML: `docs/legal/*.html` (also listed in `docs/legal/HOSTED_URLS.txt`)
- Privacy manifest, Info.plist purpose strings, release AI-key gate
- TestFlight upload defaults to **Supabase-only** AI (no client Gemini keys)
- Preflight: `dart run tool/check_release_secrets.dart`

## You must finish (cannot be done without your accounts)

### 1. RevenueCat production Apple key

Your `secrets.local.dart` still needs a production key for store builds:

1. Open [RevenueCat](https://app.revenuecat.com) → StillScout iOS app (`com.stillscout.stillscout`)
2. Copy the **public** Apple SDK key (`appl_…`)
3. Paste into `secrets.local.dart` → `revenueCatAppleApiKey`
4. Create entitlement `pro`, offering `stillscout_main`, products `stillscout_pro_monthly` / `stillscout_pro_yearly`

Then re-run:

```bash
dart run tool/check_release_secrets.dart
```

### 2. App Store Connect — paste these URLs

In **App Store Connect → StillScout → App Information**:

1. **Privacy Policy URL** → `https://somyahangsandesh.github.io/StillScout/legal/privacy.html`
2. **Support URL** → `https://somyahangsandesh.github.io/StillScout/legal/support.html`
3. **App description**: include Terms link `https://somyahangsandesh.github.io/StillScout/legal/terms.html` (or Apple Standard EULA)
4. App Privacy nutrition labels: Photos/Videos, Device ID, Purchase History — not used for tracking
5. Accept **Paid Applications Agreement** + banking/tax
6. Create auto-renewable IAPs matching the product IDs above (pricing is interactive in ASC)
7. Screenshots + review notes (mention Restore Purchases on the paywall / Settings)

### 3. Supabase

Deploy the `vision-score` Edge Function and set the Gemini secret:

```bash
export PATH="$HOME/.local/bin:$PATH"
supabase login
bash tool/deploy_vision_score.sh
supabase secrets set GEMINI_API_KEY='your_key' --project-ref iklpevzosgvdaouudaim
```

Confirm `supabaseUrl` / anon key in `secrets.local.dart` match the dashboard.

### 4. Custom domain (optional later)

Legal pages are already live on GitHub Pages. When ready, point `stillscout.app` at Pages and override defaults with `--dart-define=PRIVACY_POLICY_URL=…` (etc.), or update `StillScoutConfig` + `HOSTED_URLS.txt`.

### 5. TestFlight emergency direct keys (optional)

Only if Supabase is down during internal testing:

```bash
STILLSCOUT_ALLOW_DIRECT_AI_KEYS=1 bash tool/upload_testflight.sh
```

Never use that flag for App Store submission builds.
