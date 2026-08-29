# Distribution Guide

**Purpose:** Steps to produce a signed, notarized macOS build of Personal Wallpaper Engine for **direct download** (outside the Mac App Store), and pointers for the **Mac App Store** path.

**Strategy (App Store vs Direct vs Steam):** See [`DISTRIBUTION_CHANNELS.md`](DISTRIBUTION_CHANNELS.md). **Launch order (2026-08-20):** App Store first, Direct second. Direct how-to remains in this document; MAS process is in [`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md).

**Prerequisites (Direct):** Apple Developer account, Developer ID Application certificate, Xcode 16+, macOS 15+ build host.  
**Prerequisites (App Store):** Same membership + Mac App Store distribution certificate / provisioning — see submission guide.

---

## 1. Version and metadata

Before each release, update in Xcode target **Personal Wallpaper Engine**:

| Setting | Location |
|---------|----------|
| Marketing Version | `MARKETING_VERSION` (currently 1.0) |
| Build number | `CURRENT_PROJECT_VERSION` (increment every upload) |
| Copyright | `INFOPLIST_KEY_NSHumanReadableCopyright` |

The app uses **LSUIElement** (menu bar agent) and shows the dock icon when the main window is visible (`DockAgentPolicy`). Document this clearly in App Store review notes.

---

## 2. Entitlements and sandbox

Entitlements file: [`Personal Wallpaper Engine/Personal Wallpaper Engine.entitlements`](../Personal%20Wallpaper%20Engine/Personal%20Wallpaper%20Engine.entitlements)

| Entitlement | Purpose |
|-------------|---------|
| App Sandbox | Required for notarization and for Mac App Store |
| User-selected read-only files | Pick wallpapers and library folders |
| App-scoped bookmarks | Persist access across relaunch |

**Network:** Local video wallpapers do not need network. **Web wallpapers** (`WebRenderer` / WKWebView loading `http`/`https` URLs) require `com.apple.security.network.client` under App Sandbox — add for Mac App Store (and any sandboxed Direct build that ships remote web wallpapers). Add outbound network for Sparkle only when Direct auto-update is implemented (Milestone 3).

**App Group:** Required when Tier B screensaver ships (Milestone 2); not present in current entitlements plist.

---

## 3. Release build (Direct / Developer ID)

```bash
cd "/Users/arnev/Desktop/Personal Wallpaper Engine"
xcodebuild \
  -scheme "Personal Wallpaper Engine" \
  -configuration Release \
  -derivedDataPath /tmp/PWE_Release \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="Developer ID Application: YOUR NAME (TEAMID)" \
  build
```

When the **`PWE Direct`** scheme exists (V2.2 M3), prefer that scheme with `DIRECT_BUILD`. Until then, the default scheme is the single-flavor baseline.

Verify locally:

```bash
open /tmp/PWE_Release/Build/Products/Release/Personal\ Wallpaper\ Engine.app
```

---

## 4. Code signing verification

```bash
codesign --verify --deep --strict --verbose=2 \
  "/tmp/PWE_Release/Build/Products/Release/Personal Wallpaper Engine.app"

spctl --assess --type execute --verbose=4 \
  "/tmp/PWE_Release/Build/Products/Release/Personal Wallpaper Engine.app"
```

---

## 5. Notarization

Create a zip for notary upload:

```bash
ditto -c -k --keepParent \
  "/tmp/PWE_Release/Build/Products/Release/Personal Wallpaper Engine.app" \
  Personal-Wallpaper-Engine.zip

xcrun notarytool submit Personal-Wallpaper-Engine.zip \
  --apple-id "your@email.com" \
  --team-id "W2A9J24774" \
  --password "@keychain:AC_PASSWORD" \
  --wait
```

Staple the ticket:

```bash
xcrun stapler staple \
  "/tmp/PWE_Release/Build/Products/Release/Personal Wallpaper Engine.app"
```

---

## 6. DMG packaging (optional)

Use [create-dmg](https://github.com/create-dmg/create-dmg) or `hdiutil`:

```bash
create-dmg \
  --volname "Personal Wallpaper Engine" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --app-drop-link 425 190 \
  "Personal-Wallpaper-Engine-1.0.dmg" \
  "/tmp/PWE_Release/Build/Products/Release/Personal Wallpaper Engine.app"
```

Sign the DMG:

```bash
codesign --force --sign "Developer ID Application: YOUR NAME (TEAMID)" \
  Personal-Wallpaper-Engine-1.0.dmg
```

---

## 7. Privacy and support

Publish the privacy statement from [`PRIVACY_POLICY.md`](PRIVACY_POLICY.md) (host a copy for App Store Connect and the website):

- No account required
- No analytics or telemetry in current design
- Wallpaper files stay local; bookmarks stored on device
- Optional future: Sparkle update checks on Direct (document when added)

**Direct builds:** Point **Check for Updates…** in Settings to your release page until Sparkle is integrated ([`UpdateChecker.swift`](../Personal%20Wallpaper%20Engine/UpdateChecker.swift)).

**Mac App Store builds:** Must **not** open external update URLs; updates come only from the App Store (`#if APP_STORE_BUILD`).

---

## 8. CI regression (pre-release)

```bash
CODE_SIGNING_ALLOWED=NO ./scripts/chunk7_regression.sh
```

Smoke failures now fail the regression script. The regression script runs `build-for-testing` before `test-without-building` (app-hosted tests are not built by plain `build`), then unit tests with a concrete `platform=macOS,arch=$(uname -m)` destination via `XCODEBUILD_DESTINATION` in [`scripts/chunk7_regression.sh`](../scripts/chunk7_regression.sh). Run unit tests locally:

```bash
xcodebuild test \
  -scheme "Personal Wallpaper Engine" \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO
```

Also complete [`PRE_RELEASE_CHECKLIST.md`](PRE_RELEASE_CHECKLIST.md) (including App Store section when shipping MAS).

---

## 9. Mac App Store path

**Preferred first public channel** (see [`DISTRIBUTION_CHANNELS.md`](DISTRIBUTION_CHANNELS.md) §0). Detailed process: [`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md). Engineering charter: [`V2_2_APP_STORE_IMPLEMENTATION.md`](V2_2_APP_STORE_IMPLEMENTATION.md).

### Requirements checklist

| Item | Status / action |
|------|-----------------|
| App Sandbox | Already enabled — keep |
| Network client entitlement | **Shipped** (M1 — web wallpapers) |
| `PrivacyInfo.xcprivacy` | **Shipped** (M1) |
| Mac App Store provisioning | Configure on `PWE App Store` scheme |
| `Configurations/AppStore.xcconfig` | **Shipped** — `APP_STORE_BUILD`, `Release-AppStore` |
| `Configurations/Direct.xcconfig` | **Shipped** — `DIRECT_BUILD` for Debug/Release |
| Disable external updater UI | **Shipped** — `#if APP_STORE_BUILD` |
| Tier C lock live video | **Never** on MAS |
| `LSUIElement` | Allowed with justification — explain in review notes; do not remove unless Review requires it |
| Sparkle | Must not ship on MAS |

### Build model

- Same git **`main`** as Direct
- Separate **scheme / xcconfig / entitlements** (`APP_STORE_BUILD`)
- **Do not** maintain a permanent `app-store` git branch

Milestone 1 is on `main` via **`PWE App Store`** / `Release-AppStore`. Day-to-day Debug/Release uses **`Direct.xcconfig`** (`DIRECT_BUILD`).

---

## References

- [`PRE_RELEASE_CHECKLIST.md`](PRE_RELEASE_CHECKLIST.md)
- [`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md)
- [`DISTRIBUTION_CHANNELS.md`](DISTRIBUTION_CHANNELS.md)
- [`PRIVACY_POLICY.md`](PRIVACY_POLICY.md)
- [`V1_SIGNOFF.md`](V1_SIGNOFF.md)
- [`PERFORMANCE_TUNING.md`](PERFORMANCE_TUNING.md)
- [`V2_2_DIRECT_IMPLEMENTATION.md`](V2_2_DIRECT_IMPLEMENTATION.md)
