# Phase 1 — Verification Checklist

**Date:** 2026-05-20  
**Scope:** Fix broken existing features only (no new UI revamp).

## Code fixes applied

| Item | Change |
|------|--------|
| Hero preview vs playback | `AppViewModel.heroPreviewURL(forDisplayID:)`; `ModernHomeView` uses `resolvedHeroPreviewURL` |
| Web mode status | `updateRendererMode(.web)` shows accurate message |
| `WebRenderer.scalingMode()` | Tracks `currentScalingMode` from `setScalingMode` |
| ZStack hit-testing | Decorative gradients/spacers use `.allowsHitTesting(false)` on Home |
| Debug noise | `print` gated on `SettingsStore.debugDiagnosticsEnabled` |

## Automated build (run locally)

```bash
cd "/Users/arnev/Desktop/Personal Wallpaper Engine"
bash scripts/chunk7_smoke.sh
# optional:
bash scripts/chunk7_regression.sh
```

> **Note:** CI/agent environment may fail `xcodebuild` with IDESimulatorFoundation plugin errors. Run on your Mac after `xcodebuild -runFirstLaunch` if needed.

## Manual smoke matrix

| Test | Pass |
|------|------|
| Unified mode: choose video → hero preview matches applied wallpaper | ☐ |
| Per-display: carousel switch → hero updates for that display | ☐ |
| Apply wallpaper (unified) | ☐ |
| Apply wallpaper (per-display) | ☐ |
| Switch renderer to Web → status not “planned for next chunk” | ☐ |
| Web URL apply | ☐ |
| Collection apply from Collections tab | ☐ |
| Setup save + restore after relaunch | ☐ |
| Display carousel taps responsive (no blocked clicks) | ☐ |
| Window resize 800×600 → fullscreen without blocked controls | ☐ |

## Phase 1 exit

Proceed to **Phase 2b** when Phase 2a visual checks pass on a local build.

## Phase 2a visual checks (add after rebuild)

| Test | Pass |
|------|------|
| Home: no "Wallpaper Configuration" over utility bar | ☐ |
| Home: sidebar toggle, scaling menu, apply all visible | ☐ |
| Home: scroll down reveals display carousel (per-display) | ☐ |
| Collections: no large title over "Available Collections" | ☐ |
| Overlays feel translucent, hero visible through chrome | ☐ |
