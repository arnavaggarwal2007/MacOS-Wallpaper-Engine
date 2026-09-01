# Personal Wallpaper Engine

A macOS desktop wallpaper engine built in Swift that renders local video and web wallpapers across one or more displays with a VSCode-first development workflow. The project focuses on production-minded architecture, clean state management, and a premium preview-first UI inspired by Wallspace and Wallux.

## Overview

Personal Wallpaper Engine — shipping on the Mac App Store as **Loopscape** — plays local video files (and optional web sources) as animated macOS wallpapers. **Version 1 is complete:** engine core (Phases 1–5), wallpaper collections (6A), desktop setups (6B), and the four-tab UI final vision. **Version 2** Phases 7–10 (research) are complete; **V2.2** (App Store–first implementation) is tracked in [`version2_developmental_roadmap.md`](version2_developmental_roadmap.md) Part 3.

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

### Canonical sources

When documents disagree, these win. Everything else should link here rather than restate.

| Topic | Canonical source |
|-------|------------------|
| **Pre-launch go/no-go** | [`docs/PRE_LAUNCH_STATUS.md`](docs/PRE_LAUNCH_STATUS.md) |
| Roadmap and phase status | This README's [Roadmap](#roadmap) table |
| App Store M1 status | [`docs/M1_COMPLIANCE_CHECKLIST.md`](docs/M1_COMPLIANCE_CHECKLIST.md) |
| Doc index | [`docs/README.md`](docs/README.md) |
| CPU benchmarks and suggestion thresholds | [`docs/PERFORMANCE_TUNING.md`](docs/PERFORMANCE_TUNING.md) |
| UI copy, naming rule, design tokens | [`DESIGN.md`](DESIGN.md) |
| Architecture rationale and history | `Wallpaper Engine KB/` (sibling folder) |

| Document | Purpose |
|----------|---------|
| [`docs/PRE_LAUNCH_STATUS.md`](docs/PRE_LAUNCH_STATUS.md) | Go/no-go gate before Archive / Submit |
| [`docs/README.md`](docs/README.md) | Categorized documentation index |
| [`docs/TESTING.md`](docs/TESTING.md) | Unit tests, manual matrix, agent write-only policy |
| [`docs/V1_SIGNOFF.md`](docs/V1_SIGNOFF.md) | V1 gate: functional + performance baseline |
| [`docs/PRE_RELEASE_CHECKLIST.md`](docs/PRE_RELEASE_CHECKLIST.md) | Consolidated release gate (incl. App Store) |
| [`docs/DISTRIBUTION.md`](docs/DISTRIBUTION.md) | Direct download: signing, notarization, DMG; MAS pointers |
| [`docs/DISTRIBUTION_CHANNELS.md`](docs/DISTRIBUTION_CHANNELS.md) | App Store vs Direct vs Steam strategy |
| [`docs/APP_STORE_SUBMISSION.md`](docs/APP_STORE_SUBMISSION.md) | Mac App Store Connect + review guide |
| [`docs/M1_COMPLIANCE_CHECKLIST.md`](docs/M1_COMPLIANCE_CHECKLIST.md) | M1 engineering + Connect sign-off matrix |
| [`docs/WEB_WALLPAPERS.md`](docs/WEB_WALLPAPERS.md) | Web renderer usage, schemes, sandbox |
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
| [`PRODUCTION_TEST_CHECKLIST.md`](PRODUCTION_TEST_CHECKLIST.md) | Archived — see [`docs/PRE_RELEASE_CHECKLIST.md`](docs/PRE_RELEASE_CHECKLIST.md) |
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

Editing primarily in VSCode; build and debug via Xcode toolchains (`xcodebuild`). CI: `CODE_SIGNING_ALLOWED=NO ./scripts/chunk7_regression.sh` (build, smoke, unit tests). Owner runs XCTest in Xcode (`Cmd+U`) — see [`docs/TESTING.md`](docs/TESTING.md) and [`AGENTS.md`](AGENTS.md).

Coding standards live in [`DESIGN.md`](DESIGN.md) (UI, copy, naming) and the docs under [`docs/`](docs/). Note that `guidelines.md`, `best_coding_practices.md`, and `update_KB_guidelines.md` are **local-only working notes** — they are gitignored and will not be present on a fresh clone, so nothing here treats them as required reading.

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
| V2.2 Milestone 1 (MAS compliance / App Store v1.0) | **Engineering + owner QA complete** (2026-08-29) — Connect upload pending |
| V2.2 Milestone 2 (Tier A + B on all flavors) | Planned after M1 |
| V2.2 Milestone 3 (Direct DMG + Sparkle / Tier C) | Deferred after App Store |

## Status

**August 29–31, 2026:** M1 **engineering + owner QA complete** — full [`PRE_RELEASE_CHECKLIST`](docs/PRE_RELEASE_CHECKLIST.md) signed off 2026-08-29; **92** unit tests; owner regression `chunk7_regression.sh` **P** 2026-08-31. **Launch gate:** [`docs/PRE_LAUNCH_STATUS.md`](docs/PRE_LAUNCH_STATUS.md). **Next (owner):** Connect upload per [`docs/APP_STORE_SUBMISSION.md`](docs/APP_STORE_SUBMISSION.md).

**August 20, 2026:** Milestone 1 **complete and merged** — App Store flavor (`PWE App Store`), privacy manifest, update gating, web URL hardening + `network.client`. Launch prep also landed: the App Store display name is **Loopscape** (`INFOPLIST_KEY_CFBundleDisplayName`; bundle ID and Xcode target unchanged), in-app Privacy Policy and Support links, a first-run welcome card, and hosted pages under [`docs/`](docs/) for GitHub Pages. Docs: `M1_COMPLIANCE_CHECKLIST.md`, `WEB_WALLPAPERS.md`, `APP_STORE_SUBMISSION.md`.

A pre-launch audit followed on the same day. Most visibly, the high-CPU suggestion banner fired on nearly every launch: its thresholds were calibrated from Debug-build measurements roughly five times lower than Release, and the message quoted per-core CPU, so an app using about 1% of the machine reported "averaged 14%". Thresholds are now expressed as system-wide share ([`docs/PERFORMANCE_TUNING.md`](docs/PERFORMANCE_TUNING.md) §ADR-009). The same pass fixed resource leaks (observers, tasks, and a suspended continuation), two silent data-loss paths in settings persistence and display rekeying, dead screen-lock pause code, and several main-thread I/O and over-invalidation problems in the UI.
