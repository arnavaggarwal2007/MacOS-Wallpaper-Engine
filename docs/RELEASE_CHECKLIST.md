# Release checklist

**Purpose:** Manual and automated gate for a public build. Deskface **1.0 (2)** passed this matrix and has been on the Mac App Store since **October 6, 2026**.

**Platform:** macOS 15.0+ | **Build:** Release recommended for performance sign-off  
**Channels:** Complete the core sections for any release. Complete the **App Store** section before an App Store upload. Complete **Direct** signing rows before a public DMG.

Legend: **P** Pass · **F** Fail · **N/A** Not applicable

**Owner manual QA sign-off:** 2026-08-29 (full matrix below)

**Related:** [`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md) · [`DISTRIBUTION.md`](DISTRIBUTION.md) · [`MILESTONE_2.md`](MILESTONE_2.md) · [`RELEASE_RECORD.md`](RELEASE_RECORD.md)

---

## Automated gates

- [x] `CODE_SIGNING_ALLOWED=NO ./scripts/chunk7_regression.sh` — Debug + Release build, smoke, unit tests — **P** (owner verified 2026-08-31)
- [x] `xcodebuild test -scheme "Personal Wallpaper Engine" -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO` — unit tests pass (owner `Cmd+U` in Xcode, 2026-08-29; see [`TESTING.md`](TESTING.md))
- [x] No new Swift compiler errors or warnings introduced (M1 branch)
- [x] Release **PWE App Store** (`Release-AppStore`) configuration builds cleanly (2026-08-20)

---

## Engine core

- [x] App launches; video wallpaper behind desktop icons — **P** (2026-08-29)
- [x] Multi-display hotplug — [`archive/regression/HOTPLUG_REGRESSION.md`](archive/regression/HOTPLUG_REGRESSION.md) — **P** (2026-08-29; incl. display-bound collections + quit/relaunch)
- [x] Sleep/lock pause and resume — **P** (2026-08-29)
- [x] Security-scoped bookmarks survive relaunch — **P** (2026-08-29)

---

## Product (Phases 5–9)

- [x] Collections CRUD + apply — **P** (2026-08-29; display-bound auto, named display, mixed explicit + auto)
- [x] Setups save/restore/delete — **P** (2026-08-29)
- [x] Local library scan + apply — [`LIBRARY.md`](LIBRARY.md) — **P** (2026-08-29)
- [x] Quick modes + menu bar — [`QUICK_MODES.md`](QUICK_MODES.md); matrix in [`archive/regression/PHASE_9_REGRESSION.md`](archive/regression/PHASE_9_REGRESSION.md) — **P** (2026-08-29)
- [x] Drag-and-drop MP4/MOV on Home and Library browser — **P** (2026-08-29)
- [x] Agent mode: dock hidden when window closed; visible when open — **P** (2026-08-29)

---

## Performance (Release build)

Measure on target hardware (record logical core count):

| Scenario | Per-core CPU (AM) | System-wide CPU | Pass? |
|----------|-------------------|-----------------|-------|
| 2 disp, same 1080p, coalesced, unfocused, Balanced | ~13.75% (reference) | ~÷ N cores | **P** (2026-08-29) |
| 1 disp, coalesced, unfocused, Balanced | — | — | **P** (2026-08-29) |

See [`PERFORMANCE.md`](PERFORMANCE.md) § CPU scale.

### Suggestion banner — must be checked on real hardware

Thresholds were recalibrated 2026-08-20 against the benchmark envelope
([`PERFORMANCE.md`](PERFORMANCE.md)). Unit tests pin the arithmetic, but only a
live run confirms the banner behaves on this machine. Both directions matter — a banner that never
fires is as wrong as one that always does.

- [x] **Silent at rest:** Release build, wallpaper playing on every display, Max Quality, app
      unfocused for 60+ seconds. No "High CPU usage" banner. — **P** (2026-08-29)
- [x] **Fires under real load:** Max Quality, 4K source, different file per display. Banner appears
      within ~30 seconds and quotes a *system-wide* figure that matches the `System CPU share` row in
      Settings → Diagnostics (not the per-core rows). — **P** (2026-08-29)
- [x] **Reappears after snooze:** trigger it, choose "Remind me later", drop back to light load, then
      return to heavy load — the banner comes back. — **P** (2026-08-29)
- [x] **Debug QA toggle works:** in a Debug build, enable test thresholds in Settings → Diagnostics and
      confirm the banner appears within ~15 seconds at normal load. Confirm the toggle is **absent**
      from the Release build's Settings UI. — **P** (2026-08-29)

---

## Distribution — Direct (Developer ID)

**N/A** for Mac App Store v1.0 — complete only when shipping Direct (Milestone 3).

- [ ] [`DISTRIBUTION.md`](DISTRIBUTION.md) steps completed (sign, notarize, staple) — when shipping Direct
- [ ] Version + build number incremented
- [ ] Privacy statement published ([`PRIVACY_POLICY.md`](PRIVACY_POLICY.md))

---

## Distribution — Mac App Store

Deskface **1.0 (2)** has been **live since October 6, 2026**. The engineering matrix is archived at [`archive/M1_COMPLIANCE_CHECKLIST.md`](archive/M1_COMPLIANCE_CHECKLIST.md).

- [x] Built with **`PWE App Store`** scheme / `APP_STORE_BUILD`
- [x] `PrivacyInfo.xcprivacy` present in the archived app
- [x] Network client entitlement present (web wallpapers enabled)
- [x] Web URL allowlist: **https** + **file** only; navigation errors surfaced — [`WEB_WALLPAPERS.md`](WEB_WALLPAPERS.md)
- [x] “Check for Updates…” does **not** open GitHub / external updater (MAS flavor)
- [x] No Tier C / private API code in MAS binary
- [x] Bundle display name is **Deskface**; copyright names Arnav Aggarwal
- [x] `CFBundleName` is **Deskface**; Release-AppStore product is **Deskface.app** (Guideline 2.3.8)
- [x] In-app Privacy Policy + Support links present (Settings → System, Help menu)
- [x] First-run welcome card appears until a wallpaper is assigned
- [x] Privacy Policy and Support URLs resolve over HTTPS — **P** (Pages; Support = `/support/` not Issues — 2026-09-25)
- [x] Web smoke: local HTML + one **https** URL on Release-AppStore — **P** (2026-08-29)
- [x] Organizer **Validate App** and upload of build **1.0 (2)** (submitted **2026-10-01**)
- [x] App Store Connect privacy nutrition labels match [`PRIVACY_POLICY.md`](PRIVACY_POLICY.md) — shipped with 1.0
- [x] Review notes pasted in Connect ([`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md) §5)
- [x] Screenshots attached per submission guide (§6)
- [x] App Review approval — **October 6, 2026**, version **1.0 (2)** — [`RELEASE_RECORD.md`](RELEASE_RECORD.md)

---

## Milestone 2 extras (when Tier A/B ship)

**N/A** for MAS v1.0 desktop-only launch.

- [ ] Static lock export flow (Tier A) — Part 2, not in this build
- [ ] `Deskface.app/Contents/Library/Screen Savers/Deskface.saver` is present in the App Store build
- [ ] App Group `group.Personal.Personal-Wallpaper-Engine` is enabled on the app and the saver in the developer account, and a signed archive carries it
- [ ] Sync on, apply an MP4, quit and relaunch Deskface, System Settings preview shows that video
- [ ] Idle or a Hot Corner plays muted, full screen, one view per display
- [ ] A missing video shows “Open Deskface and choose a video”, not a hang
- [ ] A web wallpaper does not replace the screen saver video
- [ ] Preview is lighter than full-screen idle
- [ ] App Store binary has no Sparkle URL and no live lock-screen API
- [ ] MAS listing does not claim lock-screen live video

---

## Deferred (not blockers for desktop-only MAS v1.0)

- Lock-screen live video (Tier C — Direct only, later)
- Collection rotation / playlists (V2.1)
- Sparkle auto-update (Direct Milestone 3)
- 1-hour soak / stress matrix in [`archive/PRODUCTION_TEST_CHECKLIST.md`](archive/PRODUCTION_TEST_CHECKLIST.md) — run if a later review or soak check needs it
