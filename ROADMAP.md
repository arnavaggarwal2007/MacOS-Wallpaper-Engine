# Roadmap

**Status:** Deskface **1.0 (2)** has been on the Mac App Store since **October 6, 2026**.  
**Next:** [Milestone 2](docs/MILESTONE_2.md) Part 2 — static lock-screen export. Part 1 (video screensaver) is implemented and waiting on owner QA.  
**Record:** [docs/RELEASE_RECORD.md](docs/RELEASE_RECORD.md)

Living names only. Older phase numbers stay in [docs/archive/](docs/archive/).

| Name | Meaning |
|------|---------|
| **Deskface 1.0** | What is on the store: desktop engine through quick modes and the menu bar |
| **Milestone 1** | App Store compliance. Done |
| **Milestone 2** | Screensaver implemented (Part 1, not yet on the store). Static lock export is Part 2 |
| **Milestone 3** | Direct download. Later |
| **Backlog** | Technical debt. Not the next milestone |

## Milestone 2 — screensaver and static lock export

Ship on every flavor, then submit an App Store update (planned tag `v1.1`).

- Video screensaver (`.saver`) that reads a video copied into the App Group — **Part 1 implemented**, owner QA still open
- Static lock-screen image export with a guide into System Settings — **Part 2, not started**
- Settings section “Screen Saver” today; Part 2 renames it to “Lock Screen & Screen Saver”
- Optional tip in-app purchase only in the App Store build

Spec: [docs/MILESTONE_2.md](docs/MILESTONE_2.md). Branch: short-lived `feature/tier-a-b`, then merge to `main`.

## Milestone 3 — Direct download

Start after Milestone 2 is on the store. Same `main` branch, `DIRECT_BUILD` flavor. Sparkle updates, an external tip link, and live lock-screen video (Tier C) if it can be done safely. Tier C never compiles into the App Store build.

Stub: [docs/DIRECT_PLAN.md](docs/DIRECT_PLAN.md). Signing steps: [docs/DISTRIBUTION.md](docs/DISTRIBUTION.md).

Steam stays optional and unsandboxed, and only if that channel is explicitly committed.

## Build flavors

One trunk (`main`). Releases are tags. Channel differences are schemes, xcconfig files, entitlements, and compile flags. Do not keep permanent `app-store`, `direct`, or `steam` branches.

| Scheme | Flag | Sandbox | Screensaver and lock export | Live lock video | Updates |
|--------|------|---------|-----------------------------|-----------------|---------|
| `PWE App Store` | `APP_STORE_BUILD` | Yes | Milestone 2 | No | App Store |
| `PWE Direct` | `DIRECT_BUILD` | Yes | Milestone 2 | Milestone 3, conditional | Sparkle |
| `PWE Steam` | `STEAM_BUILD` | No | If that channel ships | Conditional | Steam |

Policy: [docs/CHANNELS.md](docs/CHANNELS.md). Decision record: Wallpaper Engine KB, ADR-008.

## Backlog

Known debt that waited until after the first App Store release — split `AppViewModel`, renderer unification, setup schema, Dynamic Type, localization, and tests — lives in the knowledge base: `70 Master Plan/POST_LAUNCH_BACKLOG.md`.
