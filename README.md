# Personal Wallpaper Engine

A macOS desktop wallpaper engine built in Swift that renders local video and web wallpapers across one or more displays with a VSCode-first development workflow. The project focuses on production-minded architecture, low-overhead playback, clean state management, and a premium preview-first UI inspired by Wallspace and Wallux.

## Overview

Personal Wallpaper Engine plays local video files (and optional web sources) as animated macOS wallpapers while preserving a maintainable architecture suitable for incremental feature growth. The engine core (Phases 1–5) and wallpaper collections (Phase 6A) are complete. The UI final vision (Phases 2–4) delivers a preview-first shell with app-wide live wallpaper background, glass management tabs, and scroll-reveal displays on Home.

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

## Tech Stack

| Layer | Technologies |
|-------|--------------|
| Language | Swift 5.10 |
| Platform | macOS (Xcode deployment target 26.2; broader 12.0+ compatibility goal in roadmaps) |
| UI | SwiftUI, AppKit |
| Media | AVFoundation, AVPlayer, AVPlayerLayer |
| Web Rendering | WebKit, WKWebView |
| Concurrency | Swift actors, async/await, task groups, AsyncSequence |
| Persistence | UserDefaults |
| Tooling | Xcode toolchains, xcodebuild, sourcekit-lsp, VSCode |
| Version Control | Git, GitHub |

## Architecture

The codebase follows a modular design centered around a `WallpaperManager` actor that coordinates display lifecycle, renderer assignment, and wallpaper state. Per-display behavior is encapsulated in `DisplayController`, while rendering backends conform to a shared `Renderer` protocol.

Core persistence is handled through `SettingsStore`. The UI layer uses SwiftUI with `AppViewModel` orchestration.

## Project Structure

```text
Personal Wallpaper Engine/
├── Personal_Wallpaper_EngineApp.swift   # @main → TabbedMainView
├── TabbedMainView.swift                # Home | Collections | Setups | Settings
├── SetupsTabView.swift
├── SettingsTabView.swift
├── ModernHomeView.swift                # Hero-first home workspace
├── CollectionsTabView.swift          # Collection management tab
├── AppViewModel.swift
├── WallpaperManager.swift
├── DisplayController.swift
├── Renderer.swift, VideoRenderer.swift, WebRenderer.swift
├── SettingsStore.swift, WallpaperCollection.swift, SavedSetup.swift
├── UI/                                 # AppWallpaperBackground, glass chrome, cards, modals
├── Assets.xcassets/
├── Personal Wallpaper Engine.xcodeproj/
└── README.md
```

Knowledge base (Obsidian): `Wallpaper Engine KB/` — architecture, features, ADRs, changelog.

## Development Workflow

Editing primarily in VSCode; build and debug via Xcode toolchains (`xcodebuild`). See `guidelines.md` and `best_coding_practices.md`. For non-trivial changes, consult the KB before coding and update docs per `update_KB_guidelines.md`.

## Roadmap

| Area | Status |
|------|--------|
| Phases 1–5 (core engine, web, per-display, menu bar, launch-on-login) | Complete |
| Phase 6A (wallpaper collections) | Complete |
| Phase 6B (desktop setups) | In progress (code on branch) |
| UI final vision (4 tabs, app-wide background, glass tabs) | **Complete** — merged to `main` May 2026 |
| Per-display wallpapers | Always on; use Home **Choose Wallpaper** or Settings **Apply to All** |
| Part 2 (power, local library) | Planned — `version2_developmental_roadmap.md` |

## Status

**May 20, 2026:** UI revamp Phases 0–4 complete and merged to `main` (`ui/polish/pr4-motion`). See `ui_revamp_roadmap.md`, `PHASE_3_VALIDATION.md`, and `PHASE_4_VALIDATION.md`.
