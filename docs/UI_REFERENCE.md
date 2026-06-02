# UI Reference — Final Vision

**Status:** Complete (merged to `main`, May 2026)  
**KB:** `Wallpaper Engine KB/30 Features/Feature-UI-Final-Vision.md`  
**Validation:** User sign-off May 20, 2026; automated checks in [`V1_SIGNOFF.md`](V1_SIGNOFF.md)

---

## Design intent

Preview-first, native macOS configuration window comparable to [Wallspace](https://wallspace.app/) and [Wallux](https://wallux.app/):

- Edge-to-edge **live wallpaper** as the app background
- Minimal chrome; translucent glass overlays
- **Local-first** — no community/discovery carousel on Home

---

## Application shell

**Entry:** `Personal_Wallpaper_EngineApp` → `TabbedMainView`

| Layer | Component | Role |
|-------|-----------|------|
| 0 | `AppWallpaperBackground` | Live preview on all tabs; full fidelity on Home; blur + scrim on management tabs |
| 1 | Tab content | `ModernHomeView`, `CollectionsTabView`, `SetupsTabView`, `SettingsTabView` |
| 2 | `MainTabBar` | Floating pill tab bar (icon + label) |

### Tabs

| Tab | View | Responsibility |
|-----|------|----------------|
| Home | `ModernHomeView` | Apply wallpaper, per-display carousel, status sidebar |
| Collections | `CollectionsTabView` | Full collection CRUD, apply, editor |
| Setups | `SetupsTabView` | Save / restore / delete desktop setups |
| Settings | `SettingsTabView` | Renderer, scaling, mute, launch on login, web URL |

---

## Home tab layout

`ModernHomeView` uses two interactive layers (background owned by shell):

| Layer | Contents |
|-------|----------|
| Content | `TopUtilityBar` (Choose Wallpaper, Apply, sidebar toggle); scroll area with “Scroll for Displays” hint |
| Overlay | Toggleable right sidebar — display name, wallpaper, collection/setup status, save setup, banners |

**Scroll-reveal:** Display carousel (`DisplaySwitcherView`) mounts when user scrolls past threshold; **local library horizontal strip** sits below the carousel (not above). Full library browse opens via **Browse All…** or toolbar **Browse Library** sheet.

**Hit-testing:** Decorative layers must not block clicks; sidebar uses passthrough where configured.

---

## Visual system

| Element | Implementation |
|---------|----------------|
| Tokens | `UI/DesignTokens.swift` — spacing, typography, colors, surfaces |
| Glass | `UI/GlassChrome.swift`, `GlassCardView`, `.ultraThinMaterial` / HUD material |
| Cards | `CardView`, `CardSection`, collection/setup summary cards |
| Thumbnails | `WallpaperThumbnail.swift` — 16:9 landscape; bookmark-aware URL resolve on MainActor |
| Headers | `TabHeaderView` on management tabs |

**Rules:**

- Translucent overlays, not opaque full-window gradients
- Hero preview URL must match engine playback (`AppViewModel` resolved URLs / bookmarks)
- Text readable on bright wallpapers (management tab scrim)

---

## Key flows

### Apply wallpaper (per-display)

1. Home → scroll to displays or use sidebar context
2. Select target display in carousel
3. **Choose Wallpaper** → file / source
4. **Apply Now** (focused display) or per-display apply from modal

App always uses per-display sources internally (`usePerDisplay`).

### Collections

1. Collections tab → create / edit collection
2. Apply from tab or shortcut from Home sidebar
3. Simple vs display-bound types per `WallpaperCollection`

### Setups

1. Setups tab → **Save Current Setup**
2. Select setup → **Restore & Apply** or delete
3. **Restore & Apply** writes settings to `SettingsStore`, updates previews, and applies wallpapers to connected displays (bookmarks + collection keys supported)
4. Launch does **not** auto-run setup restore; last session is restored from per-display persistence

---

## Removed legacy UI

Do not reference or restore:

- `ContentView.swift`
- `HomeTabView.swift`
- `TransparentTabSwitcher.swift`
- `CollectionsSidebarView` (never existed; use `ModernHomeView` sidebar)

Removed in Phase 4d (May 2026).

---

## Validation history

| Phase | Focus | Doc (archived) |
|-------|-------|----------------|
| 1 | Prerequisite bug fixes | `docs/archive/PHASE_1_VERIFICATION.md` |
| 3 | Always per-display, Home browse | `docs/archive/PHASE_3_VALIDATION.md` |
| 4 | Shared background, glass, scroll perf | `docs/archive/PHASE_4_VALIDATION.md` |

Automated: `chunk7_smoke.sh`, `chunk7_regression.sh` — see [`V1_SIGNOFF.md`](V1_SIGNOFF.md).

---

## Version 2 UI (roadmap)

**Complete (Phase 7):**

- Performance profile selector — Settings tab
- Battery & power policies — Settings tab
- Diagnostics panel + suggestion banner — Settings + shell (Phase 7C)

**Complete (Phase 8):**

- Local library — Home: horizontal strip below display carousel; full browse via **Browse All…** sheet or toolbar **Browse Library**
- Collection editor library picker; Settings → Local Library for folder roots

**Planned:**

- Quick mode selector (Phase 9) — Home top bar + menu bar

Polish-only tweaks remain optional without roadmap phase.
