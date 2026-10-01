# Pre-launch status — Deskface (Mac App Store v1.0)

**Purpose:** Single go/no-go page before Xcode Archive and App Store Connect submission.  
**Last updated:** 2026-09-25  
**Store name:** Deskface · **Bundle ID:** `Personal.Personal-Wallpaper-Engine` · **Build for resubmit:** `1.0 (2)`

When documents disagree, this page and the [doc hierarchy](#doc-hierarchy) table win for launch readiness.

---

## Verdict: GO for owner resubmit (2.3.8 + 1.5 fixes)

Engineering, owner manual QA, and the automated regression gate are **complete**. Naming and Support URL fixes for the **2026-09-17** rejection are landed in-repo. Remaining work is **owner-only**: push Pages, set Connect Support URL, archive build **2**, reply in Resolution Center, Submit.

---

## Completed gates

| Gate | Status | Evidence |
|------|--------|----------|
| **Engineering (M1)** | **Complete** | [`M1_COMPLIANCE_CHECKLIST.md`](M1_COMPLIANCE_CHECKLIST.md) — merged to `main` 2026-08-20; display-bound fix 2026-08-28/29 |
| **Owner manual QA** | **Complete** | [`PRE_RELEASE_CHECKLIST.md`](PRE_RELEASE_CHECKLIST.md) — signed off **2026-08-29** |
| **Unit tests (92)** | **Complete** | Owner `Cmd+U` **P** 2026-08-29; inventory in [`TESTING.md`](TESTING.md) — re-run after Support URL / naming changes |
| **Regression script** | **Complete** | Owner `chunk7_regression.sh` **P** **2026-08-31** (Debug + Release build, smoke, XCTest) |
| **Hosted URLs** | **Complete (eng)** | Privacy + landing live; **Support** page at [`support/index.html`](support/index.html) — owner must push and verify live |
| **2.3.8 installed name** | **Complete (eng)** | `CFBundleDisplayName` + `CFBundleName` = Deskface; Release-AppStore `PRODUCT_NAME` = Deskface |
| **App Store copy** | **Complete** | [`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md) — paste-ready metadata + Resolution Center reply |

---

## Remaining before Submit (owner only)

Complete in order — detailed walkthrough in [`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md) §Owner runway and §9:

1. Push `main` → confirm `https://arnavaggarwal2007.github.io/MacOS-Wallpaper-Engine/support/` loads
2. App Store Connect → App Information → Support URL = hosted `/support/` page (not GitHub Issues)
3. **Archive** scheme **`PWE App Store`** (build **1.0 (2)**) → **Validate App** → **Distribute** to Connect
4. Verify archive: Deskface display/short name + `Deskface.app`; bundle ID unchanged
5. Attach build; paste Resolution Center reply ([`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md) §7)
6. **Submit for Review**
7. After approval: update [`V1_SIGNOFF.md`](V1_SIGNOFF.md) M1 Connect row

---

## Go/no-go checklist

Proceed to Xcode/Connect when:

- [x] Engineering + owner QA complete (this page)
- [x] Regression gate (`chunk7_regression.sh`) — owner **P** 2026-08-31
- [x] Installed name + Support URL eng fixes landed (2026-09-25)
- [ ] Support page live on GitHub Pages (owner push + browser check)
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
