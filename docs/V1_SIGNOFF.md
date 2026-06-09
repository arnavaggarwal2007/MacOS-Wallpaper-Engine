# Version 1 Sign-Off

**Date:** 2026-06-01 (updated)  
**Build:** Debug local 2026-06-01; Release build verified 2026-06-01  
**Scope:** Phases 1–6B + UI final vision (Phases 0–4) + Phase 7 (7A–7G)  
**Gate:** V1 complete; **Phase 7 complete** (7A–7G, 2026-06-01); **Phase 8 complete** (8A–8C, 2026-06-01); **Phase 9 complete** (9A–9B, 2026-06-09). Phase 10 next.  
**Knowledge base:** `Wallpaper Engine KB/` — `10 Project Home.md`, `KB-Guide.md`, `30 Features/Feature-Desktop-Setups-Phase-6B.md`, `60 Changelog/Project-Changelog.md`.

---

## Sign-off summary

| Area | Status | Notes |
|------|--------|-------|
| Automated build & smoke | **Pass** | `chunk7_smoke.sh` + GitHub Actions universal Debug/Release |
| UI revamp validation | **Pass** | User verified May 20, 2026; merged to `main` |
| Functional matrix (manual) | **Pass (reported)** | Owner confirmed app working in daily use; spot-check sections below |
| Phase 7B engine efficiency | **Pass** | P0–P4 complete; see [`PERFORMANCE_TUNING.md`](PERFORMANCE_TUNING.md) |
| Phase 7C diagnostics UI | **Pass** | CPU monitor, suggestion banner, Settings diagnostics, engine restart |
| Phase 7D unified hero decode | **Pass** | Hero layer on desktop AVPlayer when same file |
| Phase 7E profile differentiation | **Pass** | 1080p cap Balanced/Battery; Max live all tabs |
| Phase 7G closeout | **Pass** | Hero attach stability; **Release 12-row benchmark matrix** in [`PERFORMANCE_TUNING.md`](PERFORMANCE_TUNING.md) § Phase 7 Closeout (2026-06-01) |
| Hotplug / launch / setup persistence | **Pass** | See [`HOTPLUG_REGRESSION.md`](HOTPLUG_REGRESSION.md) |
| Phase 7A power policy | **Pass** | [`PHASE_7A_POWER_REGRESSION.md`](PHASE_7A_POWER_REGRESSION.md) |
| Phase 7A playback UX | **Pass** | 2026-05-22 — launch auto-play, frozen-frame pause, hero preview sync; matrix rows 10–11, 15–16 |
| Phase 9A quick modes | **Pass (build + code)** | [`PHASE_9_REGRESSION.md`](PHASE_9_REGRESSION.md) — manual hero/pin rows pending owner |
| Phase 9B menu bar | **Pass (partial)** | Thumbnail/status confirmed; full matrix in PHASE_9_REGRESSION |
| Phase 9 post-ship fixes | **Pass (build + code)** | Hero attach token, pin UX, sidebar persistence, Settings cleanup |

**Recommendation:** V1 + **Phases 7–9 complete (9A–9B, 2026-06-09)**. **Phase 10** (lock-screen research) next. Engine results in [`PERFORMANCE_TUNING.md`](PERFORMANCE_TUNING.md); library regression in [`PHASE_8_LIBRARY.md`](PHASE_8_LIBRARY.md); Phase 9 matrix in [`PHASE_9_REGRESSION.md`](PHASE_9_REGRESSION.md).

---

## Automated verification

| Check | Command | Result | Date |
|-------|---------|--------|------|
| Debug smoke build | `CODE_SIGNING_ALLOWED=NO ./scripts/chunk7_smoke.sh` | Pass (universal x86_64 + arm64) | 2026-05-22 |
| Local Debug build (7A playback UX) | Xcode Debug scheme | Pass | 2026-05-22 |
| Local Debug + Release build (7G closeout) | Xcode Debug + Release | Pass | 2026-06-01 |
| CI regression | GitHub Actions `chunk7_regression.yml` on `1cfe02f` | Pass | 2026-05-21 |
| Swift concurrency (CI) | Xcode 16.4 universal build | Pass (MenuBar + thumbnail fixes) | 2026-05-21 |
| Phase 9 close-out Debug build | `xcodebuild -scheme "Personal Wallpaper Engine" Debug` | Pass | 2026-06-09 |

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

### Phase 9 (quick modes + menu bar)

| Test | Status | Notes |
|------|--------|-------|
| Quick Mode selector (Single All, Per Display, Pinned, Custom drift) | P* | *Build + code; hero manual in [`PHASE_9_REGRESSION.md`](PHASE_9_REGRESSION.md) |
| Hero stable after Single All / Per Display switch | M | Third-pass attach token fix |
| Setup pin/unpin + Quick Mode pinned item | M | |
| Home sidebar default closed + persistence | M | |
| Menu bar thumbnail + Quick Mode submenus | P* | Thumbnail/status user-confirmed |
| Settings: no video wallpaper picker | M | Web URL when web renderer |
| Show Main Window / Preferences activation | M | |

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
- **Phase 8** local library and **Phase 9** quick modes + menu bar are **shipped** (2026-06-09). Lock-screen integration remains **Phase 10** (research).

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
- [`PHASE_9_REGRESSION.md`](PHASE_9_REGRESSION.md) — Phase 9 manual matrix
