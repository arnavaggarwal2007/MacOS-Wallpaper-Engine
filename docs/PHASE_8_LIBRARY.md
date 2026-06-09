# Phase 8 — Local Library

**Status:** Implemented (8A–8C, 2026-06-01)  
**Depends on:** Phase 7 complete  
**Knowledge base:** `30 Features/Feature-V2-Local-Library.md`, `20 Architecture/Modules/LocalLibraryManager.md`, `20 Architecture/Modules/LibraryThumbnailCache.md`, `50 Decisions/ADR-006-Local-Library-Persistence.md`

## Scope

| Subphase | Deliverable |
|----------|-------------|
| 8A | `LibraryItem`, `LibraryRoot`, `LocalLibraryManager`, `SettingsStore` persistence |
| 8B | `LibraryThumbnailCache` — disk cache, LRU eviction (500 MB cap), AVFoundation metadata |
| 8C | `LibraryBrowserView`, Home strip + sheet, Settings roots, Collection editor picker |
| 8C polish | Horizontal strip on Home, full grid in sheet, tile alignment, sheet clipping fixes |

## Home UX (8C polish)

- **Scroll reveal:** Display carousel appears **first** when scrolling down on Home.
- **Local Library strip:** One horizontal row (~220px) below displays for quick pick + hero preview.
- **Browse All…** / toolbar **Browse Library:** Opens `LibraryBrowserSheet` with full grid, search, filters, and Apply.
- **Settings → Local Library:** Folder roots, rescan, cache management (unchanged).

## Architecture

```text
SettingsStore (libraryRoots, libraryItems, lastUsedLibraryItemID)
  └── LocalLibraryManager (@MainActor)
        ├── scanLibrary (utility QoS, MP4/MOV/M4V)
        ├── bookmark resolution + stale/missing handling
        └── LibraryThumbnailCache (~/Library/Caches/.../library-thumbnails)
  └── AppViewModel (preview, apply, filters)
        └── ModernHomeView / SettingsTabView / CollectionEditorView
```

## Manual regression matrix

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Add library root in Settings | Folder bookmark saved; rescan indexes MP4/MOV |
| 2 | Relaunch app | Roots + catalog restore; thumbnails load from cache |
| 3 | Home → scroll → display carousel | Displays appear before library strip |
| 4 | Home library strip | Tap tile → hero preview; header **Apply** or double-click tile → focused display; toolbar **Apply Now** uses library selection when active |
| 5 | Browse All / Browse Library sheet | Full grid with looser row spacing (22pt); search, favorites, Apply |
| 6 | Select library item | Hero previews via `transientPreviewURL` |
| 7 | Apply from library tile (sheet grid) | Apply buttons align across row; desktop bookmarks updated |
| 8 | File importer (Home) | Still works alongside library |
| 9 | Collection editor → Library | Source URL + bookmark populated; sheet borders not clipped |
| 10 | Collections Edit/New sheet | Single CardView; focus rings visible (scrollClipDisabled); min width 740 |
| 11 | Delete file on disk → rescan | Item marked missing, not crash |
| 12 | Remove library root | Items for root removed; cache entries pruned |
| 13 | Setup save/restore with library path | Bookmarks restore playback |
| 14 | Thumbnail load (50+ items) | No main-thread semaphore wait; max 4 concurrent loads |
| 15 | Home display cards | Large video/image previews stay inside 214×104 card bounds; no overlap between cards |

## Build verification

```bash
CODE_SIGNING_ALLOWED=NO ./scripts/chunk7_smoke.sh
```
