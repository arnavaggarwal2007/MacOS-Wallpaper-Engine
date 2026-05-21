# Hotplug, launch restore, and setup apply — regression matrix

**Fixed:** 2026-05-21 (display ID migration, per-display launch restore, unified URL resolution)

**Updated:** 2026-05-21 — ID reuse fix: when the same `CGDirectDisplayID` refers to a different monitor after hotplug, settings and `DisplayController` windows are remapped/recreated by screen name + resolution (not only add/remove IDs).

**Updated:** 2026-05-21 — Secondary display geometry: content views use window-local `(0,0)` sizing (not global `NSScreen.frame`), so Display 2 wallpaper is visible when the built-in has a non-zero screen origin.

**Updated:** 2026-05-21 — Replug auto-apply: disconnected monitor settings are tracked by screen signature so both displays reapply on hotplug (not only the built-in). Hotplug handler is debounced (~150ms) to avoid double screen-change races.

## Launch behavior (intended)

| On app open | Behavior |
|-------------|----------|
| Per-display sources/bookmarks exist for connected displays | Reapply each display from persisted settings |
| No per-display data | Legacy fallback: global `videoFilePath` / `videoBookmarkData` or web URL |
| `currentSetupName` set | **Does not** auto-restore setup; use **Restore & Apply** on Setups tab |
| `lastUsedCollectionName` | Used only when resolving collection-relative source keys (not full re-apply on launch) |

## Manual test matrix

| # | Steps | Expected |
|---|--------|----------|
| 1 | Two displays, different wallpapers each → unplug external → plug back (no quit) → Apply / apply collection on **Display 2 (built-in)** | Built-in desktop **visually** updates (not only status text); no rebuild required |
| 2 | Apply collection (e.g. Silver Surfer) → quit app → relaunch | Desktops match last per-display session |
| 3 | Save setup → quit → relaunch → **Restore & Apply** | Settings + desktops match setup |
| 4 | Display-bound collection after hotplug | Matched displays receive correct sources |
| 5 | Setup with collection path keys (not absolute paths) → Restore & Apply | Bookmarks/paths resolve; desktop updates |

## Automated

- `CODE_SIGNING_ALLOWED=NO ./scripts/chunk7_smoke.sh`
- CI regression workflow (universal build)
