# Distribution Guide

**Purpose:** Steps to produce a signed, notarized macOS build of Personal Wallpaper Engine for direct download (outside the Mac App Store).

**Prerequisites:** Apple Developer account, Developer ID Application certificate, Xcode 16+, macOS 15+ build host.

---

## 1. Version and metadata

Before each release, update in Xcode target **Personal Wallpaper Engine**:

| Setting | Location |
|---------|----------|
| Marketing Version | `MARKETING_VERSION` (currently 1.0) |
| Build number | `CURRENT_PROJECT_VERSION` (increment every upload) |
| Copyright | `INFOPLIST_KEY_NSHumanReadableCopyright` |

The app uses **LSUIElement** (menu bar agent) and shows the dock icon when the main window is visible (`DockAgentPolicy`).

---

## 2. Entitlements and sandbox

Entitlements file: [`Personal Wallpaper Engine/Personal Wallpaper Engine.entitlements`](../Personal%20Wallpaper%20Engine/Personal%20Wallpaper%20Engine.entitlements)

| Entitlement | Purpose |
|-------------|---------|
| App Sandbox | Required for notarization |
| User-selected read-only files | Pick wallpapers and library folders |
| App-scoped bookmarks | Persist access across relaunch |

No network entitlement is required for local-only operation. Add outbound network only if Sparkle auto-update is integrated later.

---

## 3. Release build

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

For public distribution, publish a short privacy statement:

- No account required
- No analytics or telemetry in v1.0
- Wallpaper files stay local; bookmarks stored in UserDefaults on device
- Optional future: Sparkle update checks (document when added)

Point **Check for Updates…** in Settings to your release page until Sparkle is integrated ([`UpdateChecker.swift`](../Personal%20Wallpaper%20Engine/UpdateChecker.swift)).

---

## 8. CI regression (pre-release)

```bash
CODE_SIGNING_ALLOWED=NO ./scripts/chunk7_regression.sh
```

Smoke failures now fail the regression script. Run unit tests:

```bash
xcodebuild test \
  -scheme "Personal Wallpaper Engine" \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO
```

---

## 9. Mac App Store path (alternative)

Mac App Store distribution requires:

- Sandbox-compatible entitlements (already enabled)
- App Store provisioning profile
- Remove or adjust `LSUIElement` if Review requires persistent dock presence
- Sparkle replaced by App Store updates

This repo is currently optimized for **direct Developer ID distribution**.

---

## References

- [`docs/PRE_RELEASE_CHECKLIST.md`](PRE_RELEASE_CHECKLIST.md)
- [`docs/V1_SIGNOFF.md`](V1_SIGNOFF.md)
- [`docs/PERFORMANCE_TUNING.md`](PERFORMANCE_TUNING.md)
