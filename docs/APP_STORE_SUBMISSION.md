# Mac App Store Submission Guide

**Status:** Ready for use when Milestone 1 binary exists (2026-08-20)  
**Charter:** [`V2_2_APP_STORE_IMPLEMENTATION.md`](V2_2_APP_STORE_IMPLEMENTATION.md)  
**Privacy copy:** [`PRIVACY_POLICY.md`](PRIVACY_POLICY.md)  
**Gate:** [`PRE_RELEASE_CHECKLIST.md`](PRE_RELEASE_CHECKLIST.md)  
**Related:** [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

---

## 1. Prerequisites

| Requirement | Notes |
|-------------|--------|
| Apple Developer Program membership | Active |
| App Store Connect app record | Create “Personal Wallpaper Engine” (or final public name) |
| Mac App Store distribution certificate + provisioning | Xcode Automatic or Manual for `PWE App Store` scheme |
| Marketing version + build | Increment `CURRENT_PROJECT_VERSION` every upload |
| Privacy policy URL | Host [`PRIVACY_POLICY.md`](PRIVACY_POLICY.md) content |
| Support URL | Same site or GitHub Discussions / Issues |

---

## 2. Build and upload

1. Archive with scheme **`PWE App Store`** (Release, `APP_STORE_BUILD`).
2. Organizer → **Validate App** — fix any entitlement / privacy / bitcode issues.
3. **Distribute App** → App Store Connect.
4. Confirm `PrivacyInfo.xcprivacy` is in the bundle.
5. Confirm MAS binary does **not** open external update URLs (GitHub releases).

Until the scheme exists, do not submit. Milestone 1 engineering creates it.

---

## 3. App Store Connect metadata

### Positioning

**Subtitle / short pitch:** Native Mac live wallpaper engine — local files, no account.

**Description themes (honest):**

- Local video (MP4/MOV) and optional web wallpapers
- Multi-display and per-display assignment
- Collections, desktop setups, local library
- Quick modes and menu bar controls
- Battery-aware pause and performance profiles
- Free; optional tip (if IAP added in M2)

**Do not claim:**

- Lock-screen live video (Tier C) — blocked on App Store
- Community / Workshop library
- Windows Wallpaper Engine compatibility

### Category

Prefer **Graphics & Design** (or **Utilities** — pick one and keep consistent across locales).

### Age rating / content

No user-generated networked content in v1.0. Local media only; rating per Apple questionnaire (typically 4+ if no objectionable content is distributed by the app itself).

### Keywords (examples — refine at submit time)

`wallpaper`, `live wallpaper`, `desktop`, `video wallpaper`, `multi monitor`, `mac`

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

**Web wallpapers:** If user pastes a remote URL, the app may load that URL (network entitlement). Document as user-initiated content, not developer analytics.

---

## 5. Review notes template

Paste into App Store Connect **App Review Information → Notes**:

```text
Personal Wallpaper Engine is a menu-bar / agent-style Mac app (LSUIElement)
that renders user-selected local video (or optional web URLs) as the desktop
wallpaper behind icons.

How to open the main window:
1. Click the status item in the menu bar (photo / wallpaper icon).
2. Choose “Show Main Window” (or equivalent).
3. The Dock icon appears while the main window is visible.

First-run / demo:
1. Grant access when picking an MP4/MOV via the file picker or library folder.
2. Apply to display(s) from Home.
3. Optional: paste a web wallpaper URL in Settings (user-initiated network).

No account. No analytics. No private APIs.
Updates are delivered only through the Mac App Store (no Sparkle / external updater).
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
| Reviewer cannot find UI (`LSUIElement`) | Clear review notes + screen recording |
| External payment / update link | MAS flavor must hide GitHub updates; tips only via IAP if unlocking nothing |
| Private API detection | Never ship Tier C on MAS; no undocumented selectors |
| Incomplete privacy | Nutrition labels + `PrivacyInfo.xcprivacy` + hosted policy |
| Crash on launch without sample media | Graceful empty states; ship with clear first-run copy |
| Web wallpaper network surprise | Entitlement present; disclose in privacy text |

---

## 8. Post-submit

- Respond to Resolution Center within 24–48 hours
- Tag git `v1.0` (or `v1.0-mas`) on the commit uploaded
- Update [`V1_SIGNOFF.md`](V1_SIGNOFF.md) M1 row with date
- Changelog entry in KB `Project-Changelog.md`

---

## References

- [`V2_2_APP_STORE_IMPLEMENTATION.md`](V2_2_APP_STORE_IMPLEMENTATION.md)
- [`DISTRIBUTION.md`](DISTRIBUTION.md) § Mac App Store
- [`DISTRIBUTION_CHANNELS.md`](DISTRIBUTION_CHANNELS.md) Appendix A
- [`PRE_RELEASE_CHECKLIST.md`](PRE_RELEASE_CHECKLIST.md)
