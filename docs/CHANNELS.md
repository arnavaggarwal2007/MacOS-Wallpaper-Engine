# Distribution channels

**Status:** Deskface 1.0 shipped on the Mac App Store (October 6, 2026).  
**Scoring and per-store appendices:** [archive/distribution-channels-research.md](archive/distribution-channels-research.md)  
**Decision:** knowledge base ADR-008

## Order

| Order | Channel | When | Ceiling |
|-------|---------|------|---------|
| 1 | Mac App Store | Milestone 1 done. Milestone 2 next | Desktop, screensaver, static lock export. No live lock video |
| 2 | Direct DMG or zip | Milestone 3, after the App Store build is stable | Same as the store, plus Sparkle and conditional live lock video |
| 3 | Steam | Only if Steamworks is explicitly committed | Same technical ceiling as Direct, unsandboxed |

June 2026 research scored Direct highest for a free app plus tips and a full feature set. That score is about capability. Launch order is the App Store first, for discovery and trust.

## Feature matrix

| Feature | App Store | Direct | Steam |
|---------|-----------|--------|-------|
| Desktop engine (video, web, displays, collections, setups, library, quick modes) | Shipped | Same trunk | Same trunk |
| Static lock export | Milestone 2 | Milestone 2 | If that channel ships |
| Video screensaver | Milestone 2 | Milestone 2 | If that channel ships |
| Live lock-screen video | No | Milestone 3, conditional | Conditional |
| Updates | App Store | Sparkle (Milestone 3) | Steam |
| Tips | Optional in-app purchase | External link | External link |

## Money

The app stays **free**. Optional tips: an in-app purchase on the App Store, an external link on Direct and Steam. A tip must not unlock features. No paid tier for 1.0.

## Flavors

One git trunk. Schemes, entitlements, and `#if` flags carry the channel differences. See [../ROADMAP.md](../ROADMAP.md).

| Scheme | Sandbox | Live lock video | Updates |
|--------|---------|-----------------|---------|
| `PWE App Store` | Yes | No | App Store |
| `PWE Direct` | Yes | Conditional | Sparkle |
| `PWE Steam` | No | Conditional | Steam |
