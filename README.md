# Personal Wallpaper Engine

A macOS desktop wallpaper engine built in Swift that renders local video and web wallpapers across one or more displays with a VSCode-first development workflow. The project focuses on production-minded architecture, clean state management, and a premium preview-first UI inspired by Wallspace and Wallux.

## Overview

Personal Wallpaper Engine plays local video files (and optional web sources) as animated macOS wallpapers. **Version 1 is complete:** engine core (Phases 1–5), wallpaper collections (6A), desktop setups (6B), and the four-tab UI final vision. **Version 2** (power, engine efficiency, local library, quick modes) is tracked in [`version2_developmental_roadmap.md`](version2_developmental_roadmap.md).

## Features

- Local video wallpaper playback for MP4 and MOV files.
- Multi-display wallpaper rendering and per-display source assignment.
- Virtual desktop and display-change awareness.
- Multiple scaling modes with per-display scaling support.
- Web wallpaper rendering through a swappable renderer architecture (WKWebView).
- Wallpaper collections (simple and display-bound) with security-scoped bookmarks.
- Desktop setups — save and restore full application state snapshots.
- Menu bar controls for play/pause, mute, preferences, and quit.
- Persistent user settings via UserDefaults (JSON-encoded collections and setups).
- Launch-on-login support for supported macOS versions (13.2+).
- Modern UI shell: four tabs with shared live wallpaper background (`AppWallpaperBackground`), glass chrome, and hero-first Home with scroll-reveal display carousel.

## Documentation

| Document | Purpose |
|----------|---------|
| [`docs/V1_SIGNOFF.md`](docs/V1_SIGNOFF.md) | V1 gate: functional + performance baseline |
| [`docs/VERSION_1_REFERENCE.md`](docs/VERSION_1_REFERENCE.md) | V1 feature inventory and architecture |
| [`docs/UI_REFERENCE.md`](docs/UI_REFERENCE.md) | UI spec (tabs, layout, flows) |
| [`version2_developmental_roadmap.md`](version2_developmental_roadmap.md) | Phases 7–10 (V2) |
| [`PRODUCTION_TEST_CHECKLIST.md`](PRODUCTION_TEST_CHECKLIST.md) | Full manual test matrix |
| [`docs/archive/`](docs/archive/) | Historical roadmaps and phase validation notes |

Knowledge base (Obsidian): `Wallpaper Engine KB/` — architecture, features, ADRs, changelog.

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

The codebase follows a modular design centered around a `WallpaperManager` actor that coordinates display lifecycle, renderer assignment, and wallpaper state. Per-display behavior is encapsulated in `DisplayController`, while rendering backends conform to a shared `Renderer` protocol.

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
| Version 2 Phase 7 (performance & power) | Next — see `version2_developmental_roadmap.md` |
| Version 2 Phases 8–10 (library, quick modes, lock screen research) | Planned |

## Status

**May 21, 2026:** V1 sign-off doc added; documentation consolidated under `docs/`. CI regression green on `main`. Complete performance baseline table in `docs/V1_SIGNOFF.md` before Phase 7B engine optimization.
