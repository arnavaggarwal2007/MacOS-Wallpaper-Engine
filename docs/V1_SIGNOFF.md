# Version 1 Sign-Off

**Date:** 2026-06-21 (Phase 1–9 audit update)  
**Build:** Release verified 2026-06-01; audit hardening 2026-06-21  
**Scope:** Phases 1–6B + UI final vision + V2 Phases 7–9  
**Gate:** V1 + **Phases 7–9 complete (9A–9B)**. **Phase 10 research complete** (2026-06-21). **V2.2 docs / App Store–first charter complete** (2026-08-20) — see [`PHASE_10_SUMMARY.md`](PHASE_10_SUMMARY.md), [`V2_2_APP_STORE_IMPLEMENTATION.md`](V2_2_APP_STORE_IMPLEMENTATION.md).  
**Knowledge base:** Sibling `Wallpaper Engine KB/` — `10 Project Home.md`, `KB-Guide.md`, ADR-008.

---

## Sign-off summary

| Area | Status | Notes |
|------|--------|-------|
| Automated build & smoke | **Pass** | `chunk7_regression.sh` — build, smoke, unit tests (2026-08-28) |
| UI revamp validation | **Pass** | User verified May 20, 2026 |
| Functional matrix (manual) | **Pass** | Owner full PRE_RELEASE matrix **P** (2026-08-29); Phase 9 matrix **P** (2026-06-21) |
| Phase 7B engine efficiency | **Pass** | [`PERFORMANCE_TUNING.md`](PERFORMANCE_TUNING.md) |
| Phase 7C diagnostics UI | **Pass** | Per-core + system-wide CPU display |
| Phase 7D–7G | **Pass** | Release 12-row benchmark matrix |
| Phase 8 local library | **Pass** | [`PHASE_8_LIBRARY.md`](PHASE_8_LIBRARY.md) |
| Phase 9 quick modes + menu bar | **Pass** | [`PHASE_9_REGRESSION.md`](PHASE_9_REGRESSION.md) — all rows **P** |
| XCTest unit suite | **Pass (expanded)** | Display mapping, migration, collections, SettingsStore — see [`TESTING.md`](TESTING.md) |
| Distribution docs | **Pass** | [`DISTRIBUTION.md`](DISTRIBUTION.md), [`DISTRIBUTION_CHANNELS.md`](DISTRIBUTION_CHANNELS.md), [`PRE_RELEASE_CHECKLIST.md`](PRE_RELEASE_CHECKLIST.md), V2.2 App Store charters (2026-08-20) |

**Recommendation:** Phases 1–9 **complete and hardened** as the App Store Milestone 1 product baseline. **Owner manual QA complete (2026-08-29).** Engineering and product sign-off are done; **Connect upload remains owner-gated** — follow [`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md). Phase 10 research complete; **launch order:** App Store first, then Direct — [`DISTRIBUTION_CHANNELS.md`](DISTRIBUTION_CHANNELS.md) §0.

---

## V2.2 distribution milestones (sign-off tracking)

| Milestone | Scope | Status | Date |
|-----------|--------|--------|------|
| Docs / charter (trunk + flavors, App Store first) | Roadmap Part 3 + submission/privacy docs | **Pass** | 2026-08-20 |
| M1 — Mac App Store compliance + submit v1.0 | Flavor, privacy manifest, Connect | Engineering **Pass** (2026-08-28); Owner QA **Pass** (2026-08-29); Connect upload **Owner pending** | 2026-08-29 |
| M2 — Tier A + Tier B (v1.1) | Lock export + screensaver | Pending | |
| M3 — Direct DMG | Sparkle + tip link + conditional Tier C | Deferred | |

## Automated verification

| Check | Command | Result | Date |
|-------|---------|--------|------|
| Debug smoke build | `CODE_SIGNING_ALLOWED=NO ./scripts/chunk7_smoke.sh` | Pass | 2026-05-22 |
| CI regression | `chunk7_regression.sh` | Pass | 2026-06-01 |
| CI unit tests | `chunk7_regression.sh` (XCTest) | Pass | 2026-08-28 |
| Phase 9 close-out Debug build | `xcodebuild` Debug | Pass | 2026-06-09 |
| Unit tests (owner Cmd+U) | Xcode Test | Pass | 2026-08-29 |
| Manual QA (PRE_RELEASE full matrix) | Owner hardware | Pass | 2026-08-29 |
| M1 Release-AppStore build | `PWE App Store` / `Release-AppStore` | Pass | 2026-08-20 |
| M1 regression | `chunk7_regression.sh` | Pass | 2026-08-20 |
| Phase 1–9 audit build | `chunk7_regression.sh` | Pass | 2026-06-21 |

---

## Functional sign-off (high priority)

Legend: **P** = Pass, **D** = Defer, **F** = Fail.

### Phase 9 (quick modes + menu bar)

| Test | Status | Notes |
|------|--------|-------|
| Quick Mode selector + all modes | **P** | [`PHASE_9_REGRESSION.md`](PHASE_9_REGRESSION.md) |
| Hero stable after mode switch | **P** | Owner + audit 2026-06-09/21 |
| Setup pin/unpin + sidebar persistence | **P** | |
| Menu bar controls + activation | **P** | |
| Settings scope (video on Home only) | **P** | |

### Deferred / extended matrix

Full 1-hour soak tests in [`PRODUCTION_TEST_CHECKLIST.md`](../PRODUCTION_TEST_CHECKLIST.md) remain **D** unless App Store submission requires them.

---

## Performance baseline

**Test asset:** 1080p H.264 MP4 wallpaper loop (same file for all rows)  
**Machine:** Apple Silicon Mac, **12 logical cores**, macOS 15+  
**Build:** Release (2026-06-01 canonical matrix)

### CPU scale

All **Per-core** values use Activity Monitor / `ps` semantics (100% = one logical core). **System-wide** = per-core ÷ 12.

### Results table (Release, Phase 7 closeout)

| Scenario | Power | Per-core CPU (avg) | System-wide (÷12) | Memory (MB) | Notes |
|----------|-------|-------------------|-------------------|-------------|-------|
| 2 disp, same 1080p, coalesced, unfocused, Balanced | AC | **13.75%** | **~1.15%** | — | Canonical row 1 |
| 2 disp, same 1080p, coalesced, unfocused, Max Quality | AC | 14.17% | ~1.18% | — | Release matrix |
| 2 disp, same 1080p, coalesced, unfocused, Battery Saver | AC | 13.80% | ~1.15% | — | Release matrix |
| 2 disp, both covered, unfocused, Balanced | AC | 6.67% | ~0.56% | — | Visibility pause |
| Debug, 2 disp, coalesced, unfocused, Balanced | AC | 2.5% | ~0.21% | — | 7B desktop-only row |

Source: [`PERFORMANCE_TUNING.md`](PERFORMANCE_TUNING.md) § Phase 7 Closeout.

### Competitor reference (marketing, same per-core scale)

| App | Claimed CPU (typical) | Notes |
|-----|------------------------|-------|
| Wallspace | ~&lt;2% per-core | Marketing |
| Wallux | ~0.2% per-core | Ideal conditions |
| PWE Release canonical | ~13.75% per-core (~1.15% system on 12 cores) | Competitive when scale understood |

---

## Known gaps (accepted post Phase 9)

- Lock-screen / screensaver — Phase 10 **research complete**; implementation V2.2 M2 — [`PHASE_10_SUMMARY.md`](PHASE_10_SUMMARY.md), [`V2_2_APP_STORE_IMPLEMENTATION.md`](V2_2_APP_STORE_IMPLEMENTATION.md)
- ~~Mac App Store flavor / privacy manifest~~ — **closed** by V2.2 M1 (2026-08-20): sandbox entitlements, `PrivacyInfo.xcprivacy`, build flavors, and update gating all shipped
- Collection rotation / playlists — V2.1
- Sparkle auto-update — Direct M3 ([`V2_2_DIRECT_IMPLEMENTATION.md`](V2_2_DIRECT_IMPLEMENTATION.md)); MAS uses App Store updates
- Community wallpaper platform — out of local-first scope

---

## Approvals

| Role | Name | Date |
|------|------|------|
| Engineering | Phase 1–9 audit | 2026-06-21 |
| Engineering | V2.2 documentation / charter | 2026-08-20 |
| Product / owner | | |

---

## References

- [`PRE_RELEASE_CHECKLIST.md`](PRE_RELEASE_CHECKLIST.md)
- [`DISTRIBUTION.md`](DISTRIBUTION.md)
- [`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md)
- [`V2_2_APP_STORE_IMPLEMENTATION.md`](V2_2_APP_STORE_IMPLEMENTATION.md)
- [`PHASE_9_REGRESSION.md`](PHASE_9_REGRESSION.md)
- [`PERFORMANCE_TUNING.md`](PERFORMANCE_TUNING.md)
