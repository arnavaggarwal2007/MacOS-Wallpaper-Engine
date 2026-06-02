# Version 2 Developmental Roadmap (Phases 7–10)

**Prerequisite:** Version 1 complete — see [`docs/V1_SIGNOFF.md`](docs/V1_SIGNOFF.md), [`docs/VERSION_1_REFERENCE.md`](docs/VERSION_1_REFERENCE.md), [`docs/UI_REFERENCE.md`](docs/UI_REFERENCE.md).

Here’s a linear “Part 2” roadmap (Phase 7+) that assumes your existing roadmap through Phase 6 (Collections + Desktop Setups) is complete and stable. It’s structured in the same style so you can drop it straight into your document as the next section.[^1]

***

## Phase 7 Roadmap — Performance, Power, and Diagnostics

**Goal:** Make the engine explicitly battery‑ and performance‑aware so it feels as \"light\" as apps like Wallspace on MacBooks and under load.[^2][^3][^4]

### Phase 7 Summary

| Phase | Scope | Duration | Depends On |
| :-- | :-- | :-- | :-- |
| 7A | PowerPolicyManager + power events wiring | ~2 weeks | V1 sign-off ([docs/V1_SIGNOFF.md](docs/V1_SIGNOFF.md)) |
| 7B | Engine efficiency + performance profiles | ~3 weeks | 7A complete |
| 7C | Performance monitoring + diagnostics UI | ~2 weeks | 7B complete |


***

### Phase 7A — PowerPolicyManager and Battery‑Aware Behavior

**Scope:** Introduce a dedicated power‑policy subsystem that observes AC/battery state, battery level, and Low Power Mode, then exposes simple signals to WallpaperManager.[^1]

**Key Design Points:**

- New module `PowerPolicyManager` (actor or `@MainActor` class):
    - Observes power source changes via `ProcessInfo` / IOKit.
    - Monitors battery percentage and Low Power Mode.
    - Exposes an `AsyncStream<PowerEvent>` with events like:
        - `.powerSourceChanged(ac: Bool)`
        - `.batteryLevelChanged(percentage: Int)`
        - `.lowPowerModeChanged(enabled: Bool)`
- Integration in `WallpaperManager`:
    - Subscribe to power events and adjust behavior:
        - On battery: option to pause wallpapers or reduce frame rate.
        - Below threshold (e.g., 20%): auto‑pause wallpapers and show non‑intrusive UI notice.
    - Respect user preferences (configurable thresholds and policies).

**Implementation Steps (7A):**

1. **Define Power Events (Days 1–2)**
    - Create `PowerEvent` enum and `PowerPolicyManager.swift`.
    - Implement platform‑specific observers for power source, battery level, and Low Power Mode.
2. **Wire Power Events into WallpaperManager (Days 3–6)**
    - Add `powerPolicyManager` reference to `WallpaperManager` init.
    - Start an async task in `WallpaperManager` similar to your screen/space AsyncSequence observers.[^1]
    - Define internal methods like `handlePowerEvent(_:)` to translate events into actions (pause/resume, throttling).
3. **Settings and UI (Days 7–10)**
    - Extend `SettingsStore` with:
        - `pauseOnBattery: Bool`
        - `pauseOnLowBattery: Bool`
        - `lowBatteryThreshold: Int` (e.g., default 20).
    - Add a \"Battery \& Power\" section in the UI:
        - Toggles for \"Pause wallpapers when on battery\" and \"Pause when battery is below X%\".
    - Optionally surface status text like \"Wallpapers paused to save battery\" in the preview/status card.
4. **Testing \& Validation (Days 11–20)**
    - Manual matrix: AC vs battery, Low Power Mode on/off, battery above/below threshold.
    - Ensure transitions are glitch‑free (no flicker, no half‑paused state).
    - Confirm behavior on desktops (no battery) is neutral.

**Success Criteria (7A):**

- Wallpapers automatically pause/resume based on user power policies without regressions to Phase 4–6 behavior.[^1]
- Settings persist across relaunch and are honored immediately on change.
- No crashes or hangs when power source changes repeatedly (e.g., plugging/unplugging rapidly).

**7A playback UX (complete 2026-05-22):** Frozen-frame desktop pause (no black screen), launch auto-play when policy allows, hero preview follows global pause, intent logging. Regression: [`docs/PHASE_7A_POWER_REGRESSION.md`](docs/PHASE_7A_POWER_REGRESSION.md).

**7B prerequisite:** Documentation gate complete (KB + repo docs synced); baseline in [`docs/PERFORMANCE_TUNING.md`](docs/PERFORMANCE_TUNING.md).

***

### Phase 7B — Engine Efficiency + Performance Profiles

**Status:** **Complete** (2026-05-23). Phase 7C (diagnostics UI) is next.

**Scope:** (1) **Reduce real resource usage** in the playback and preview stack; (2) expose **PerformanceProfile** presets (Max Quality / Balanced / Battery Saver). Compare all changes to the baseline in `docs/V1_SIGNOFF.md`.[^3][^5][^2]

**Delivered in 7B:**

- **Pause when not visible:** `DesktopVisibilityTracker` + per-display pause (P3/P4-A); shared session pauses when all attached displays occluded.
- **Multi-display:** `SharedVideoPlaybackSession` — one AVPlayer, N layers when same file (P2-fix); launch-restore coalesce (7B closeout).
- **UI/preview cost:** Live hero + `AppPreviewVisibilityMonitor` (P1b); async carousel thumbnails (P4-B).
- **WebRenderer:** Visibility pause + Battery Saver `stopLoading` (P4-C).
- **Profiles:** Max Quality / Balanced / Battery Saver in Settings; visibility pause differs by profile.
- **Document:** `docs/PERFORMANCE_TUNING.md` + KB `ADR-005-Performance-Engine-Strategy`.

**Deferred (not 7B):**

| Item | Status | Phase |
|------|--------|-------|
| Seek-timer FPS caps | Rejected permanently | — |
| Static hero | Rejected permanently | — |
| Unified hero + desktop single decode | **Complete (7D)** | — |
| 1080p cap on Balanced/Battery | **Complete (7E)** | — |
| Balanced unfocus freeze-frame polish | Deferred | Post–V2 / Phase 10+ |
| Manual frame stepping / new FPS mechanism | Deferred | 9+ / research |
| CPU history graphs | Deferred | 10 |

**Success Criteria (7B) — met:**

- Steady-state CPU measurably below V1 baseline on Balanced (2.5% vs 5.9% same-file 2 disp).
- Profiles produce visible CPU differences (Max Quality +0.5–1.3% vs Balanced in P6).
- No regressions in collections, setups, or multi-display apply.

***

### Phase 7C — Auto‑Tuning and Performance Diagnostics

**Status:** **Complete** (2026-05-23). Extensions **7D–7G complete** (2026-06-01). Phase 8 (local library) is next.

**Scope:** Auto‑tuning heuristics and a lightweight diagnostics panel to help users understand and control performance — **not** further decode optimization.

**Key Design Points:**

- Auto‑tuning:
    - Sample wallpaper process CPU usage at intervals.
    - If sustained usage exceeds a threshold (e.g., >8–10% for N seconds), suggest switching to a lower profile or temporarily pausing.
- Diagnostics panel:
    - Show approximate CPU usage, active displays, active profile, and quick actions like \"Restart Engine\".

**Implementation Steps (7C):**

1. **Metrics Sampling (Days 1–7)**
    - Introduce a `PerformanceMonitor` helper that periodically samples CPU for the process.
    - Integrate with `WallpaperManager` to track average CPU over a window.
2. **Auto‑Tuning Logic (Days 8–12)**
    - Define heuristics (thresholds, durations) per profile.
    - For now: only suggest profile changes via non‑modal banner/toast; do not auto‑switch silently.
3. **Diagnostics UI (Days 13–20)**
    - Add a \"Diagnostics\" section or modal:
        - Current profile, CPU estimate, GPU notes (if available), active displays and sources.
        - Buttons: \"Restart Wallpaper Engine\" (reinit `WallpaperManager` and `DisplayController`s) and \"Reset to Safe Default\" (e.g., static image or paused state).
4. **Stability \& Regression Testing (Days 21–25)**
    - Ensure restarting the engine does not break collections, setups, or power policies.[^1]
    - Ensure metrics sampling overhead is negligible.

**Success Criteria (7C):**

- Diagnostics panel provides clear, accurate enough information to explain performance behavior.
- Auto‑tuning suggestions trigger only when truly needed; no spammy prompts.

***

## Phase 8 Roadmap — Local Library and Thumbnail‑Based Browsing

**Goal:** Move beyond a plain file picker to a \"mini library\" experience while staying local‑only (no network), capturing some of the curated feel that Wallspace offers.[^2][^3][^6]

**Status:** **Complete** (8A–8C, 2026-06-01). Phase 9 (quick modes) is next.

### Phase 8 Summary

| Phase | Scope | Duration | Depends On |
| :-- | :-- | :-- | :-- |
| 8A | LocalLibrary data model + indexing | 20 days | Phase 7 complete |
| 8B | Thumbnail generation \& metadata cache | 20 days | 8A complete |
| 8C | Library UI integration | 25 days | 8B complete |


***

### Phase 8A — LocalLibrary Data Model and Indexing

**Scope:** Introduce a `LocalLibrary` module that indexes user‑selected folders and keeps a persistent catalog of available wallpaper videos.

**Implementation Steps (8A):**

1. **Data Model (Days 1–4)**
    - New file `LocalLibraryModels.swift` with:
        - `LibraryItem` (id, URL/bookmark, display name, duration, resolution, codec, created/added date, favorite flag).
    - Codable for JSON persistence.
2. **Library Manager (Days 5–10)**
    - `LocalLibraryManager` (actor or class) that:
        - Manages a set of root folders (security‑scoped bookmarks).
        - Scans for supported video types (MP4/MOV) and builds `LibraryItem`s.
        - Handles removable volumes and stale entries gracefully.
3. **SettingsStore Extensions (Days 11–15)**
    - Persist:
        - List of library roots.
        - Serialized library catalog.
        - Favorites and last used items.
4. **Testing (Days 16–20)**
    - Indexing scenarios: single folder, nested folders, external drives.
    - Handling of missing/removed files without crashes.

**Success Criteria (8A):**

- Users can add one or more folders and see a library catalog built from them.
- Library survives relaunch and responds to file deletions/volume removal gracefully.

***

### Phase 8B — Thumbnail Generation and Metadata Cache

**Scope:** Generate thumbnails and surface key metadata so the library is visually informative and fast.

**Implementation Steps (8B):**

1. **Thumbnail Pipeline (Days 1–7)**
    - Use AVAsset to grab a representative frame for each `LibraryItem`.
    - Store thumbnails in an app cache directory (e.g., hashed by item id).
2. **Metadata Extraction (Days 8–12)**
    - Capture duration, resolution, and codec info on scan or lazy‑load.
    - Cache metadata in the library JSON so UI can read it without re‑parsing every time.
3. **Cache Management (Days 13–16)**
    - Implement size limits and cleanup policies (e.g., LRU if needed).
    - Handle cache invalidation when items are updated/removed.
4. **Testing (Days 17–20)**
    - Large libraries (hundreds of items).
    - Performance of loading the library UI and scrolling.

**Success Criteria (8B):**

- Each library entry has a thumbnail and basic metadata with tolerable scan times.
- Cache does not grow without bound and is resilient to corruption.

***

### Phase 8C — Library UI and Integration

**Scope:** Integrate the local library into the **four-tab shell** (`TabbedMainView` / Home + Collections) as a first‑class way of choosing wallpapers, complementing the file importer.

**Implementation Steps (8C):**

1. **Library UI Shell (Days 1–8)**
    - Add a Library section to `ModernHomeView` (primary browse) and library picker in `CollectionEditorView` / `CollectionsTabView` — not a fifth tab; see [`docs/UI_REFERENCE.md`](docs/UI_REFERENCE.md):
        - Grid layout of thumbnails with titles and badges (duration, resolution).
        - Filters for favorites and possibly simple tag search (e.g., by folder name).
2. **Selection and Apply Flows (Days 9–15)**
    - Single‑click or double‑click to select and preview.
    - \"Apply to All Displays\" and (later) \"Apply to X display\" actions integrated with existing per‑display source logic.[^1]
    - Integrate with collections and setups:
        - Allow picking library items when creating collections/setups.
3. **Library Management (Days 16–20)**
    - UI for adding/removing library roots.
    - Favorite toggles.
    - Empty state messaging.
4. **Regression Testing (Days 21–25)**
    - Ensure the old file importer still works and coexists cleanly.
    - Verify collections and setups behave correctly when items come from the library.

**Success Criteria (8C):**

- Typical flow becomes: open app → browse local library → preview → apply, with minimal friction.
- File importer remains available for edge cases.

***

## Phase 9 Roadmap — Quick Modes and UX Streamlining

**Goal:** Layer simple, high‑level presets on top of your powerful configuration so it feels as approachable as consumer apps like Wallspace, without sacrificing your engine’s flexibility.[^3][^2]

### Phase 9 Summary

| Phase | Scope | Duration | Depends On |
| :-- | :-- | :-- | :-- |
| 9A | Quick modes design + wiring | 20 days | Phase 8 complete |
| 9B | Menu bar integration + UX polish | 20 days | 9A complete |


***

### Phase 9A — Quick Modes

**Scope:** Introduce high‑level \"modes\" that map to your existing flags/collections/setups rather than adding new engine complexity.

**Example Modes:**

- `SingleAllDisplays` – one source mirrored everywhere.
- `PerDisplayCustom` – your current per‑display configuration.
- `CollectionRotation` – uses Wallpaper Collections to rotate over time (future enhancement).
- `SavedSetupX` – quick access to one or more favorite Desktop Setups.[^1]

**Implementation Steps (9A):**

1. **Mode Enum and Mapping (Days 1–5)**
    - Add `QuickMode` enum and a `quickMode` property in `SettingsStore`.
    - Define mapping functions in AppViewModel that:
        - For each mode, set appropriate flags (`usePerDisplay`, selected collection/setup, etc.).
2. **Main UI Integration (Days 6–12)**
    - Add a Quick Mode selector at the top of ContentView:
        - Buttons or segmented control with short descriptions.
    - When mode changes:
        - Drive existing AppViewModel APIs to reconfigure wallpaper sources.
3. **State Consistency (Days 13–20)**
    - Ensure that manual changes (per‑display tweaks, collections) either:
        - Update the mode (e.g., switching back to `PerDisplayCustom`), or
        - Show that you are in a \"Custom\" mode.

**Success Criteria (9A):**

- Fresh install → first wallpaper in very few clicks via a mode and a library selection.
- Existing advanced workflows remain possible; quick modes are a convenience layer, not a restriction.

***

### Phase 9B — Menu Bar Quick Controls and UX Polish

**Scope:** Extend quick modes and library integration into the menu bar and refine small UX edges now that the engine is feature‑complete.

**Implementation Steps (9B):**

1. **Menu Bar Quick Modes (Days 1–7)**
    - Add a submenu under your existing menu‑bar item to switch quick modes directly.
    - Add \"Pause Until Plugged In\" and \"Switch to Battery Saver\" actions leveraging Phase 7 policies.
2. **Flow Polish (Days 8–15)**
    - Audit flows for:
        - First‑time user.
        - Laptop user frequently switching AC/battery.
        - Multi‑display user with collections/setups.
    - Reduce unnecessary prompts or extra clicks.
    - Improve empty states, error banners, and status indicators.
3. **Usability Testing Pass (Days 16–20)**
    - Run through your Production Testing Checklist but framed as end‑user scenarios, not just technical cases.[^1]
    - Identify and fix any remaining friction around collections/setups + quick modes.

**Success Criteria (9B):**

- Menu bar provides 80% of day‑to‑day control needs (pause, mode switch, basic apply).
- The app feels coherent despite the deep feature set.

***

## Phase 10 Roadmap — Lock‑Screen and Screensaver Strategy (Planned Future)

**Goal:** Lay out a clear path to lock‑screen and/or screensaver integration inspired by Wallspace’s lock‑screen live wallpapers, while explicitly treating this as a research/planning phase that may depend on future macOS APIs and entitlements.[^5][^7][^3]

> This phase is intentionally last and can be postponed or skipped if you decide to keep the project purely personal/local.

### Phase 10 Summary

| Phase | Scope | Duration | Depends On |
| :-- | :-- | :-- | :-- |
| 10A | API/entitlement research + feasibility | 15 days | Phase 9 complete |
| 10B | Screensaver fallback design | 20 days | 10A complete |
| 10C | Lock‑screen integration plan | 20 days | 10A complete |


***

### Phase 10A — Research and Feasibility

**Scope:** Investigate which APIs and entitlements are needed to provide video backgrounds on lock screen or via screensaver on current macOS versions.[^7][^3]

**Deliverable:** A short internal design doc, not necessarily shipping code.

***

### Phase 10B — Screensaver Fallback Design

**Scope:** Define how to reuse your engine components in a screensaver target (if lock‑screen APIs remain inaccessible or too constrained).

- Explore creating a separate screensaver bundle that uses a subset of WallpaperManager/Renderer logic.
- Define communication/persistence boundaries (e.g., sharing SettingsStore data via app group if needed).

***

### Phase 10C — Lock‑Screen Integration Plan

**Scope:** If macOS APIs permit, define a clean integration approach:

- New `LockScreenIntegration` abstraction behind feature flags.
- Clear version gating (e.g., macOS 26+ only).
- Strict separation so the desktop engine remains stable even if lock‑screen is not available.

***

## How to Attach This as “Part 2”

- Add a new top‑level section after your current \"Phase 6 Roadmap\" titled something like **\"Phase 7+ Roadmap — Power, Library, and UX\"**.[^1]
- Insert Phases 7–10 exactly in this order; each phase depends on stable completion of your current roadmap, and earlier phases (7 and 8) directly address the biggest product‑level gaps vs Wallspace (battery friendliness, library experience, quick flows).[^6][^2][^3]

If you’d like, next step can be to zoom into one of these phases (for example, Phase 7A or 8A) and turn it into the same ultra‑detailed “step‑by‑step implementation” style you used for earlier phases (with concrete filenames, properties, and method signatures).

<div align="center">⁂</div>

[^1]: developmental_roadmap.md

[^2]: https://wallspace.app/blog/why-wallspace-best-free-live-wallpaper-app-macos/

[^3]: https://wallspace.app

[^4]: https://www.reddit.com/r/macgaming/comments/1sevj98/built_a_free_live_wallpaper_app_for_mac_gaming/

[^5]: https://cindori.com/how-to/best-wallpaper-engine-mac-backdrop

[^6]: https://alternativeto.net/software/wallspace/about/

[^7]: https://wallspace.app/blog

