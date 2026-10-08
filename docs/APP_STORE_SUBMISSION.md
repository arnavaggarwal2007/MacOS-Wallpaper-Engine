# Mac App Store Submission Guide — Deskface

**Status:** Deskface **1.0 (2)** has been **live on the Mac App Store since October 6, 2026.** This guide is the procedure for the next update. The 2.3.8 and 1.5 rejection notes below stay as the record of the 1.0 resubmit.  
**Store name:** **Deskface** (display + short name + App Store product name — bundle ID and Xcode target unchanged)  
**Next feature spec:** [`MILESTONE_2.md`](MILESTONE_2.md)  
**Privacy copy:** [`PRIVACY_POLICY.md`](PRIVACY_POLICY.md)  
**Gate:** [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md)  
**Related:** [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

---

## Owner runway (after QA sign-off)

Engineering and manual QA for 1.0 are complete ([`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md) — 2026-08-29). The list below is the record of the **2026-10-01** resubmit. That build has been **live since October 6, 2026**.

| Step | Action | Section |
|------|--------|---------|
| 1 | Push `main` so GitHub Pages serves [`support/index.html`](support/index.html); confirm Support URL loads | §1 |
| 2 | App Store Connect → App Information → Support URL = hosted `/support/` page | §1 |
| 3 | Archive scheme **`PWE App Store`** (build **1.0 (2)**) → **Validate App** → **Distribute** to Connect | §2 |
| 4 | Confirm archived `Info.plist` has `CFBundleDisplayName` + `CFBundleName` = Deskface; product `Deskface.app` | §2 |
| 5 | Attach new build; keep listing name **Deskface**; paste Resolution Center reply (§7) | §7 / §9 |
| 6 | **Submit for Review** | §9 |

Marketing version remains **1.0**; build is **`CURRENT_PROJECT_VERSION` = 2**.

---

## 1. Prerequisites

| Requirement | Value / notes |
|-------------|---------------|
| Apple Developer Program membership | Individual — **Arnav Aggarwal** (owner action) |
| App Store Connect app record | **Deskface** |
| Bundle ID | `Personal.Personal-Wallpaper-Engine` (unchanged by the display-name rename) |
| Mac App Store distribution certificate + provisioning | Xcode Automatic for the `PWE App Store` scheme |
| Marketing version + build | `1.0` / `2` for resubmit after 2.3.8 + 1.5 rejection; increment `CURRENT_PROJECT_VERSION` every upload |
| Privacy policy URL | `https://arnavaggarwal2007.github.io/MacOS-Wallpaper-Engine/privacy/` |
| Support URL | `https://arnavaggarwal2007.github.io/MacOS-Wallpaper-Engine/support/` |
| Review contact | Arnav Aggarwal · arnevaggarrwal@gmail.com · 408-892-7318 |

### Enabling the hosted pages (one-time — **done**; support page added 2026-09-25)

GitHub Pages is **live** (2026-08-23). Privacy verified 2026-08-29. Hosted **Support** page added for Guideline **1.5** (do not use GitHub Issues as the Connect Support URL).

The landing page, privacy policy, and support page are committed as static HTML under [`docs/`](.):
[`index.html`](index.html), [`privacy/index.html`](privacy/index.html), and [`support/index.html`](support/index.html), with `.nojekyll`
so GitHub serves them verbatim.

1. Push `main` to GitHub.
2. Repository **Settings → Pages**.
3. Source: **Deploy from a branch**; Branch: `main`; Folder: **`/docs`**; Save.
4. Wait for the first deploy, then confirm privacy, support, and landing URLs load over HTTPS.

The URLs are compiled into the app via [`AppLinks.swift`](../Personal%20Wallpaper%20Engine/AppLinks.swift),
so they must resolve before submission.

---

## 2. Build and upload

1. Archive with scheme **`PWE App Store`** (Release-AppStore, `APP_STORE_BUILD`).
2. Organizer → **Validate App** — fix any entitlement / privacy / bitcode issues.
3. **Distribute App** → App Store Connect.
4. Confirm `PrivacyInfo.xcprivacy` is in the bundle.
5. Confirm MAS binary does **not** open external update URLs (GitHub releases).
6. **Guideline 2.3.8 check:** In the archive, open `Deskface.app` → Show Package Contents → `Contents/Info.plist` and confirm `CFBundleDisplayName` and `CFBundleName` are both **Deskface**. The product must be **`Deskface.app`**. Bundle ID must remain `Personal.Personal-Wallpaper-Engine`.

The **`PWE App Store`** scheme ships with Release-AppStore / `APP_STORE_BUILD` — use it for all archives.

---

## 3. App Store Connect metadata (final copy — paste as-is)

### Identity

| Field | Value |
|-------|-------|
| App name | `Deskface` |
| Subtitle (30 char max) | `Live wallpapers for your Mac` (28) |
| SKU | `personal.personal-wallpaper-engine` |
| Primary category | Graphics & Design |
| Secondary category | Utilities |
| Price | Free |
| Availability | All countries and regions |
| License | Apple Standard EULA |

**Naming rationale:** every established Mac competitor (Backdrop, Plash, Paper, Wallux, WallTune)
avoids the word “Engine,” which reads as the Steam product. **Deskface** is short and distinctive;
discovery terms go in the subtitle and keyword field, which is where Apple indexes them.

### Keywords (100 char max, comma separated, no spaces)

```text
wallpaper,live wallpaper,video wallpaper,animated,desktop,multi monitor,screen,background
```

### Description

```text
Deskface turns your own video files into live wallpapers for macOS.

Point it at an MP4 or MOV on your Mac and it plays behind your desktop icons, on one display or
on every display independently. Nothing is uploaded, and no account is required.

FEATURES
- Local video wallpapers (MP4, MOV) rendered behind your desktop icons
- Per-display assignment, or one wallpaper spanning all displays
- Collections to group wallpapers, and saved desktop setups you can restore
- A local library that indexes folders of videos with thumbnail browsing
- Quick modes and menu bar controls for switching without opening the window
- Battery-aware pausing and explicit performance profiles
- Drag and drop support for video files
- Optional web wallpapers: render an https page or a local HTML file as your background

PRIVACY
Deskface is local-first. No account, no analytics, no advertising, and no generative AI. Your
wallpaper files never leave your Mac.

NOTE
Deskface runs as a menu bar app. Click the menu bar icon to open the main window. It changes the
desktop wallpaper only; it does not replace the macOS lock screen. Deskface is not affiliated
with, and does not import content from, Wallpaper Engine on Steam.
```

### What's New (version 1.0)

```text
First release.
```

### Promotional text (optional, 170 char max)

```text
Your own videos, playing behind your desktop icons. Per-display control, collections, and battery-aware performance. Local-first, no account.
```

**Do not claim:** lock-screen live video (Tier C, blocked on App Store), a community or Workshop
library, or Wallpaper Engine compatibility.

### Age rating questionnaire — pre-drafted answers

| Question | Answer | Reason |
|----------|--------|--------|
| Cartoon or fantasy violence, realistic violence, guns | None | No game or narrative content |
| Sexual content or nudity, mature or suggestive themes | None | App ships no content of its own |
| Profanity or crude humor, horror or fear themes | None | |
| Alcohol, tobacco, drug use or references | None | |
| Chance-based activities (gambling, simulated gambling, loot boxes, contests) | None | Free app, no IAP in v1.0 |
| Medical or wellness information | None | |
| **Unrestricted web access** | **Yes** | Web wallpaper mode renders any user-entered `https` page in a `WKWebView` |
| User-generated content | No | No accounts, feeds, sharing, or community |
| Messaging and chat, social media | No | |
| Advertising | No | |
| Parental controls / age assurance | No | |

**Expected result: 16+.** Under Apple's current tiers (4+, 9+, 13+, 16+, 18+), declaring
unrestricted web access sets the rating to
[16+](https://developer.apple.com/help/app-store-connect/reference/age-ratings).

**Why declare it:** the user can point the web renderer at an arbitrary `https` page, which meets
Apple's definition ("users can navigate to any webpage within the app"). Under-declaring this is a
well-known metadata-rejection cause. The direct precedent is
[Plash](https://apps.apple.com/us/app/plash/id1494023538?mt=12), the closest Mac App Store analogue,
which ships at **16+** with "Contains Unrestricted Web Access."

The alternative — dropping web wallpaper mode to reach 4+ — was considered and rejected: it is an
established feature and Milestone 1 explicitly committed to keeping it. Revisit only if the 16+
rating measurably hurts discovery.

---

## 4. Privacy nutrition labels

Aligned with [`PRIVACY_POLICY.md`](PRIVACY_POLICY.md):

| Data type | Collect? | Linked to identity? | Used for tracking? |
|-----------|----------|---------------------|--------------------|
| Contact info | No | — | — |
| Location | No | — | — |
| User content (wallpaper files) | **Not collected by developer** — stays on device | No | No |
| Identifiers / diagnostics to Apple | Only if system crash reports (user-controlled) | — | No |
| Advertising data | No | — | No |

**Privacy manifest:** Declare APIs used that require reason codes (e.g. UserDefaults) per Apple’s current required-reason API list. No tracking domains.

**Web wallpapers:** If user pastes a remote URL, the app may load that URL (network entitlement). Document as user-initiated content, not developer analytics. Only **`https://`** and local **`file://`** URLs are accepted — see [`WEB_WALLPAPERS.md`](WEB_WALLPAPERS.md).

**Generative AI:** App does not use generative AI — state in privacy questionnaire and policy ([`PRIVACY_POLICY.md`](PRIVACY_POLICY.md) § Generative AI).

**Export compliance:** Answer that the app uses only exempt/standard encryption (`ITSAppUsesNonExemptEncryption=NO` in build settings).

---

## 5. Review notes template

Paste into App Store Connect **App Review Information → Notes**:

```text
Deskface is a menu bar / agent-style Mac app (LSUIElement) that renders a
user-selected local video, or an optional user-supplied web page, as the desktop
wallpaper behind the icons.

HOW TO OPEN THE MAIN WINDOW
The app has no Dock icon until a window is open. To open it:
1. Click the Deskface icon in the menu bar (top-right of the screen).
2. Choose "Show Main Window."
3. The Dock icon appears while the main window is visible.

On first launch the Home tab shows a "Welcome to Deskface" card with the two
actions needed to get started.

HOW TO TEST IN UNDER A MINUTE
1. Open the main window from the menu bar as above.
2. Click "Choose Wallpaper" and pick any MP4 or MOV file. macOS will prompt for
   file access; this uses the standard open panel and security-scoped bookmarks.
3. The video begins playing as the desktop wallpaper behind the desktop icons.
4. Optional web mode: Settings > Renderer Mode > Web, enter an https URL, then
   Apply. Only https:// URLs and local HTML files are accepted.

NOTES FOR REVIEW
- No account, no login, no analytics SDKs, no advertising, no generative AI.
- No private APIs. The app does not modify the macOS lock screen or screen saver.
- Network access is used only when the user explicitly enters a web wallpaper URL.
- The age rating declares Unrestricted Web Access because of that optional mode.
- Updates are delivered only through the Mac App Store. There is no Sparkle or
  other external updater in this build.
- Deskface is not affiliated with Wallpaper Engine on Steam and does not import
  Steam Workshop content.
```

Attach a short screen recording if Review has historically struggled with agent apps.

---

## 6. Screenshot checklist

Capture on a clean macOS 15+ desktop, Release build, representative wallpaper:

| # | Scene |
|---|--------|
| 1 | Home — hero preview + Apply |
| 2 | Home — display carousel (multi-monitor if available) |
| 3 | Local library grid / Browse Library |
| 4 | Collections or Setups tab |
| 5 | Settings — Battery & Performance / Diagnostics |
| 6 | Menu bar control center open |

After Milestone 2, add: lock export sheet; Screen Saver settings callout.

---

## 7. Rejection playbook (common risks)

| Risk | Mitigation |
|------|------------|
| Reviewer cannot find UI (`LSUIElement`) | Review notes section 5 + first-run welcome card + screen recording |
| Age rating understated | Unrestricted Web Access declared → 16+ (matches Plash) |
| Privacy policy URL dead at review time | Enable GitHub Pages before submitting (section 1) |
| **Guideline 2.3.8 — store name ≠ installed name** | Connect name **Deskface**; `CFBundleDisplayName` + `CFBundleName` = Deskface; Release-AppStore `PRODUCT_NAME` = Deskface (`Deskface.app`). **Do not** change the bundle ID. Verify archive Info.plist before upload. |
| **Guideline 1.5 — Support URL not usable support** | Connect + `AppLinks.support` must be the hosted page `…/support/` (contact + FAQ). GitHub Issues alone is not enough. |
| External payment / update link | MAS flavor must hide GitHub updates; tips only via IAP if unlocking nothing |
| Private API detection | Never ship Tier C on MAS; no undocumented selectors |
| Incomplete privacy | Nutrition labels + `PrivacyInfo.xcprivacy` + hosted policy |
| Crash on launch without sample media | Graceful empty states; ship with clear first-run copy |
| Web wallpaper network surprise | Entitlement present; disclose in privacy text |

### Resolution Center reply template (2.3.8 + 1.5 resubmit)

Paste when resubmitting after the 2026-09-17 rejection:

```
Thank you for the review feedback.

Guideline 2.3.8: The installed app name now matches the App Store name. Both CFBundleDisplayName and CFBundleName are Deskface, and the App Store build product is Deskface.app. The bundle identifier is unchanged (Personal.Personal-Wallpaper-Engine).

Guideline 1.5: The Support URL now points to our hosted support page with contact information and troubleshooting guidance:
https://arnavaggarwal2007.github.io/MacOS-Wallpaper-Engine/support/

Please let us know if anything else is needed.
```

---

## 8. Post-submit

- Respond to Resolution Center within 24–48 hours
- Tag git `v1.0` (or `v1.0-mas`) on the **commit you uploaded** — tagging at upload time is fine; record App Store **approval date** separately in sign-off docs
- Approval is recorded in [`RELEASE_RECORD.md`](RELEASE_RECORD.md): Deskface **1.0 (2)**, **October 6, 2026**.
- Changelog entry in KB `Project-Changelog.md`

---

## 9. Owner step-by-step guide

Engineering and manual QA are complete ([`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md) — 2026-08-29; regression **P** 2026-08-31). Sections **§3–§6** above hold paste-ready copy blocks. This section is the detailed walkthrough.

### What's already done (skip)

- Product code, M1 compliance flavor, privacy manifest, web allowlist
- GitHub Pages live (privacy + landing + **support** URLs)
- Full manual QA + unit tests (Cmd+U passed); **92** tests in repo
- Marketing version **1.0**, build **2** — required for resubmit after rejection of **1.0 (1)**
- Installed-name alignment: `CFBundleDisplayName` / `CFBundleName` = Deskface; App Store product `Deskface.app`

### Quick reference URLs

| Purpose | Value |
|---------|-------|
| Privacy Policy | `https://arnavaggarwal2007.github.io/MacOS-Wallpaper-Engine/privacy/` |
| Support | `https://arnavaggarwal2007.github.io/MacOS-Wallpaper-Engine/support/` |
| Bundle ID | `Personal.Personal-Wallpaper-Engine` |
| Store name | Deskface |
| SKU | `personal.personal-wallpaper-engine` |

### Phase 1 — Xcode signing (~15 min)

**1.1 Open the project**

- Open `Personal Wallpaper Engine.xcodeproj` in Xcode.
- In the scheme picker, select **`PWE App Store`** (not the default “Personal Wallpaper Engine” scheme).

**1.2 Sign in to your Apple Developer account**

- Xcode → Settings → **Accounts**.
- Click **+** → Apple ID → sign in with the Apple ID tied to your paid Developer Program membership.
- Select your team. You should see your team name and role (Account Holder or Admin).

**1.3 Confirm signing for the App Store target**

- Project Navigator → blue **Personal Wallpaper Engine** project.
- Select the **Personal Wallpaper Engine** target (not the test target).
- **Signing & Capabilities:**
  - **Team:** your developer team
  - **Signing:** Automatically manage signing is fine
  - **Bundle Identifier:** `Personal.Personal-Wallpaper-Engine`
- If Xcode shows a yellow warning, click **Try Again** or **Download Manual Profiles**.

**1.4 Optional: verify certificates**

- Accounts → select your team → **Manage Certificates…**
- You want an **Apple Distribution** (Mac App Store) certificate. Xcode usually creates one on first archive.

**1.5 Quick build check (optional)**

- Scheme: **PWE App Store** → Product → Build (`Cmd+B`). Fix signing errors before archiving.

### Phase 2 — App Store Connect app record (~20 min)

**2.1 Create the app**

- Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com).
- **Apps** → **+** → **New App**.
- Platforms: **macOS** · Name: **Deskface** · Primary language: English (U.S.)
- Bundle ID: `Personal.Personal-Wallpaper-Engine` (create App ID in Certificates, Identifiers & Profiles first if missing)
- SKU: `personal.personal-wallpaper-engine` · User Access: Full Access → **Create**

**2.2 Set required URLs early**

App Information → set Privacy Policy and Support URLs from the table above. Save and confirm both load in a browser.

**2.3 App Review contact**

App Review Information: Arnav Aggarwal · 408-892-7318 · arnevaggarrwal@gmail.com. Paste review notes in Phase 5.

### Phase 3 — Archive, validate, and upload (~30–60 min)

**3.1 Prepare**

- Scheme **PWE App Store**, destination **My Mac**.
- Target **General:** Version **1.0**, Build **1** (do not change unless build 1 was already uploaded).

**3.2 Archive**

- Product → **Archive**. Organizer opens with the new archive.
- If **Archive** is grayed out: destination must be **My Mac** and scheme **PWE App Store**.

**3.3 Validate**

- Organizer → select archive → **Validate App** → your team, Mac App Store distribution.
- Fix errors before distributing (signing, entitlements).

**3.4 Upload**

- **Distribute App** → App Store Connect → **Upload** → follow wizard.

**3.5 Processing**

- Connect → Deskface → build section. Status **Processing** (often 10–30 minutes).
- When **Ready to Submit**, continue. Read Apple's email if processing fails.

**3.6 Export compliance**

- Encryption: Yes (HTTPS only). Exempt: Yes — `ITSAppUsesNonExemptEncryption=NO` is in the project.

### Phase 4 — Store listing metadata (~30 min)

On the version page (e.g. **1.0 Prepare for Submission**), use **§3** above for identity, keywords, description, What's New, and promotional text.

### Phase 5 — Privacy, age rating, and review notes (~20 min)

- **App Privacy:** Data Not Collected — matches [`PRIVACY_POLICY.md`](PRIVACY_POLICY.md).
- **Age rating:** use **§3** questionnaire — **Unrestricted Web Access = Yes** → expect **16+**.
- **Review notes:** paste **§5** template. Optional: 30–60 s screen recording (menu bar → Show Main Window → Choose Wallpaper → video on desktop).

### Phase 6 — Screenshots (~30–60 min)

Capture per **§6** on clean macOS 15+, Release **PWE App Store** build. Recommended **1280×800** or **1440×900**. Upload all six for macOS.

### Phase 7 — Submit for review (~10 min)

1. Version page → **Build** → select build **1.0 (2)** (or current `CURRENT_PROJECT_VERSION`).
2. Final checklist: build ready, 6 screenshots, metadata, privacy + **support** URLs, App Privacy, age **16+**, review notes, contact info.
3. Reply in Resolution Center with the §7 template if this is a resubmit after rejection.
4. **Submit for Review**. Status → **Waiting for Review** (hours to a few days typical).

### Phase 8 — After submission

- Monitor **Resolution Center** daily; respond within 24–48 hours.
- **Approved and released:** Deskface **1.0 (2)** has been live since **October 6, 2026**. Record is [`RELEASE_RECORD.md`](RELEASE_RECORD.md).
- **If rejected:** see **§7** rejection playbook. Increment **Build**, re-archive, re-upload.

### What you do not need for v1.0 MAS

- Direct DMG / notarization / Developer ID distribution
- Milestone 2 (lock screen export, screensaver)
- Changing the **bundle ID** (breaks upgrades — Apple warns against this for 2.3.8 fixes)
- Code changes beyond Validate App / Review failures (name + Support URL fixes already landed for build 2)

### Order of operations (summary)

1. Push Pages; confirm Support URL loads  
2. Connect: set Support URL to `…/support/`  
3. Xcode: **PWE App Store** Archive → Validate → Upload (build **2**)  
4. Connect: wait for build processing  
5. Connect: select build + Resolution Center reply → Submit for Review  
6. Monitor Resolution Center → release when approved  


---

## 9. Version 1.1 draft — do not upload yet

Part 1 (screensaver) is in the tree. **Do not bump the version, archive, or submit** until Product → Test (`Cmd+U`) is green and the screensaver rows in [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md) are signed off. The milestone tag `v1.1` also includes static lock export (Part 2). Prefer one review after Part 2. If you ship the saver alone, use the copy below and do not mention lock-screen export.

The live listing is still **1.0 (2)**. Marketing version in the project stays **1.0** and build stays **2** until that upload.

### Before the archive

1. Register App Group `group.Personal.Personal-Wallpaper-Engine` and saver App ID `Personal.Personal-Wallpaper-Engine.DeskfaceSaver` on team `W2A9J24774`. See [`DISTRIBUTION.md`](DISTRIBUTION.md).
2. Set marketing version **1.1** and build **3** (`CURRENT_PROJECT_VERSION` must be higher than **2**).
3. Publish this privacy-policy edit to GitHub Pages (`docs/privacy/index.html`). App Privacy stays **Data Not Collected**. Age rating stays **16+**.

### Archive

Scheme **PWE App Store**, destination **My Mac**, Product → Archive. In the archive confirm `Deskface.app`, display name Deskface, bundle id `Personal.Personal-Wallpaper-Engine`, `Contents/Library/Screen Savers/Deskface.saver`, and the app group entitlement on the app and the saver. Organizer → Validate App → Distribute App → Upload.

### What’s New (1.1, saver only)

```text
Deskface can now play a video you choose as your screen saver when the Mac is idle.
Pick it in Settings, then select Deskface under System Settings → Screen Saver.
```

### Description note to add

The desktop wallpaper sentence can stay. You may add that Deskface includes an idle video screen saver. Do not say the lock screen plays video.

### Review notes — replace the screen-saver sentence

The 1.0 notes say the app does not modify the screen saver. For 1.1, replace that bullet with:

```text
- No private APIs. The app does not set the macOS lock-screen image and does not play video on the lock screen.
- Screen saver: Settings → Screen Saver → Use the desktop wallpaper (or Choose Screen Saver Video). Then System Settings → Screen Saver → select Deskface. The module is inside the app at Contents/Library/Screen Savers/Deskface.saver. Playback is muted.
```

Add a screenshot of the Screen Saver card. The lock-export screenshot waits for Part 2.

### After approval

Fill the Milestone 2 row in [`RELEASE_RECORD.md`](RELEASE_RECORD.md) only if Part 2 shipped in the same version. Tag `v1.1` on the uploaded commit and delete `feature/tier-a-b` only when the milestone acceptance list is complete.

---

## References

- [`archive/V2_2_APP_STORE_IMPLEMENTATION.md`](archive/V2_2_APP_STORE_IMPLEMENTATION.md)
- [`DISTRIBUTION.md`](DISTRIBUTION.md) § Mac App Store
- [`CHANNELS.md`](CHANNELS.md)
- [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md)
