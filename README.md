# Personal Wallpaper Engine

A macOS desktop wallpaper engine built in Swift that renders local video wallpapers across one or more displays with a VSCode-first development workflow. The project focuses on production-minded architecture, low-overhead playback, clean state management, and extensibility for future rendering modes and setup management.

## Overview

Personal Wallpaper Engine is designed to play local video files as animated macOS wallpapers while preserving a maintainable architecture suitable for incremental feature growth. The current roadmap reflects a stable core with multi-display support, per-display configuration, persistence, menu bar controls, web wallpaper support, and launch-on-login integration.

## Features

- Local video wallpaper playback for MP4 and MOV files.
- Multi-display wallpaper rendering and per-display source assignment.
- Virtual desktop and display-change awareness.
- Multiple scaling modes with per-display scaling support.
- Web and YouTube wallpaper rendering through a swappable renderer architecture.
- Menu bar controls for common actions such as play/pause, mute, preferences, and quit.
- Persistent user settings for wallpaper sources, renderer mode, mute state, and layout preferences.
- Launch-on-login support for supported macOS versions.
- Modular architecture built to support future collections, saved setups, and additional renderers.

## Tech Stack

| Layer | Technologies |
|-------|--------------|
| Language | Swift 5.10 |
| Platform | macOS 12+ |
| UI | SwiftUI, AppKit |
| Media | AVFoundation, AVPlayer, AVPlayerLayer |
| Web Rendering | WebKit, WKWebView |
| Concurrency | Swift actors, async/await, task groups, AsyncSequence |
| Persistence | UserDefaults |
| Tooling | Xcode toolchains, xcodebuild, sourcekit-lsp, VSCode |
| Version Control | Git, GitHub |

## Architecture

The codebase follows a modular design centered around a `WallpaperManager` actor that coordinates display lifecycle, renderer assignment, and wallpaper state. Per-display behavior is encapsulated in `DisplayController`, while rendering backends conform to a shared `Renderer` protocol, enabling clean separation between video and web wallpaper implementations.

Core persistence is handled through `SettingsStore`, and the UI layer is structured around SwiftUI views with reactive state updates. This separation keeps rendering logic, system integration, and interface concerns isolated and easier to extend.

## Project Structure

```text
PersonalWallpaperEngine/
├── PersonalWallpaperEngineApp.swift
├── ContentView.swift
├── AppViewModel.swift
├── WallpaperManager.swift
├── DisplayController.swift
├── Renderer.swift
├── VideoRenderer.swift
├── WebRenderer.swift
├── SettingsStore.swift
├── Assets.xcassets/
├── .vscode/
├── PersonalWallpaperEngine.xcodeproj/
└── README.md
```

## Development Workflow

This project uses a hybrid Swift development workflow: editing primarily in VSCode while relying on Xcode toolchains and SDKs for building, linking, debugging, and platform integration. The repository is structured to support local development first, with GitHub used for version control, collaboration, and milestone tracking.

## Roadmap

The implemented roadmap establishes a stable wallpaper engine core and Phase 5 feature set, including web rendering, per-display configuration, persistence improvements, menu bar controls, launch-on-login, and UI modernization. Planned next steps focus on wallpaper collections and full desktop setup snapshots for faster switching between saved configurations.

## Status

Current roadmap status indicates the Phase 5 feature set is complete and stable, with Phase 6 planned around collections and saved setups. The project is positioned as a local-first macOS utility rather than an App Store-distributed product at this stage.
