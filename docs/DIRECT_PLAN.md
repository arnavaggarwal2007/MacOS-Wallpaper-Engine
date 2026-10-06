# Direct download (Milestone 3)

**Status:** Later. Start after Milestone 2 is underway or shipped. Deskface 1.0 is already on the Mac App Store (October 6, 2026).  
**Trunk:** same `main`, `DIRECT_BUILD` flavor. No permanent `direct` branch.  
**Screensaver and lock export:** [MILESTONE_2.md](MILESTONE_2.md)  
**Signing how-to:** [DISTRIBUTION.md](DISTRIBUTION.md)

---

## Why this waits

| Factor | Notes |
|--------|--------|
| Discovery | The App Store listing is the first public channel |
| Policy | Direct can later enable live lock-screen video (private API, opt-in). The App Store build cannot |
| Updates | Sparkle 2, which the App Store does not allow |
| Tips | An external tip link, without Apple’s in-app purchase cut |

Milestone 2 features inherit automatically when Direct is built from the same `main`.

## Planned work

| Item | Notes |
|------|--------|
| `Configurations/Direct.xcconfig` and `DIRECT_BUILD` | Already present for day-to-day builds |
| `PWE Direct` scheme | Developer ID signing |
| Sparkle 2 | Replace the `UpdateChecker` placeholder |
| Notarization and DMG CI | Automate [DISTRIBUTION.md](DISTRIBUTION.md) on release tags |
| External tip link | Free app; the link does not unlock features |
| Live lock-screen video | Only after macOS 26+ checks; never compiled into `APP_STORE_BUILD` |
| Hosted privacy and EULA | Sparkle and the download page point here |

## Out of scope until this milestone starts

- A permanent `direct` branch
- Dropping the sandbox by default
- Steamworks
- Shipping live lock video without a kill switch and a clear risk note

## Acceptance (when work starts)

- [ ] Direct Release notarizes and staples
- [ ] Sparkle update path tested
- [ ] The App Store flavor still builds from the same `main` without live lock video or Sparkle
- [ ] The tip link does not unlock paid features
- [ ] [DISTRIBUTION.md](DISTRIBUTION.md), [CHANNELS.md](CHANNELS.md), [../ROADMAP.md](../ROADMAP.md), and the knowledge-base changelog updated

## References

- [CHANNELS.md](CHANNELS.md)
- [archive/PHASE_10C_LOCK_SCREEN_RESEARCH.md](archive/PHASE_10C_LOCK_SCREEN_RESEARCH.md) (live lock video research)
- Knowledge base ADR-008
