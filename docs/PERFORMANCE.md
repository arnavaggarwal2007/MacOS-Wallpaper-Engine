# Performance

**Status:** Profiles, diagnostics, and suggestion thresholds shipped with Deskface 1.0.  
**Full measurement log:** [archive/performance-log.md](archive/performance-log.md)

## CPU scale

| Scale | Definition | Example (12 logical cores) |
|-------|------------|----------------------------|
| **Per-core** | CPU-time ÷ wall-time. 100% is one logical core. Matches Activity Monitor and `ps`. | 12% in Activity Monitor |
| **System-wide** | Per-core ÷ logical processor count | 12% ÷ 12 = about 1% of the machine |

In-app diagnostics use the per-core scale. Settings → Diagnostics also shows **System CPU share**. Do not divide an in-app reading by the core count a second time.

Canonical Release row (2026-06-01, 12 cores, two displays, same 1080p file, coalesced, app unfocused, Balanced): about **13.75% per-core**, about **1.15% system-wide**.

## How to measure

1. Apply a wallpaper and wait 30 seconds.
2. Activity Monitor → the app process → Update Frequency: Very Low (1 sec).
3. Record CPU, GPU, Energy, and Memory for 60 seconds.
4. Sign-off rows use a **Release** build. Debug inflates CPU.

## Profiles

| Profile | Desktop decode | Hero preview |
|---------|----------------|--------------|
| **Max Quality** | Full resolution; no pause when a display is covered | Live on all tabs; one decode with the desktop when the file matches |
| **Balanced** | 1080p cap on 4K; pause when not visible | Still thumbnail on management tabs; live on Home when focused |
| **Battery Saver** | 1080p cap, 2 Mbps peak bit rate, same visibility pause | Same as Balanced; web renderer stops loading while paused |

Seek-timer frame caps were removed. They raised CPU.

## Release benchmark (2026-06-01, smoothed per-core %)

| Scenario | Max Quality | Balanced | Battery Saver |
|----------|-------------|----------|---------------|
| Two displays, same 1080p, unfocused | 14.17 | 13.75 | 13.80 |
| Same file, Home focused | 13.00 | 12.00 | 11.00 |
| Different files, one 4K, unfocused | 11.21 | 10.76 | 10.50 |
| Both displays covered, unfocused | 11.75 | 6.67 | 5.68 |

## Suggestion thresholds

Thresholds are a share of **total system CPU**, not per-core. The old per-core gates were calibrated on Debug (~2.5%) and fired on almost every Release launch, and the banner quoted the per-core number so ~1% of the machine read as “14%”.

| Gate | System-wide | About this on 12 cores (per-core) |
|------|-------------|-----------------------------------|
| Max Quality → Balanced | 2.5% | ~30% |
| Balanced → Battery Saver | 3.5% | ~42% |
| Test mode (Debug only) | 0.5% / 0.5% | ~6% |

The measured Release envelope on 12 cores is about **0.47%–1.18%** of the system. Release gates sit near twice the top of that range. Test gates sit under the baseline so QA can force the banner. Code: `PerformanceSuggestionPolicy.swift`.

To re-derive after new benchmarks: measure the heaviest realistic scenario, divide by `activeProcessorCount`, and set Max → Balanced at about twice that system-wide share.

## References

- [RELEASE_RECORD.md](RELEASE_RECORD.md)
- Knowledge base: ADR-005, ADR-009
