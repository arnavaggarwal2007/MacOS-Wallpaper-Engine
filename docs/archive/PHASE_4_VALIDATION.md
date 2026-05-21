# Phase 4 — Validation

**Date:** 2026-05-20  
**Scope:** App-wide wallpaper background, management-tab glass UI, Home scroll performance  
**Sign-off:** User verified working May 20, 2026. Merged to `main`.

## Automated checks

| Check | Command | Result |
|-------|---------|--------|
| Debug build | `xcodebuild -destination 'platform=macOS'` | Pass |
| Chunk 7 smoke | `scripts/chunk7_smoke.sh` | Pass |
| Chunk 7 regression | `scripts/chunk7_regression.sh` | Pass |

## Manual matrix

### Shared background (Phase 4a)

- [ ] Home tab: live wallpaper full fidelity (no extra blur/scrim)
- [ ] Collections / Setups / Settings: same wallpaper visible with blur + dark scrim
- [ ] Text readable on bright wallpapers on management tabs
- [ ] Tab switch updates background intensity without stutter
- [ ] Focused display / collection apply still updates background preview

### Management UI (Phase 4b)

- [ ] Collections: glass header, action bar, library card, thumbnail strip
- [ ] Collections: 2-column grid when multiple collections (wide window)
- [ ] Setups: glass header, save CTA, restore/delete work
- [ ] Settings: Workspace / Source / System glass sections with captions

### Home scroll performance (Phase 4c)

- [ ] Trackpad scroll to displays feels smooth (no stutter)
- [ ] “Scroll for Displays” button reveals carousel
- [ ] Scroll back to top hides carousel and shows hint
- [ ] Video preview pauses while scrolling (resumes when back at top)
- [ ] Sidebar open: scroll still works in hero area (hit-test passthrough)

### Cleanup (Phase 4d)

- [ ] Legacy `ContentView`, `HomeTabView`, `TransparentTabSwitcher` removed
- [ ] No new build errors; `ApplyWallpaperModal` thumbnail API updated

## Notes

- Root shell: `TabbedMainView` + `AppWallpaperBackground` + floating `MainTabBar`.
- Home content no longer embeds its own `HeroWallpaperView` layer.
