# Phase 10A — Feasibility Research

**Status:** Complete (2026-06-21)  
**Scope:** Channel-agnostic feasibility for lock-screen and screensaver features  
**Related:** [`PHASE_10B_SCREENSAVER_RESEARCH.md`](PHASE_10B_SCREENSAVER_RESEARCH.md), [`PHASE_10C_LOCK_SCREEN_RESEARCH.md`](PHASE_10C_LOCK_SCREEN_RESEARCH.md), [`DISTRIBUTION_CHANNELS.md`](DISTRIBUTION_CHANNELS.md)

---

## 1. Executive summary

Personal Wallpaper Engine (PWE) Phases 1–9 deliver a production-ready **desktop** video/web wallpaper engine. Phase 10 researched extending that capability to **lock screen** and **screensaver** surfaces, and how those features interact with three distribution channels.

| Tier | Feature | Feasibility | Recommendation |
|------|---------|-------------|----------------|
| **A** | Static lock-screen image export | **Conditional GO** | Implement first; App Store–friendly |
| **B** | Video screensaver (`.saver`) | **GO** | Public API; companion app + App Group pattern |
| **C** | Lock-screen live video | **Conditional GO** (Direct/Steam only) | No public API; private paths fragile; blocked on App Store |

**Primary differentiator across distribution channels:** Tier C availability. App Store builds cannot ship private-API lock-screen video without high rejection risk. Direct and Steam can pursue Tier C on macOS 26+ at maintainer's risk.

**Desktop engine baseline:** No blockers for extension targets. Reuse of `VideoRenderer` / AVPlayer logic is architecturally sound; screensaver runs in a separate process (`legacyScreenSaver.appex`) requiring App Group shared state.

---

## 2. Tier feasibility ratings

### Tier A — Static lock-screen frame

**Rating: Conditional GO**

| Aspect | Finding |
|--------|---------|
| Public APIs | No single API sets lock-screen video. Static images can be exported and user-applied via System Settings → Wallpaper, or via helper that writes to a known export location with user guidance. |
| macOS versions | macOS 15+: export + manual apply viable. macOS 26+: System may expose richer wallpaper surfaces; observe in 10A.4. |
| User workflow | App exports current frame (or selected still) → user picks in System Settings, or future shortcut opens Wallpaper pane. |
| Risk | Low technical risk; UX friction (not one-click like Wallspace Pro). |
| Competitors | Wallspace offers static lock image as fallback when live video unavailable. |

**Evidence:** Apple documents desktop wallpaper via `NSWorkspace.shared.setDesktopImageURL` for **desktop** only—not lock screen. Lock-screen imagery is managed by `WallpaperAgent` / System Settings without a documented third-party setter for arbitrary images on all OS versions.

### Tier B — Video screensaver

**Rating: GO**

| Aspect | Finding |
|--------|---------|
| Public APIs | `ScreenSaverView` (ScreenSaver framework) is a documented, supported extension point. |
| Process model | `.saver` bundles run inside `legacyScreenSaver.appex` with **host sandbox**, not the main app's entitlements. |
| Companion pattern | Main app manages video library; `.saver` reads shared paths via **App Group** container (Aerial, pond, and similar apps use this pattern). |
| macOS versions | macOS 15+ supported. |
| Risk | Medium maintenance (separate target, App Group sync); low rejection risk on App Store if no private APIs. |

**Evidence:** [Apple Screen Saver documentation](https://developer.apple.com/documentation/screendialog); open-source Aerial documents companion app + `.saver` + shared container.

### Tier C — Lock-screen live video

**Rating: Conditional GO (non–App Store only)**

| Aspect | Finding |
|--------|---------|
| Public APIs | **None** for third-party live video on lock screen as of macOS 15–26 public SDK. |
| Competitor techniques | Observed (not endorsed for App Store): private `WallpaperExtensionKit` usage, aerials manifest injection under `/Library/Application Support/com.apple.idleassetsd`, reverse-engineered WallpaperAgent hooks. |
| macOS 26 | Apple expanded dynamic wallpaper infrastructure; competitors (e.g. Wallspace, Backdrop) ship lock-screen video on recent betas—techniques remain private and OS-update fragile. |
| arm64 | Some private paths may be arm64-only; document universal binary impact in implementation phase. |
| Risk | **High:** OS updates can break silently; App Review rejection if detected; ethical/legal gray area for store distribution. |

**Evidence:** Wallpaper Engine (Windows) FAQ states no Mac port due to maintenance; Mac competitors ship lock-screen via non-public mechanisms. [Wallpaper Engine Linux/macOS FAQ](https://help.wallpaperengine.io/en/functionality/linuxmacos.html).

---

## 3. Risk register

| ID | Risk | Likelihood | Impact | Mitigation |
|----|------|------------|--------|------------|
| R1 | macOS update breaks Tier C private path | High | High | Feature flag; graceful disable; desktop-only fallback |
| R2 | App Store rejection (Tier C or undocumented behavior) | High (Tier C) | High | Ship Tier A+B only on MAS build flavor |
| R3 | Screensaver App Group sync failures | Medium | Medium | Validate container on launch; clear error in System Settings |
| R4 | User confusion (lock screen ≠ desktop) | Medium | Low | In-app copy; tier labeling in Settings |
| R5 | Maintenance burden (multi-flavor builds) | Medium | Medium | Shared core package; compile flags per channel |
| R6 | Steam sandbox incompatibility | Certain | Medium | Separate unsandboxed Steam target (documented in DISTRIBUTION_CHANNELS) |

---

## 4. Competitor technique taxonomy

| Product | Desktop video | Lock static | Lock live video | Screensaver | Distribution |
|---------|---------------|-------------|-----------------|-------------|--------------|
| **Wallspace** | Yes | Yes | Yes (Pro, macOS 26+) | Unknown | Direct (paid Pro) |
| **Backdrop** | Yes | Yes | Yes (recent macOS) | Yes | Direct |
| **Wallux** | Yes | Limited | Limited | Unknown | Direct |
| **Wallpaper Engine** | Yes (Windows) | N/A | N/A | N/A | Steam (Windows only) |
| **Vivid Walls** | Yes | Unknown | Unknown | Unknown | App Store (~$9.99) |
| **Aerial** | N/A | N/A | N/A | Yes (Apple TV aerials) | Direct + App Store |
| **PWE (current)** | Yes | No | No | No | Not shipped |

**Technique classes observed:**

1. **Public desktop overlay** — PWE current model (`DisplayController` + desktop-level window).
2. **Public screensaver** — `.saver` + App Group (Tier B).
3. **Static export** — User-mediated lock image (Tier A).
4. **Private lock extension** — WallpaperExtensionKit / idle assets / agent injection (Tier C).
5. **Steam Workshop** — UGC pipeline (future; not Phase 10 scope).

---

## 5. Desktop engine baseline (codebase)

Read-only analysis of Phases 1–9 for extension feasibility:

| Component | Location | Reuse for Tier B/C |
|-----------|----------|-------------------|
| `WallpaperManager` | `WallpaperManager.swift` | Logic patterns reusable; cannot run inside `.saver` process directly |
| `DisplayController` | `DisplayController.swift` | Desktop-specific; not applicable to lock screen |
| `VideoRenderer` / AVPlayer | Renderer stack | **Core reuse candidate** for `.saver` and possibly Tier C adapter |
| `WebRenderer` | WKWebView | Screensaver web wallpapers possible but heavy; defer |
| `SettingsStore` | UserDefaults + JSON | Needs App Group suite for `.saver` sync |
| Entitlements | App Sandbox, user-selected files, bookmarks | Screensaver needs App Group; Tier C may need unsandboxed flavor |

**Current entitlements** (`Personal Wallpaper Engine.entitlements`):

- `com.apple.security.app-sandbox` — true
- `com.apple.security.files.user-selected.read-only` — true
- `com.apple.security.files.bookmarks.app-scope` — true

**Lifecycle hooks already present:** `WallpaperManager` observes screen sleep/wake and lock/unlock notifications—useful for Tier C design (pause desktop on lock) even before lock-screen rendering exists.

---

## 6. macOS version gating matrix

| Capability | macOS 15 | macOS 26+ |
|------------|----------|-----------|
| Desktop video (current) | Yes | Yes |
| Tier A static export | Yes | Yes |
| Tier B screensaver | Yes | Yes |
| Tier C live lock (private API) | Unlikely / untested | Conditional (competitor activity) |
| Public Tier C API | No | No (as of research date) |

### 10A.4 — macOS 26 observations

**Research gap:** No macOS 26 hardware available in research environment at time of writing.

**Secondary sources:**

- Competitor release notes (Wallspace, Backdrop) cite lock-screen live wallpaper on macOS 26 betas.
- Apple continues to consolidate wallpaper management under System Settings and `WallpaperAgent`.
- `/Library/Application Support/com.apple.idleassetsd` remains system-managed; third-party injection is not public API.

**Recommendation:** Re-run observational checklist when macOS 26 GA hardware available:

1. WallpaperAgent process behavior during lock
2. Aerials / idle assets folder permissions
3. Competitor app entitlements and bundle IDs (read-only `codesign -d --entitlements`)
4. arm64 vs x86_64 behavior on Tier C tools

Document findings as addendum to this file and `PHASE_10C_LOCK_SCREEN_RESEARCH.md`.

---

## 7. GO/NO-GO matrix (implementation phase)

| Tier | Universal | Implement in V2.2? | App Store | Direct | Steam |
|------|-----------|-------------------|-----------|--------|-------|
| A | Conditional GO | Yes (first) | Enable | Enable | Enable |
| B | GO | Yes | Enable | Enable | Enable |
| C | Conditional GO | Yes (Direct/Steam only) | **Disable** | Conditional | Conditional |

---

## 8. Cross-references

- **Screensaver deep-dive:** [`PHASE_10B_SCREENSAVER_RESEARCH.md`](PHASE_10B_SCREENSAVER_RESEARCH.md)
- **Lock-screen deep-dive:** [`PHASE_10C_LOCK_SCREEN_RESEARCH.md`](PHASE_10C_LOCK_SCREEN_RESEARCH.md)
- **Distribution synthesis:** [`DISTRIBUTION_CHANNELS.md`](DISTRIBUTION_CHANNELS.md)
- **Executive summary:** [`PHASE_10_SUMMARY.md`](PHASE_10_SUMMARY.md)

---

## 9. Sources

- Apple Screen Saver framework documentation
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Steamworks macOS platform doc](https://partner.steamgames.com/doc/store/application/platforms)
- Wallpaper Engine official FAQ (no Mac Steam port)
- Repo: `WallpaperManager.swift`, `Personal Wallpaper Engine.entitlements`, `version2_developmental_roadmap.md`
