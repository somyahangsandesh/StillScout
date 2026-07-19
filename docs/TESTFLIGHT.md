# TestFlight setup (do not App Store release)

App Store Connect app for StillScout is registered. Use this path for **TestFlight only**.

## Important: TestFlight does NOT need your iPhone registered

If the phone can’t enable **Developer Mode** (financed / restricted device), that’s fine.

| Path | Needs Developer Mode? | Needs UDID registered? |
|------|----------------------|-------------------------|
| Xcode cable install | Yes | Yes |
| Ad Hoc IPA | No (for install) | Yes |
| **TestFlight** | **No** | **No** |

**App Store Connect → TestFlight** installs through the TestFlight app with your Apple ID.  
We will **not** submit or release on the App Store.

What we still need from you (one UUID):

1. Open https://appstoreconnect.apple.com/access/integrations/api  
2. Copy **Issuer ID** at the top (looks like `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)  
3. Paste it in chat — **not** the Key ID `725F75L52R`

Then we upload a build to TestFlight only. You install via TestFlight on the iPhone — no Developer Mode.


## One-time machine setup

1. **Xcode signing**
   - Open `ios/Runner.xcworkspace`
   - Runner → Signing & Capabilities → Team = your team (`S8WFJFA85T`)
   - Xcode → Settings → Accounts → Manage Certificates → add **Apple Distribution**

2. **App Store Connect API key**
   - ASC → Users and Access → Integrations → App Store Connect API
   - Confirm / create key id `725F75L52R` (or update `ASC_KEY_ID`)
   - Download `AuthKey_725F75L52R.p8`
   - Copy Issuer ID (UUID)

3. **Credentials file**
   ```bash
   cp secrets.asc.example.env secrets.asc.env
   # edit ASC_ISSUER_ID and ASC_KEY_PATH
   ```

## Build + upload (TestFlight only)

```bash
chmod +x tool/upload_testflight.sh
./tool/upload_testflight.sh
```

This uploads an IPA for TestFlight processing. It does **not** submit the app for App Store review or release.

## After upload

1. ASC → StillScout → **TestFlight** → wait for build processing  
2. Add yourself / internal testers  
3. Install via TestFlight app  
4. Leave Pricing / App Store version **unsubmitted**

## App Store Connect checklist for TestFlight

Minimum usually required before the first binary can process:

- [x] App created with bundle `com.stillscout.stillscout`
- [ ] Privacy Policy URL: `https://stillscout.app/legal/privacy`
- [ ] Export compliance: already set in Info.plist (`ITSAppUsesNonExemptEncryption = false`)
- [ ] Sign Age Rating / content rights when ASC prompts (can be draft)

IAP products can be unfinished for **internal** TestFlight; wire RevenueCat `appl_…` before testing purchases.
