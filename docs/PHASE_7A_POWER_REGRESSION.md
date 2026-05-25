# Phase 7A — Power policy regression matrix

**Scope:** `PowerPolicyManager`, `WallpaperManager` power pause/resume, Settings → Battery & Power.

**Pause behavior:** Pausing stops desktop `AVPlayer` playback and leaves the **current video frame visible** (frozen video on the last rendered frame). Play/pause is **global** — all connected displays pause and resume together. In-app hero preview pauses when globally paused; carousel tiles show a “Paused” scrim; a compact banner under the Home utility bar appears when paused.

**Launch / previews:** Per-display and collection bookmarks must resolve on cold start (no `No bookmark found` + `not readable` for configured sources). Home display carousel should show thumbnails without tapping Apply. On launch, desktops **auto-play** when power policy allows (AC / no battery pause rule); otherwise stay paused with policy chrome.

**Power debounce:** AC/battery events are debounced (~400ms) so brief plug flicker does not instantly resume after pause.

## Settings (defaults)

| Setting | Default |
|---------|---------|
| Pause on Battery | Off |
| Pause on Low Battery | On |
| Low battery threshold | 20% |

## Manual test matrix

| # | Steps | Expected |
|---|--------|----------|
| 1 | MacBook on AC, wallpapers playing, enable **Pause on Battery** | No change while plugged in |
| 2 | Unplug AC with **Pause on Battery** on; **stay on battery ≥10s** (do not plug in yet) | **Physical desktops** frozen; `pausing playback` with `source=powerPolicy`; **no** `resuming … powerPolicy` until AC returns |
| 3 | Plug AC back in | Wallpapers resume automatically |
| 4 | On battery, set threshold 50%, enable **Pause on Low Battery** | Pauses when charge &lt; 50% (if applicable) |
| 5 | Charge above threshold or plug in AC | Resumes when policy allows |
| 6 | Toggle **Pause on Low Battery** off while on battery | Resumes if only low-battery rule was active |
| 7 | Sleep / wake MacBook | Existing sleep pause still works; wake re-evaluates power policy |
| 8 | Desktop Mac (no battery) | No spurious pause; AC assumed |
| 9 | Change settings while paused for battery | Policy re-evaluates immediately |
| 10 | Relaunch on **AC**, Pause on Battery **off**, saved wallpapers | `Launch auto-play — starting desktop playback`; `lifecycle=playing`; toolbar **Pause**; no manual Play required |
| 10b | Relaunch on **battery** with Pause on Battery **on** | `Launch auto-play skipped — power policy requires pause`; desktops frozen; toolbar **Play** |
| 11 | AC stable, Pause on Battery **off**, two displays playing → press **Pause** once, then **Play** | Desktops show **frozen frame** (not black); hero + preview static; `Desktop pause: holding frame (layer attached)`; `Desktop pause verified rate=0`; Play → `Desktop resume: playback started` |
| 12 | While paused, switch display in carousel | **Both physical desktops** still frozen; hero overlay visible; preview **not** animating; tiles show paused scrim |
| 13 | Manual pause → unplug/plug AC (Pause on Battery on) | Desktops stay paused until user presses play; `Skipping powerPolicy resume — user paused`; no `resuming (reason: powerPolicy)` while user-paused |
| 13b | On battery (policy paused) → **Play** → **Pause** | Desktops play then freeze again; **no** `pauseWallpaperPlayback skipped — engine already globally paused`; expect `re-enforcing` or `pausing userInitiated` |
| 14 | Press play after manual pause | Both desktops resume; no `Cannot recover: no stored video URL` |
| 15 | Pause → wait 5s without clicking | Desktops and hero stay frozen; **no** `resumeWallpaperPlayback` unless Play pressed |
| 16 | Pause → click within 2.5s expecting pause again | `Resume ignored — post-pause grace` or only one resume after grace expires; `Play/Pause intent=resume` only when Play intended |

## Automated

- `CODE_SIGNING_ALLOWED=NO ./scripts/chunk7_smoke.sh`

## Console signals

- `Power policy observation started`
- `Power source changed: AC=true/false`
- `Wallpapers paused to save battery` (status UI)
- `Launch auto-play — starting desktop playback after restore` on cold launch (AC)
- `Launch auto-play skipped — power policy requires pause` on battery when policy applies
- `WallpaperManager pausing playback (command=` without immediate `resuming playback (reason: user source: toolbar` unless Play pressed or policy allows
- `Desktop pause verified rate=0` on each display after pause
- `Desktop pause: holding frame (layer attached)` — pause without black screen
- `Resume ignored — post-pause grace` (2.5s window) or `Resume ignored — debounce after user pause` (Δms=…) if pause double-fired — desktops stay frozen
- `Play/Pause pressed intent=pause|resume` with `playbackActive=`
- `Playback pause/resume (command=…) Δms since …` for timing diagnosis
- `pauseWallpaperPlayback started/finished`, `resumeWallpaperPlayback started/finished`
- `Playback state snapshot:` with `lifecycle=`, `desktopRates=[display:rate]`, `chromePaused=`, `policyOverride=`
- `Desktop resume: playback started rate=` after Play
- `Pausing N desktop renderer(s) in parallel` and per-display `Desktop pause task completed`
- `Resume skipped — lifecycle already playing` — failure if Play pressed while desktops already moving
- `User resume — power policy chrome override until next unplug` after manual Play on battery
- **Failure signals:** `pauseWallpaperPlayback skipped — engine already globally paused`; `resumeWallpaperPlayback finished` with `playbackActive=true` and `chromePaused=true` together; `Desktop pause: detached AVPlayer from layer` (regression — detach removed); solid black desktops after pause
- `Skipping powerPolicy resume — user paused playback` when AC returns during manual pause
- `resuming playback (command=` with `reason: user|powerPolicy|wake` when resume is intentional
- No repeated `Pausing with zero container bounds` during manual pause (warning OK once if geometry still settling)
