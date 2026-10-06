# Pre-launch status — Deskface (Mac App Store v1.0)

**Purpose:** Single go/no-go page before Xcode Archive and App Store Connect submission.  
**Last updated:** 2026-10-01  
**Store name:** Deskface · **Bundle ID:** `Personal.Personal-Wallpaper-Engine` · **Build in review:** `1.0 (2)`

When documents disagree, this page and the [doc hierarchy](#doc-hierarchy) table win for launch readiness.

---

## Verdict: Waiting for Review

Deskface **1.0 (2)** was resubmitted **2026-10-01** after the Guideline 2.3.8 and 1.5 rejection. The hosted support page is live and the Connect Support URL points at it. App Review has the build. **Next:** monitor Resolution Center. Do not record an approval date until Apple approves.

---

## Completed gates

| Gate | Status | Evidence |
|------|--------|----------|
| **Engineering (M1)** | **Complete** | [`M1_COMPLIANCE_CHECKLIST.md`](M1_COMPLIANCE_CHECKLIST.md) — merged to `main` 2026-08-20; display-bound fix 2026-08-28/29 |
| **Owner manual QA** | **Complete** | [`PRE_RELEASE_CHECKLIST.md`](PRE_RELEASE_CHECKLIST.md) — signed off **2026-08-29** |
| **Unit tests (92)** | **Complete** | Owner `Cmd+U` **P** 2026-08-29; inventory in [`TESTING.md`](TESTING.md) — re-run after Support URL / naming changes |
| **Regression script** | **Complete** | Owner `chunk7_regression.sh` **P** **2026-08-31** (Debug + Release build, smoke, XCTest) |
| **Hosted URLs** | **Complete** | Privacy, landing, and **Support** (`…/support/`) live; Connect Support URL updated |
| **2.3.8 installed name** | **Complete (eng)** | `CFBundleDisplayName` + `CFBundleName` = Deskface; Release-AppStore `PRODUCT_NAME` = Deskface |
| **App Store copy** | **Complete** | [`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md) — paste-ready metadata + Resolution Center reply |

---

## Resubmit checklist (done 2026-10-01)

1. Support page live at `https://arnavaggarwal2007.github.io/MacOS-Wallpaper-Engine/support/`
2. App Store Connect Support URL set to that page
3. Archived scheme **`PWE App Store`**, build **1.0 (2)**, validated, and uploaded
4. Resolution Center reply sent; listing name remains **Deskface**; bundle ID unchanged
5. **Submitted for Review** — status **Waiting for Review**

## After approval

Update [`V1_SIGNOFF.md`](V1_SIGNOFF.md) with the App Review approval date. That date is still open.

---

## Go/no-go checklist

- [x] Engineering + owner QA complete (this page)
- [x] Regression gate (`chunk7_regression.sh`) — owner **P** 2026-08-31
- [x] Installed name + Support URL eng fixes landed (2026-09-25)
- [x] Support page live on GitHub Pages
- [x] Build **1.0 (2)** submitted — **Waiting for Review** (2026-10-01)
- [ ] App Review approval recorded in [`V1_SIGNOFF.md`](V1_SIGNOFF.md)

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
