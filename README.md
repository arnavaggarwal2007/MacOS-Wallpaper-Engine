# Personal Wallpaper Engine

A macOS desktop wallpaper engine built in Swift that renders local video and web wallpapers across one or more displays with a VSCode-first development workflow. The project focuses on production-minded architecture, clean state management, and a premium preview-first UI inspired by Wallspace and Wallux.

## Overview

Personal Wallpaper Engine plays local video files (and optional web sources) as animated macOS wallpapers. **Version 1 is complete:** engine core (Phases 1–5), wallpaper collections (6A), desktop setups (6B), and the four-tab UI final vision. **Version 2** Phases 7–10 (research) are complete; **V2.2** (App Store–first implementation) is tracked in [`version2_developmental_roadmap.md`](version2_developmental_roadmap.md) Part 3.

## Features

- Local video wallpaper playback for MP4 and MOV files.
- Multi-display wallpaper rendering and per-display source assignment.
- Virtual desktop and display-change awareness.
- Multiple scaling modes with per-display scaling support.
- Web wallpaper rendering through a swappable renderer architecture (WKWebView).
- Wallpaper collections (simple and display-bound) with security-scoped bookmarks.
- Desktop setups — save and restore full application state snapshots.
- Quick modes (Single All, Per Display, Pinned Setup) with drift-to-Custom detection.
- Menu bar control center: display-aware preview, quick modes, collections/setups, recents, power shortcuts.
- Persistent user settings via UserDefaults (JSON-encoded collections and setups).
- Launch-on-login support for supported macOS versions (13.2+).
- Modern UI shell: four tabs with shared live wallpaper background (`AppWallpaperBackground`), glass chrome, and hero-first Home with scroll-reveal display carousel.

## Documentation

| Document | Purpose |
|----------|---------|
| [`docs/V1_SIGNOFF.md`](docs/V1_SIGNOFF.md) | V1 gate: functional + performance baseline |
| [`docs/PRE_RELEASE_CHECKLIST.md`](docs/PRE_RELEASE_CHECKLIST.md) | Consolidated release gate (incl. App Store) |
| [`docs/DISTRIBUTION.md`](docs/DISTRIBUTION.md) | Direct download: signing, notarization, DMG; MAS pointers |
| [`docs/DISTRIBUTION_CHANNELS.md`](docs/DISTRIBUTION_CHANNELS.md) | App Store vs Direct vs Steam strategy |
| [`docs/APP_STORE_SUBMISSION.md`](docs/APP_STORE_SUBMISSION.md) | Mac App Store Connect + review guide |
| [`docs/V2_2_APP_STORE_IMPLEMENTATION.md`](docs/V2_2_APP_STORE_IMPLEMENTATION.md) | V2.2 M1/M2 charter (trunk + flavors) |
| [`docs/V2_2_DIRECT_IMPLEMENTATION.md`](docs/V2_2_DIRECT_IMPLEMENTATION.md) | Direct DMG stub (after App Store) |
| [`docs/PRIVACY_POLICY.md`](docs/PRIVACY_POLICY.md) | Hostable privacy policy |
| [`docs/PHASE_10A_FEASIBILITY.md`](docs/PHASE_10A_FEASIBILITY.md) | Phase 10A: lock-screen/screensaver feasibility |
| [`docs/PHASE_10B_SCREENSAVER_RESEARCH.md`](docs/PHASE_10B_SCREENSAVER_RESEARCH.md) | Phase 10B: screensaver research |
| [`docs/PHASE_10C_LOCK_SCREEN_RESEARCH.md`](docs/PHASE_10C_LOCK_SCREEN_RESEARCH.md) | Phase 10C: lock-screen research |
| [`docs/PHASE_10_SUMMARY.md`](docs/PHASE_10_SUMMARY.md) | Phase 10 executive summary |
| [`docs/VERSION_1_REFERENCE.md`](docs/VERSION_1_REFERENCE.md) | V1 feature inventory and architecture |
| [`DESIGN.md`](DESIGN.md) | Design spec (product shape, tokens, copy catalog) |
| [`docs/UI_REFERENCE.md`](docs/UI_REFERENCE.md) | UI spec (tabs, layout, flows) |
| [`version2_developmental_roadmap.md`](version2_developmental_roadmap.md) | Phases 7–10 + V2.2 Part 3 |
| [`docs/PHASE_9_QUICK_MODES.md`](docs/PHASE_9_QUICK_MODES.md) | Phase 9 quick modes + menu bar |
| [`docs/PHASE_9_REGRESSION.md`](docs/PHASE_9_REGRESSION.md) | Phase 9 regression matrix |
| [`PRODUCTION_TEST_CHECKLIST.md`](PRODUCTION_TEST_CHECKLIST.md) | Full manual test matrix |
| [`docs/archive/`](docs/archive/) | Historical roadmaps and phase validation notes |

Knowledge base (Obsidian): sibling folder `Wallpaper Engine KB/` on Desktop — start at `10 Project Home.md` and `KB-Guide.md` (architecture, features, ADRs, changelog).

## Tech Stack

| Layer | Technologies |
|-------|--------------|
| Language | Swift 5.10 |
| Platform | macOS 15.0+ (deployment target 15.0; launch-on-login requires 13.2+ at runtime) |
| UI | SwiftUI, AppKit |
| Media | AVFoundation, AVPlayer, AVPlayerLayer |
| Web Rendering | WebKit, WKWebView |
| Concurrency | Swift actors, async/await, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` |
| Persistence | UserDefaults |
| Tooling | Xcode, xcodebuild, VSCode, GitHub Actions |
| Version Control | Git, GitHub |

## Architecture

The codebase follows a modular design centered around a `@MainActor` `WallpaperManager` that coordinates display lifecycle, renderer assignment, and wallpaper state. Per-display behavior is encapsulated in `DisplayController`, while rendering backends conform to a shared `Renderer` protocol.

Core persistence is handled through `SettingsStore`. The UI layer uses SwiftUI with `AppViewModel` orchestration.

## Project Structure

```text
Personal Wallpaper Engine/
├── docs/                    # V1 sign-off, references, archive
├── Personal_Wallpaper_EngineApp.swift
├── TabbedMainView.swift
├── ModernHomeView.swift
├── CollectionsTabView.swift
├── SetupsTabView.swift
├── SettingsTabView.swift
├── AppViewModel.swift
├── WallpaperManager.swift
├── UI/                      # Glass chrome, cards, thumbnails
├── scripts/                 # xcodebuild_ci, chunk7 smoke/regression
└── Personal Wallpaper Engine.xcodeproj/
```

## Development Workflow

Editing primarily in VSCode; build and debug via Xcode toolchains (`xcodebuild`). See `guidelines.md` and `best_coding_practices.md`. CI: `CODE_SIGNING_ALLOWED=NO ./scripts/chunk7_regression.sh`.

## Roadmap

| Area | Status |
|------|--------|
| Phases 1–5 (core engine, web, per-display, menu bar, launch-on-login) | Complete |
| Phase 6A (wallpaper collections) | Complete |
| Phase 6B (desktop setups) | Complete |
| UI final vision (4 tabs, app-wide background, glass tabs) | Complete — merged to `main` May 2026 |
| Version 2 Phase 7 (performance, power, diagnostics — 7A–7G) | Complete — signed off 2026-06-01; see `docs/PERFORMANCE_TUNING.md` |
| Version 2 Phase 8 (local library — 8A–8C) | Complete — see [`docs/PHASE_8_LIBRARY.md`](docs/PHASE_8_LIBRARY.md) |
| Version 2 Phase 9 (quick modes + menu bar) | Complete — see `version2_developmental_roadmap.md` |
| Version 2 Phase 10 (lock-screen + distribution research) | **Complete** — see Phase 10 docs above |
| V2.2 docs + App Store–first charter (trunk + flavors) | **Complete** (2026-08-20) — see Part 3 in roadmap |
| V2.2 Milestone 1 (MAS compliance / App Store v1.0) | **Next** — engineering not started |
| V2.2 Milestone 2 (Tier A + B on all flavors) | Planned after M1 |
| V2.2 Milestone 3 (Direct DMG + Sparkle / Tier C) | Deferred after App Store |

## Status

**August 20, 2026:** Documentation solidified for **App Store–first** phased launch on a **single trunk with build flavors** (no permanent channel branches). Phases 1–9 remain the shippable desktop product; Phase 10 research stands; V2.2 implementation charters are in `docs/`. **Next:** Milestone 1 engineering (`feature/mas-compliance`). KB: sibling `Wallpaper Engine KB/`.
