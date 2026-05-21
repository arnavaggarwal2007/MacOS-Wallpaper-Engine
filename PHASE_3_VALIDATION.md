# Phase 3 — Validation

**Date:** 2026-05-20  
**Scope:** Post UI revamp (2a–2d) + always per-display + Home browse + collection preview sync  
**Sign-off:** User verified working May 20, 2026. Merged to `main`.

## Automated checks

| Check | Command | Result |
|-------|---------|--------|
| Debug build | `xcodebuild -destination 'platform=macOS'` | Pass |
| Chunk 7 smoke | `scripts/chunk7_smoke.sh` | Pass |
| Chunk 7 regression | `scripts/chunk7_regression.sh` | Pass (Debug + Release) |

## Manual matrix (required on hardware)

### Home — hero-first + scroll reveal (Phase 2d)

- [ ] Launch Home: hero + glass utility bar dominate; **Displays** carousel not fully visible until scroll down
- [ ] “Scroll for Displays” hint visible until first scroll (or hidden after scroll)
- [ ] Tab bar shows **pill-only** glass (no full-width grey strip)
- [ ] Utility bar and display panel are **translucent** (hero visible through chrome)
- [ ] Sidebar uses glass panel styling

### Home — wallpaper browse

- [ ] **Choose Wallpaper** in top bar opens file picker → display selection modal
- [ ] **Choose Wallpaper** in sidebar does the same
- [ ] Apply to one display updates only that display
- [ ] Apply to all displays sets the same file on every screen
- [ ] **Apply Now** applies the focused display’s stored source
- [ ] Display carousel works after scrolling into view

### Per-display mode (no toggle)

- [ ] Settings has **no** “Use Per-Display Wallpapers” toggle
- [ ] Legacy unified preference migrates on launch (both screens can show wallpapers)
- [ ] Same file on both displays is allowed (duplicate per-display entries)

### Collections

- [ ] Thumbnail strip uses **landscape** (16:9) previews
- [ ] Collections with bookmarks show real previews (not generic MP4 icon when file exists)
- [ ] After **Apply Collection**, Home hero + carousel previews match collection sources

### Tabs & polish

- [ ] Tab labels: Home, Collections, Setups, Settings
- [ ] Tab switch without heavy stutter
- [ ] Setups restore/delete still work

### Scroll smoothness (Phase 4c — verify on hardware)

- [ ] Trackpad scroll to displays feels smooth
- [ ] “Scroll for Displays” button reveals carousel
- [ ] Scroll to top hides carousel again

### Regression

- [ ] Multi-display hot-plug: carousel updates
- [ ] Setup save/restore after relaunch
- [ ] Launch on login toggle (if tested)

## Notes

- Unified **mode** removed; “apply to all” is a convenience action, not a separate engine mode.
- Settings **Apply to All Displays** duplicates the chosen source per screen.
- Legacy `ContentView` / `HomeTabView` / `TransparentTabSwitcher` removed 2026-05-20 (Phase 4d).
- Phase 4 cross-tab background and glass management UI: see `PHASE_4_VALIDATION.md`.
