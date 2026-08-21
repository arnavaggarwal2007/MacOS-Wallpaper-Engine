import Foundation

/// Thresholds and the sustained-usage decision for non-modal performance profile suggestions.
///
/// **Units:** thresholds are a share of **total system CPU capacity**, not the per-core scale that
/// `PerformanceMonitor` reports (where 100% = one logical core). `isSustained` performs the
/// conversion, so callers pass raw per-core samples and never have to reason about the scale.
///
/// Previously the thresholds were per-core (10% and 14%) but had been calibrated against Debug
/// measurements of roughly 2.5%. The Release baseline is about 13.8% per-core, so every profile sat
/// above its own trigger and the banner fired on nearly every launch. System-wide share is the more
/// durable unit because it is what the user actually experiences and it scales with core count: the
/// same wallpaper is a real cost on a 2-core laptop and noise on a 12-core desktop. See ADR-009.
enum PerformanceSuggestionPolicy {
    /// Balanced→Battery Saver enabled after 7E resolution/bitrate caps.
    static let balancedSuggestionsEnabled = true

    struct Thresholds {
        /// Suggest Balanced once Max Quality sustains more than this share of system CPU.
        let maxToBalancedSystemPercent: Double
        /// Suggest Battery Saver once Balanced sustains more than this share of system CPU.
        let balancedToBatterySaverSystemPercent: Double
        let sustainedSampleWindow: Int
        let sustainedFraction: Double

        /// Roughly twice the heaviest Release measurement. The benchmark envelope in
        /// `docs/PERFORMANCE_TUNING.md` spans 0.47%–1.18% of system on 12 cores across every
        /// profile and scenario, so these leave headroom for normal operation while still firing on
        /// hardware where the wallpaper costs a real share of the machine.
        static let release = Thresholds(
            maxToBalancedSystemPercent: 2.5,
            balancedToBatterySaverSystemPercent: 3.5,
            sustainedSampleWindow: 30,
            sustainedFraction: 0.75
        )

        /// Deliberately *below* the measured baseline so QA can force the banner on demand, and with
        /// a shorter window so it appears in about 15 seconds. Debug builds only.
        static let test = Thresholds(
            maxToBalancedSystemPercent: 0.5,
            balancedToBatterySaverSystemPercent: 0.5,
            sustainedSampleWindow: 15,
            sustainedFraction: 0.75
        )
    }

    static func thresholds(useTestMode: Bool) -> Thresholds {
        useTestMode ? .test : .release
    }

    /// The system-wide threshold for leaving `profile`, or `nil` when no suggestion applies.
    static func systemPercentThreshold(
        leaving profile: PerformanceProfile,
        thresholds: Thresholds
    ) -> (threshold: Double, suggested: PerformanceProfile)? {
        switch profile {
        case .maxQuality:
            return (thresholds.maxToBalancedSystemPercent, .balanced)
        case .balanced:
            guard balancedSuggestionsEnabled else { return nil }
            return (thresholds.balancedToBatterySaverSystemPercent, .batterySaver)
        case .batterySaver:
            return nil
        }
    }

    /// Whether per-core samples sustain usage above a system-wide threshold for long enough.
    ///
    /// - Parameter perCoreSamples: samples on `PerformanceMonitor`'s per-core scale, oldest first.
    static func isSustained(
        perCoreSamples: [Double],
        aboveSystemPercent threshold: Double,
        thresholds: Thresholds
    ) -> Bool {
        guard perCoreSamples.count >= thresholds.sustainedSampleWindow else { return false }

        let window = perCoreSamples.suffix(thresholds.sustainedSampleWindow)
        let aboveCount = window.filter {
            CPUMetricsFormatting.systemWidePercent(fromPerCore: $0) > threshold
        }.count
        let required = Int(ceil(Double(thresholds.sustainedSampleWindow) * thresholds.sustainedFraction))
        return aboveCount >= required
    }
}
