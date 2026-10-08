# Personal Wallpaper Engine

A macOS desktop wallpaper engine built in Swift that renders local video and web wallpapers across one or more displays with a VSCode-first development workflow. The project focuses on production-minded architecture, clean state management, and a premium preview-first UI inspired by Wallspace and Wallux.

## Overview

Personal Wallpaper Engine — shipping on the Mac App Store as **Deskface** — plays local video files (and optional web sources) as animated macOS wallpapers. **Deskface 1.0** includes the desktop engine, collections, setups, the four-tab UI, performance profiles, the local library, and quick modes with a menu bar. **Next:** [Milestone 2](ROADMAP.md) Part 2 (static lock-screen export). The video screensaver (Part 1) is implemented and waiting on owner QA.

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

When documents disagree, the table below wins. The index is [`docs/README.md`](docs/README.md).

| Topic | Canonical source |
|-------|------------------|
| What ships next | [`ROADMAP.md`](ROADMAP.md) |
| Milestone 2 (screensaver and lock export) | [`docs/MILESTONE_2.md`](docs/MILESTONE_2.md) |
| Release record | [`docs/RELEASE_RECORD.md`](docs/RELEASE_RECORD.md) |
| QA matrix | [`docs/RELEASE_CHECKLIST.md`](docs/RELEASE_CHECKLIST.md) |
| CPU and suggestion thresholds | [`docs/PERFORMANCE.md`](docs/PERFORMANCE.md) |
| UI copy, naming, design tokens | [`DESIGN.md`](DESIGN.md) |
| Architecture and history | `Wallpaper Engine KB/` (sibling folder) |

| Document | Purpose |
|----------|---------|
| [`docs/README.md`](docs/README.md) | Documentation index |
| [`docs/UI.md`](docs/UI.md) | Tabs, layout, flows |
| [`docs/LIBRARY.md`](docs/LIBRARY.md) | Local library |
| [`docs/QUICK_MODES.md`](docs/QUICK_MODES.md) | Quick modes and menu bar |
| [`docs/WEB_WALLPAPERS.md`](docs/WEB_WALLPAPERS.md) | Web renderer, sandbox, URL allowlist |
| [`docs/CHANNELS.md`](docs/CHANNELS.md) | App Store, Direct, and Steam |
| [`docs/DIRECT_PLAN.md`](docs/DIRECT_PLAN.md) | Milestone 3 stub |
| [`docs/DISTRIBUTION.md`](docs/DISTRIBUTION.md) | Signing, notarization, DMG |
| [`docs/APP_STORE_SUBMISSION.md`](docs/APP_STORE_SUBMISSION.md) | App Store Connect guide |
| [`docs/PRIVACY_POLICY.md`](docs/PRIVACY_POLICY.md) | Privacy policy |
| [`docs/TESTING.md`](docs/TESTING.md) | Unit tests and agent policy |
| [`docs/archive/`](docs/archive/) | Old roadmaps, phase research, and regression matrices |

Knowledge base (Obsidian): sibling folder `Wallpaper Engine KB/` — start at `10 Project Home.md` and `KB-Guide.md`.

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
├── docs/                    # Living references, release docs, archive
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
| Deskface 1.0 (desktop engine, collections, setups, UI, performance, library, quick modes, menu bar) | **Live** on the Mac App Store since October 6, 2026 — version **1.0 (2)** |
| Milestone 2 Part 1 (screensaver) | **Implemented**, not on the store — owner QA in [`docs/RELEASE_CHECKLIST.md`](docs/RELEASE_CHECKLIST.md) |
| Milestone 2 Part 2 (static lock export) | **Next** — [`docs/MILESTONE_2.md`](docs/MILESTONE_2.md) |
| Milestone 3 (Direct download, Sparkle, live lock video) | Later — [`docs/DIRECT_PLAN.md`](docs/DIRECT_PLAN.md) |
| Backlog (view-model split, accessibility, localization, tests) | After launch — knowledge base `POST_LAUNCH_BACKLOG.md` |

Full map: [`ROADMAP.md`](ROADMAP.md).

## Status

**October 6, 2026:** Deskface **1.0 (2)** is on the Mac App Store. Next work is Milestone 2. Record: [`docs/RELEASE_RECORD.md`](docs/RELEASE_RECORD.md).

**August 29–31, 2026:** Milestone 1 engineering and owner QA finished — [`docs/RELEASE_CHECKLIST.md`](docs/RELEASE_CHECKLIST.md) signed off 2026-08-29; **92** unit tests; owner regression `chunk7_regression.sh` **P** 2026-08-31.

**August 20, 2026:** App Store flavor (`PWE App Store`), privacy manifest, update gating, web URL hardening, and `network.client` merged. The store name is **Deskface**. Bundle ID and the Xcode target name are unchanged.

A pre-launch audit the same day recalibrated the high-CPU suggestion banner. Thresholds had been taken from Debug builds and the message quoted per-core CPU, so an app using about 1% of the machine reported “averaged 14%”. Thresholds are now a system-wide share ([`docs/PERFORMANCE.md`](docs/PERFORMANCE.md)). That pass also fixed resource leaks, two silent data-loss paths, dead screen-lock pause code, and main-thread I/O in the UI.
