# UI Revamp Roadmap — Final Vision (Wallspace / Wallux Competitive)

**Status:** Complete — merged to `main` May 20, 2026  
**Canonical spec:** KB `Feature-UI-Final-Vision.md`  
**Execution order:** Phase 0 (docs) → Phase 1 (broken fixes only) → Phase 2 (this roadmap) → Phase 3 (validation)  
**Out of scope:** Community/online wallpaper carousel, Workshop, lock screen (future)

---

## Design references

- [Wallspace](https://wallspace.app/) — preview-first, native, minimal chrome, multi-display
- [Wallux](https://wallux.app/) — efficient engine, per-display, clean management UI

**Personal Wallpaper Engine difference:** Local files and user collections only—no discovery grid on Home.

---

## Target experience

### Home tab

1. **Hero (layer 0):** Edge-to-edge live preview = app background; shows resolved wallpaper for selected display.
2. **Content (layer 1):** Translucent `TopUtilityBar`; scroll **down** to reveal **display carousel** (select preview + edit target).
3. **Overlay (layer 2):** Toggleable **right sidebar** — status only (display, wallpaper name, collection/setup status, save setup, banners).

### Tabs (top of window)

| Tab | Responsibility |
|-----|----------------|
| **Home** | Preview, apply local wallpaper, per-display carousel |
| **Collections** | Full CRUD / apply (`CollectionsTabView`) |
| **Setups** | List, save, restore, delete (`SetupsTabView` — extract from sidebar) |
| **Settings** | Renderer, scaling, mute, per-display mode, launch on login, web URL |

### Visual rules

- Translucent, legible overlays (`.ultraThinMaterial`, light hero scrims)—not opaque full-window dark gradients.
- Three logical ZStack layers; no full-screen non-interactive layers stealing clicks.
- Hero preview URL must match engine playback (bookmarks / resolved URLs).

---

## Phase 1 — Verify existing behavior (prerequisite)

**Status:** Code fixes applied 2026-05-20 — **local build + manual matrix required** (`PHASE_1_VERIFICATION.md`).

**Goal:** Confirm what is broken before UI refactor. **No new features.**

| Check | Action if fail |
|-------|----------------|
| Display carousel selects display | Fix selection binding |
| Apply wallpaper (unified + per-display) | Fix `AppViewModel` / bookmarks |
| Collection apply from Collections tab | Regression only |
| Setup save/restore | Regression only |
| Hero preview vs desktop playback | ✅ `heroPreviewURL(forDisplayID:)` |
| Web mode status message | ✅ Updated `updateRendererMode` copy |
| `WebRenderer.scalingMode()` | ✅ `currentScalingMode` tracking |
| ZStack blocked clicks | ✅ Minimal hit-test fix on decorative layers |

**Exit:** Smoke + manual matrix pass; then Phase 2a.

---

## Phase 2a — Home shell (3–4 days)

**Status:** Implemented 2026-05-20

**Files:** `ModernHomeView.swift`, `HeroWallpaperView.swift`, `DisplaySwitcherView.swift`, `TopUtilityBar.swift`, `CollectionsTabView.swift`

**Tasks:**

1. ✅ Remove page-title ZStack overlays ("Wallpaper Configuration", "Wallpaper Collections").
2. ✅ Collapse to **3-layer** ZStack (hero → utility bar + scroll → sidebar).
3. ✅ Move display carousel **into ScrollView**; remove bottom overlay layer.
4. ✅ Replace opaque gradients with **`.ultraThinMaterial`** on Home and Collections.
5. Hero uses resolved preview URL from `AppViewModel` (Phase 1).

**Acceptance:**

- [x] No page-title overlays blocking utility bar or collection cards
- [x] `TopUtilityBar` unobstructed on Home
- [x] Collections tab content starts below tab bar without floating header
- [x] Carousel only in scroll region (not duplicate bottom overlay)
- [x] Scroll down to reveal display carousel (Phase 2d)
- [x] Translucent glass chrome on utility bar, tab pills, display panel (Phase 2d)
- [ ] 800×600 through fullscreen — no clip/block on hero (verify locally)
- [ ] Display switch and apply responsive (verify locally)

---

## Phase 2b — Four tabs + slim sidebar (1–2 days)

**Status:** Implemented 2026-05-20

**Files:** `TabbedMainView.swift`, `SetupsTabView.swift`, `SettingsTabView.swift`, `ModernHomeView.swift`

**Tasks:**

1. ✅ Add **Setups** and **Settings** tabs.
2. ✅ Migrate setup list/restore/delete to Setups tab; settings cards to Settings tab.
3. ✅ Slim Home sidebar: display, wallpaper, collection status (+ apply shortcut), setup status, save setup, status banners.
4. ✅ Remove collection editor/setup CRUD and workspace controls from Home sidebar.

**Acceptance:**

- [x] Four tabs navigable
- [x] Home sidebar ≤ status blocks per `Feature-UI-Final-Vision`
- [x] Collections tab remains sole full editor home

---

## Phase 2c — Visual polish (2–3 days)

**Status:** Implemented 2026-05-20

**Files:** `DesignTokens.swift`, `MainTabBar.swift`, `WallpaperThumbnail.swift`, `CollectionThumbnailStrip.swift`, `CollectionSummaryCard.swift`, `CollectionsTabView.swift`, `SetupPreviewCard.swift`, `TabbedMainView.swift`

**Tasks:**

1. ✅ Glassmorphism / shadow depth tokens (`DesignTokens.Surfaces`, shared scroll backdrop opacity).
2. ✅ Thumbnail-forward collection strip + preview on `CollectionSummaryCard`.
3. ✅ PR4 motion helpers (`Motion.selectionAnimation`, `hoverAnimation`); `reduceMotion` on setup cards.
4. ⏭ Optional: `CollectionWorkspacePreview` split editor (deferred).
5. ✅ Labeled `MainTabBar` (icon + text); legacy `ContentView` / `HomeTabView` marked unused; `TransparentTabSwitcher` deprecated.

**Acceptance:**

- [x] Tab bar shows **Home**, **Collections**, **Setups**, **Settings** labels
- [x] Premium translucent aesthetic on management tabs
- [x] Collections tab thumbnail strip + summary preview

---

## Phase 2d — Home glass + scroll reveal (2026-05-20)

**Status:** Implemented 2026-05-20

**Files:** `UI/GlassChrome.swift`, `MainTabBar.swift`, `TopUtilityBar.swift`, `ModernHomeView.swift`, `DisplaySwitcherView.swift`, `DesignTokens.swift`

**Tasks:**

1. Shared `GlassChrome` + `VisualEffectView` (HUD window material, pill/bar/panel styles).
2. `MainTabBar` — pill-only glass; no full-width grey strip.
3. `TopUtilityBar` + `DisplaySwitcherView` + Home sidebar — glass panels.
4. Home scroll spacer (~62% height) reveals display carousel; “Scroll for Displays” hint.
5. Removed Layer 1 full-window material blanket.

---

## Phase 3 — Validation (1 day)

**Status:** Automated complete 2026-05-20; manual matrix in `PHASE_3_VALIDATION.md`

- [x] `scripts/chunk7_smoke.sh` — build + bundle check
- [x] `scripts/chunk7_regression.sh` — Debug/Release
- [x] Manual sign-off (user verified May 20, 2026)
- [x] Always per-display (toggle removed); Home **Choose Wallpaper** restored
- [x] Collection apply refreshes Home preview
- [x] Merged `ui/polish/pr4-motion` → `main`

---

## Phase 4a — App-wide wallpaper background (2026-05-20)

**Status:** Implemented 2026-05-20

**Files:** `UI/AppWallpaperBackground.swift`, `TabbedMainView.swift`, `ModernHomeView.swift`, `CollectionsTabView.swift`, `SetupsTabView.swift`, `SettingsTabView.swift`, `DesignTokens.swift`

**Tasks:**

1. Shared `AppWallpaperBackground` at shell level (hero vs management intensity).
2. Remove duplicate Home hero layer; management tabs use transparent scroll roots.
3. Blur + scrim on non-Home tabs for readability.

---

## Phase 4b — Management tab visual refresh (2026-05-20)

**Status:** Implemented 2026-05-20

**Files:** `UI/TabHeaderView.swift`, `UI/GlassCardView.swift`, `CollectionsTabView.swift`, `SetupsTabView.swift`, `SettingsTabView.swift`

**Tasks:**

1. Glass section headers and cards on Collections / Setups / Settings.
2. Collections sticky action bar + 2-column grid when multiple collections.
3. Settings grouped sections with captions.

---

## Phase 4c — Home scroll performance (2026-05-20)

**Status:** Implemented 2026-05-20

**Files:** `ModernHomeView.swift`, `VideoPreviewView.swift`, `HeroWallpaperView.swift`

**Tasks:**

1. Threshold-based scroll state (no per-frame full-tree updates).
2. Shorter scroll spacer; cached display cards.
3. Pause wallpaper video while scrolling; carousel mounts only when revealed (no `drawingGroup` ghost panel).

---

## Phase 4d — Cleanup (2026-05-20)

**Status:** Implemented 2026-05-20

- Removed legacy `ContentView.swift`, `HomeTabView.swift`, `TransparentTabSwitcher.swift`.
- Updated `ApplyWallpaperModal` thumbnail generation API.

---

## Phase 4 — Validation

**Status:** Automated complete 2026-05-20; manual matrix in `PHASE_4_VALIDATION.md`

---

## Mapping from legacy 9-phase plan

| Legacy phase | New mapping |
|--------------|-------------|
| 1 Architecture + bug fix | Phase 2a |
| 2 Per-display carousel | Phase 2a (scroll placement) |
| 3 Visual depth | Phase 2c (partial) |
| 4 Collection editor | Phase 2c optional |
| 5 Image quality | Phase 1 + 2a hero URL |
| 6 Collections browsing | Collections tab + 2c |
| 7 Sidebar typography | Slim sidebar 2b |
| 8 Global settings | Settings tab 2b |
| 9 Validation | Phase 3 |

---

## Files — do not reference

- `CollectionsSidebarView` — does not exist; use `ModernHomeView.sidebarPanel`
- ~~`ContentView`~~ — removed; use `TabbedMainView` / `ModernHomeView`

---

**Document version:** 3.1  
**Last updated:** 2026-05-20  
**Status:** Phases 0–4 complete; merged to `main`
