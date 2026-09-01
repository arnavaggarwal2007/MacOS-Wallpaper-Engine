# Pre-launch status — Deskloop (Mac App Store v1.0)

**Purpose:** Single go/no-go page before Xcode Archive and App Store Connect submission.  
**Last updated:** 2026-08-31  
**Store name:** Deskloop · **Bundle ID:** `Personal.Personal-Wallpaper-Engine`

When documents disagree, this page and the [doc hierarchy](#doc-hierarchy) table win for launch readiness.

---

## Verdict: GO for owner distribution

Engineering, owner manual QA, and the automated regression gate are **complete**. Remaining work is **owner-only** Connect steps (signing, Validate, metadata, screenshots, Submit).

---

## Completed gates

| Gate | Status | Evidence |
|------|--------|----------|
| **Engineering (M1)** | **Complete** | [`M1_COMPLIANCE_CHECKLIST.md`](M1_COMPLIANCE_CHECKLIST.md) — merged to `main` 2026-08-20; display-bound fix 2026-08-28/29 |
| **Owner manual QA** | **Complete** | [`PRE_RELEASE_CHECKLIST.md`](PRE_RELEASE_CHECKLIST.md) — signed off **2026-08-29** |
| **Unit tests (92)** | **Complete** | Owner `Cmd+U` **P** 2026-08-29; inventory in [`TESTING.md`](TESTING.md) |
| **Regression script** | **Complete** | Owner `chunk7_regression.sh` **P** **2026-08-31** (Debug + Release build, smoke, XCTest) |
| **Hosted URLs** | **Complete** | GitHub Pages live; privacy + support verified 2026-08-29 |
| **App Store copy** | **Complete** | [`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md) — paste-ready metadata |

---

## Remaining before Submit (owner only)

Complete in order — detailed walkthrough in [`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md) §Owner runway and §9:

1. Xcode → Accounts → sign in; confirm **PWE App Store** scheme signing
2. App Store Connect → create **Deskloop** app record (if not already)
3. **Archive** → **Validate App** → **Distribute** to Connect
4. Connect → privacy nutrition labels, age rating **16+**, review notes (§3–5)
5. Attach **6 screenshots** (§6)
6. Select build → **Submit for Review**
7. After approval: update [`V1_SIGNOFF.md`](V1_SIGNOFF.md) M1 Connect row

---

## Go/no-go checklist

Proceed to Xcode/Connect when:

- [x] Engineering + owner QA complete (this page)
- [x] Regression gate (`chunk7_regression.sh`) — owner **P** 2026-08-31
- [ ] Apple Developer Program active (owner confirmed enrolled)
- [ ] You accept **16+** age rating (unrestricted web access for optional web wallpapers)

---

## Explicitly deferred post-launch

Not blockers for desktop-only MAS v1.0. Tracked in KB [`POST_LAUNCH_BACKLOG.md`](../../Wallpaper%20Engine%20KB/70%20Master%20Plan/POST_LAUNCH_BACKLOG.md):

- AppViewModel split / bookmark resolver unification
- Renderer path unification
- Setup schema v2
- Dynamic Type, localization
- Slot-based portable display-bound collections
- Orchestration-layer integration tests

Direct DMG / M2 lock-screen tiers / Steam — see [`DISTRIBUTION_CHANNELS.md`](DISTRIBUTION_CHANNELS.md).

---

## Doc hierarchy

| Topic | Canonical source |
|-------|------------------|
| **Launch readiness (this gate)** | `PRE_LAUNCH_STATUS.md` |
| Release checklist rows | `PRE_RELEASE_CHECKLIST.md` |
| M1 engineering matrix | `M1_COMPLIANCE_CHECKLIST.md` |
| Connect paste copy + owner steps | `APP_STORE_SUBMISSION.md` |
| Unit tests + agent policy | `TESTING.md`, `AGENTS.md` |
| UI / copy / naming | `DESIGN.md`, `UI_REFERENCE.md` |
| Roadmap | `README.md` |
| Architecture history | `Wallpaper Engine KB/` |

---

## Related

- [`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md)
- [`PRE_RELEASE_CHECKLIST.md`](PRE_RELEASE_CHECKLIST.md)
- [`M1_COMPLIANCE_CHECKLIST.md`](M1_COMPLIANCE_CHECKLIST.md)
- [`TESTING.md`](TESTING.md)
- [`README.md`](../README.md)
