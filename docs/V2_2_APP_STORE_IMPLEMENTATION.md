# V2.2 App Store Implementation Charter

**Status:** Milestone 1 engineering **complete** (2026-08-20) — merged to `main`, tagged `v1.0`; Connect upload pending owner  
**Roadmap:** [`version2_developmental_roadmap.md`](../version2_developmental_roadmap.md) Part 3  
**Submission:** [`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md)  
**Privacy:** [`PRIVACY_POLICY.md`](PRIVACY_POLICY.md)  
**Channels:** [`DISTRIBUTION_CHANNELS.md`](DISTRIBUTION_CHANNELS.md)  
**KB:** ADR-008 (amended), `Feature-V2-Lock-Screen-Research`

---

## 1. Purpose

Define how Personal Wallpaper Engine ships on the **Mac App Store** under a phased launch, while keeping a **single trunk** and **build flavors** for future Direct and Steam releases.

| Milestone | Product outcome | Tag (planned) |
|-----------|-----------------|---------------|
| **M1** | Phases 1–9 desktop engine + MAS compliance | `v1.0` |
| **M2** | Tier A (static lock export) + Tier B (video screensaver) | `v1.1` |
| **M3** | Direct DMG flavor (out of this charter) | See [`V2_2_DIRECT_IMPLEMENTATION.md`](V2_2_DIRECT_IMPLEMENTATION.md) |

---

## 2. Branching and flavor policy

### Adopted

- **One trunk:** `main`
- **Short-lived feature branches** that merge and delete:
  - `feature/mas-compliance` (M1)
  - `feature/tier-a-b` (M2)
- **Build flavors** via schemes + `.xcconfig` + entitlements + `#if` compile flags
- **Releases as tags**, not long-lived channel branches

### Rejected

- Permanent `app-store`, `direct`, or `steam` branches that diverge over time

### Why

~90%+ of the product is shared. Tier A and Tier B are **universal** (all channels). Channel deltas (updates UI, Tier C, sandbox for Steam, Steamworks) are thin and belong behind flags. Permanent forks force triple cherry-picks for every engine fix.

### Flavor matrix (target)

| Scheme | Flag | Sandbox | Tier A/B | Tier C | Updates |
|--------|------|---------|----------|--------|---------|
| `PWE App Store` | `APP_STORE_BUILD` | Yes | Yes (M2) | **No** | App Store |
| `PWE Direct` | `DIRECT_BUILD` | Yes | Yes (M2) | Conditional (M3) | Sparkle (M3) |
| `PWE Steam` | `STEAM_BUILD` | **No** | Yes (if shipped) | Conditional | Steam |

**Today:** `PWE App Store` scheme + `Release-AppStore` configuration ship M1; Direct uses `Direct.xcconfig` (`DIRECT_BUILD`); Steam scheme deferred.

```swift
#if APP_STORE_BUILD
  // MAS: no external update URL; no Tier C; optional tip IAP
#elseif DIRECT_BUILD
  // Direct: Sparkle + tip link + conditional Tier C (M3)
#elseif STEAM_BUILD
  // Steam: later; unsandboxed + Steamworks
#endif
```

---

## 3. Milestone 1 — Compliance (**implemented** 2026-08-20)

### Goals

Ship a review-safe Mac App Store build of the existing Phases 1–9 product.

### File / project touch list (done)

| Item | Action |
|------|--------|
| `Configurations/AppStore.xcconfig` | **Done** — `APP_STORE_BUILD`, export compliance |
| `Configurations/Direct.xcconfig` | **Done** — `DIRECT_BUILD`, `REGISTER_APP_GROUPS=NO` |
| Xcode scheme `PWE App Store` | **Done** — archives `Release-AppStore` |
| `Personal Wallpaper Engine AppStore.entitlements` | **Done** — sandbox + files + bookmarks + **network.client** |
| `PrivacyInfo.xcprivacy` | **Done** — no tracking, no collected data types |
| `UpdateChecker.swift` | **Done** — `#if !APP_STORE_BUILD` for external updates |
| `SettingsTabView.swift` | **Done** — MAS update copy; web file importer |
| `WebWallpaperURLValidator.swift` + `WebRenderer.swift` | **Done** — https/file allowlist + nav delegate |
| `docs/M1_COMPLIANCE_CHECKLIST.md`, `docs/WEB_WALLPAPERS.md` | **Done** |
| CI / local QA | **Done** — regression, tests, Release-AppStore build |

### Explicitly not in M1

- Tier A / Tier B / Tier C application code
- Sparkle
- App Group / `.saver` target
- Steamworks
- Permanent channel git branches

### Acceptance criteria

- [x] `feature/mas-compliance` merged to `main`; branch deleted
- [ ] Release **PWE App Store** archive validates in Organizer / Transporter (owner, signed)
- [x] No external update URL reachable in MAS binary
- [x] `PrivacyInfo.xcprivacy` present in app bundle
- [x] Engineering rows in [`PRE_RELEASE_CHECKLIST.md`](PRE_RELEASE_CHECKLIST.md) / [`M1_COMPLIANCE_CHECKLIST.md`](M1_COMPLIANCE_CHECKLIST.md)
- [ ] Owner sign-off on [`V1_SIGNOFF.md`](V1_SIGNOFF.md) M1 row (Connect upload)
- [ ] Upload to App Store Connect complete per [`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md)

---

## 4. Milestone 2 — Tier A + Tier B (code not started)

### Goals

Competitive fast-follow for App Store and shared foundation for Direct.

Research sources:

- Tier A: [`PHASE_10C_LOCK_SCREEN_RESEARCH.md`](PHASE_10C_LOCK_SCREEN_RESEARCH.md)
- Tier B: [`PHASE_10B_SCREENSAVER_RESEARCH.md`](PHASE_10B_SCREENSAVER_RESEARCH.md)

### File / project touch list (planned)

| Item | Action |
|------|--------|
| App Group entitlement | Main app + `.saver`; fix orphan `REGISTER_APP_GROUPS` without plist |
| `.saver` target | `ScreenSaverView` + AVPlayer loop; App Group config read |
| Lock export UI | Frame capture → Pictures (or user folder) → guided System Settings |
| Settings section | “Lock Screen & Screen Saver” — no Tier C copy on MAS |
| Optional tip IAP | MAS only |
| Regression notes | Extend PRE_RELEASE / production checklist for saver + export |

### Acceptance criteria

- [ ] `feature/tier-a-b` merged to `main`; branch deleted
- [ ] Tier A export works on single- and multi-display setups
- [ ] Tier B preview and idle playback read App Group state after relaunch
- [ ] MAS binary still excludes Tier C and external update URLs
- [ ] App Store update (v1.1) screenshots and notes updated
- [ ] Owner sign-off on V1_SIGNOFF M2 row

---

## 5. Competitive positioning (App Store)

| Strength (ship M1) | Gap until M2 | Permanent MAS gap |
|--------------------|--------------|-------------------|
| Deep multi-display, collections, setups | Static lock export | Lock-screen **live** video (Tier C) |
| Local library + quick modes + menu bar | Video screensaver | — |
| Explicit power / performance profiles | — | — |
| Free, local-first, no account | — | — |

Store copy must not claim lock-screen live video. After Direct ships, marketing may mention Direct-only Tier C — never on the App Store listing.

---

## 6. Guidelines and standards

Implementation (when started) must follow:

- Repo [`guidelines.md`](../guidelines.md) and [`best_coding_practices.md`](../best_coding_practices.md)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) — especially 2.x performance, 3.1 payments, 5.1 privacy
- Sandbox + Hardened Runtime retained on MAS
- No private APIs in MAS flavor
- Accessibility / Reduce Motion patterns already used in UI (preserve)
- Prefer smallest diffs; no drive-by refactors outside flavor/compliance scope

---

## 7. Definition of done for this documentation phase

This charter is **done** when:

- Part 3 exists in `version2_developmental_roadmap.md`
- Submission, privacy, Direct stub, and channel docs reflect App Store–first + trunk/flavors
- KB ADR-008 amended; master plan and changelog updated

**Next action after docs:** Start M1 engineering on `feature/mas-compliance` (not part of this documentation pass).

---

## References

- [`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md)
- [`DISTRIBUTION.md`](DISTRIBUTION.md)
- [`DISTRIBUTION_CHANNELS.md`](DISTRIBUTION_CHANNELS.md)
- [`PHASE_10_SUMMARY.md`](PHASE_10_SUMMARY.md)
- [`PRE_RELEASE_CHECKLIST.md`](PRE_RELEASE_CHECKLIST.md)
- [`V2_2_DIRECT_IMPLEMENTATION.md`](V2_2_DIRECT_IMPLEMENTATION.md)
