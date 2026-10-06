# Version 1 Reference

**Status:** Complete (Phases 1–6B + UI final vision)  
**Last updated:** 2026-08-31  
**Branch:** `main`  
**V2 status:** Phases 7–9 complete; **Phase 10 research complete** (2026-06-21); **V2.2 docs / App Store–first charter complete** (2026-08-20) — [`PHASE_10_SUMMARY.md`](PHASE_10_SUMMARY.md), [`V2_2_APP_STORE_IMPLEMENTATION.md`](V2_2_APP_STORE_IMPLEMENTATION.md), [`version2_developmental_roadmap.md`](../version2_developmental_roadmap.md) Part 3  
**Knowledge base:** Sibling [`Wallpaper Engine KB/`](../../Wallpaper%20Engine%20KB/) — [`20 Architecture/00 Architecture Index`](../../Wallpaper%20Engine%20KB/20%20Architecture/00%20Architecture%20Index.md), [`30 Features/00 Features Index`](../../Wallpaper%20Engine%20KB/30%20Features/00%20Features%20Index.md)  

Sign-off record: [`V1_SIGNOFF.md`](V1_SIGNOFF.md)

---

## What Version 1 includes

### Phases 1–4 — Engine core

| Phase / chunk | Deliverable |
|---------------|-------------|
| 1–3 | `WallpaperManager`, `DisplayController`, `Renderer` protocol, `VideoRenderer` (AVPlayer), file apply, mute, scaling |
| 4A–4D | Lifecycle (sleep/wake), recovery, resize debounce, state reconciliation |
| 4E | Diagnostics flag, system health tracking, production checklist |

### Phase 5 — Product shell

| Subphase | Deliverable |
|----------|-------------|
| 5A–5F | Web renderer (`WebRenderer`), renderer mode switching |
| 5G | Launch on login (`LoginItemManager`) |
| 5H–5I | Per-display wallpapers, scaling per display, UI enhancements |

### Phase 6A — Wallpaper collections

- `WallpaperCollection` (simple + display-bound)
- CRUD and apply via `AppViewModel`
- Security-scoped bookmarks in `SettingsStore`
- [`CollectionsTabView.swift`](../Personal%20Wallpaper%20Engine/CollectionsTabView.swift), collection editor UI

### Phase 6B — Desktop setups

- `SavedSetup` full state snapshot (sources, renderer, mute, scaling, bookmarks)
- Save / restore / delete via `AppViewModel`
- [`SetupsTabView.swift`](../Personal%20Wallpaper%20Engine/SetupsTabView.swift)

### UI final vision (2026-05)

- Four tabs: Home, Collections, Setups, Settings (`TabbedMainView`)
- App-wide live wallpaper background (`AppWallpaperBackground`)
- Hero-first Home, scroll-reveal display carousel, glass management tabs
- Spec: [`UI_REFERENCE.md`](UI_REFERENCE.md), KB `Feature-UI-Final-Vision`

---

## Architecture (current)

```text
Personal_Wallpaper_EngineApp
  └── TabbedMainView
        ├── AppWallpaperBackground (layer 0)
        ├── Tab content (ModernHomeView | Collections | Setups | Settings)
        └── MainTabBar (floating)
  └── MenuBarController (status item)
  └── AppViewModel (@MainActor)
        └── WallpaperManager (@MainActor)
              └── DisplayController × N
                    └── VideoRenderer | WebRenderer | SharedVideoLayerRenderer
        └── SettingsStore (UserDefaults)
        └── LocalLibraryManager (V2 Phase 8)
        └── PowerPolicyManager / PerformanceMonitor (V2 Phase 7)
```

**Concurrency:** `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` on target; `WallpaperManager` and `AppViewModel` are `@MainActor` classes. See KB `ADR-003-WallpaperManager-Actor-Architecture`.

**Platform:** macOS 15.0+ deployment target; CI builds universal binary (arm64 + x86_64) via `scripts/xcodebuild_ci.sh`.

---

## Persistence model (what restores on launch)

| Stored data | Written when | Restored on launch? |
|-------------|----------------|---------------------|
| `perDisplaySources` / `perDisplayBookmarks` | Apply, collections, setups | **Yes** — `reapplyPersistedPerDisplayWallpapers()` |
| `lastUsedCollectionName` | Collection apply | Used when resolving source keys (not a full collection re-apply alone) |
| `currentSetupName` | Setup **Restore & Apply** | **No** — only selects active setup in UI until user restores |
| `videoFilePath` / `videoBookmarkData` | Single-file pick | Fallback if no per-display entries exist |

**Hotplug:** When display IDs change after reconnecting a monitor, `DisplayConfigurationMigrator` re-keys settings by screen name + resolution, then reapplies. See [`HOTPLUG_REGRESSION.md`](HOTPLUG_REGRESSION.md).

---

## Module map

| Module | Responsibility |
|--------|----------------|
| `DisplayConfigurationMigrator.swift` | Re-key per-display settings when `CGDirectDisplayID` changes |
| `WallpaperManager.swift` | Display registry, screen/space observers, apply/pause, reconciliation |
| `DisplayController.swift` | Per-display window + renderer lifecycle |
| `VideoRenderer.swift` | AVPlayer / AVPlayerLayer wallpaper |
| `WebRenderer.swift` | WKWebView wallpaper |
| `AppViewModel.swift` | UI state, collections, setups, apply flows |
| `SettingsStore.swift` | Persistence (paths, bookmarks, collections, setups) |
| `MenuBarController.swift` | Menu bar controls |
| `LoginItemManager.swift` | Launch at login |
| `UI/*` | Design tokens, glass chrome, cards, modals, thumbnails |

### Version 2 modules (Phases 7–8)

| Module | Responsibility |
|--------|----------------|
| `PowerPolicyManager.swift` | AC/battery/LPM events (7A) |
| `SharedVideoPlaybackSession.swift` | Coalesced multi-display decode (7B P2) |
| `DesktopVisibilityTracker.swift` | Occlusion-based desktop pause (7B P3) |
| `PerformanceMonitor.swift` | CPU sampling, profiles, suggestions (7B–7C) |
| `LocalLibraryManager.swift` | Library roots, scan, favorites (8) |
| `LibraryThumbnailCache.swift` | Disk thumbnails, LRU (8B) |
| `LibraryBrowserView.swift` | Home library grid (8C) |

KB: `Feature-V2-*` notes under `30 Features/`, architecture modules under `20 Architecture/Modules/`.

---

## Verification

| Layer | How |
|-------|-----|
| CI | `.github/workflows/chunk7_regression.yml` — Debug + Release, unsigned |
| Local smoke | `CODE_SIGNING_ALLOWED=NO ./scripts/chunk7_smoke.sh` |
| Local regression | `CODE_SIGNING_ALLOWED=NO ./scripts/chunk7_regression.sh` |
| Manual | [`PRODUCTION_TEST_CHECKLIST.md`](../PRODUCTION_TEST_CHECKLIST.md), [`V1_SIGNOFF.md`](V1_SIGNOFF.md) |

---

## Historical documentation

Full phase-by-phase implementation history (2500+ lines) is archived at:

[`docs/archive/developmental_roadmap.md`](archive/developmental_roadmap.md)

UI execution history: [`docs/archive/ui_revamp_roadmap.md`](archive/ui_revamp_roadmap.md)

---

## Version 2 pointer

- **Phases 7–8:** Complete (2026-06-01) — power, engine performance, diagnostics, local library.
- **Phase 9:** Quick modes + menu bar (complete). See [`PHASE_9_QUICK_MODES.md`](PHASE_9_QUICK_MODES.md).
- **Phase 10:** Research complete. See [`PHASE_10_SUMMARY.md`](PHASE_10_SUMMARY.md).
- **V2.2:** App Store–first implementation charter — [`V2_2_APP_STORE_IMPLEMENTATION.md`](V2_2_APP_STORE_IMPLEMENTATION.md); roadmap Part 3.
- Repo: `version2_developmental_roadmap.md`, `docs/PERFORMANCE_TUNING.md`, `docs/PHASE_8_LIBRARY.md`.
- KB: `70 Master Plan/MASTER_DEVELOPMENT_PLAN.md`, `60 Changelog/Project-Changelog.md`, ADR-008.
