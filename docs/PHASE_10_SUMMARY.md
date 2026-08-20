# Phase 10 — Executive Summary

**Date:** 2026-06-21 (research) · **Amended:** 2026-08-20 (launch order)  
**Status:** Research complete — no Phase 10 application code shipped  
**Next phase:** V2.2 Implementation — [`V2_2_APP_STORE_IMPLEMENTATION.md`](V2_2_APP_STORE_IMPLEMENTATION.md), roadmap Part 3

---

## 1. Phase 10 feature conclusions

| Tier | Feature | Feasibility | Recommended path |
|------|---------|-------------|------------------|
| **A** | Static lock-screen image export | Conditional GO | Ship on **all channels** (V2.2 Milestone 2) |
| **B** | Video screensaver (`.saver`) | GO | Ship on **all channels**; App Store's strongest Phase 10 feature |
| **C** | Lock-screen live video | Conditional GO | **Direct + Steam only**; disable on App Store |

Deep dives: [`PHASE_10A_FEASIBILITY.md`](PHASE_10A_FEASIBILITY.md), [`PHASE_10B_SCREENSAVER_RESEARCH.md`](PHASE_10B_SCREENSAVER_RESEARCH.md), [`PHASE_10C_LOCK_SCREEN_RESEARCH.md`](PHASE_10C_LOCK_SCREEN_RESEARCH.md)

---

## 2. Distribution channel priority (amended 2026-08-20)

### Launch order (current)

| Role | Channel | Rationale |
|------|---------|-----------|
| **First ship** | **Mac App Store** | Discovery + trust; Tier A+B only; phased M1 compliance → M2 features |
| **Second** | **Direct DMG/zip** | Full ceiling including conditional Tier C + Sparkle + external tips |
| **Later / optional** | Steam | Only if Steamworks + Workshop commitment; unsandboxed flavor |

### Historical research recommendation (2026-06-21)

Phase 10 scored **Direct** highest for free + tips and full Tier A/B/C ceiling. That analysis remains valid for **feature completeness**. Product decision for **launch order** is now **App Store first**, then Direct. See ADR-008 amendment and [`DISTRIBUTION_CHANNELS.md`](DISTRIBUTION_CHANNELS.md) § Current channel priority.

### Architecture (unchanged)

**Trunk + build flavors** — not three permanent git branches. Shared core on `main`; schemes / xcconfigs / `#if` flags per channel.

Full analysis: [`DISTRIBUTION_CHANNELS.md`](DISTRIBUTION_CHANNELS.md)

---

## 3. Feature × channel matrix (condensed)

| Feature | App Store | Direct | Steam |
|---------|-----------|--------|-------|
| Desktop engine (Ph 1–9) | Yes (M1) | Yes | Yes |
| Tier A static lock | Yes (M2) | Yes (M2) | Yes |
| Tier B screensaver | Yes (M2) | Yes (M2) | Yes |
| Tier C lock live video | **No** | Conditional (M3+) | Conditional |
| Free + tips | Caveats (IAP) | **Best** | Caveats |
| Workshop (future) | No | Costly | Best fit |

---

## 4. Current vs delta

### App Store (first ship)

| Already have | Must add in V2.2 |
|--------------|------------------|
| Sandboxed desktop engine (Ph 1–9) | `APP_STORE_BUILD` flavor + MAS signing (M1) |
| — | `PrivacyInfo.xcprivacy` (M1) |
| `UpdateChecker` opens GitHub | Disable on MAS flavor (M1) |
| No App Group / `.saver` | Add for Tier B (M2) |
| No lock export UI | Tier A (M2) |
| Single build flavor | Multi-scheme on same `main` |

### Direct (second ship)

| Already have | Must add later |
|--------------|----------------|
| Notarization docs ([`DISTRIBUTION.md`](DISTRIBUTION.md)) | Sparkle 2 + CI release pipeline |
| Sandboxed engine | Direct scheme; tip link; conditional Tier C |

Stub: [`V2_2_DIRECT_IMPLEMENTATION.md`](V2_2_DIRECT_IMPLEMENTATION.md)

---

## 5. Monetization

**Decision:** Ship **free** on all channels. **Optional tips** — external links on Direct/Steam; IAP tip jar optional on App Store (M2+).

Paid tier **not required** for v1.

Details: [`DISTRIBUTION_CHANNELS.md`](DISTRIBUTION_CHANNELS.md) §7

---

## 6. Future roadmap constraints

| Feature | Direct | App Store | Steam |
|---------|--------|-----------|-------|
| iCloud sync | Custom/none | CloudKit | Steam Cloud |
| Workshop | Self-host costly | Blocked | Native fit |
| V2.1 CPU graphs | Yes | Yes | Yes |

Use **V2.2** naming for lock-screen/screensaver implementation to avoid collision with KB Phase 11 (iCloud).

---

## 7. V2.2 Implementation charter (amended)

| Item | Plan |
|------|------|
| **First channel** | **Mac App Store** (phased) |
| **Second channel** | Direct DMG |
| **Features** | M1 compliance → M2 Tier A+B (universal) → M3 Direct Sparkle/Tier C |
| **Build model** | One trunk + flavors; **no** permanent channel branches |
| **Monetization** | Free; optional tip IAP (MAS) / tip link (Direct) |
| **Estimate** | M1 ~1–2 weeks eng; Tier A+B ~15–20 days; Tier C +15–25 days (high uncertainty) |
| **Prerequisites** | Privacy manifest, MAS flavor flags; later App Group, `.saver`, Sparkle |

Charters: [`V2_2_APP_STORE_IMPLEMENTATION.md`](V2_2_APP_STORE_IMPLEMENTATION.md), [`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md)

---

## 8. Phase 10 deliverables (complete)

| Document | Purpose |
|----------|---------|
| [`PHASE_10A_FEASIBILITY.md`](PHASE_10A_FEASIBILITY.md) | Universal feasibility |
| [`PHASE_10B_SCREENSAVER_RESEARCH.md`](PHASE_10B_SCREENSAVER_RESEARCH.md) | Screensaver research |
| [`PHASE_10C_LOCK_SCREEN_RESEARCH.md`](PHASE_10C_LOCK_SCREEN_RESEARCH.md) | Lock-screen research |
| [`DISTRIBUTION_CHANNELS.md`](DISTRIBUTION_CHANNELS.md) | Three-channel strategy |
| [`PHASE_10_SUMMARY.md`](PHASE_10_SUMMARY.md) | This document |
| KB ADR-007, ADR-008 | Decisions recorded in vault (ADR-008 amended 2026-08-20) |

---

## 9. ADR references

- KB `ADR-007-Lock-Screen-Screensaver-Research`
- KB `ADR-008-Distribution-Channel-Strategy` (amended: App Store launch first; trunk + flavors)

---

## 10. macOS 26 research gap

No macOS 26 hardware available during Phase 10. Tier C implementation must begin with observational analysis on GA before selecting a private integration path. See [`PHASE_10A_FEASIBILITY.md`](PHASE_10A_FEASIBILITY.md) §10A.4. Tier C remains **Direct/Steam only**.
