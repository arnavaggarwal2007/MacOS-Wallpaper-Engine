# Pre-Release Checklist (Phases 1–9 + App Store)

**Purpose:** Consolidated gate before public distribution. Supersedes scattered manual rows across phase matrices.

**Platform:** macOS 15.0+ | **Build:** Release recommended for performance sign-off  
**Channels:** Complete the core sections for any release. Complete the **App Store** section before Mac App Store upload. Complete **Direct** signing rows before public DMG.

Legend: **P** Pass · **F** Fail · **N/A** Not applicable

**Owner manual QA sign-off:** 2026-08-29 (full matrix below)

**Related:** [`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md) · [`DISTRIBUTION.md`](DISTRIBUTION.md) · [`V2_2_APP_STORE_IMPLEMENTATION.md`](V2_2_APP_STORE_IMPLEMENTATION.md)

---

## Automated gates

- [x] `CODE_SIGNING_ALLOWED=NO ./scripts/chunk7_regression.sh` — Debug + Release build, smoke, unit tests — **P** (owner verified 2026-08-31)
- [x] `xcodebuild test -scheme "Personal Wallpaper Engine" -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO` — unit tests pass (owner `Cmd+U` in Xcode, 2026-08-29; see [`TESTING.md`](TESTING.md))
- [x] No new Swift compiler errors or warnings introduced (M1 branch)
- [x] Release **PWE App Store** (`Release-AppStore`) configuration builds cleanly (2026-08-20)

---

## Engine core

- [x] App launches; video wallpaper behind desktop icons — **P** (2026-08-29)
- [x] Multi-display hotplug — [`HOTPLUG_REGRESSION.md`](HOTPLUG_REGRESSION.md) — **P** (2026-08-29; incl. display-bound collections + quit/relaunch)
- [x] Sleep/lock pause and resume — **P** (2026-08-29)
- [x] Security-scoped bookmarks survive relaunch — **P** (2026-08-29)

---

## Product (Phases 5–9)

- [x] Collections CRUD + apply — **P** (2026-08-29; display-bound auto, named display, mixed explicit + auto)
- [x] Setups save/restore/delete — **P** (2026-08-29)
- [x] Local library scan + apply — [`PHASE_8_LIBRARY.md`](PHASE_8_LIBRARY.md) — **P** (2026-08-29)
- [x] Quick modes + menu bar — [`PHASE_9_REGRESSION.md`](PHASE_9_REGRESSION.md) — **P** (2026-08-29)
- [x] Drag-and-drop MP4/MOV on Home and Library browser — **P** (2026-08-29)
- [x] Agent mode: dock hidden when window closed; visible when open — **P** (2026-08-29)

---

## Performance (Release build)

Measure on target hardware (record logical core count):

| Scenario | Per-core CPU (AM) | System-wide CPU | Pass? |
|----------|-------------------|-----------------|-------|
| 2 disp, same 1080p, coalesced, unfocused, Balanced | ~13.75% (reference) | ~÷ N cores | **P** (2026-08-29) |
| 1 disp, coalesced, unfocused, Balanced | — | — | **P** (2026-08-29) |

See [`PERFORMANCE_TUNING.md`](PERFORMANCE_TUNING.md) § CPU scale glossary.

### Suggestion banner — must be checked on real hardware

Thresholds were recalibrated 2026-08-20 against the benchmark envelope
([`PERFORMANCE_TUNING.md`](PERFORMANCE_TUNING.md) §ADR-009). Unit tests pin the arithmetic, but only a
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

## Distribution — Mac App Store (Milestone 1+)

Complete before App Store Connect upload. See [`M1_COMPLIANCE_CHECKLIST.md`](M1_COMPLIANCE_CHECKLIST.md).

- [x] Built with **`PWE App Store`** scheme / `APP_STORE_BUILD`
- [x] `PrivacyInfo.xcprivacy` present in the archived app
- [x] Network client entitlement present (web wallpapers enabled)
- [x] Web URL allowlist: **https** + **file** only; navigation errors surfaced — [`WEB_WALLPAPERS.md`](WEB_WALLPAPERS.md)
- [x] “Check for Updates…” does **not** open GitHub / external updater (MAS flavor)
- [x] No Tier C / private API code in MAS binary
- [x] Bundle display name is **Deskface**; copyright names Arnav Aggarwal
- [x] In-app Privacy Policy + Support links present (Settings → System, Help menu)
- [x] First-run welcome card appears until a wallpaper is assigned
- [x] Privacy Policy and Support URLs resolve over HTTPS — **P** (GitHub Pages live 2026-08-23; in-app links verified 2026-08-29)
- [x] Web smoke: local HTML + one **https** URL on Release-AppStore — **P** (2026-08-29)
- [ ] Organizer **Validate App** succeeds (signed archive — owner; see [`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md) §2)
- [ ] App Store Connect privacy nutrition labels match [`PRIVACY_POLICY.md`](PRIVACY_POLICY.md)
- [ ] Review notes pasted in Connect ([`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md) §5)
- [ ] Screenshots attached per submission guide (§6)
- [ ] Owner sign-off on [`V1_SIGNOFF.md`](V1_SIGNOFF.md) M1 Connect upload row (after submit)

---

## Milestone 2 extras (when Tier A/B ship)

**N/A** for MAS v1.0 desktop-only launch.

- [ ] Static lock export flow (Tier A)
- [ ] Screensaver install / App Group sync (Tier B)
- [ ] MAS listing does not claim lock-screen live video

---

## Deferred (not blockers for desktop-only MAS v1.0)

- Lock-screen live video (Tier C — Direct only, later)
- Collection rotation / playlists (V2.1)
- Sparkle auto-update (Direct Milestone 3)
- 1-hour soak / stress matrix in legacy [`PRODUCTION_TEST_CHECKLIST.md`](../PRODUCTION_TEST_CHECKLIST.md) — run if Review or soak confidence requires it
