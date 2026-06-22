# Pre-Release Checklist (Phases 1–9)

**Purpose:** Consolidated gate before public distribution. Supersedes scattered manual rows across phase matrices.

**Platform:** macOS 15.0+ | **Build:** Release recommended for performance sign-off

Legend: **P** Pass · **F** Fail · **N/A** Not applicable

---

## Automated gates

- [ ] `CODE_SIGNING_ALLOWED=NO ./scripts/chunk7_regression.sh` — Debug + Release build, smoke passes
- [ ] `xcodebuild test -scheme "Personal Wallpaper Engine" -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO` — unit tests pass
- [ ] No new Swift compiler errors or warnings introduced

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

## Distribution

- [ ] [`DISTRIBUTION.md`](DISTRIBUTION.md) steps completed (sign, notarize, staple)
- [ ] Version + build number incremented
- [ ] Privacy statement published (if public)

---

## Deferred (not release blockers for local-first v1.0)

- Lock-screen video (Phase 10)
- Collection rotation / playlists (V2.1)
- Sparkle auto-update (manual release page for now)
- 1-hour soak / stress matrix in legacy [`PRODUCTION_TEST_CHECKLIST.md`](../PRODUCTION_TEST_CHECKLIST.md)
