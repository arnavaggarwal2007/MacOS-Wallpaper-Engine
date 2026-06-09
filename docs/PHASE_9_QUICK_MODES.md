# Phase 9 — Quick Modes and Menu Bar (9A–9B)

**Status:** Complete (2026-06-09)

## Delivered

### 9A — Quick Modes

- `QuickMode` enum: `singleAllDisplays`, `perDisplayCustom`, `pinnedSetup`, `custom`
- `SettingsStore`: `quickMode`, `lastNonCustomQuickMode`, `pinnedSetupName`, `recentLibraryItemIDs`
- `QuickModeSelector` on Home toolbar
- `AppViewModel.applyQuickMode` maps to existing apply/restore APIs
- Drift detection → `.custom` when manual per-display or collection changes diverge

### 9B — Menu Bar

- Display-aware thumbnail header (248×160 frame-based layout; bottom-anchored caption/status)
- Submenus: Quick Mode, Apply Saved (Collections + Setups), Library Recents
- Power shortcuts: Pause Until Plugged In, Battery Saver profile
- Diagnostics line (CPU + memory), Clear Thumbnail Cache, Launch at Login
- `bringAppToFront(selecting:)` for synchronous window activation

## Bug fixes (2026-06-09)

| Issue | Fix |
|-------|-----|
| Hero black after mode switch | Batch `notifyDisplaySourcesChanged` in `selectVideoForDisplays`; `refreshHeroPreviewAfterQuickMode`; policy-pause holds desktop frame while snapshot loads |
| Pinned Setup submenu vanishes | Flattened setup list in `QuickModeSelector` (no nested SwiftUI Menu) |
| Menu preview missing | Explicit frame on `MenuBarPreviewHeaderView` (NSMenuItem views collapse Auto Layout to 0×0) |
| Show Main Window / Preferences | `bringAppToFront` called synchronously from menu handlers |

### Follow-up fixes (2026-06-09)

| Issue | Fix |
|-------|-----|
| Hero black (residual, especially when scrolled) | Full hero recovery in `refreshHeroPreviewAfterQuickMode`; policy-pause attach-failure fallback; hold-frame retry; deferred Quick Mode apply after menu dismiss |
| Menu status line clipped | Header height 160; bottom-anchored text layout |

### Third-pass fixes (2026-06-09)

| Issue | Fix |
|-------|-----|
| Hero black (Single All / Per Display) | `heroPreviewAttachToken` remount instead of external detach; coordinator `isHeroPreviewAttached` guard; mode-specific apply (skip reapply when already unified / per-display mode-only); `isQuickModeTransitionActive` scroll-pause exemption |
| No pin/unpin in Setups | `pinSetup` / `unpinSetup` API + card controls; Quick Mode shows one pinned item |
| Sidebar resets on tab switch | `homeSidebarVisible` in SettingsStore (default closed); lifted to AppViewModel |
| Settings video picker broken | Removed; wallpaper assignment on Home only |

## Pinned setup workflow

1. Save a setup on **Setups** tab.
2. Tap **Pin for Quick Access** on the setup card (optional).
3. From Home toolbar or menu bar Quick Mode → **Pinned: {name}** to restore.
4. If no setup is pinned, Quick Mode shows **Pin a setup in Setups…** (navigates to Setups tab).

Pinning does not apply the setup or change quick mode until user explicitly chooses the pinned item.

KB: `Wallpaper Engine KB/40 Bugs/Bug-Phase9-Quick-Mode-Hero-And-Menu-Bar.md`

## Deferred

- `CollectionRotation` quick mode (requires `RotationScheduler`, V2.1)

## Key files

- `QuickMode.swift`
- `UI/QuickModeSelector.swift`
- `MenuBarController.swift`
- `AppViewModel.swift` (Quick Mode section)

## Regression

- Switch Quick Modes on Home — hero stays visible
- Menu bar thumbnail visible on open
- Show Main Window / Preferences bring app forward when another app is active
- Menu bar: apply collection, setup, recent, quick mode still work

Full matrix: [`docs/PHASE_9_REGRESSION.md`](docs/PHASE_9_REGRESSION.md)
