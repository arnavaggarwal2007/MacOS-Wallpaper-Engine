# Phase 4 Production Testing Checklist (Chunk 4E)

**Status:** Ready for Release Gate Sign-Off  
**Date:** May 3, 2026  
**Tester:** [Name/Date to be filled]  
**Build:** Personal Wallpaper Engine Release Build  

## Pre-Testing Setup

- [ ] Clean build passes: `xcodebuild clean build` succeeds without warnings
- [ ] All previous chunks (1-4D) compile and function
- [ ] macOS version 12.0+ for testing
- [ ] Test videos available: MP4/MOV files (small, medium, 4K)
- [ ] Multi-display setup available (or can simulate via Spaces)
- [ ] Debug diagnostics flag can be toggled via UserDefaults

---

## Test Matrix: Single Display

### Basic Functionality
- [ ] App launches without crashes
- [ ] Desktop wallpaper appears behind desktop icons
- [ ] Video plays smoothly at 60fps
- [ ] CPU usage < 10%, GPU < 2% at idle (measured via Activity Monitor)
- [ ] Audio muting works correctly (toggle in UI)
- [ ] Scaling modes (Fill/Fit/Stretch) apply correctly
- [ ] Wallpaper persists after app quit/reopen

### Lifecycle Management (Chunk 4A)
- [ ] Screen lock pauses playback
- [ ] Screen unlock resumes playback
- [ ] System sleep pauses playback
- [ ] System wake resumes playback
- [ ] Multiple pause/resume cycles work without issue

### Recovery & Resilience (Chunk 4B)
- [ ] App recovers if renderer crashes (simulated)
- [ ] Wallpaper restarts after recovery
- [ ] Settings (muted, scaling) preserved after recovery
- [ ] Recovery doesn't exceed max retry limit (3 attempts)

### Resize Handling (Chunk 4C)
- [ ] Resolution change (e.g., 1080p → 1440p) resizes wallpaper
- [ ] Rapid resolution changes debounced correctly
- [ ] Window frame updates match new resolution
- [ ] Renderer layer size synchronized with window

### State Reconciliation (Chunk 4D)
- [ ] Reconciliation triggered after lifecycle events
- [ ] Window level verified and restored
- [ ] Muted state synchronized after reconciliation
- [ ] Scaling mode synchronized after reconciliation
- [ ] No spurious repairs during normal operation

---

## Test Matrix: Multi-Display

### Display Connection
- [ ] Connect external monitor: wallpaper appears on both displays
- [ ] Disconnect external monitor: wallpaper removed from that display gracefully
- [ ] Rapid connect/disconnect: no crashes, state recovers

### Per-Display State
- [ ] Each display renders same video independently
- [ ] Window levels correct on both displays (behind icons)
- [ ] Muted state consistent across displays
- [ ] Scaling mode consistent across displays

### Hotplug Scenarios
- [ ] Connect display during playback: new display starts wallpaper
- [ ] Connect display while paused: new display stays paused
- [ ] Disconnect primary display: wallpaper transfers to secondary
- [ ] Disconnect all displays: app remains stable, wallpaper reappears when display reconnects

---

## Test Matrix: Virtual Desktops/Spaces

### Space Visibility
- [ ] Wallpaper visible in all Spaces
- [ ] Switching between Spaces maintains playback
- [ ] Mission Control shows wallpaper in thumbnails
- [ ] Wallpaper stays behind desktop icons in all Spaces

### Space Transitions
- [ ] Rapid Space switching (4+ spaces) doesn't crash
- [ ] Reconciliation coalesces multiple space changes
- [ ] Window ordering restored after space change

---

## Test Matrix: Stress Scenarios

### Continuous Operation
- [ ] Video plays continuously for 1+ hour
- [ ] No memory leaks (check Allocations instrument)
- [ ] No file handle leaks (check Activity Monitor)
- [ ] CPU/GPU usage remains stable over time

### Rapid Event Churn
- [ ] Rapid pause/resume cycles (10+ per second) handled gracefully
- [ ] Rapid display connect/disconnect (5+ cycles) without hangs
- [ ] Rapid space switching (10+ switches) coalesced correctly
- [ ] Rapid resolution changes (resolution cycling tool) debounced correctly

### Error Conditions
- [ ] Missing video file: error shown, app remains stable
- [ ] Corrupted video file: error shown, recovers with new selection
- [ ] Unsupported video format: error shown with format guidance
- [ ] Permission denied: error shown, app suggests remedy
- [ ] System low on memory: app handles gracefully without crash

---

## Test Matrix: User Settings & Persistence

### Settings Storage
- [ ] Video path persists after quit/reopen
- [ ] Muted setting persists after quit/reopen
- [ ] Scaling mode persists after quit/reopen
- [ ] Bookmark data (security-scoped) persists across sessions

### Dynamic Updates
- [ ] Toggling mute applies immediately across all displays
- [ ] Changing scaling mode applies immediately
- [ ] Selecting new video applies immediately
- [ ] Settings synchronized across manager → controller → renderer

---

## Test Matrix: Diagnostics & Logging (Chunk 4E)

### Debug Flag
- [ ] Debug flag disabled: no /tmp/pwe_*.log files created
- [ ] Debug flag enabled: diagnostic logs created and populated
- [ ] Disabling flag mid-run: diagnostics stop accumulating
- [ ] Enabling flag mid-run: diagnostics resume

### Log Quality
- [ ] Logs have consistent timestamps and format
- [ ] Logs include display IDs for multi-display correlation
- [ ] Reconciliation events logged with reason (screen change, space change, resume)
- [ ] Failures logged with clear error descriptions
- [ ] No excessive noisy debug spam in production mode

### System Health Tracking
- [ ] Failure count increments on reconciliation failures
- [ ] Last failure reason updated when new failure occurs
- [ ] Failure threshold (5) tracked correctly
- [ ] AppViewModel.systemHealthStatus reflects failure count

---

## Regression Testing (4A-4D Integration)

### Chunk 4A + 4B Integration
- [ ] Sleep/wake: renderer validity checked and recovered if needed
- [ ] Pause/resume: recovery fallback attempted if renderer invalid
- [ ] No double-recovery (4A recovery shouldn't trigger 4B recovery again)

### Chunk 4B + 4C Integration
- [ ] Resize after recovery: renderer handles resize after re-initialization
- [ ] Recovery preserves resize settings (scales to new resolution)
- [ ] Debounce doesn't interfere with recovery timing

### Chunk 4C + 4D Integration
- [ ] Reconciliation triggered after resize debounce completes
- [ ] Window level verified after resize
- [ ] Renderer resize() called with correct new size

### Full 4A-4D Chain
- [ ] Screen sleep → pause → wake → resume → reconciliation → playback
- [ ] Display connect → reconciliation → playback
- [ ] Space change → reconciliation → window order restored
- [ ] Resolution change → debounce → reconciliation → resize applied

---

## Performance & Resource Tests

### CPU/GPU Profiling
- [ ] At idle: CPU < 10%, GPU < 2% (sustained)
- [ ] During playback: CPU < 15%, GPU < 5%
- [ ] After recovery: peak CPU < 20%, returns to baseline within 100ms
- [ ] After resize: no spike in CPU/GPU

### Memory Profiling (Instruments)
- [ ] Allocations: heap stable at ~80-100MB during playback
- [ ] No growth over 1 hour (max 10% growth acceptable)
- [ ] AV objects properly deallocated after dispose()
- [ ] Notification observers cleaned up on stop()

### File Handle Leaks
- [ ] lsof shows no unclosed file handles after playback stop
- [ ] Video file bookmarks properly scoped
- [ ] Diagnostic log files properly closed after writes

---

## Edge Cases & Boundary Conditions

### Video Codec Support
- [ ] H.264 video plays smoothly (primary codec)
- [ ] 30fps video plays correctly
- [ ] 60fps video plays smoothly
- [ ] 4K video (if hardware supports) plays without excessive CPU

### Display Configurations
- [ ] Single display (laptop screen alone)
- [ ] Single external monitor (primary display)
- [ ] Dual monitors (internal + external)
- [ ] Dual monitors with different resolutions
- [ ] Dual monitors with different refresh rates

### Aspect Ratios
- [ ] 16:9 video on 16:10 display (Fill/Fit/Stretch)
- [ ] 4:3 video on 16:9 display (Fill/Fit/Stretch)
- [ ] Ultrawide display (21:9) with standard video
- [ ] Vertical display orientation (if monitor supports)

---

## User Experience Tests

### First-Run Experience
- [ ] App launches with no crashes
- [ ] UI responsive on first launch
- [ ] File picker works smoothly
- [ ] Selected video applies without delay

### Stability Under Rapid Input
- [ ] Clicking Apply button rapidly doesn't hang or crash
- [ ] Changing settings rapidly applies correctly
- [ ] File picker doesn't block main thread

### Error Messages & Recovery
- [ ] Error messages are clear and actionable
- [ ] Recovery suggestions present when applicable
- [ ] User can recover by selecting different video
- [ ] App doesn't enter unrecoverable state

---

## Sign-Off Criteria

### Build Quality
- [x] Clean build passes
- [ ] No compiler warnings
- [ ] No lint violations
- [ ] Code review completed (if applicable)

### Testing Coverage
- [ ] All single-display tests passed
- [ ] All multi-display tests passed (or documented as not available in environment)
- [ ] All stress tests passed
- [ ] All regression tests passed
- [ ] No critical issues found

### Performance Gate
- [ ] CPU/GPU targets met under all test conditions
- [ ] Memory stable without leaks
- [ ] No file handle leaks
- [ ] Recovery time < 200ms

### Diagnostics & Logging
- [ ] Debug flag works as intended
- [ ] Production logging clean (no spam)
- [ ] System health tracking functional
- [ ] Failure visibility implemented

### Known Issues
- [ ] Document any known issues not addressed in this release:
  1. (None expected for Phase 4)
  2. (Add as discovered)

---

## Release Readiness Checklist

- [ ] All critical tests passed
- [ ] No blockers from test execution
- [ ] Performance within acceptable range
- [ ] Diagnostics hardened and working
- [ ] Roadmap updated with completion markers
- [ ] This checklist signed and dated

---

## Tester Sign-Off

**Tester Name:** ___________________  
**Date:** ___________________  
**Status:** ☐ Pass (Ready for Release)  ☐ Fail (Return to Dev)  
**Comments:**  

```
[Space for tester notes and findings]
```

---

## Release Notes Template (for user documentation)

**Version:** Phase 4 Release  
**Release Date:** [Fill in]  

### Features in This Release
- ✅ Lifecycle management with pause/resume on screen lock/sleep
- ✅ Renderer recovery with fallback re-initialization
- ✅ Display resize handling with debounce
- ✅ State reconciliation with self-healing
- ✅ System health tracking and visibility

### Known Limitations
- Single video per system (future: per-display selection)
- No launch-on-login support yet (future: Phase 5)
- No web rendering yet (future: Phase 1.5 extension)

### System Requirements
- macOS 12.0 or later
- ~100MB disk space
- ~100MB RAM during playback

### Getting Started
1. Select a video file (MP4/MOV)
2. Click Apply
3. Wallpaper appears immediately
4. Settings persist automatically

---

**End of Checklist**
