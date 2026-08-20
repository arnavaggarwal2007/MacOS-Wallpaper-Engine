# Pre-Release Checklist (Phases 1–9 + App Store)

**Purpose:** Consolidated gate before public distribution. Supersedes scattered manual rows across phase matrices.

**Platform:** macOS 15.0+ | **Build:** Release recommended for performance sign-off  
**Channels:** Complete the core sections for any release. Complete the **App Store** section before Mac App Store upload. Complete **Direct** signing rows before public DMG.

Legend: **P** Pass · **F** Fail · **N/A** Not applicable

**Related:** [`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md) · [`DISTRIBUTION.md`](DISTRIBUTION.md) · [`V2_2_APP_STORE_IMPLEMENTATION.md`](V2_2_APP_STORE_IMPLEMENTATION.md)

---

## Automated gates

- [ ] `CODE_SIGNING_ALLOWED=NO ./scripts/chunk7_regression.sh` — Debug + Release build, smoke passes
- [ ] `xcodebuild test -scheme "Personal Wallpaper Engine" -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO` — unit tests pass
- [ ] No new Swift compiler errors or warnings introduced
- [ ] (When scheme exists) Release **PWE App Store** configuration builds cleanly

---

## Engine core

- [ ] App launches; video wallpaper behind desktop icons
- [ ] Multi-display hotplug — [`HOTPLUG_REGRESSION.md`](HOTPLUG_REGRESSION.md)
- [ ] Sleep/lock pause and resume
- [ ] Security-scoped bookmarks survive relaunch

---

## Product (Phases 5–9)

- [ ] Collections CRUD + apply
- [ ] Setups save/restore/delete
- [ ] Local library scan + apply — [`PHASE_8_LIBRARY.md`](PHASE_8_LIBRARY.md)
- [ ] Quick modes + menu bar — [`PHASE_9_REGRESSION.md`](PHASE_9_REGRESSION.md) (all **P**)
- [ ] Drag-and-drop MP4/MOV on Home and Library browser
- [ ] Agent mode: dock hidden when window closed; visible when open

---

## Performance (Release build)

Measure on target hardware (record logical core count):

| Scenario | Per-core CPU (AM) | System-wide CPU | Pass? |
|----------|-------------------|-----------------|-------|
| 2 disp, same 1080p, coalesced, unfocused, Balanced | ~13.75% (reference) | ~÷ N cores | |
| 1 disp, coalesced, unfocused, Balanced | | | |

See [`PERFORMANCE_TUNING.md`](PERFORMANCE_TUNING.md) § CPU scale glossary.

---

## Distribution — Direct (Developer ID)

- [ ] [`DISTRIBUTION.md`](DISTRIBUTION.md) steps completed (sign, notarize, staple) — when shipping Direct
- [ ] Version + build number incremented
- [ ] Privacy statement published ([`PRIVACY_POLICY.md`](PRIVACY_POLICY.md))

---

## Distribution — Mac App Store (Milestone 1+)

Complete before App Store Connect upload:

- [ ] Built with **`PWE App Store`** scheme / `APP_STORE_BUILD` (when available)
- [ ] `PrivacyInfo.xcprivacy` present in the archived app
- [ ] Network client entitlement present if web wallpapers are enabled
- [ ] “Check for Updates…” does **not** open GitHub / external updater
- [ ] No Tier C / private API code in MAS binary
- [ ] Organizer **Validate App** succeeds
- [ ] App Store Connect privacy nutrition labels match [`PRIVACY_POLICY.md`](PRIVACY_POLICY.md)
- [ ] Privacy Policy URL and Support URL live
- [ ] Review notes include menu bar agent instructions ([`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md) §5)
- [ ] Screenshots attached per submission guide
- [ ] Owner sign-off on [`V1_SIGNOFF.md`](V1_SIGNOFF.md) M1 (and M2 when applicable)

---

## Milestone 2 extras (when Tier A/B ship)

- [ ] Static lock export flow (Tier A)
- [ ] Screensaver install / App Group sync (Tier B)
- [ ] MAS listing does not claim lock-screen live video

---

## Deferred (not blockers for desktop-only MAS v1.0)

- Lock-screen live video (Tier C — Direct only, later)
- Collection rotation / playlists (V2.1)
- Sparkle auto-update (Direct Milestone 3)
- 1-hour soak / stress matrix in legacy [`PRODUCTION_TEST_CHECKLIST.md`](../PRODUCTION_TEST_CHECKLIST.md) — run if Review or soak confidence requires it
