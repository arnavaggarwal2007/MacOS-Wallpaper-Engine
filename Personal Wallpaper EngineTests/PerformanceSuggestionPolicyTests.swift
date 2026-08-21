import XCTest
@testable import Personal_Wallpaper_Engine

/// Pins the unit contract between `PerformanceMonitor` (per-core) and
/// `PerformanceSuggestionPolicy` (system-wide). See ADR-009.
final class PerformanceSuggestionPolicyTests: XCTestCase {
    private let release = PerformanceSuggestionPolicy.Thresholds.release

    /// Builds a per-core sample value that represents the given share of total system CPU, so these
    /// tests assert the same thing regardless of the host machine's core count.
    private func perCoreSample(forSystemPercent systemPercent: Double) -> Double {
        systemPercent * Double(CPUMetricsFormatting.logicalProcessorCount)
    }

    private func window(systemPercent: Double, count: Int? = nil) -> [Double] {
        Array(
            repeating: perCoreSample(forSystemPercent: systemPercent),
            count: count ?? release.sustainedSampleWindow
        )
    }

    // MARK: - Unit contract

    func testSystemWidePercentDividesByLogicalCoreCount() {
        let cores = Double(CPUMetricsFormatting.logicalProcessorCount)
        XCTAssertEqual(CPUMetricsFormatting.systemWidePercent(fromPerCore: cores * 5), 5, accuracy: 0.0001)
    }

    // MARK: - Sustained decision

    /// The heaviest Release scenario in `docs/PERFORMANCE_TUNING.md` measures ~1.18% of system CPU
    /// (14.17% per-core on 12 cores). Release thresholds calibrated below that fired the banner on
    /// nearly every launch, which is the regression this pins.
    func testHeaviestMeasuredReleaseScenarioDoesNotSuggest() {
        XCTAssertFalse(
            PerformanceSuggestionPolicy.isSustained(
                perCoreSamples: window(systemPercent: 1.18),
                aboveSystemPercent: release.maxToBalancedSystemPercent,
                thresholds: release
            ),
            "Normal operation must stay quiet, or the banner is noise"
        )
    }

    func testIdleBaselineDoesNotSuggest() {
        XCTAssertFalse(
            PerformanceSuggestionPolicy.isSustained(
                perCoreSamples: window(systemPercent: 0.5),
                aboveSystemPercent: release.maxToBalancedSystemPercent,
                thresholds: release
            )
        )
    }

    func testGenuinelyHeavyUsageSuggests() {
        XCTAssertTrue(
            PerformanceSuggestionPolicy.isSustained(
                perCoreSamples: window(systemPercent: 12),
                aboveSystemPercent: release.maxToBalancedSystemPercent,
                thresholds: release
            )
        )
    }

    /// The QA toggle is useless unless it trips under ordinary load.
    func testTestModeThresholdsFireAtNormalUsage() {
        let test = PerformanceSuggestionPolicy.Thresholds.test
        XCTAssertTrue(
            PerformanceSuggestionPolicy.isSustained(
                perCoreSamples: window(systemPercent: 1.0, count: test.sustainedSampleWindow),
                aboveSystemPercent: test.maxToBalancedSystemPercent,
                thresholds: test
            )
        )
    }

    func testShortWindowNeverSuggests() {
        let tooFew = window(systemPercent: 50, count: release.sustainedSampleWindow - 1)
        XCTAssertFalse(
            PerformanceSuggestionPolicy.isSustained(
                perCoreSamples: tooFew,
                aboveSystemPercent: release.maxToBalancedSystemPercent,
                thresholds: release
            ),
            "A partial window must not suggest, however high the samples are"
        )
    }

    func testBriefSpikeDoesNotSuggest() {
        // Half the window heavy, half idle — below the 75% sustained fraction.
        let half = release.sustainedSampleWindow / 2
        let samples = window(systemPercent: 1, count: release.sustainedSampleWindow - half)
            + window(systemPercent: 40, count: half)

        XCTAssertFalse(
            PerformanceSuggestionPolicy.isSustained(
                perCoreSamples: samples,
                aboveSystemPercent: release.maxToBalancedSystemPercent,
                thresholds: release
            )
        )
    }

    func testOnlyTrailingWindowIsConsidered() {
        // Old heavy history followed by a full idle window must not suggest.
        let samples = window(systemPercent: 40) + window(systemPercent: 1)
        XCTAssertFalse(
            PerformanceSuggestionPolicy.isSustained(
                perCoreSamples: samples,
                aboveSystemPercent: release.maxToBalancedSystemPercent,
                thresholds: release
            )
        )
    }

    // MARK: - Profile gating

    func testMaxQualitySuggestsBalanced() {
        let gate = PerformanceSuggestionPolicy.systemPercentThreshold(leaving: .maxQuality, thresholds: release)
        XCTAssertEqual(gate?.suggested, .balanced)
        XCTAssertEqual(gate?.threshold, release.maxToBalancedSystemPercent)
    }

    func testBalancedSuggestsBatterySaver() {
        let gate = PerformanceSuggestionPolicy.systemPercentThreshold(leaving: .balanced, thresholds: release)
        XCTAssertEqual(gate?.suggested, .batterySaver)
        XCTAssertEqual(gate?.threshold, release.balancedToBatterySaverSystemPercent)
    }

    func testBatterySaverHasNothingToSuggest() {
        XCTAssertNil(
            PerformanceSuggestionPolicy.systemPercentThreshold(leaving: .batterySaver, thresholds: release)
        )
    }

    // MARK: - Threshold sanity

    func testReleaseThresholdsSitClearOfMeasuredBaseline() {
        // Benchmarked Release envelope tops out at ~1.18% of system across all profiles.
        XCTAssertGreaterThan(release.maxToBalancedSystemPercent, 1.5)
        XCTAssertGreaterThan(release.balancedToBatterySaverSystemPercent, release.maxToBalancedSystemPercent)
    }

    func testTestModeThresholdsSitBelowMeasuredBaseline() {
        XCTAssertLessThan(PerformanceSuggestionPolicy.Thresholds.test.maxToBalancedSystemPercent, 1.0)
    }

    func testTestModeThresholdsAreLowerThanRelease() {
        let test = PerformanceSuggestionPolicy.Thresholds.test
        XCTAssertLessThan(test.maxToBalancedSystemPercent, release.maxToBalancedSystemPercent)
        XCTAssertLessThan(test.sustainedSampleWindow, release.sustainedSampleWindow)
    }

    func testThresholdSelectionFollowsTestModeFlag() {
        XCTAssertEqual(
            PerformanceSuggestionPolicy.thresholds(useTestMode: true).sustainedSampleWindow,
            PerformanceSuggestionPolicy.Thresholds.test.sustainedSampleWindow
        )
        XCTAssertEqual(
            PerformanceSuggestionPolicy.thresholds(useTestMode: false).sustainedSampleWindow,
            release.sustainedSampleWindow
        )
    }
}
