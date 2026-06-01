# Performance tuning (Phase 7B)

**Purpose:** Track CPU/GPU/battery measurements and optimization experiments. Baseline copied from [`V1_SIGNOFF.md`](V1_SIGNOFF.md); all 7B changes compare against the same scenarios.

**Status:** Phase 7 **complete** (7A–7G, 2026-06-01). Phase 8 next.

**Reference clip (7B A/B):** 1080p H.264 MP4 — use the same file for every row (e.g. a typical wallpaper loop).

---

## How to measure

1. Apply wallpaper; let playback stabilize **30s**.
2. **Activity Monitor** → **Personal Wallpaper Engine** → View → Update Frequency: **Very Low (1 sec)**.
3. Record **% CPU**, **% GPU**, **Energy Impact**, **Memory** over **60s** (note avg or min/avg/max).
4. Optional: Xcode **Instruments** → Energy Log or Time Profiler.
5. For sign-off, add one **Release** build row (Debug inflates CPU ~10–20%).
6. Note in each row: **app focus**, **tab**, **hero active**, **P2 coalesced** (check logs for `attachments=2`), **clip resolution**, **build**.

**Canonical desktop-only row:** 2 displays, same 1080p file, Apply to All, app **unfocused**, both visible, 60s after 30s settle.

**Canonical product row:** Same setup but app **focused on Home** (includes hero decode — expect ~2× desktop-only cost).

---

## V1 / 7B “before” baseline (frozen)

Copied from V1 sign-off (pre–7B engine work).

| Scenario | Power | CPU % (avg) | GPU % (avg) | Energy | Memory (MB) | Notes |
|----------|-------|-------------|-------------|--------|-------------|-------|
| 1 display, playing, app on Home | AC | 4.9 | — | — | 450 | V1 recorded |
| 1 display, playing, app minimized | AC | 3.9 | — | — | 450 | V1 recorded |
| 2 displays, same video both | AC | 5.9 | — | — | 650 | V1 recorded |
| 1 display, playing | Battery | 4.9 | — | — | 450 | V1 recorded |
| 2 displays | Battery | 6.7 | — | — | 800 | V1 recorded |

---

## 7B re-measurement

| Scenario | Power | Profile | CPU % (avg) | Date | Build | Notes |
|----------|-------|---------|-------------|------|-------|-------|
| 1 display, AC, Home (pre-P0 Balanced) | AC | Balanced | 8 | 5/22 | Debug | Pre-P0 |
| 2 displays, AC (pre-P0) | AC | Balanced | 11 | 5/22 | Debug | Pre-P0 |
| 1 display, AC, Max Quality | AC | Max Quality | 5 | 5/22 | Debug | |
| 2 displays, AC, same file | AC | Balanced | 2.5 | 5/23 | Debug | Desktop-only; P2 coalesced |
| 2 displays, AC, same file | AC | Max Quality | 2.9 | 5/23 | Debug | Desktop-only; P2 coalesced |
| 2 displays, AC, same file | AC | Battery Saver | 2.3 | 5/23 | Debug | Desktop-only; P2 coalesced |
| 2 displays, AC, different files | AC | Balanced | 5.6 | 5/23 | Debug | 2× standalone |
| 1 display, AC, Home focused | AC | Balanced | 3.5 | 5/23 | Debug | Hero + desktop |
| 2 displays, home, app unfocused | AC | Balanced | 6.7 | 5/23 | Debug | Hero paused |
| 2 displays, home, app focused | AC | Balanced | 5.5 | 5/23 | Debug | Hero + desktop |
| 2 displays, app minimized | AC | Balanced | 5.6 | 5/23 | Debug | |
| 2 displays, collections tab | AC | Balanced | 5.9 | 5/23 | Debug | Hero paused (non-Home) |
| 2 displays, collections tab | AC | Max Quality | 6.4 | 5/23 | Debug | |
| 2 displays, app occluded | AC | Balanced | 5.5 | 5/23 | Debug | |
| 2 displays, one covered, unfocused | AC | Balanced | 7.3 | 5/23 | Debug | Per-display pause |
| 2 displays, one covered, focused | AC | Balanced | 6.6 | 5/23 | Debug | |
| 2 displays, both covered, unfocused | AC | Balanced | **0** | 5/23 | Debug | Full visibility pause |
| 2 displays, both covered, focused | AC | Balanced | 4 | 5/23 | Debug | Hero still live |
| 1 display, covered, unfocused | AC | Balanced | **0** | 5/23 | Debug | |
| 1 display, covered, focused | AC | Balanced | 4.3 | 5/23 | Debug | Hero still live |
| Max Quality vs Balanced, both covered | AC | Max 11.75% sm | Bal 6.67% sm | — | Release 2026-06-01 | Row 4 matrix |
| Reference scenario Release row | AC | Balanced | 13.75% sm | 2026-06-01 | Release | 2 disp same 1080p unfocused (row 1) |
| Release canonical per profile | AC | Max 14.17 / Bal 13.75 / Bat 13.8 | sm smoothed | 2026-06-01 | Release | 2 disp same 1080p unfocused (row 1) |
| 2 disp, 4K + different file, unfocused | AC | Max Quality | 9–12 (instant) | 5/20 | Debug | 2× decode; stress, not canonical |

### P6 evening session (5/23, Debug, often 4K clips)

| Scenario | CPU % (avg) | Profile | Notes |
|----------|-------------|---------|-------|
| 2 displays, different wallpapers, app focused | 6.3 | Balanced | 2× decode + hero |
| 2 displays, different wallpapers, app unfocused | 6.7 | Balanced | |
| 2 displays, same wallpapers, app focused | 5.0 | Balanced | Hero + desktop (may not be P2 coalesced) |
| 2 displays, different wallpapers, both covered, app focused | 3.7 | Balanced | Visibility pause active |
| 2 displays, different wallpapers, app focused | 7.1 | Max Quality | No visibility pause |
| 2 displays, different wallpapers, app unfocused | 6.5 | Max Quality | |
| 2 displays, same wallpapers, app focused | 6.3 | Max Quality | |
| 2 displays, different wallpapers, both covered, app focused | 5.4 | Max Quality | |

**P6 vs 2.5% row:** P6 “same wallpaper focused” (~5–6.3%) includes hero decode and often 4K sources; the 2.5% row is desktop-only with P2 coalesced on 1080p. Not a regression.

---

## Decode paths (what shares what)

| Path | Mechanism | When |
|------|-----------|------|
| **P2 multi-display** | One `AVPlayer` → N desktop layers (`SharedVideoPlaybackSession`) | Same file on all displays |
| **Standalone desktop** | One `AVPlayer` per display | Different files per display |
| **Hero preview** | Separate `AVPlayer` in `VideoPreviewView` | App focused on Home (P1b pauses when unfocused) |

P2 reduces **desktop** CPU (2.5% same-file 2 disp). Hero + desktop on 1 display Home is still double decode (~3.5% with P1b).

Launch/hotplug restore now coalesces after batch apply (7B closeout).

---

## Deferred optimizations (not in 7B)

| Optimization | Status | Target phase |
|--------------|--------|--------------|
| Seek-timer / timed FPS caps | **Rejected permanently** | — (+60% CPU) |
| Static hero (no live preview) | **Rejected permanently** | — (UX) |
| Unified hero + desktop single `AVPlayer` | **Complete (7D)** | — |
| Per-layer pause on shared session | Deferred | Phase 8+ |
| 4K → 1080p downscale on Battery Saver | **Complete (7E)** via `preferredMaximumResolution` | — |
| Balanced unfocus freeze-frame (current-frame snapshot vs `CMTime.zero` thumbnail) | Deferred | Post–V2 polish / Phase 10+ |
| `AVPlayerItemVideoOutput` manual frame stepping | Deferred | Research |
| Profile FPS caps via new engine mechanism | Deferred | Phase 9+ |
| Historical CPU graphs / export diagnostics | Deferred | Phase 10 |
| **Phase 7D — unified hero decode** | **Complete** | Phase 7D |
| **Phase 7E — profile decode tuning** | **Complete** | Phase 7E |
| **Phase 7G — hero attach stability closeout** | **Complete** | Phase 7G |

---

## Competitor reference (marketing only)

| App | Claimed CPU |
|-----|-------------|
| Wallspace | ~&lt;2% |
| Wallux | ~0.2% |

**7B target:** Measurably **lower than V1 baseline** on Balanced; aspirational **&lt;5%** steady-state. Not a pass/fail vs competitor marketing. Focused Home + 4K + Debug will read higher than competitor claims.

---

## Experiment log

| Date | Change | CPU before | CPU after | Notes |
|------|--------|------------|-----------|-------|
| 2026-05-22 | Doc gate + seek-timer FPS cap | 8% Balanced | — | **Reverted P0** — seek pacing +60% CPU |
| 2026-05-22 | **P0:** Continuous `player.play()` all profiles | 8% | ~5% | Balanced matches Max Quality |
| 2026-05-23 | **P1:** Static hero frame | 6.5% | 3.5% | **Reverted** — live hero required |
| 2026-05-23 | **P2-fix:** Shared session + coalesce | 5.8% | **2.3–2.9%** | `shared=true`, `attachments=2` |
| 2026-05-23 | **P1b:** Live hero + app visibility pause | 6.5% | 3.5% (1 disp focused) | Hero pauses unfocused/occluded |
| 2026-05-23 | **P3:** Desktop visibility pause | — | **0%** idle | Both covered + unfocused |
| 2026-05-23 | **P4-A:** Per-display visibility pause | 7.3% (1 covered) | _re-measure_ | Standalone renderers pause individually |
| 2026-05-23 | **P4-B:** Async carousel thumbnails | — | — | Removes main-thread sync block |
| 2026-05-23 | **P4-C:** WebRenderer visibility + Battery | — | — | JS media pause; stopLoading on Battery visibility pause |
| 2026-05-23 | Reconciliation debounce 0.35s | | | WallpaperManager |
| 2026-05-23 | Thumbnail utility QoS cache | | | ModernHomeView + VideoWallpaperThumbnail |
| 2026-05-23 | **7B closeout:** Launch coalesce + SwiftUI defer fixes | | | `reapplyPersistedPerDisplayWallpapers` |

---

## Profile definitions (7B + 7E)

| Profile | Desktop decode | Hero preview |
|---------|----------------|--------------|
| **Max Quality** | Full resolution; no occlusion pause | **Live on all tabs** (7E); unified with desktop decode when same file (7D) |
| **Balanced** | 1080p cap on 4K via `preferredMaximumResolution`; pause when not visible | Static thumbnail on management tabs; live on Home when focused; unified decode when same file |
| **Battery Saver** | 1080p cap + 2 Mbps `preferredPeakBitRate`; same visibility pause as Balanced | Same as Balanced; WebRenderer `stopLoading` on visibility pause |

**Removed permanently:** Seek-timer FPS caps (regressed CPU). **7D:** Hero preview layer attaches to desktop `AVPlayer` when URLs match — no second decode.

---

## Release benchmark protocol (Phase 7D)

Run in **Release** build; Activity Monitor Very Often, 60s sample after 30s settle. Record Diagnostics instant / smoothed / `ps` / AM per profile.

**2026-06-01 Release run:** Measured on Release scheme (dual-display MacBook). Format per cell: instant / smoothed / ps / AM (%).

| # | Scenario | Max | Balanced | Battery | Notes |
|---|----------|-----|----------|---------|-------|
| 1 | 2 disp, same 1080p, Apply to All, unfocused, visible | 14.60 / 14.17 / 13.5 / 13.9 | 14.32 / 13.75 / 12.9 / 13.1 | 13.4 / 13.8 / 7.47 / 13.6 | Coalesced; hero policy pause Balanced/Battery |
| 2 | Same + Home focused | 14.0 / 13.0 / 12.27 / 10.5 | 11.0 / 12.0 / 11.43 / 9.7 | 10.0 / 11.0 / 11.47 / 9.9 | Unified hero + coalesced |
| 3 | 2 disp, different files, one 4K, unfocused | 10.54 / 11.21 / 9.8 / 11.6 | 10.24 / 10.76 / 6.53 / 10.4 | 10.07 / 10.50 / 7.01 / 10.3 | Dual decode stress |
| 4 | Both displays covered, unfocused | 12.13 / 11.75 / 12.0 / 13.3 | 7.9 / 6.67 / 6.4 / 8.6 | 5.49 / 5.68 / 4.57 / 8.9 | Max still decodes; Balanced/Battery reduced |

```bash
while true; do ps -p $(pgrep -x 'Personal Wallpaper Engine') -o %cpu=; sleep 2; done
```

---

## Phase 7C — Diagnostics & monitoring

- **CPU sampling (7C.2.3):** 1s interval; instant (raw window), smoothed (slow EMA α=0.08), and 60s mean of instant samples. Primary source: `clock_gettime_nsec_np`; cross-check: `proc_pidinfo` + mach timebase.
- **Suggestions (7E):** Max→Balanced at smoothed **10%**; Balanced→Battery Saver at smoothed **14%** (after 7E resolution caps). Test mode: 4%/3%.
- **Settings → Diagnostics:** Profile, CPU, lifecycle, per-display source/decode path, heavy-scenario callout, test-threshold toggle, Restart Engine, Reset to Safe Default.
- **Restart:** Disposes renderers, reapplies persisted wallpapers + coalesce; collections/setups unchanged.

### Measurement semantics (7C.2.4)

All in-app CPU values use **CPU-time / wall-time** on the ps scale (100% = one logical core).

| Source | What it measures | Smoothing |
|--------|------------------|-----------|
| **In-app instant** | CPU time over last 1s | None |
| **In-app smoothed** | EMA (α=0.08) of instant | ~10–15s effective window |
| **`ps %cpu`** | Decaying average of CPU time | macOS kernel decay (~60s half-life) |
| **Activity Monitor** | Process “% CPU” column | Heavy UI smoothing; often reads **lower** than in-app/`ps` |

**Validation targets:**
- **Smoothed vs `ps`:** ±1.5pp
- **Smoothed vs Activity Monitor:** in-app often **2–5pp higher** — acceptable
- **60s avg vs AM:** closest match to AM’s feel

```bash
while true; do ps -p $(pgrep -x 'Personal Wallpaper Engine') -o %cpu=; sleep 2; done
```

### Phase 7C.1 patch (2026-05-20)

- Hero preview no longer pulses on Settings (management tabs always pause hero; visibility monitor debounced 300ms; redundant play/pause guarded).
- CPU readings align closer to Activity Monitor; `@Published` diagnostics updates deferred off view-update pass.

### Phase 7C.2 patch (2026-05-20)

- **Management tabs:** static `VideoWallpaperThumbnail` background (no in-app `AVPlayerView` on Settings/Collections/Setups).
- **Visibility revision:** only bumps on Home tab; management tabs ignore app-active flicker for SwiftUI relayout.
- **Max Quality Home:** hero ignores brief `isAppActive` flicker (pause on hidden only).
- **CPU:** background sampler + AM-normalized formula; diagnostics refresh via `RunLoop.main.perform`.

### Phase 7C.2.1 patch (2026-05-20)

- **CPU callback:** `onSample` published via `Task { @MainActor in }` (fixes GCD + `@MainActor` mismatch that stalled UI at 0%).
- **Baseline seed:** first timer tick produces a delta (~1s to first reading); warmup is one valid sample.
- **Display:** CPU shown to two decimal places in Diagnostics.

### Phase 7C.2.2 patch (2026-05-20)

- **Scale fix:** Removed incorrect `÷ activeProcessorCount` (Windows-style); AM process column uses top/ps scale where 100% = one logical core.
- **Apple Silicon units:** `proc_pidinfo` CPU ticks converted via `mach_timebase_info`; primary reading from `clock_gettime_nsec_np(CLOCK_PROCESS_CPUTIME_ID)` (nanoseconds).
- **Sampling:** 2s interval; monotonic wall clock for interval measurement.
- **Diagnostics UI:** Caption clarifying AM scale; logical CPU count row.
- **Debug log:** `clockGettime`, `procPidinfo`, tick/ns deltas, mach factor, source tag.

#### 7C.2.2 validation checklist

1. Build Debug; open Settings → Diagnostics.
2. Reproduce a baseline scenario (e.g. 2 displays, same 1080p, unfocused, Max Quality — expect ~2.9% per table above).
3. Activity Monitor → **Personal Wallpaper Engine** process row → Update Frequency: **Very Often (1 sec)**.
4. Compare Diagnostics **CPU (smoothed)** to `ps -o %cpu=` — target ±1.5pp.
5. Compare **CPU (60s avg)** to AM `% CPU` — closest match; AM may read 2–5pp **lower** than in-app.
6. Xcode console: `clockGettime` and `procPidinfo` should agree within ~10%; `source=clockGettime` when both available.
7. Terminal cross-check: `ps -p $(pgrep -x 'Personal Wallpaper Engine') -o %cpu=`

### Phase 7C.2.3 patch (2026-05-20)

- **Three CPU metrics:** instant (1s window), smoothed (slow EMA for `ps`/AM parity), 60s avg (mean of instant samples).
- **Sample interval:** 1s (Activity Monitor “Very Often”).
- **Suggestion banner:** thresholds evaluated on instant samples; X snoozes 1 hour; profile changes no longer reset dismiss state; “Don't show again” persists via UserDefaults.
- **Diagnostics labels:** CPU (instant) / CPU (smoothed) / CPU (60s avg).

#### 7C.2.3 validation checklist

1. Steady-state playback; compare **CPU (smoothed)** to `ps -o %cpu=` — target ±1.5pp.
2. Compare **CPU (instant)** to Xcode log `instant=` — should match.
3. **CPU (instant)** may diverge more during spikes — expected.
4. Dismiss banner with X — should not reappear for 1 hour even if profile toggled.
5. “Don't show again” — banner never returns (until UserDefaults cleared).

### Phase 7C.2.4 patch (2026-05-20)

- **AM semantics:** Document that in-app CPU (especially instant) often reads **2–5pp higher** than Activity Monitor while matching `ps`; no formula change.
- **Heavy-scenario callout:** Diagnostics shows context when multiple decode paths, 4K source, or Max Quality elevate expected CPU.
- **Suggestions:** Max→Balanced only; gate on **smoothed** samples; Release threshold **10%** (was 12% instant). Balanced→Battery Saver disabled until Phase 7D.
- **Debug test toggle:** Settings “Use test suggestion thresholds” respected in Debug builds (was always forced to test mode).

#### 7C.2.4 validation checklist

1. **Canonical:** 2 disp, same 1080p, unfocused, Balanced, Debug → instant ~2.5%, smoothed within ±1.5pp of `ps`.
2. **AM comparison:** Smoothed/60s avg vs AM — expect in-app higher by ~2–5pp vs instant readings.
3. **Heavy scenario:** 4K + different files per display → callout visible; Max→Balanced banner only if smoothed >10% for ≥23 of 30 samples.
4. **Balanced at ~10%:** No Battery Saver banner.
5. **Debug toggle:** Test thresholds (4%) apply only when toggle enabled.
6. **Release (optional):** Same canonical scenario → ~3–7% instant target.

#### 7C.2.4 observed deltas (user session, 5/20)

| Scenario | In-app instant | In-app smoothed | In-app 60s avg | vs `ps` | vs AM |
|----------|----------------|-----------------|----------------|---------|-------|
| 4K dual-decode, Max Quality, Debug | ~9–12% | ~11–12% | ~12% | ±2pp | in-app ~4pp **higher** |
| Canonical coalesced 1080p (7B table) | ~2.5–2.9% | — | — | ±1.5pp target | AM lower |

`clockGettime` ≈ `procPidinfo` in console logs — sampler pipeline healthy. Heavy session is stress, not regression.

---

## Phase 7D — Unified hero + desktop decode (2026-05-23)

- **`DesktopVideoPreviewProviding`:** Hero preview attaches an `AVPlayerLayer` to the existing desktop player when URLs match.
- **`UnifiedVideoPreviewView`:** Shell hero uses shared decode; static thumbnail when hero paused (does not pause desktop player).
- **Diagnostics:** Decode path count, hero-shares-desktop flag, coalesce tip when different files per display.

### Phase 7E — Profile differentiation (2026-05-23)

- **Max Quality:** Live hero on **all tabs** (Settings/Collections/Setups); full resolution decode.
- **Balanced / Battery Saver:** `PerformanceProfileConfiguration` — 1080p `preferredMaximumResolution`; Battery adds 2 Mbps peak bitrate cap.
- **Independent hero** (`VideoPreviewView`): profile caps applied when unified decode unavailable.
- **Suggestions:** Balanced→Battery Saver re-enabled at **14%** smoothed (high threshold).

### Phase 7D.1 / 7E.1 — Hero stability + Max management styling (2026-05-23)

- **7D.1:** Idempotent hero preview attach — no detach/reattach on CPU tick; coordinator guards in `UnifiedVideoPreviewView`; frame-only layout updates.
- **7E.1:** Max Quality on management tabs uses **live video + blur/scrim** (same chrome as Balanced static); Home stays full hero intensity.

### Phase 7D.1.1 — Hero attach retry hotfix (2026-05-23)

- **Root cause:** Coordinator cached URL state after first attach attempt with zero bounds; later updates short-circuited without retry.
- **Fix:** Early-return only when `isAttached`; retry attach from `onLayout` and deferred main-queue pass; skip `layoutSubtreeIfNeeded` when bounds already valid.
- **Fallback:** `HeroWallpaperView` shows static thumbnail or independent `VideoPreviewView` if unified attach fails; Max management tabs preload thumbnail for fallback.

### Phase 7G — Closeout runtime hygiene (2026-06-01)

- **Hero attach stability:** Keep `UnifiedVideoPreviewView` mounted during policy pause; hide hero layer instead of detach; `TabbedMainView` uses `@State` pause policy (no visibility-revision body invalidation).
- **Layout:** Hero layout work deferred off `PreviewContainerView.layout()` via main-queue async.
- **SwiftUI:** Defer `heroPreviewVisibilityRevision`, post-restore `@Published` sync, and CPU sample UI updates off view-update pass.
- **Acceptance:** ≤1 `Hero preview attached…` log per URL on focus bounce; no layout recursion warning; no startup state-during-update warnings.

### Profile CPU gap expectations (post-7E)

| Scenario | Max Quality | Balanced | Battery Saver | Primary lever |
|----------|-------------|----------|---------------|---------------|
| 2 disp, same 1080p, coalesced, unfocused | ~baseline | ~baseline | ~baseline | Same source resolution |
| 2 disp, 4K coalesced, unfocused | Full 4K decode | 1080p cap | 1080p + bitrate cap | `preferredMaximumResolution` |
| Home focused, same file | Unified decode (1 player) | Unified + static mgmt tabs | Same | 7D hero layer |
| Both covered, unfocused | >0% | 0% | 0% | Occlusion pause |

---

## Phase 7D (archived plan notes)

**Goal:** Widen CPU gap between Max Quality and Balanced in visible-desktop scenarios so suggestion thresholds are meaningful. Balanced→Battery Saver policy revisited after 7D benchmarks.

**Current gaps (Debug, visible desktop):**

| Scenario | Max Quality | Balanced | Gap today | Target gap |
|----------|-------------|----------|-----------|------------|
| 2 disp, same 1080p, unfocused, coalesced | 2.9% | 2.5% | 0.4pp | ≥2pp |
| 2 disp, different files, unfocused | 7.1% | 6.7% | 0.4pp | ≥3pp |
| Both covered, unfocused | >0% | 0% | Large | — |

**Candidate levers (pick 1–2):**

1. **Balanced unfocused desktop throttle** — reduce decode cost when app unfocused but desktop visible; Max keeps full rate.
2. **Battery Saver differentiation** — 4K→1080p downscale or aggressive WebRenderer idle (see deferred table).
3. **Profile-aware hero cost** — Balanced static hero sooner after unfocus; Max keeps live hero longer.

**After 7D re-benchmark, choose Balanced suggestion policy:**

- Remove Balanced→Battery Saver entirely, or
- High threshold only (sustained smoothed >14–16%), or
- Battery / Low Power Mode gated only.

**Re-benchmark matrix:** Re-run rows in “7B re-measurement” for coalesced 1080p and P6 dual-decode scenarios per profile after each lever.

---

## References

- [`V1_SIGNOFF.md`](V1_SIGNOFF.md)
- [`version2_developmental_roadmap.md`](../version2_developmental_roadmap.md)
- KB: `ADR-005-Performance-Engine-Strategy`
