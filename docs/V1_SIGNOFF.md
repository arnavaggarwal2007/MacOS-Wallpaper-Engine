# Version 1 Sign-Off

**Date:** 2026-05-22 (updated)  
**Build:** Debug local build 2026-05-22; prior CI `main` @ `1cfe02f`  
**Scope:** Phases 1–6B + UI final vision (Phases 0–4) + Phase 7A  
**Gate:** V1 complete; 7A playback UX signed off; **Phase 7B complete** (2026-05-23); **Phase 7C complete** (2026-05-23); Phase 8 next  

---

## Sign-off summary

| Area | Status | Notes |
|------|--------|-------|
| Automated build & smoke | **Pass** | `chunk7_smoke.sh` + GitHub Actions universal Debug/Release |
| UI revamp validation | **Pass** | User verified May 20, 2026; merged to `main` |
| Functional matrix (manual) | **Pass (reported)** | Owner confirmed app working in daily use; spot-check sections below |
| Phase 7B engine efficiency | **Pass** | P0–P4 complete; see [`PERFORMANCE_TUNING.md`](PERFORMANCE_TUNING.md) |
| Phase 7C diagnostics UI | **Pass** | CPU monitor, suggestion banner, Settings diagnostics, engine restart |
| Hotplug / launch / setup persistence | **Pass** | See [`HOTPLUG_REGRESSION.md`](HOTPLUG_REGRESSION.md) |
| Phase 7A power policy | **Pass** | [`PHASE_7A_POWER_REGRESSION.md`](PHASE_7A_POWER_REGRESSION.md) |
| Phase 7A playback UX | **Pass** | 2026-05-22 — launch auto-play, frozen-frame pause, hero preview sync; matrix rows 10–11, 15–16 |

**Recommendation:** V1 + **7A + 7B + 7C complete**. Phase **8** (local library) next. Results in [`PERFORMANCE_TUNING.md`](PERFORMANCE_TUNING.md).

---

## Automated verification

| Check | Command | Result | Date |
|-------|---------|--------|------|
| Debug smoke build | `CODE_SIGNING_ALLOWED=NO ./scripts/chunk7_smoke.sh` | Pass (universal x86_64 + arm64) | 2026-05-22 |
| Local Debug build (7A playback UX) | Xcode Debug scheme | Pass | 2026-05-22 |
| CI regression | GitHub Actions `chunk7_regression.yml` on `1cfe02f` | Pass | 2026-05-21 |
| Swift concurrency (CI) | Xcode 16.4 universal build | Pass (MenuBar + thumbnail fixes) | 2026-05-21 |

---

## Functional sign-off (high priority)

Derived from [`PRODUCTION_TEST_CHECKLIST.md`](../PRODUCTION_TEST_CHECKLIST.md).  
Legend: **P** = Pass, **D** = Defer / not tested, **F** = Fail.

### Engine core

| Test | Status | Notes |
|------|--------|-------|
| App launches without crash | P | |
| Desktop wallpaper behind icons | P | |
| Video playback (MP4/MOV) | P | |
| Mute toggle | P | |
| Scaling modes (fill/fit/stretch) | P | |
| Wallpaper persists after relaunch | P | Security-scoped bookmarks |
| Screen lock / sleep pause & resume | P | Chunks 4A–4D |
| Multi-display connect/disconnect | P | Full hotplug matrix — [`HOTPLUG_REGRESSION.md`](HOTPLUG_REGRESSION.md) |
| Per-display independent sources | P | Always per-display model |
| Spaces / Mission Control | P | |
| Missing file / error handling | P | |

### Product features (Phase 5–6)

| Test | Status | Notes |
|------|--------|-------|
| Web wallpaper mode | P | WKWebView path |
| Menu bar play/pause/mute/prefs/quit | P | `@MainActor` MenuBarController |
| Launch on login (macOS 13.2+) | P | Settings toggle |
| Collection create / edit / apply / delete | P | Simple + display-bound |
| Setup save / restore / delete | P | `SetupsTabView` |
| Setup restore after relaunch | P | |
| Collection bookmarks across sessions | P | |

### UI (four-tab shell)

| Test | Status | Notes |
|------|--------|-------|
| Home: live hero background | P | `AppWallpaperBackground` |
| Scroll-reveal display carousel | P | Phase 4c |
| Display select updates preview | P | |
| Choose Wallpaper + Apply (focused display) | P | Phase 3 |
| Collections tab CRUD + apply | P | |
| Setups tab save/restore/delete | P | |
| Settings tab (renderer, scaling, login, battery & power) | P | Phase 7A |
| Management tabs: blur/scrim readability | P | |
| Legacy ContentView removed | P | Phase 4d |

### Deferred / extended matrix

Full stress, diagnostics-flag, and 1-hour soak tests in `PRODUCTION_TEST_CHECKLIST.md` remain **D** unless you need release-grade assurance. Re-run before App Store distribution.

---

## Performance baseline

Record **before** Version 2 Phase 7 optimization. Use the same test clip and display layout for all rows.

**Test asset:** _____________________ (path, resolution, codec, e.g. 1080p H.264 MP4)  
**Machine:** _____________________ (model, chip, macOS version)  
**Xcode / build:** Debug or Release: ___________

### How to measure

1. Apply wallpaper; let playback stabilize 30s.
2. Open **Activity Monitor** → select **Personal Wallpaper Engine** → View → Update Frequency: Very Low (1 sec).
3. Record **% CPU**, **% GPU**, **Energy Impact**, **Memory** over 60s (average eyeball or note min/avg/max).
4. Optional: Xcode **Instruments** → Energy Log or Time Profiler for one scenario.

### Results table

| Scenario | Power | CPU % (avg) | GPU % (avg) | Energy | Memory (MB) | Notes |
|----------|-------|-------------|-------------|--------|-------------|-------|
| 1 display, wallpaper playing, app on Home | AC | 4.9 | | | 450 | GPU/Energy N/A |
| 1 display, wallpaper playing, app minimized | AC | 3.9 | | | 450 | GPU/Energy N/A |
| 2 displays, same video both | AC | 5.9 | | | 650 | GPU/Energy N/A |
| 1 display, wallpaper playing | Battery | 4.9 | | | 450 | GPU/Energy N/A |
| 2 displays | Battery | 6.7 | | | 800 | No GPU/Energy data available|

### Competitor reference (marketing, not pass/fail)

| App | Claimed CPU (typical) |
|-----|------------------------|
| Wallspace | ~&lt;2% (blog/marketing) |
| Wallux | ~0.2% (marketing) |

**V2 Phase 7B internal target (suggested):** measurably lower than your table above on “1 display, AC, Balanced” — aspirational &lt;5% CPU on laptop for 1080p H.264 after optimization.

---

## Known gaps (accepted for V1)

- No automated XCTest suite; regression is build + smoke + manual.
- WebRenderer / VideoRenderer Swift 6 concurrency **warnings** on Xcode 16.4 (not errors).
- Resource usage improved vs V1 baseline on Balanced (see [`PERFORMANCE_TUNING.md`](PERFORMANCE_TUNING.md)); Phase **7C** adds diagnostics UI.
- No local library index, quick modes, lock screen — **Version 2**.

---

## Approvals

| Role | Name | Date |
|------|------|------|
| Engineering | | |
| Product / owner | | |

---

## References

- [`docs/VERSION_1_REFERENCE.md`](VERSION_1_REFERENCE.md) — feature inventory
- [`docs/UI_REFERENCE.md`](UI_REFERENCE.md) — UI spec
- [`PRODUCTION_TEST_CHECKLIST.md`](../PRODUCTION_TEST_CHECKLIST.md) — full matrix
- [`version2_developmental_roadmap.md`](../version2_developmental_roadmap.md) — next phases
- [`PHASE_7A_POWER_REGRESSION.md`](PHASE_7A_POWER_REGRESSION.md) — 7A playback + power matrix
- [`PERFORMANCE_TUNING.md`](PERFORMANCE_TUNING.md) — 7B baseline and experiment log
