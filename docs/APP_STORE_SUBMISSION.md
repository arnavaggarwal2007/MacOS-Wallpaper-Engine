# Mac App Store Submission Guide — Loopscape

**Status:** Engineering and owner manual QA complete (2026-08-29). Regression gate **P** (2026-08-31). **Next:** Xcode signing → Connect record → Archive → Validate → metadata → Submit. **Launch gate:** [`PRE_LAUNCH_STATUS.md`](PRE_LAUNCH_STATUS.md)  
**Store name:** **Loopscape** (display name only — bundle ID and Xcode target are unchanged)  
**Charter:** [`V2_2_APP_STORE_IMPLEMENTATION.md`](V2_2_APP_STORE_IMPLEMENTATION.md)  
**Privacy copy:** [`PRIVACY_POLICY.md`](PRIVACY_POLICY.md)  
**Gate:** [`PRE_RELEASE_CHECKLIST.md`](PRE_RELEASE_CHECKLIST.md)  
**Related:** [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

---

## Owner runway (after QA sign-off)

Engineering and manual QA are complete ([`PRE_RELEASE_CHECKLIST.md`](PRE_RELEASE_CHECKLIST.md) — 2026-08-29). Complete these in order:

| Step | Action | Section |
|------|--------|---------|
| 1 | Xcode → Settings → Accounts → sign in; confirm Mac App Store distribution cert | §1 |
| 2 | App Store Connect → create **Loopscape** app (`Personal.Personal-Wallpaper-Engine`, SKU `pwe-mas-001`) | §1 |
| 3 | Archive scheme **`PWE App Store`** → **Validate App** → **Distribute** to Connect | §2 |
| 4 | Paste metadata, privacy labels (Data Not Collected), age rating 16+, review notes | §3–5 |
| 5 | Attach 6 screenshots | §6 |
| 6 | Select build → **Submit for Review** | §2 |

Version for first upload: **1.0 (1)** — see `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` in the Xcode project.

---

## 1. Prerequisites

| Requirement | Value / notes |
|-------------|---------------|
| Apple Developer Program membership | Individual — **Arnav Aggarwal** (owner action) |
| App Store Connect app record | **Loopscape** |
| Bundle ID | `Personal.Personal-Wallpaper-Engine` (unchanged by the display-name rename) |
| Mac App Store distribution certificate + provisioning | Xcode Automatic for the `PWE App Store` scheme |
| Marketing version + build | `1.0` / `1` for the first upload; increment `CURRENT_PROJECT_VERSION` every upload |
| Privacy policy URL | `https://arnavaggarwal2007.github.io/MacOS-Wallpaper-Engine/privacy/` |
| Support URL | `https://github.com/arnavaggarwal2007/MacOS-Wallpaper-Engine/issues` |
| Review contact | Arnav Aggarwal · arnevaggarrwal@gmail.com · 408-892-7318 |

### Enabling the hosted pages (one-time — **done**)

GitHub Pages is **live** (2026-08-23). Privacy and support URLs verified 2026-08-29.

The landing page and privacy policy are committed as static HTML under [`docs/`](.):
[`index.html`](index.html) and [`privacy/index.html`](privacy/index.html), with `.nojekyll`
so GitHub serves them verbatim.

1. Push `main` to GitHub.
2. Repository **Settings → Pages**.
3. Source: **Deploy from a branch**; Branch: `main`; Folder: **`/docs`**; Save.
4. Wait for the first deploy, then confirm both URLs load over HTTPS.

The URLs are compiled into the app via [`AppLinks.swift`](../Personal%20Wallpaper%20Engine/AppLinks.swift),
so they must resolve before submission.

---

## 2. Build and upload

1. Archive with scheme **`PWE App Store`** (Release, `APP_STORE_BUILD`).
2. Organizer → **Validate App** — fix any entitlement / privacy / bitcode issues.
3. **Distribute App** → App Store Connect.
4. Confirm `PrivacyInfo.xcprivacy` is in the bundle.
5. Confirm MAS binary does **not** open external update URLs (GitHub releases).

The **`PWE App Store`** scheme ships with Release-AppStore / `APP_STORE_BUILD` — use it for all archives.

---

## 3. App Store Connect metadata (final copy — paste as-is)

### Identity

| Field | Value |
|-------|-------|
| App name | `Loopscape` |
| Subtitle (30 char max) | `Live wallpapers for your Mac` (28) |
| SKU | `pwe-mas-001` |
| Primary category | Graphics & Design |
| Secondary category | Utilities |
| Price | Free |
| Availability | All countries and regions |
| License | Apple Standard EULA |

**Naming rationale:** every established Mac competitor (Backdrop, Plash, Paper, Wallux, WallTune)
avoids the word “Engine,” which reads as the Steam product. `Loopscape` is distinctive and memorable,
and pushes discovery terms into the subtitle and keyword field, which is where
Apple actually indexes them.

### Keywords (100 char max, comma separated, no spaces)

```text
wallpaper,live wallpaper,video wallpaper,animated,desktop,multi monitor,screen,background
```

### Description

```text
Loopscape turns your own video files into live wallpapers for macOS.

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
Loopscape is local-first. No account, no analytics, no advertising, and no generative AI. Your
wallpaper files never leave your Mac.

NOTE
Loopscape runs as a menu bar app. Click the menu bar icon to open the main window. It changes the
desktop wallpaper only; it does not replace the macOS lock screen. Loopscape is not affiliated
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
Loopscape is a menu bar / agent-style Mac app (LSUIElement) that renders a
user-selected local video, or an optional user-supplied web page, as the desktop
wallpaper behind the icons.

HOW TO OPEN THE MAIN WINDOW
The app has no Dock icon until a window is open. To open it:
1. Click the Loopscape icon in the menu bar (top-right of the screen).
2. Choose "Show Main Window."
3. The Dock icon appears while the main window is visible.

On first launch the Home tab shows a "Welcome to Loopscape" card with the two
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
- Loopscape is not affiliated with Wallpaper Engine on Steam and does not import
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
| External payment / update link | MAS flavor must hide GitHub updates; tips only via IAP if unlocking nothing |
| Private API detection | Never ship Tier C on MAS; no undocumented selectors |
| Incomplete privacy | Nutrition labels + `PrivacyInfo.xcprivacy` + hosted policy |
| Crash on launch without sample media | Graceful empty states; ship with clear first-run copy |
| Web wallpaper network surprise | Entitlement present; disclose in privacy text |

---

## 8. Post-submit

- Respond to Resolution Center within 24–48 hours
- Tag git `v1.0` (or `v1.0-mas`) on the **commit you uploaded** — tagging at upload time is fine; record App Store **approval date** separately in sign-off docs
- Update [`V1_SIGNOFF.md`](V1_SIGNOFF.md) M1 row with approval date (not upload date)
- Changelog entry in KB `Project-Changelog.md`

---

## 9. Owner step-by-step guide

Engineering and manual QA are complete ([`PRE_RELEASE_CHECKLIST.md`](PRE_RELEASE_CHECKLIST.md) — 2026-08-29; regression **P** 2026-08-31). Sections **§3–§6** above hold paste-ready copy blocks. This section is the detailed walkthrough.

### What's already done (skip)

- Product code, M1 compliance flavor, privacy manifest, web allowlist
- GitHub Pages live (privacy + landing URLs)
- Full manual QA + unit tests (Cmd+U passed); **92** tests in repo
- Marketing version **1.0**, build **1** — correct for first upload

### Quick reference URLs

| Purpose | Value |
|---------|-------|
| Privacy Policy | `https://arnavaggarwal2007.github.io/MacOS-Wallpaper-Engine/privacy/` |
| Support | `https://github.com/arnavaggarwal2007/MacOS-Wallpaper-Engine/issues` |
| Bundle ID | `Personal.Personal-Wallpaper-Engine` |
| Store name | Loopscape |
| SKU | `pwe-mas-001` |

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
- Platforms: **macOS** · Name: **Loopscape** · Primary language: English (U.S.)
- Bundle ID: `Personal.Personal-Wallpaper-Engine` (create App ID in Certificates, Identifiers & Profiles first if missing)
- SKU: `pwe-mas-001` · User Access: Full Access → **Create**

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

- Connect → Loopscape → build section. Status **Processing** (often 10–30 minutes).
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

1. Version page → **Build** → select build **1.0 (1)**.
2. Final checklist: build ready, 6 screenshots, metadata, privacy URLs, App Privacy, age **16+**, review notes, contact info.
3. **Submit for Review**. Status → **Waiting for Review** (hours to a few days typical).

### Phase 8 — After submission

- Monitor **Resolution Center** daily; respond within 24–48 hours.
- **If approved:** choose release; tag uploaded commit `v1.0` if not already; update [`V1_SIGNOFF.md`](V1_SIGNOFF.md).
- **If rejected:** see **§7** rejection playbook. Increment **Build** to 2, re-archive, re-upload.

### What you do not need for v1.0 MAS

- Direct DMG / notarization / Developer ID distribution
- Milestone 2 (lock screen export, screensaver)
- Version bump beyond **1.0 (1)** unless re-uploading after rejection
- Code changes unless Validate App or Review fails

### Order of operations (summary)

1. Xcode: sign in + **PWE App Store** scheme  
2. Connect: create Loopscape app + URLs  
3. Xcode: Archive → Validate → Upload  
4. Connect: wait for build processing  
5. Connect: metadata + privacy + age rating + review notes  
6. Connect: screenshots  
7. Connect: select build → Submit for Review  
8. Monitor Resolution Center → release when approved  


---

## References

- [`V2_2_APP_STORE_IMPLEMENTATION.md`](V2_2_APP_STORE_IMPLEMENTATION.md)
- [`DISTRIBUTION.md`](DISTRIBUTION.md) § Mac App Store
- [`DISTRIBUTION_CHANNELS.md`](DISTRIBUTION_CHANNELS.md) Appendix A
- [`PRE_RELEASE_CHECKLIST.md`](PRE_RELEASE_CHECKLIST.md)
