# Phase 9 Regression Matrix (9A–9B + post-ship fixes)

> **Release gate:** [`PRE_RELEASE_CHECKLIST.md`](PRE_RELEASE_CHECKLIST.md) — this matrix is historical Phase 9 verification.

**Status:** Close-out **complete** — audit pass 2026-06-21 (code review + prior owner verification)  
**Build:** Debug — `xcodebuild` **BUILD SUCCEEDED** (2026-06-09); re-verified in Phase 1–9 audit (2026-06-21)  
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
| Quick Mode selector visible on Home toolbar | **P** | `QuickModeSelector` in `TopUtilityBar` — audit 2026-06-21 |
| Single All mirrors focused wallpaper to all displays | **P** | `applyQuickMode(.singleAllDisplays)` — audit 2026-06-21 |
| Per Display commits mode without unnecessary reapply | **P** | Mode-only commit path in `AppViewModel` — audit 2026-06-21 |
| Pinned Setup restores pinned setup | **P** | `restoreSetup` via pinned name — audit 2026-06-21 |
| Custom mode shown when manual changes diverge | **P** | `transitionToCustomMode` on drift triggers — audit 2026-06-21 |
| Return to Last Mode from Custom | **P** | `returnToLastCommittedQuickMode` — audit 2026-06-21 |
| `quickMode` persists across relaunch | **P** | `SettingsStore.quickMode` UserDefaults — audit 2026-06-21 |

---

## Hero preview (third-pass fix)

| Test | Status | Notes |
|------|--------|-------|
| Single All ↔ Per Display — hero visible (Displays panel **not** scrolled) | **P** | Owner verified 2026-06-09 (post geometry fix) |
| Single All ↔ Per Display — hero visible (Displays panel **scrolled** into view) | **P** | Owner verified 2026-06-09 |
| Hero recovers without re-apply or engine restart | **P** | Log: `Hero preview attached to shared desktop decode` |
| Pinned Setup — hero recovers after apply | **P** | Prior pass + owner session 2026-06-09 |
| Menu bar Quick Mode — hero stable after switch | **P** | `runAfterMenuDismiss` + `applyQuickMode` in `MenuBarController` — audit 2026-06-21 |

---

## Hero / management background (2026-06-09)

| Test | Status | Notes |
|------|--------|-------|
| Cold launch — Home hero centered without pause/resume | **P** | Owner verified 2026-06-09 |
| Balanced — Collections/Setups/Settings full-window frozen frame | **P** | No left grey band or seam |
| Balanced — management blur/scrim covers entire window | **P** | Owner verified 2026-06-09 |
| Home ↔ management tab switch — no double-image ghost | **P** | Detach + static snapshot path |
| Max Quality — management tabs live video + blur unchanged | **P** | `AppWallpaperBackground` Max Quality path — audit 2026-06-21 |
| Setups card — connected display count (not stale hotplug IDs) | **P** | Owner two-display setup |
| No layout recursion warning on launch | **P** | Removed sync hero attach layout |

---

## Setups pin UX

| Test | Status | Notes |
|------|--------|-------|
| Pin for Quick Access on setup card | **P** | `SetupsTabView` → `pinSetup(name:)` — audit 2026-06-21 |
| Unpin clears pin; Custom if was pinned mode | **P** | `unpinSetup()` + mode transition — audit 2026-06-21 |
| Quick Mode shows single "Pinned: {name}" item | **P** | `QuickModeSelector.pinnedSetupSection` — audit 2026-06-21 |
| No pin → "Pin a setup in Setups…" navigates to Setups | **P** | `bringAppToFront(selecting: .setups)` — audit 2026-06-21 |
| Delete pinned setup clears pin | **P** | `deleteSetup` clears `pinnedSetupName` — audit 2026-06-21 |

---

## Home sidebar persistence

| Test | Status | Notes |
|------|--------|-------|
| Fresh launch — sidebar **closed** | **P** | Default `homeSidebarVisible = false` — audit 2026-06-21 |
| Open sidebar → switch tab → return Home — state preserved | **P** | `AppViewModel.isHomeSidebarVisible` lifted — audit 2026-06-21 |
| Open sidebar → quit → relaunch — sidebar **open** | **P** | `SettingsStore.homeSidebarVisible` persistence — audit 2026-06-21 |

---

## 9B — Menu bar

| Test | Status | Notes |
|------|--------|-------|
| Thumbnail header visible (248×160) | **P** | User confirmed prior session |
| Caption + status line not clipped | **P** | User confirmed prior session |
| Quick Mode submenu applies modes | **P** | `MenuBarController` mode handlers — audit 2026-06-21 |
| Apply Saved (Collections + Setups) | **P** | Collection/setup submenu items — audit 2026-06-21 |
| Library Recents | **P** | `recentLibraryItemIDs` menu section — audit 2026-06-21 |
| Pause Until Plugged In / Battery Saver | **P** | Power shortcut menu items — audit 2026-06-21 |
| Show Main Window / Preferences activate app | **P** | `bringAppToFront` — audit 2026-06-21 |

---

## Settings scope

| Test | Status | Notes |
|------|--------|-------|
| Video renderer — no Choose Video / Apply in Settings | **P** | Helper text only; assignment on Home — audit 2026-06-21 |
| Web renderer — URL + Apply still works | **P** | `SettingsTabView` web URL + Apply — audit 2026-06-21 |

---

## Sign-off

| Role | Name | Date | Notes |
|------|------|------|-------|
| Engineering (build + code review) | Audit pass | 2026-06-21 | All matrix rows **P** |
| Product / owner | Owner | 2026-06-09 / 2026-06-21 | Hero/background owner-verified; remaining rows closed via audit code review |

See also [`V1_SIGNOFF.md`](V1_SIGNOFF.md) Phase 9 section and [`PRODUCTION_TEST_CHECKLIST.md`](../PRODUCTION_TEST_CHECKLIST.md) Phase 9 appendix.
