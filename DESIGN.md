# Personal Wallpaper Engine — Design Specification

**Document version:** 1.1  
**Status:** Derived from repository source (June 2026)  
**Platform:** macOS 15.0+ deployment target (`README.md`); launch-on-login requires macOS 13.2+ at runtime (`LoginItemManager.swift`, Settings copy)  
**Implementation map:** [`docs/UI_REFERENCE.md`](docs/UI_REFERENCE.md)  
**Engine / CPU:** [`docs/PERFORMANCE_TUNING.md`](docs/PERFORMANCE_TUNING.md)

---

## Source of truth

| Priority | Location |
|----------|----------|
| 1 | Swift UI strings, enums, and `AppViewModel` messages in `Personal Wallpaper Engine/` |
| 2 | [`README.md`](README.md) for product name, overview, and feature list |
| 3 | [`docs/UI_REFERENCE.md`](docs/UI_REFERENCE.md) for shell wiring |

This document does not invent labels, placeholder copy, or color hex values. If a string is not in the repo, it is not specified here. Visual values come from `DesignTokens.swift`, `GlassChrome.swift`, and component files.

---

## Table of contents

1. [Product identity](#1-product-identity)  
2. [Core product shape](#2-core-product-shape)  
3. [Feature priority (README order)](#3-feature-priority-readme-order)  
4. [Terminology and enumerated values](#4-terminology-and-enumerated-values)  
5. [Visual design system](#5-visual-design-system)  
6. [Application shell](#6-application-shell)  
7. [User-visible copy catalog](#7-user-visible-copy-catalog)  
8. [Home](#8-home)  
9. [Collections](#9-collections)  
10. [Setups](#10-setups)  
11. [Settings](#11-settings)  
12. [Menu bar](#12-menu-bar)  
13. [Errors and validation](#13-errors-and-validation)  
14. [Accessibility and motion](#14-accessibility-and-motion)  
15. [Performance-aware UI](#15-performance-aware-ui)  
16. [Persistence vs UI state](#16-persistence-vs-ui-state)  
17. [Implementation index](#17-implementation-index)  
18. [Document history](#18-document-history)

---

## 1. Product identity

### Naming rule — Deskloop vs Personal Wallpaper Engine

The app ships to users as **Deskloop**. `Personal Wallpaper Engine` is the internal name only.

| Use | Name | Where it comes from |
|-----|------|---------------------|
| Anything a user reads — UI copy, App Store listing, marketing, support pages, privacy policy | **Deskloop** | `INFOPLIST_KEY_CFBundleDisplayName`; read in code via `AppInfo.displayName` — never hardcode the literal |
| Repo, Xcode project, target, scheme, bundle ID, file paths, developer docs, KB | `Personal Wallpaper Engine` | Unchanged; renaming would churn the project for no user benefit |

New user-facing strings must interpolate `AppInfo.displayName` rather than either literal, so a future
rename is a single Info.plist change. Historical docs keep the old name; do not retro-edit them.

**Name:** Deskloop (user-facing) / Personal Wallpaper Engine (internal)

**Description:**

> A macOS desktop wallpaper engine built in Swift that renders local video and web wallpapers across one or more displays with a VSCode-first development workflow. The project focuses on production-minded architecture, clean state management, and a premium preview-first UI inspired by Wallspace and Wallux.

**Overview:**

> Personal Wallpaper Engine plays local video files (and optional web sources) as animated macOS wallpapers.

**UI shell (README Features):**

> Modern UI shell: four tabs with shared live wallpaper background (`AppWallpaperBackground`), glass chrome, and hero-first Home with scroll-reveal display carousel.

**Design intent** ([`docs/UI_REFERENCE.md`](docs/UI_REFERENCE.md)):

- Edge-to-edge **live wallpaper** as the app background  
- Minimal chrome; translucent glass overlays  
- **Local-first** — no community/discovery carousel on Home  

---

## 2. Core product shape

The README leads with **local video wallpaper** and **multi-display rendering**. The UI and engine are organized around that pipeline—not a generic settings app.

```text
┌─────────────────────────────────────────────────────────────────┐
│  Media source (file path / file URL / HTTP(S) URL)               │
│       MP4, MOV (README); WKWebView for web (README Features)     │
└────────────────────────────┬────────────────────────────────────┘
                             │ security-scoped bookmarks (README)
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  Per-display assignment (SettingsStore.perDisplaySources)          │
│       CGDirectDisplayID → source string                          │
│       optional per-display scaling (perDisplayScalingModes)      │
└────────────────────────────┬────────────────────────────────────┘
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  WallpaperManager (actor) → DisplayController × N → Renderer     │
│       VideoRenderer (AVPlayer) | WebRenderer (WKWebView)         │
└────────────────────────────┬────────────────────────────────────┘
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  macOS desktop wallpaper windows (one per display)               │
└─────────────────────────────────────────────────────────────────┘

        Grouping layers (Phase 6, README):
        WallpaperCollection  →  named sets of sources
        SavedSetup           →  full state snapshot (restore)
```

**UI mirrors the pipeline on Home:**

1. **Hero** — preview of the focused display’s resolved source (`AppWallpaperBackground` + `AppViewModel.heroPreviewURL`).  
2. **Assign** — `Choose Wallpaper` → `DisplaySelectionModal` → per-display keys in `SettingsStore`.  
3. **Apply** — `Apply Now` / engine apply paths push sources to `WallpaperManager`.  
4. **Organize** — Collections and Setups tabs sit above the pipeline; Settings holds defaults and engine policy.

Internal persistence always uses per-display sources (`AppViewModel.ensurePerDisplayMode()`, `SavedSetup.usePerDisplay`); the UI exposes “apply to all” as a shortcut, not a separate mode ([`docs/UI_REFERENCE.md`](docs/UI_REFERENCE.md)).

---

## 3. Feature priority (README order)

The configuration window weights UI and documentation in the same order as [`README.md`](README.md) **Features**:

| Priority | README feature | Primary UI surface |
|----------|----------------|-------------------|
| 1 | Local video wallpaper playback (MP4, MOV) | **Home** hero + `Choose Wallpaper` / `Apply Now` |
| 2 | Multi-display rendering and per-display assignment | **Home** scroll-reveal `DisplaySwitcherView` |
| 3 | Virtual desktop and display-change awareness | Engine (no dedicated tab); hotplug via `DisplayConfigurationMigrator` |
| 4 | Scaling modes + per-display scaling | Home utility **Scaling** menu; per-display scaling on display cards; Settings default |
| 5 | Web wallpaper (WKWebView) | Settings **Renderer Mode** → Web; web URL field |
| 6 | Wallpaper collections | **Collections** tab; Home sidebar **Collection** |
| 7 | Desktop setups | **Setups** tab; Home sidebar **Setup** |
| 8 | Menu bar controls | `MenuBarController` |
| 9 | UserDefaults persistence | Engine + `SettingsStore` (no UI) |
| 10 | Launch on login (13.2+) | Settings **System** |
| 11 | Four-tab shell + live background | `TabbedMainView` |

Phases 7A–7G (performance, power, diagnostics) extend **Settings**; see [`README.md`](README.md) Status and [`docs/PERFORMANCE_TUNING.md`](docs/PERFORMANCE_TUNING.md).

---

## 4. Terminology and enumerated values

### 4.1 Tabs (`TabbedMainView.MainTab`)

| Tab | Label | SF Symbol |
|-----|-------|-----------|
| Home | `Home` | `house.fill` |
| Collections | `Collections` | `square.stack.3d.up.fill` |
| Setups | `Setups` | `square.and.arrow.down.fill` |
| Settings | `Settings` | `gearshape.fill` |

### 4.2 Renderer mode (`WallpaperRendererMode`)

| Raw value | `displayName` |
|-----------|---------------|
| `video` | Video |
| `web` | Web |

### 4.3 Scaling mode (`VideoScalingMode`)

| Raw value | `displayName` | AVLayer gravity |
|-----------|---------------|-----------------|
| `resizeAspectFill` | Fill | `resizeAspectFill` |
| `resizeAspect` | Fit | `resizeAspect` |
| `resizeAspectHeight` | Stretch | `resize` |

### 4.4 Performance profile (`PerformanceProfile`)

| Case | `displayName` | `caption` (Settings picker helper) |
|------|---------------|----------------------------------|
| `maxQuality` | Max Quality | Full resolution, live hero on every tab (dimmed on Settings), desktop keeps playing when covered. |
| `balanced` | Balanced | Recommended — 1080p decode cap on 4K sources, static hero on Settings tabs, pauses when not visible. |
| `batterySaver` | Battery Saver | Lowest power — 1080p cap + lower bitrate, same pause rules as Balanced, Web idle when paused. |

Settings card also shows (static copy in `SettingsTabView.swift`):

> Balanced pauses decode when wallpaper windows aren't visible; Max Quality keeps live hero on every tab (dimmed on Settings).

### 4.5 Collection type (`WallpaperCollection.CollectionType`)

| Raw value | UI label (`CollectionSummaryCard`, editor) |
|-----------|---------------------------------------------|
| `simple` | Simple |
| `displayBound` | Display-Bound |

### 4.6 Collection source (`CollectionSource`)

Fields used in mapping UI: `url`, `displayLabel`, `displayIDFallback`, `scalingMode`, `order`.

### 4.7 Saved setup (`SavedSetup`)

Snapshot fields: `rendererMode`, `isMuted`, `scalingMode`, `usePerDisplay`, `unifiedSource`, `perDisplaySources`, `perDisplayScalingModes`, bookmark base64 fields, `createdAt`, `updatedAt`.

---

## 5. Visual design system

**Authority:** `Personal Wallpaper Engine/UI/DesignTokens.swift`, `GlassChrome.swift`, and component-local values where noted.

### 5.1 Colors (`DesignTokens.Colors`)

| Token | Definition |
|-------|------------|
| `background` | `Color(nsColor: .windowBackgroundColor)` |
| `cardBackground` | `Color(nsColor: .controlBackgroundColor)` |
| `cardSurface` | `Color(nsColor: .textBackgroundColor)` |
| `cardBorder` | `Color.primary.opacity(0.12)` |
| `cardHighlight` | `Color.white.opacity(0.06)` |
| `primary` | `Color.accentColor` |
| `textPrimary` | `Color.primary` |
| `textSecondary` | `Color.secondary` |

Asset catalog `AccentColor.colorset` is universal with no custom components — accent follows the system.

**Status banner tints** (`SettingsTabView`, `ModernHomeView`): `.blue` (applying), `.green` (success), `.red` (error), `.orange` (power policy).

**Performance suggestion banner** (`PerformanceSuggestionBanner.swift`): `.orange` icon; stroke `Color.orange.opacity(0.35)`.

**Pause overlay** (`AppWallpaperBackground.swift`): `Color.black.opacity(0.38)`; label `Color.white.opacity(0.92)`.

### 5.2 Surfaces (`DesignTokens.Surfaces`)

| Token | Value |
|-------|-------|
| `scrollBackdropOpacity` | 0.65 |
| `selectedTabFillOpacity` | 0.15 |
| `selectedTabStrokeOpacity` | 0.28 |
| `thumbnailShadowOpacity` | 0.18 |
| `glassStrokeOpacity` | 0.12 |
| `glassBorderWidth` | 1 pt |
| `glassShadowOpacity` | 0.06 |
| `tabBarGroupMaterialOpacity` | 0.88 |
| `unselectedTabFillOpacity` | 0.42 |
| `managementScrimOpacity` | 0.50 |
| `managementBlurOpacity` | 0.72 |
| `mainTabBarReservedHeight` | 52 pt |
| `homeUtilityBarReservedHeight` | 108 pt |
| `homeScrollPeekHeight` | 44 pt |
| `homeDisplaysPanelHeight` | 248 pt |
| `homeDisplaysRevealThreshold` | 48 pt scroll offset |
| `homeDisplaysHideThreshold` | 20 pt scroll offset |
| `thumbnailLandscapeAspectWidth` × `height` | 16 × 9 |
| `thumbnailLandscapeWidth` | 96 pt |
| `thumbnailLandscapeSummaryWidth` | 160 pt |

**Management tab background** (`AppWallpaperBackground`): HUD material at `managementBlurOpacity`; scrim `Color.black.opacity(managementScrimOpacity)`.

### 5.3 Spacing (`DesignTokens.Spacing`)

| Token | pt |
|-------|-----|
| `small` | 8 |
| `medium` | 16 |
| `large` | 24 |

### 5.4 Corner radius (`DesignTokens.Corner` / `Elevation`)

| Token | pt |
|-------|-----|
| `Corner.radius` / `Elevation.cardRadius` | 12 |
| `Corner.heroRadius` / `Elevation.cardHeroRadius` | 18 |
| `Corner.tab` | 8 |
| `Corner.thumbnail` | 10 |

**Glass chrome** (`GlassChromeStyle.cornerRadius`): bar and tabBarGroup → 12; panel → 18; pill → 8.

**Display cards** (`DisplaySwitcherView.swift`, not in tokens): outer radius 20 pt; preview clip 16 pt; card width 238 pt; preview height 104 pt; active stroke `primary.opacity(0.55)` width 2; inactive `cardBorder` width 1.

### 5.5 Typography (`DesignTokens.Typography`)

| Token | Font |
|-------|------|
| `heroTitle` | 24 pt semibold |
| `heroSubtitle` | 15 pt regular |
| `title` | 15 pt semibold |
| `subtitle` | 13 pt medium |
| `body` | 13 pt regular |

Captions use SwiftUI `.caption` / `.caption2` in views. Utility bar uses `.system(size: 13, weight: .semibold)` for **Choose Wallpaper**.

### 5.6 Elevation and shadow

| Token | Value |
|-------|-------|
| `cardShadowRadius` | 16 |
| `cardShadowYOffset` | 6 |
| `heroShadowRadius` | 22 |
| `heroShadowYOffset` | 10 |
| Glass chrome shadow | black @ `glassShadowOpacity`, radius 8, y 3 |

### 5.7 Motion (`DesignTokens.Motion`)

| Token | Value |
|-------|-------|
| `standardDuration` | 0.18 s |
| `gentleDuration` | 0.12 s |
| `hoverShadowOpacity` | 0.08 |
| `hoverScale` | 1.01 |

`selectionAnimation` / `hoverAnimation`: `.easeInOut` for `standardDuration`, or `.linear(duration: 0)` when `accessibilityReduceMotion` is true.

**TopUtilityBar** hover scale: 1.05 (not from tokens).

**Performance suggestion banner** transition: `.easeInOut(duration: 0.25)` in `TabbedMainView`.

### 5.8 Effects (`DesignTokens.Effects`)

| Token | Value |
|-------|-------|
| `heroBackdropOpacity` | 0.06 |
| `cardBackdropOpacity` | 0.04 |

### 5.9 Glass and materials

- `VisualEffectView`: `NSVisualEffectView.Material.hudWindow`, blending `.withinWindow`, state `.active`.  
- Selected tab pill: material + `Colors.primary.opacity(selectedTabFillOpacity)` + stroke.  
- Unselected pill: material + `Color.black.opacity(unselectedTabFillOpacity)`.  
- Tab bar group: material + `Color.black.opacity(tabBarGroupMaterialOpacity * 0.35)`.

Apply via `.glassChrome(_:)` (`GlassChrome.swift`). Management sections use `GlassCardView` → `.glassChrome(.panel)`.

### 5.10 Thumbnails

16:9 landscape; widths from `DesignTokens.Surfaces`. Generated via `WallpaperThumbnail` / `VideoWallpaperThumbnail` with bookmark-aware URL resolution on MainActor ([`docs/UI_REFERENCE.md`](docs/UI_REFERENCE.md)).

---

## 6. Application shell

**Entry:** `Personal_Wallpaper_EngineApp` → `TabbedMainView` + `MenuBarController` + `AppViewModel`.

```text
ZStack (TabbedMainView)
  0  AppWallpaperBackground(intensity: .hero | .management)
  1  ModernHomeView | CollectionsTabView | SetupsTabView | SettingsTabView
  2  MainTabBar (top, horizontal padding DesignTokens.Spacing.medium)
  3  PerformanceSuggestionBanner (optional, bottom padding ~56)
```

| `AppWallpaperBackground.Intensity` | Tab | Behavior |
|------------------------------------|-----|----------|
| `.hero` | Home | Live hero video when profile allows |
| `.management` | Collections, Setups, Settings | Blur + scrim over preview |

**Minimum frame:** `minWidth: 800`, `minHeight: 600` (`TabbedMainView`, tab roots).

**Save setup sheet:** `minWidth: 400`, `minHeight: 520` (`SetupsTabView`).

Decorative background: `allowsHitTesting(false)`, `accessibilityHidden(true)`.

---

## 7. User-visible copy catalog

Strings below are copied from Swift sources. Dynamic segments shown as `{placeholder}`.

### 7.1 Home — `TopUtilityBar`, `DisplaySwitcherView`, `ModernHomeView`

| Control / region | String |
|------------------|--------|
| Choose Wallpaper | `Choose Wallpaper` |
| Play (accessibility) | `Play wallpapers on all displays` |
| Pause (accessibility) | `Pause wallpapers on all displays` |
| Mute / Unmute (accessibility) | `Mute audio` / `Unmute audio` |
| Scaling menu label | `Scaling` |
| Apply | `Apply Now` |
| Sidebar | `Hide sidebar` / `Show sidebar` |
| Pause banner (default) | `Wallpapers paused on all displays — in-app preview may still animate.` |
| Pause banner (power) | Uses `appModel.powerPolicyStatusMessage` when set |
| Scroll hint | `Scroll for Displays` |
| Scroll hint (accessibility) | `Show display picker` |
| Displays title | `Displays` |
| Displays caption | `Play and pause affect wallpapers on every display. Cards switch the hero preview only.` |
| Display card title | `Display {n}` (1-based index) |
| Display card empty subtitle | `No source selected yet.` |
| Display card paused overlay | `Paused` |
| Display card hint | `Switch hero preview to {badge}. Play and pause affect all displays.` |
| No displays | `No displays detected. Connect a display to assign wallpapers.` |
| Sidebar header | `Status` |
| Sidebar sections | `Display`, `Wallpaper`, `Collection`, `Setup` |
| Collection helper | `Manage collections in the Collections tab.` |
| Setup helper | `Restore and delete setups in the Setups tab.` |
| Applying banner | `Applying wallpaper...` |

### 7.1a First-run welcome card — `ModernHomeView.welcomeCard`

Shown centered over the hero while no display has a wallpaper assigned, and not yet dismissed this
session. There is no persisted "seen" flag: assigning a wallpaper hides it, and clearing every
wallpaper brings it back.

| Control / region | String |
|------------------|--------|
| Title | `Welcome to {AppInfo.displayName}` |
| Body | `Pick an MP4 or MOV from your Mac and it plays as your desktop wallpaper, behind your icons. Nothing is uploaded.` |
| Primary action | `Choose Wallpaper` |
| Secondary action | `Browse Library` |
| Tertiary action | `Dismiss` |
| Accessibility label | `Welcome to {AppInfo.displayName}` |

### 7.2 Display selection modal

| String |
|--------|
| `Select Displays` |
| `Choose which displays this wallpaper should be applied to` |
| `Apply to All Displays` |
| `Set the same wallpaper on every connected display` |
| `Select Specific Displays` |
| `Resolution: {width}×{height}` |
| `Cancel` |
| `Apply` |

### 7.3 Collections tab

| String |
|--------|
| `Collections` |
| `Create, preview, and apply wallpaper sets for your displays.` |
| `Library` |
| `{n} collection` / `{n} collections` |
| `Select a collection to preview, apply, or manage.` |
| `Create a collection to save a wallpaper set.` |
| `Last Used` |
| `No Collections Yet` |
| `Create your first collection to get started.` |
| `Create First Collection` |
| `Select Collection` (picker placeholder tag) |
| `New`, `Apply`, `Edit`, `Delete` |
| `{n} saved` |
| Delete alert: `Are you sure you want to delete the selected collection? This cannot be undone.` |
| Editor sheet title | `Create Collection` / `Edit Collection` |

### 7.4 Collection editor

| String |
|--------|
| `Group wallpaper sources into a reusable collection. Collection behavior is unchanged; this view only improves how the inputs are presented and validated.` |
| `Simple`, `Display-Bound` |
| `Add a source to get started.` |
| `Add Source` |
| `{n} active source(s)` |
| `Sources: {n}` |
| `The preview reflects the collection metadata and source count only.` |

### 7.5 Collection summary card

| String |
|--------|
| Pills: `Simple`, `Display-Bound`, `Selected`, `Last used` |
| `Sources`, `Updated` |
| `Mapping` |
| `No source mappings available.` |
| `And {n} more source(s)` |

### 7.6 Setups tab

| String |
|--------|
| `Setups` |
| `Save and restore full desktop wallpaper configurations.` |
| `Save Current Setup` |
| `Active: {name}` |
| `Saved Setups` |
| `{n} saved setup(s)` |
| `Save the current wallpaper configuration to restore it later.` |
| `Select a setup to preview, restore, or delete.` |
| `Active` |
| `No Setups Yet` |
| `Capture your current display configuration from the Home tab or here.` |
| `Select Setup` |
| `Restore & Apply` |
| `Delete` |

### 7.7 Save setup modal

| String |
|--------|
| `Save Current Setup` |
| `Capture the current wallpaper engine configuration` |
| `Setup Name` |
| `Description (optional)` |
| `Current Configuration` |
| `Renderer`, `Scaling`, `Displays` |
| `{n} connected` |
| `Cancel`, `Save Setup` |

### 7.8 Setup preview card badges

Uses emoji prefixes in `SetupPreviewCard.swift`: `🌐 Web` / `🎬 Video`, `🖥 Displays`, `🔇 Muted` / `🔊 Sound`; values `Web`, `Video`, `{n} assigned`, `Muted`, `Sound On`. Metadata labels: `Created`, `Updated`.

### 7.9 Settings tab

| Section / control | String |
|-------------------|--------|
| Header | `Settings` |
| Subtitle | `Renderer, scaling, audio, and startup preferences.` |
| Workspace | `Renderer Mode`, `Scaling Mode`, `Mute Audio` |
| Renderer caption | `Video uses local files; Web loads a URL in the desktop layer.` |
| Scaling caption | `Default scaling for new assignments; per-display overrides apply on Home.` |
| Mute caption | `Silences wallpaper playback in the app preview and engine.` |
| Wallpaper Source | `No video selected` (when empty) |
| Web | `Web Source URL`, placeholder `https://example.com/wallpaper.html`, `Choose File`, `Apply` |
| Video | `Choose Video`, `Apply to All Displays` |
| Video caption | `Assign per display on the Home tab, or apply this source to every connected display here.` |
| Performance | `Performance Profile` + profile `caption` values (§4.4) + static Balanced/Max Quality sentence (§4.4) |
| Diagnostics | `Diagnostics`, `Live engine status and recovery actions.` |
| Diagnostics toggle | `Use test suggestion thresholds` / `Lower Max→Balanced gate (4%) for verifying the suggestion banner.` |
| Diagnostics actions | `Restart Engine`, `Reset to Safe Default` |
| CPU footnote | `Process CPU — 100% = one logical core. Smoothed aligns with \`ps\`; Activity Monitor often reads 2–5pp lower due to heavier smoothing. Instant is the last 1s window. Suggestions use smoothed CPU.` |
| CPU measuring | `Measuring…` |
| Per display heading | `Per display` |
| Row format | `{sourceName} · shared|standalone · rate {rate}` + optional ` · visibility paused` |
| Heavy CPU callout | `Elevated CPU is expected with {reasons}. Canonical baseline: same 1080p on all displays, unfocused (~2.5–3% Debug).` — note the quoted baseline is a **Debug** figure; Release runs ~13.8% per-core (~1.15% of system on 12 cores) |
| Battery | `Pause on Battery` / `Stops wallpaper playback while unplugged (MacBook).` |
| | `Pause on Low Battery` / `Pauses when charge falls below the threshold.` |
| | `Low battery threshold` |
| System | `Launch on Login` / `Automatically start when you log in (macOS 13.2+).` |

**Diagnostics row labels:** `CPU (instant)`, `CPU (smoothed)`, `CPU (60s avg)`, `Logical CPUs`, `Profile`, `Lifecycle`, `Playback active`, `Displays`, `Decode paths`, `Hero shares desktop decode`, `Shared decode`, `Desktop visible`. Values: `Yes` / `No`, or `Yes ({n} layers)` / `1 layer` for shared decode.

### 7.10 Performance suggestion banner

| String |
|--------|
| `High CPU usage` |
| `Switch to {PerformanceProfile.displayName}` |
| `Don't show again` |
| Help: `Remind me later`, `Never show performance suggestions` |

Dynamic message from `AppViewModel`: `Wallpaper playback has averaged {percent}% of your Mac's CPU recently. Switch to {profile.displayName} to reduce usage.`

`{percent}` is **system-wide** share (one decimal), matching the `System CPU share` diagnostics row.
It is not the per-core figure the other CPU rows show — see repo `docs/PERFORMANCE_TUNING.md` §ADR-009.

### 7.11 Global pause overlay

| String |
|--------|
| `Wallpapers paused on all displays` |

### 7.12 Power policy (`WallpaperManager`)

| Condition | Message |
|-----------|---------|
| Low battery | `Wallpapers paused — battery below {threshold}%.` |
| On battery | `Wallpapers paused to save battery.` |
| Default | `Wallpapers paused for power policy.` |

### 7.13 `AppViewModel` status and error messages

**Status (success / info):**

- `Selected for {display}: {filename}`  
- `Applied to {display}: {filename}`  
- `Applied to {n} display(s)`  
- `Wallpaper applied to {n} display(s).`  
- `Could not apply to: {list}` (partial)  
- `Wallpaper applied: {filename}`  
- `Selected: {filename}`  
- `Web wallpaper mode is ready`  
- `Web mode enabled. Enter a URL and tap Apply.` / `Web mode enabled.`  
- `Applied web wallpaper to {n} display(s)`  
- `Wallpaper engine restarted.`  
- `Reset to safe default — Balanced profile, playback paused.`  
- `Collection '{name}' saved.` / `updated.` / `deleted.`  
- `Collection '{name}' has no sources to apply.`  
- `Collection '{name}' applied to all displays.`  
- `Collection '{name}' applied to {n} display(s).`  
- `Applied {n} source(s). {m} extra source(s) were skipped because fewer displays are available.`  
- `Collection '{name}' applied to matched displays.`  
- `Setup '{name}' saved successfully.`  
- `Setup '{name}' restored to {n} display(s).`  
- `Setup '{name}' settings restored. No wallpapers were configured for connected displays.`  
- `Setup '{name}' settings restored with warnings.`  
- `Setup '{name}' deleted.`  
- `Preferences window would open here (Phase 5F+)`  
- Login: `Launch-on-Login enabled` / `disabled` (`LoginItemManager`)

**Errors:**

- `No display available.`  
- `Choose a wallpaper for this display first.`  
- `Please choose a wallpaper source for display {id}.`  
- `Unable to apply wallpaper for display {id}.`  
- `No displays selected.`  
- `Could not apply wallpaper to connected displays.`  
- `Saved video access expired. Please reselect the video file.{details}`  
- `No displays connected.`  
- `Please select a video file first.`  
- `Please enter a valid web URL.`  
- `Unable to apply wallpaper.`  
- `File selection failed: {error}` (`SettingsTabView` / `ModernHomeView` importer)  
- `Applying wallpaper...` (in-progress banner)  
- Login: `Launch-on-Login requires macOS 13.2 or later`; `Failed to enable: {desc}` / `Failed to disable: {desc}`  

(Collection/setup/collection-name errors: see §13.)

---

## 8. Home

Dominant surface per README: video preview, file pick, multi-display assignment, apply.

### 8.1 Layout (z-order)

1. ScrollView — spacer (`scrollRevealSpacerHeight`) then optional `DisplaySwitcherView`.  
2. `TopUtilityBar` — fixed below tab bar (`mainTabBarReservedHeight + 8`).  
3. Scroll hint — bottom until panel revealed.  
4. Sidebar — trailing, width `clamp(33% window, 320…420)`.

Scroll thresholds: reveal ≥ `homeDisplaysRevealThreshold` (48 pt); hide ≤ `homeDisplaysHideThreshold` (20 pt). Panel id: `displaysPanelScrollID`.

### 8.2 Primary actions

| Action | Effect |
|--------|--------|
| Choose Wallpaper | `fileImporter` — `.movie`, `.mpeg4Movie`, `.quickTimeMovie` → `DisplaySelectionModal` |
| Play / Pause | `handlePlayPauseButtonPressed(source: .toolbar)` — all displays |
| Mute | `toggleMute()` |
| Scaling | Menu of `VideoScalingMode.displayName` values; updates global default |
| Apply Now | `applyWallpaperToFocusedDisplay()` |
| Sidebar toggle | `isSidebarVisible` |

### 8.3 Display carousel

Mounted only when `isDisplaysPanelVisible` to avoid off-screen decode ([`docs/UI_REFERENCE.md`](docs/UI_REFERENCE.md)). `isGloballyPaused` passed from `shouldShowPausedChrome`.

### 8.4 Sidebar

| Card | Actions |
|------|---------|
| Display | Focused display status |
| Wallpaper | Path + **Choose Wallpaper** |
| Collection | **Apply Collection** |
| Setup | **Save Current Setup** |

---

## 9. Collections

Second grouping layer: named `WallpaperCollection` with `simple` or `displayBound` sources.

### 9.1 Action bar

`New` (prominent), `Apply` (prominent), `Edit`, `Delete`, `{n} saved`.

### 9.2 Apply behavior (engine)

| Type | Behavior (`AppViewModel`) |
|------|---------------------------|
| `simple`, 1 source | Same source to all connected displays |
| `simple`, N sources | Map to displays in screen order; overflow message if more sources than displays |
| `displayBound` | Match `displayLabel` / `displayIDFallback` to connected screens |

---

## 10. Setups

Full snapshot: `SavedSetup` via `saveCurrentStateAsSetup` / `restoreSetup`.

| Control | Action |
|---------|--------|
| Save Current Setup | `SaveSetupModal` → validation (name ≤ 100 chars, unique, requires source) |
| Restore & Apply | `restoreSetup(name:)` |
| Delete | `deleteSetup(name:)` |

**Active label:** `Active: {selectedSetupName}` (glass card) and `Active` / name in Saved Setups header.

Launch restores per-display persistence, not automatic setup restore ([`docs/VERSION_1_REFERENCE.md`](docs/VERSION_1_REFERENCE.md)).

---

## 11. Settings

Defaults and engine policy—subordinate to Home pipeline.

| `GlassCardView` title | Contents |
|-----------------------|----------|
| Workspace | Renderer, Scaling, Mute |
| Wallpaper Source | Path / web URL / apply all |
| Performance | `PerformanceProfile` segmented control |
| Diagnostics | `EngineDiagnosticsSection` |
| Battery & Power | Pause on battery / low battery; threshold stepper 5…50 step 5 |
| System | Launch on Login |

`EngineDiagnosticsSection` sets `setDiagnosticsPanelVisible(true/false)` on appear/disappear.

---

## 12. Menu bar

`MenuBarController` items:

| Item | Title states | Shortcut |
|------|--------------|----------|
| Play/Pause | `Pause` / `Play` | — |
| Mute | `Mute` / `Unmute` | `m` |
| Preferences | `Preferences...` | `,` |
| Quit | `Quit` | `q` |

Status item button title: `🔇` if muted; else `▶` if playing, `⏸` if paused.

---

## 13. Errors and validation

### 13.1 `WallpaperError` (`Errors.swift`)

| Case | `errorDescription` pattern |
|------|----------------------------|
| `videoFileNotFound` | `Video file not found: {path}` |
| `videoFileNotReadable` | `Video file is not readable: {path}` |
| `videoDecodingFailed` | `Video decoding failed for {filename}: {reason}` |
| `windowCreationFailed` | `Window creation failed: {reason}` |
| `rendererInitializationFailed` | `Renderer initialization failed: {reason}` |
| `screenNotFound` | `Screen not found: {id}` |
| `internalError` | `Internal error: {description}` |

### 13.2 Collection extensions (`WallpaperCollection.swift`)

| Factory | Message pattern |
|---------|-----------------|
| `collectionNotFound` | `Collection '{name}' not found. It may have been deleted.` |
| `invalidCollectionName` | `Invalid collection name: {reason}` |
| `invalidCollectionSource` | `Invalid source URL '{url}': {reason}` |
| `displayMismatchWarning` | `Display mismatch: {message}` |

**Name validation reason:** `Name must be non-empty, max 255 characters, and contain no special characters (/, \, *).`

**Source URL validation reason:** `URL must be a valid file path (file:///) or HTTP(S) URL.`

**Editor:** `At least one source is required.`

### 13.3 Setup validation (`AppViewModel`)

- `Setup name cannot be empty.`  
- `Setup name must be less than 100 characters.`  
- `Setup '{name}' already exists.`  
- `No wallpaper source selected. Please set a wallpaper before saving.`  
- `Setup '{name}' not found.`  
- `Setup '{name}' has corrupted data. Please recreate it.`  

### 13.4 Collection operations

- `Collection '{name}' already exists.`  
- `No displays are currently available.`  
- `Invalid source URL.` (via `invalidCollectionSource`)

---

## 14. Accessibility and motion

From SwiftUI usage in shell components:

| Element | Behavior |
|---------|----------|
| Tab buttons | `accessibilityLabel(tab.label)`; `.isSelected` when active |
| Toolbar play/mute/sidebar | Explicit `accessibilityLabel` / `help` strings (§7.1) |
| Scroll hint | `accessibilityLabel("Show display picker")` |
| Display cards | `accessibilityLabel(display.title)`; hint §7.1 |
| Background / hero | `accessibilityHidden(true)` on decorative layer |
| Pause overlay | Combined element: `Wallpapers paused on all displays` |
| Paused utility banner | `Wallpapers paused. {pausedBannerText}` |
| Reduce Motion | `DesignTokens.Motion.selectionAnimation(reduceMotion:)`; utility hover scale disabled |

---

## 15. Performance-aware UI

| UI behavior | Source |
|-------------|--------|
| Scroll-reveal display panel | `ModernHomeView` thresholds §5.2 |
| Preview pause while scrolling | `wallpaperPreviewPause` / `onWallpaperPreviewPauseChange` |
| Hero live vs thumbnail | `AppWallpaperBackground` + `PerformanceProfile` ([`docs/PERFORMANCE_TUNING.md`](docs/PERFORMANCE_TUNING.md)) |
| Suggestion banner | `PerformanceSuggestionBanner` + `AppViewModel` CPU thresholds |
| Diagnostics sampling | `setDiagnosticsPanelVisible` while Settings diagnostics visible |
| Heavy scenario callout | `EngineDiagnosticsSection.heavyScenarioCallout` §7.9 |

---

## 16. Persistence vs UI state

From [`docs/VERSION_1_REFERENCE.md`](docs/VERSION_1_REFERENCE.md):

| Data | Restored on launch? |
|------|---------------------|
| `perDisplaySources` / `perDisplayBookmarks` | Yes |
| `lastUsedCollectionName` | Used when resolving collection source keys |
| `currentSetupName` | No full restore — UI selection only until user **Restore & Apply** |
| `videoFilePath` / `videoBookmarkData` | Fallback if no per-display entries |

---

## 17. Implementation index

| Concern | File |
|---------|------|
| Shell | `TabbedMainView.swift` |
| Home | `ModernHomeView.swift`, `UI/TopUtilityBar.swift`, `UI/DisplaySwitcherView.swift` |
| Collections | `CollectionsTabView.swift`, `UI/CollectionEditorView.swift`, `UI/CollectionSummaryCard.swift` |
| Setups | `SetupsTabView.swift`, `UI/SaveSetupModal.swift`, `UI/SetupPreviewCard.swift` |
| Settings | `SettingsTabView.swift`, `UI/EngineDiagnosticsSection.swift` |
| Tokens / glass | `UI/DesignTokens.swift`, `UI/GlassChrome.swift`, `UI/GlassCardView.swift` |
| Background | `UI/AppWallpaperBackground.swift` |
| State | `AppViewModel.swift`, `SettingsStore.swift` |
| Engine | `WallpaperManager.swift`, `DisplayController.swift` |
| Models | `WallpaperCollection.swift`, `SavedSetup.swift` |
| Menu bar | `MenuBarController.swift` |

**Removed legacy UI** (do not restore): `ContentView.swift`, `HomeTabView.swift`, `TransparentTabSwitcher.swift` ([`docs/UI_REFERENCE.md`](docs/UI_REFERENCE.md)).

---

## 18. Document history

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-06-01 | Initial spec from shipped UI |
| 1.1 | 2026-06-01 | Repo-sourced copy and tokens; README-led structure; copy catalog; removed invented values |

---

*Personal Wallpaper Engine — macOS desktop wallpaper engine (Swift).*
