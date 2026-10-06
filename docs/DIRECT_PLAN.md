# V2.2 Direct Distribution Implementation (Stub)

**Status:** Deferred stub (2026-08-20) — **do not start until App Store Milestone 1 is submitted and Milestone 2 is underway or complete**  
**Launch order:** Mac App Store first → Direct DMG second  
**Trunk policy:** Same `main` + `DIRECT_BUILD` flavor — **no** permanent `direct` git branch  
**Charter (App Store):** [`V2_2_APP_STORE_IMPLEMENTATION.md`](V2_2_APP_STORE_IMPLEMENTATION.md)  
**How-to (existing):** [`DISTRIBUTION.md`](DISTRIBUTION.md)

---

## 1. Purpose

Describe the **Direct (Developer ID + notarized DMG/zip)** flavor after App Store shipping. This document is a scope stub so the roadmap and KB stay aligned; it is not an active engineering track yet.

---

## 2. Why Direct comes after App Store

| Factor | Notes |
|--------|--------|
| Discovery / trust | App Store listing first |
| Policy | Direct can later enable **Tier C** (private API, opt-in) that MAS cannot ship |
| Updates | Sparkle 2 (or equivalent) — prohibited on MAS |
| Monetization | External tip links (Ko-fi / Sponsors) without IAP cut |

Universal Tier A/B from Milestone 2 **inherits automatically** on Direct when built from the same `main`.

---

## 3. Planned deliverables (Milestone 3)

| Item | Notes |
|------|--------|
| `Configurations/Direct.xcconfig` + `DIRECT_BUILD` | Day-to-day / release Direct scheme |
| `PWE Direct` scheme | Developer ID signing |
| Sparkle 2 | Replace `UpdateChecker` placeholder for auto-update |
| Notarization + DMG CI | Automate [`DISTRIBUTION.md`](DISTRIBUTION.md) on release tags |
| External tip link in About / Settings | Free + tips model |
| Tier C (conditional) | Only after macOS 26+ observational validation; feature-flagged; never compiled into `APP_STORE_BUILD` |
| Hosted privacy + EULA on website | Point Sparkle / download page here |

---

## 4. Explicit non-goals (this stub)

- Permanent `direct` branch
- Removing sandbox by default (keep sandbox unless Tier C research proves otherwise)
- Steamworks (separate Steam flavor only if committed)
- Shipping Tier C without a kill-switch and clear user risk disclosure

---

## 5. Acceptance criteria (when M3 starts)

- [ ] Direct Release scheme notarizes and staples
- [ ] Sparkle update path documented and tested
- [ ] MAS flavor still builds from same `main` without Tier C / Sparkle
- [ ] Tip link does not unlock paid features (compliance with spirit of free app)
- [ ] Docs: DISTRIBUTION.md, CHANNELS, README, changelog updated

---

## 6. References

- [`DISTRIBUTION.md`](DISTRIBUTION.md)
- [`DISTRIBUTION_CHANNELS.md`](DISTRIBUTION_CHANNELS.md) Appendix B
- [`PHASE_10C_LOCK_SCREEN_RESEARCH.md`](PHASE_10C_LOCK_SCREEN_RESEARCH.md) (Tier C)
- [`PHASE_10_SUMMARY.md`](PHASE_10_SUMMARY.md)
- KB ADR-008 (amended)
