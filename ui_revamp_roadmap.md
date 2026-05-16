# UI Revamp Roadmap: Modern macOS Wallpaper App

**Status:** Planning phase  
**Start Date:** 2026-05-15  
**Target Completion:** ~10–14 days (8 phases)  
**Vision:** Transform the app from a "polished settings panel" to a "sleek, modern macOS wallpaper showcase app" inspired by Wallspace.

---

## Executive Summary

The current UI is functional and polished, but positioned like system preferences rather than a modern macOS application. This overhaul will:

- **Emphasize visual beauty**: Hero preview dominates (50–60% of window); controls are minimal and overlay-based
- **Adopt hero-first layout**: Large, high-quality wallpaper preview with display switcher carousel
- **Improve image quality**: Fix blurry previews and incorrect aspect ratios (square per-display tiles)
- **Create visual collections browsing**: Collections sidebar with rich thumbnails, not text-heavy cards
- **Design for future extensibility**: Structure assumes online library integration later (not implementing now)
- **Integrate per-display UX**: Display switching in hero area via carousel; no separate settings section
- **Modernize interactions**: Full-screen collection editor sheet with live workspace preview
- **Add depth and polish**: Glassmorphism, gradients, proper shadows, and smooth animations

**Key Inspiration:** Wallspace (hero-dominant layout, visual-first design, discovery-focused browsing)

---

## Phase 1: Architecture & Hero-First Layout (2–3 days)

**Goal:** Establish new layout model with hero preview as primary content.

### Tasks

1. **Redesign ContentView.swift** — Major rewrite
   - New split layout: Left (70%) = hero + display switcher; Right (30%) = collections sidebar + quick controls
   - Hero preview: 50–60% of window height (vs. current ~20%)
   - Top chrome: Floating toolbar with play/pause, mute, settings (minimal)
   - Collections sidebar: Scrollable list with visual thumbnails
   - Per-display switch integrated into hero area (not separate section)

2. **Create `HeroWallpaperView.swift`** (new component)
   - Large, high-quality wallpaper preview
   - Overlay controls: display name, scaling mode, quick apply/preview buttons
   - Gradient overlay for text legibility
   - Smooth transitions when switching displays

3. **Create `CollectionsSidebarView.swift`** (new component)
   - Vertical scrollable list of collections
   - Small thumbnail + collection name + source count per item
   - Selected state highlighting
   - Quick action buttons on hover (edit, apply, delete)

4. **Refactor `TopUtilityBar.swift`**
   - Make floating and minimal
   - Position as overlay on hero preview
   - Subtle background (glassmorphism or semi-transparent blur)

### Files Modified
- `ContentView.swift` — Major rewrite
- `TopUtilityBar.swift` — Refactor to floating layout
- `HeroWallpaperView.swift` — Create new
- `CollectionsSidebarView.swift` — Create new
- `AppViewModel.swift` — Minor updates for display switcher state

### Acceptance Criteria
- ✅ App builds cleanly after refactor
- ✅ Hero preview is 50–60% of window height
- ✅ Collections sidebar visible on right
- ✅ Floating toolbar appears over hero
- ✅ Layout responsive to window resize

---

## Phase 2: Per-Display Browsing (2 days)

**Goal:** Integrate multi-display switching into hero view with carousel.

### Tasks

1. **Create `DisplaySwitcherView.swift`** (new component)
   - Horizontal carousel of display thumbnails
   - Shows current wallpaper for each display
   - Tap to switch hero preview
   - Displays name + resolution per display

2. **Update `HeroWallpaperView.swift`**
   - Display switching triggers smooth hero preview transition
   - Show "bound to Display X" indicator for per-display wallpapers
   - No separate "Per-Display Settings" section

3. **Integrate display carousel into hero area**
   - Below main preview or in a floating carousel UI

### Files Modified
- `HeroWallpaperView.swift` — Add display switching logic
- `DisplaySwitcherView.swift` — Create new
- `ContentView.swift` — Integrate carousel

### Acceptance Criteria
- ✅ Display carousel visible below or adjacent to hero
- ✅ Clicking display thumbnail switches hero preview smoothly
- ✅ Display name and resolution shown
- ✅ Per-display wallpaper indicator visible

---

## Phase 3: Visual Refinements & Depth (2 days)

**Goal:** Add premium, modern aesthetic through colors, typography, shadows, and animations.

### Tasks

1. **Enhance `DesignTokens.swift`**
   - Add new tokens: `elevatedShadow`, `heroGradient`, `cardGradient`
   - Increase shadow depth for layered feel
   - Add gradient overlay colors for hero image legibility
   - Increase typography sizes for hero prominence
   - Add backdrop blur tokens for glassmorphism

2. **Update component styling**
   - Collection cards: Add gradient overlays and text overlays
   - Buttons: Larger, rounded, more prominent (Apple-style)
   - Use `.continuous` corner styles consistently
   - Reduce sharp corners throughout

3. **Implement glassmorphism/backdrop blur**
   - Top toolbar: Subtle blur background
   - Collections sidebar: Optional semi-transparent blur
   - Floating panels: Depth through shadows and blur

### Files Modified
- `DesignTokens.swift` — Add new tokens
- `CardView.swift` — Update styling with gradients and depth
- `HeroWallpaperView.swift` — Add gradient overlay
- `CollectionsSidebarView.swift` — Add backdrop blur
- `TopUtilityBar.swift` — Add glassmorphic background

### Acceptance Criteria
- ✅ New shadow tokens applied consistently
- ✅ Gradient overlays visible on collection cards
- ✅ Backdrop blur visible on sidebar and toolbar
- ✅ Typography sizes increased for prominence
- ✅ No sharp corners; consistent `.continuous` radius

---

## Phase 4: Collections Editor & Modals (2 days)

**Goal:** Transform collection editor from cramped form to immersive full-screen sheet.

### Tasks

1. **Redesign `CollectionEditorView.swift`** — Major rewrite
   - Full-screen sheet (not modal dialog)
   - Split layout: Left (60%) = hero workspace preview; Right (40%) = settings
   - Workspace preview: Live grid/carousel of sources being edited
   - Updates in real-time as sources are added/removed
   - Source addition feels more visual/browsing, less form-like

2. **Create `CollectionWorkspacePreview.swift`** (new component)
   - Live preview of collection as you edit
   - Shows thumbnails of sources at proper aspect ratios
   - Updates as sources are added/removed
   - Grid or carousel layout

3. **Polish `CollectionSourceInput.swift`**
   - Less form-like appearance
   - Visual file browser with thumbnail previews
   - Display mapping shown as visual selectors (not dropdowns)

### Files Modified
- `CollectionEditorView.swift` — Major rewrite to full-screen sheet
- `CollectionWorkspacePreview.swift` — Create new
- `CollectionSourceInput.swift` — Polish and simplify
- `ContentView.swift` — Update sheet presentation

### Acceptance Criteria
- ✅ Collection editor appears as full-screen sheet
- ✅ Workspace preview shows live collection thumbnail grid
- ✅ Settings on right side; clear and uncluttered
- ✅ Sources update in real-time on preview
- ✅ No form-like appearance; visual and inviting

---

## Phase 5: Image Quality & Aspect Ratios (1 day)

**Goal:** Fix preview blurriness and incorrect proportions.

### Tasks

1. **Review all preview image rendering**
   - Ensure `WallpaperPreviewCard` uses `.resizable().scaledToFill()` with proper clipping
   - Remove any blur filters or unintended down-sampling
   - Verify image scaling logic is optimal

2. **Fix per-display preview proportions**
   - Currently rendering as squares (incorrect)
   - Change to proper 16:9 or matching source aspect ratio
   - Update `PerDisplayPreviewTile.swift` sizing

3. **Ensure thumbnail sharpness**
   - Verify thumbnails are cached and not re-rendered
   - Check sampling filters are appropriate
   - No unnecessary image processing

### Files Modified
- `WallpaperPreviewCard.swift` — Fix image rendering
- `PerDisplayPreviewTile.swift` — Fix aspect ratio from square
- `HeroWallpaperView.swift` — Ensure high-quality rendering
- Image caching logic review

### Acceptance Criteria
- ✅ Preview images are sharp, not blurry
- ✅ Per-display tiles show proper 16:9 ratio (not square)
- ✅ Hero preview is high-quality
- ✅ No artifacting or unexpected scaling

---

## Phase 6: Collections Browsing & Discovery (1–2 days)

**Goal:** Make collections browsing feel like Wallspace's carousel experience.

### Tasks

1. **Enhance collections sidebar**
   - Vertical scrollable with richer visual cards
   - Thumbnail of first source in collection
   - Collection name overlaid (like Wallspace)
   - Type badge (Simple/Display-Bound)
   - Source count indicator

2. **Visual collection cards**
   - Thumbnail background with text overlay
   - Hover state: Show quick actions (apply, edit, delete)
   - Smooth transitions and animations
   - Selection highlighting

3. **Add carousel-like feel (if horizontal layout)**
   - Scrollable carousel of collection cards
   - Thumbnail-based browsing
   - Similar to Wallspace grid

### Files Modified
- `CollectionsSidebarView.swift` — Enhance visual cards
- New collection card component (if needed)
- Motion tokens for smooth transitions

### Acceptance Criteria
- ✅ Collection cards show thumbnails prominently
- ✅ Hover actions visible and accessible
- ✅ Smooth animations on interaction
- ✅ Selection state clear
- ✅ Type badge visible

---

## Phase 7: Global Settings & Refinements (1 day)

**Goal:** Move less-used controls out of hero area; add final polish.

### Tasks

1. **Create `SettingsPanelView.swift`** (new component or refactored section)
   - Renderer mode (Video/Web)
   - Scaling mode global default
   - Launch on login
   - Less prominent in main view
   - Accessible via settings icon or menu

2. **Fine-tune spacing and padding**
   - Apply new spacing tokens consistently
   - Ensure text is never cramped
   - Proper breathing room around controls

3. **Polish animations and transitions**
   - Smooth display switching
   - Fade/scale on collection selection
   - Gentle motion on hover

### Files Modified
- `SettingsPanelView.swift` — Create new or refactor existing
- `ContentView.swift` — Finalize spacing and layout
- `TopUtilityBar.swift` — Polish animations
- `DesignTokens.swift` — Finalize all spacing values

### Acceptance Criteria
- ✅ Settings accessible but not cluttering main view
- ✅ Consistent spacing throughout
- ✅ All motion feels smooth and purposeful
- ✅ No cramped or hard-to-read text

---

## Phase 8: Validation & Testing (1 day)

**Goal:** Comprehensive testing and final visual acceptance.

### Tasks

1. **Smoke tests**
   - Build succeeds in Debug configuration
   - App launches without crashes
   - All sections render without errors

2. **Regression tests**
   - Collection creation/editing works
   - Collection apply works (simple and display-bound)
   - Per-display wallpaper switching works
   - Settings persistence works
   - Launch on login functions

3. **Visual acceptance pass**
   - Compare against Wallspace screenshots
   - Verify hero-first layout works
   - Check image quality and aspect ratios
   - Validate animation smoothness
   - Test responsive layout (narrow/wide windows)

4. **Performance validation**
   - No lag on preview switching
   - Smooth scrolling in collections sidebar
   - Image rendering is efficient

### Files Modified
- All files: Verify no warnings or errors
- Test scripts may need updates

### Acceptance Criteria
- ✅ All smoke tests pass
- ✅ All regression tests pass
- ✅ Visual comparison: UI matches Wallspace inspiration
- ✅ No compile warnings or errors
- ✅ Performance is smooth across all interactions
- ✅ Responsive layout works on narrow and wide windows

---

## Summary of All Files Modified/Created

### Major Rewrites
- `ContentView.swift` — New hero-first layout with split view
- `CollectionEditorView.swift` — Full-screen sheet with workspace preview

### New Components
- `HeroWallpaperView.swift` — Large preview with overlay controls
- `DisplaySwitcherView.swift` — Multi-display carousel
- `CollectionsSidebarView.swift` — Visual collections browser
- `CollectionWorkspacePreview.swift` — Live collection preview during editing
- `SettingsPanelView.swift` — Global settings panel

### Refactors & Polish
- `TopUtilityBar.swift` — Floating, minimal toolbar
- `DesignTokens.swift` — New tokens for depth, shadows, gradients
- `CardView.swift` — Updated styling with depth
- `WallpaperPreviewCard.swift` — Fix image quality; add gradient
- `PerDisplayPreviewTile.swift` — Fix aspect ratio
- `CollectionSourceInput.swift` — Simplify, visual file browser
- `AppViewModel.swift` — Minor display switcher state updates

### Deprecated/Retired
- `PerDisplayCard.swift` — Functionality absorbed into hero + display carousel
- `TopUtilityBar.swift` (current form) — Reimplemented as floating overlay

---

## Timeline

| Phase | Duration | Start | End |
|-------|----------|-------|-----|
| 1: Layout & Hero | 2–3 days | Day 1 | Day 3 |
| 2: Per-Display | 2 days | Day 4 | Day 5 |
| 3: Visual Polish | 2 days | Day 6 | Day 7 |
| 4: Editor & Modals | 2 days | Day 8 | Day 9 |
| 5: Image Quality | 1 day | Day 10 | Day 10 |
| 6: Collections Browse | 1–2 days | Day 11 | Day 12 |
| 7: Settings & Refinements | 1 day | Day 13 | Day 13 |
| 8: Validation & Testing | 1 day | Day 14 | Day 14 |
| **Total** | **~10–14 days** | — | — |

---

## Design Decisions

### Hero-First Layout (Option: Middle of 1 & 2)
- Large hero preview dominates visual hierarchy
- Collections sidebar secondary but visible
- Rationale: Balances visual prominence with collection accessibility

### Hybrid-Ready Structure
- Design assumes online library could be added later
- Collections browsing pattern mirrors carousel UI
- Rationale: Extensibility without redesign

### Integrated Per-Display UX
- Display carousel in hero area; no separate settings section
- Display switching smooth and immediate
- Rationale: Reduces UI complexity; keeps focus on visual content

### Full-Screen Collection Editor
- Immersive sheet, not cramped modal
- Live workspace preview shows collection as you edit
- Rationale: Makes editing feel creative, not utilitarian

### Visual-First Information Hierarchy
- Images and beauty prioritized over text and controls
- Controls minimal and overlay-based
- Rationale: Wallpaper engine is fundamentally about visual content

---

## Known Constraints & Future Work

### Out of Scope
- Online wallpaper library (planned for Phase 6B)
- Community curation (planned for Phase 6B)
- Explore tab / discovery (planned for future)
- Advanced effects and filters (future phase)

### Assumptions
- Local wallpapers and collections remain primary use case
- Multi-display support continues to work as-is
- Wallpaper apply and rendering logic unchanged

### Future Enhancements
- Online library carousel integration (minimal changes needed)
- Advanced filtering and search
- Favorites and custom collections
- Animation and effect previews

---

## Verification Checklist

### Phase 1 Acceptance
- [ ] App builds cleanly
- [ ] Hero preview is 50–60% of window
- [ ] Collections sidebar visible on right
- [ ] Floating toolbar appears over hero
- [ ] Layout responsive to resize

### Phase 2 Acceptance
- [ ] Display carousel visible
- [ ] Display switching smooth
- [ ] Display name and resolution shown

### Phase 3 Acceptance
- [ ] New shadow tokens applied
- [ ] Gradient overlays visible
- [ ] Backdrop blur working
- [ ] Typography sizes increased

### Phase 4 Acceptance
- [ ] Full-screen sheet works
- [ ] Workspace preview live
- [ ] Settings on right clear
- [ ] Visual, not form-like

### Phase 5 Acceptance
- [ ] Previews sharp
- [ ] Per-display 16:9 (not square)
- [ ] No blur artifacts

### Phase 6 Acceptance
- [ ] Collection cards visual
- [ ] Hover actions visible
- [ ] Smooth animations

### Phase 7 Acceptance
- [ ] Settings accessible
- [ ] Consistent spacing
- [ ] Motion smooth

### Phase 8 Acceptance
- [ ] All smoke tests pass
- [ ] All regression tests pass
- [ ] Visual comparison matches Wallspace inspiration
- [ ] No warnings/errors
- [ ] Performance smooth

---

## Next Steps

1. Review and approve this roadmap
2. Create KB entries linking to phases
3. Begin Phase 1 implementation
4. Daily progress updates and phase completions

---

**Document Version:** 1.0  
**Last Updated:** 2026-05-15  
**Created By:** AI Assistant  
**Status:** Ready for implementation
