import Foundation

/// Thresholds for non-modal performance profile suggestions (Phase 7C / 7C.2.4).
enum PerformanceSuggestionPolicy {
    /// Balanced→Battery Saver enabled after 7E resolution/bitrate caps (high threshold until re-benchmark).
    static let balancedSuggestionsEnabled = true

    struct Thresholds {
        let maxToBalanced: Double
        let balancedToBatterySaver: Double
        let sustainedSampleWindow: Int
        let sustainedFraction: Double

        static let release = Thresholds(
            maxToBalanced: 10,
            balancedToBatterySaver: 14,
            sustainedSampleWindow: 30,
            sustainedFraction: 0.75
        )

        static let test = Thresholds(
            maxToBalanced: 4,
            balancedToBatterySaver: 3,
            sustainedSampleWindow: 15,
            sustainedFraction: 0.75
        )
    }

    static func thresholds(useTestMode: Bool) -> Thresholds {
        useTestMode ? .test : .release
    }
}
