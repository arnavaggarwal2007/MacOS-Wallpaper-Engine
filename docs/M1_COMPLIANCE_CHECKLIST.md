# Milestone 1 — Mac App Store Compliance Checklist

**Branch:** `feature/mas-compliance` → PR → `main`  
**Tag (post-upload):** `v1.0`  
**Charter:** [`V2_2_APP_STORE_IMPLEMENTATION.md`](V2_2_APP_STORE_IMPLEMENTATION.md)  
**Submission:** [`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md)  
**Web wallpapers:** [`WEB_WALLPAPERS.md`](WEB_WALLPAPERS.md)

Legend: **P** Pass · **F** Fail · **N/A** Not applicable · **Owner** Requires account / hosting outside repo

---

## Engineering — build flavors

| Item | Status | Notes |
|------|--------|-------|
| `Configurations/AppStore.xcconfig` with `APP_STORE_BUILD` | **P** | Release-AppStore configuration |
| `Configurations/Direct.xcconfig` with `DIRECT_BUILD` | **P** | Debug/Release default |
| Scheme `PWE App Store` archives Release-AppStore | **P** | `xcshareddata/xcschemes/PWE App Store.xcscheme` |
| `Personal Wallpaper Engine AppStore.entitlements` | **P** | Sandbox + files + bookmarks + **network.client** |
| Direct entitlements include network.client (web parity) | **P** | `Personal Wallpaper Engine.entitlements` |
| Orphan `REGISTER_APP_GROUPS=YES` cleared | **P** | `REGISTER_APP_GROUPS=NO` in Direct xcconfig |

---

## Engineering — privacy & export

| Item | Status | Notes |
|------|--------|-------|
| `PrivacyInfo.xcprivacy` in target resources | **P** | Bundled in Release-AppStore app |
| `NSPrivacyTracking` = false; no collected data types | **P** | Developer does not collect |
| `ITSAppUsesNonExemptEncryption=NO` | **P** | In AppStore + Direct xcconfig |

---

## Engineering — Guideline 3.1.1 (updates)

| Item | Status | Notes |
|------|--------|-------|
| `UpdateChecker` gates external GitHub on MAS | **P** | `#if !APP_STORE_BUILD` |
| Settings hides “Check for Updates…” on MAS | **P** | Shows Mac App Store copy |
| Unit test for MAS vs Direct update copy | **P** | `UpdateCheckerTests` |

---

## Engineering — web wallpapers

| Item | Status | Notes |
|------|--------|-------|
| `network.client` entitlement (root cause of remote failure) | **P** | App Store + Direct entitlements |
| URL allowlist: `https` + `file` only | **P** | `WebWallpaperURLValidator` |
| Reject `http`, `javascript:`, empty | **P** | Unit tests |
| `WKNavigationDelegate` surfaces load failures | **P** | `WebRendererNavigationDelegate` |
| User-facing docs | **P** | [`WEB_WALLPAPERS.md`](WEB_WALLPAPERS.md) |

---

## Security scare-list mapping (applicable vs N/A)

| Concern | Applies to PWE M1? | Action |
|---------|-------------------|--------|
| Hide API keys / git secrets | Low risk (none found) | Secrets scan **P** (2026-08-20) |
| Server auth / RLS / sessions | **N/A** | No backend |
| Cloud encryption at rest | **N/A** | Local preferences only |
| SQL/XSS on server | **N/A** | Harden WKWebView URL input instead |
| Public storage buckets | **N/A** | Local file picker only |
| Force HTTPS for user web loads | **Yes** | https/file allowlist; ATS defaults |
| Dependency scan | **Yes** | No SPM/CocoaPods; re-check if added |
| Privacy policy + nutrition labels | **Yes** | [`PRIVACY_POLICY.md`](PRIVACY_POLICY.md) |
| “We collect data” / third-party analytics | **No collection** | PP states none; web loads user-initiated |
| Generative AI disclosure | **N/A in product** | PP: does not use generative AI |
| Account deletion (5.1.1v) | **N/A** | No accounts |
| External updater | **Yes** | Gated on MAS |
| Private APIs / Tier C on MAS | **Yes** | Not shipped in M1 |
| `LSUIElement` discoverability | **Yes** | Review notes template ready |

---

## Automated QA (2026-08-20)

| Check | Command | Result |
|-------|---------|--------|
| Regression | `CODE_SIGNING_ALLOWED=NO ./scripts/chunk7_regression.sh` | **P** |
| Unit tests | `xcodebuild test -scheme "Personal Wallpaper Engine"` | **P** (incl. new validator tests) |
| Release-AppStore build | `xcodebuild -scheme "PWE App Store" -configuration Release-AppStore` | **P** |
| Privacy manifest in bundle | `Release-AppStore.app/Contents/Resources/PrivacyInfo.xcprivacy` | **P** |
| Secrets scan | `rg` for keys/tokens/.p12/.env | **P** (no secrets) |

---

## Manual QA — App Store flavor (owner)

| Item | Status | Notes |
|------|--------|-------|
| Remote https web wallpaper smoke | **Owner** | Settings → Web → paste https URL → Apply |
| Local HTML via Choose File smoke | **Owner** | Full-screen animated HTML |
| “Check for Updates” absent / MAS copy only | **P** | Code review + `UpdateCheckerTests` on Direct |
| Core Phases 1–9 on Release-AppStore | **Owner** | [`PRE_RELEASE_CHECKLIST.md`](PRE_RELEASE_CHECKLIST.md) |
| Organizer **Validate App** on signed archive | **Owner** | Requires distribution cert + upload |
| 1-hour soak | **N/A** | Optional unless Review requires |

---

## Launch prep — brand, in-app compliance, hosting (2026-08-20)

| Item | Status | Notes |
|------|--------|-------|
| Store display name locked | **P** | **Deskloop** via `INFOPLIST_KEY_CFBundleDisplayName`; bundle ID unchanged |
| Copyright string | **P** | `Copyright © 2026 Arnav Aggarwal. All rights reserved.` |
| Broken update URL fixed | **P** | Pointed at a nonexistent org; now `arnavaggarwal2007/MacOS-Wallpaper-Engine` |
| Outbound URLs centralized | **P** | [`AppLinks.swift`](../Personal%20Wallpaper%20Engine/AppLinks.swift); release notes excluded from MAS builds |
| In-app Privacy Policy + Support links | **P** | Settings → System card, and Help menu |
| First-run guidance (Guideline 2.4.5 discoverability) | **P** | Welcome card on Home until a wallpaper is assigned |
| Web URL placeholder | **P** | Reserved `example.com` documentation domain, `.html` form |
| Privacy policy content filled | **P** | Contact, support, developer name; no placeholders remain |
| Hosted pages committed | **P** | [`index.html`](index.html) + [`privacy/index.html`](privacy/index.html) with `.nojekyll` |
| GitHub Pages enabled | **Owner** | Settings → Pages → `main` / `/docs` (submission guide §1) |
| Store copy final | **P** | Name, subtitle, description, keywords, What's New in submission guide §3 |
| Age rating answers drafted | **P** | Unrestricted Web Access = Yes → **16+** (Plash precedent) |
| Review notes | **P** | Rewritten for Deskloop with a one-minute test path |

## App Store Connect prep

| Item | Status | Notes |
|------|--------|-------|
| Privacy nutrition labels = Data Not Collected | **Owner** | Match PP; web loads = user-initiated |
| ASC app record (Graphics & Design) | **Owner** | Name **Deskloop**, bundle ID `Personal.Personal-Wallpaper-Engine` |
| Screenshots (6 scenes) | **Owner** | [`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md) §6 |
| Export compliance answer | **Ready** | Standard encryption exempt (HTTPS only) |
| Upload + Resolution Center | **Owner** | After signed archive from `main` |

---

## Git / release

| Item | Status | Notes |
|------|--------|-------|
| `feature/mas-compliance` merged to `main` | **P** | Fast-forward merge 2026-08-20 |
| Branch deleted after merge | **Owner** | Optional cleanup |
| Tag `v1.0` on uploaded commit | **P** | Tagged on `main` @ `65c5682` |
| [`V1_SIGNOFF.md`](V1_SIGNOFF.md) M1 row | **P** | Engineering 2026-08-20; Connect upload **Owner** |

---

## Explicitly out of M1

Tier A/B/C · Sparkle · App Group / `.saver` · Steam · permanent channel branches · disabling web wallpapers

---

## Sign-off

| Role | Engineering M1 | Connect submit |
|------|----------------|----------------|
| Agent / CI | **P** (2026-08-20) | Docs + templates ready |
| Owner | Review manual smoke | Host PP, Validate, Upload, tag |
