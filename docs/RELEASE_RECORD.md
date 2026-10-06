# Release record

**Store:** Deskface on the Mac App Store  
**Live:** October 6, 2026 · version **1.0 (2)**  
**Bundle ID:** `Personal.Personal-Wallpaper-Engine`  
**Knowledge base:** sibling `Wallpaper Engine KB/`

---

## Milestones

| Milestone | Scope | Status | Date |
|-----------|--------|--------|------|
| Charter (one trunk, App Store first) | Flavors, privacy, submission docs | **Pass** | 2026-08-20 |
| Milestone 1 — App Store 1.0 | Compliance flavor and desktop engine | **Live** on the Mac App Store, build **1.0 (2)** | 2026-10-06 |
| Milestone 2 — screensaver and static lock export | `v1.1` | Pending | |
| Milestone 3 — Direct download | Sparkle, tip link, conditional live lock video | Deferred | |

## Sign-off for 1.0

| Area | Status | Notes |
|------|--------|-------|
| Automated build and smoke | **Pass** | `chunk7_regression.sh` (2026-08-31) |
| UI | **Pass** | Owner, May 20, 2026 |
| Manual QA | **Pass** | [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md), 2026-08-29 |
| Performance | **Pass** | [PERFORMANCE.md](PERFORMANCE.md) |
| Library | **Pass** | [LIBRARY.md](LIBRARY.md) |
| Quick modes and menu bar | **Pass** | [QUICK_MODES.md](QUICK_MODES.md); matrix in [archive/regression/](archive/regression/) |
| Unit tests | **Pass** | [TESTING.md](TESTING.md) |
| App Review | **Approved** | October 6, 2026, version 1.0 (2) |

## Automated checks

| Check | Result | Date |
|-------|--------|------|
| `chunk7_smoke.sh` | Pass | 2026-05-22 |
| `chunk7_regression.sh` | Pass | 2026-08-31 |
| Owner unit tests (`Cmd+U`) | Pass | 2026-08-29 |
| Owner manual QA | Pass | 2026-08-29 |
| `PWE App Store` / `Release-AppStore` | Pass | 2026-08-20 |

## Still open after 1.0

- Screensaver and static lock export — [MILESTONE_2.md](MILESTONE_2.md)
- Direct download, Sparkle, and live lock-screen video — [DIRECT_PLAN.md](DIRECT_PLAN.md)
- Collection playlists
- Technical debt — knowledge base `POST_LAUNCH_BACKLOG.md`

## Approvals

| Role | What | Date |
|------|------|------|
| Engineering | Phases through quick modes | 2026-06-21 |
| Engineering | App Store charter | 2026-08-20 |
| Owner | Manual QA | 2026-08-29 |
| App Review | Deskface 1.0 (2) | 2026-10-06 |

## References

- [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md)
- [APP_STORE_SUBMISSION.md](APP_STORE_SUBMISSION.md)
- [DISTRIBUTION.md](DISTRIBUTION.md)
- [../ROADMAP.md](../ROADMAP.md)
