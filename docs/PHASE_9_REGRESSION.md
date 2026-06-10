# Phase 9 Regression Matrix (9A–9B + post-ship fixes)

**Status:** Close-out recorded 2026-06-09 (hero/management background pass verified by owner)  
**Build:** Debug — `xcodebuild` **BUILD SUCCEEDED** (2026-06-09)  
**KB:** `Wallpaper Engine KB/40 Bugs/Bug-Phase9-Quick-Mode-Hero-And-Menu-Bar.md`, `Bug-Management-Tab-Shell-Background-Geometry.md`

Legend: **P** = Pass, **M** = Manual verify required, **N/A** = Not applicable

---

## Automated verification

| Check | Command | Result | Date |
|-------|---------|--------|------|
| Debug build | `xcodebuild -scheme "Personal Wallpaper Engine" -configuration Debug build` | **P** | 2026-06-09 |
| Quick Mode persistence keys compile | SettingsStore `quickMode`, `pinnedSetupName`, `homeSidebarVisible` | **P** | 2026-06-09 |
| Hero attach token wired | `heroPreviewAttachToken` in `HeroWallpaperView` `.id()` | **P** (code review) | 2026-06-09 |
| Coordinator detach guard | `isHeroPreviewAttached(to:)` in `UnifiedVideoPreviewView` | **P** (code review) | 2026-06-09 |
| Shell background GeometryReader fill | `AppWallpaperBackground` ZStack `.frame(width:height:)` | **P** (code review) | 2026-06-09 |
| Launch hero recovery task | `scheduleShellHeroLayoutRecovery()` cancellable Task | **P** (code review) | 2026-06-09 |

---

## 9A — Quick Modes

| Test | Status | Notes |
|------|--------|-------|
| Quick Mode selector visible on Home toolbar | **M** | `QuickModeSelector` in `TopUtilityBar` |
| Single All mirrors focused wallpaper to all displays | **M** | Skips reapply when already unified |
| Per Display commits mode without unnecessary reapply | **M** | |
| Pinned Setup restores pinned setup | **M** | Requires pinned setup in Setups tab |
| Custom mode shown when manual changes diverge | **M** | Drift on per-display, collection, setup restore, library apply |
| Return to Last Mode from Custom | **M** | |
| `quickMode` persists across relaunch | **M** | |

---

## Hero preview (third-pass fix)

| Test | Status | Notes |
|------|--------|-------|
| Single All ↔ Per Display — hero visible (Displays panel **not** scrolled) | **P** | Owner verified 2026-06-09 (post geometry fix) |
| Single All ↔ Per Display — hero visible (Displays panel **scrolled** into view) | **P** | Owner verified 2026-06-09 |
| Hero recovers without re-apply or engine restart | **P** | Log: `Hero preview attached to shared desktop decode` |
| Pinned Setup — hero recovers after apply | **P** | Prior pass + owner session 2026-06-09 |
| Menu bar Quick Mode — hero stable after switch | **M** | Menu-dismiss defer aligned with Home |

---

## Hero / management background (2026-06-09)

| Test | Status | Notes |
|------|--------|-------|
| Cold launch — Home hero centered without pause/resume | **P** | Owner verified 2026-06-09 |
| Balanced — Collections/Setups/Settings full-window frozen frame | **P** | No left grey band or seam |
| Balanced — management blur/scrim covers entire window | **P** | Owner verified 2026-06-09 |
| Home ↔ management tab switch — no double-image ghost | **P** | Detach + static snapshot path |
| Max Quality — management tabs live video + blur unchanged | **M** | |
| Setups card — connected display count (not stale hotplug IDs) | **P** | Owner two-display setup |
| No layout recursion warning on launch | **P** | Removed sync hero attach layout |

---

## Setups pin UX

| Test | Status | Notes |
|------|--------|-------|
| Pin for Quick Access on setup card | **M** | |
| Unpin clears pin; Custom if was pinned mode | **M** | |
| Quick Mode shows single "Pinned: {name}" item | **M** | |
| No pin → "Pin a setup in Setups…" navigates to Setups | **M** | |
| Delete pinned setup clears pin | **M** | |

---

## Home sidebar persistence

| Test | Status | Notes |
|------|--------|-------|
| Fresh launch — sidebar **closed** | **M** | Default `homeSidebarVisible = false` |
| Open sidebar → switch tab → return Home — state preserved | **M** | |
| Open sidebar → quit → relaunch — sidebar **open** | **M** | |

---

## 9B — Menu bar

| Test | Status | Notes |
|------|--------|-------|
| Thumbnail header visible (248×160) | **P** | User confirmed prior session |
| Caption + status line not clipped | **P** | User confirmed prior session |
| Quick Mode submenu applies modes | **M** | |
| Apply Saved (Collections + Setups) | **M** | |
| Library Recents | **M** | |
| Pause Until Plugged In / Battery Saver | **M** | |
| Show Main Window / Preferences activate app | **M** | `bringAppToFront` |

---

## Settings scope

| Test | Status | Notes |
|------|--------|-------|
| Video renderer — no Choose Video / Apply in Settings | **M** | Helper text points to Home |
| Web renderer — URL + Apply still works | **M** | |

---

## Sign-off

| Role | Name | Date | Notes |
|------|------|------|-------|
| Engineering (build + code review) | | 2026-06-09 | Automated rows **P** |
| Product / owner (manual matrix) | Owner | 2026-06-09 | Hero + management background rows **P**; remaining **M** rows before App Store / public release |

See also [`V1_SIGNOFF.md`](V1_SIGNOFF.md) Phase 9 section and [`PRODUCTION_TEST_CHECKLIST.md`](../PRODUCTION_TEST_CHECKLIST.md) Phase 9 appendix.
