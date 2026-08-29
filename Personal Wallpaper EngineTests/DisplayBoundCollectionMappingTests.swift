import XCTest
@testable import Personal_Wallpaper_Engine

final class DisplayBoundCollectionMappingTests: XCTestCase {
    private let builtIn = DisplayBoundCollectionMapping.ConnectedDisplay(id: 1, name: "Built-in Retina Display")
    private let external = DisplayBoundCollectionMapping.ConnectedDisplay(id: 2, name: "LG UltraFine")

    private func source(
        url: String = "file:///tmp/a.mp4",
        label: String? = nil,
        id: Int? = nil
    ) -> CollectionSource {
        CollectionSource(
            id: UUID().uuidString,
            url: url,
            displayLabel: label,
            displayIDFallback: id,
            scalingMode: nil,
            order: 0
        )
    }

    func testAutoDetectRoundRobinUsesUnusedDisplaysInOrder() {
        var claimed = Set<CGDirectDisplayID>()
        claimed.insert(1)

        let assigned = DisplayBoundCollectionMapping.autoDetectDisplayIDs(
            count: 2,
            orderedDisplayIDs: [1, 2, 3],
            claimed: claimed
        )

        XCTAssertEqual(assigned, [2, 3])
    }

    func testExplicitLabelMatchIgnoresStaleIDFallback() {
        var claimed = Set<CGDirectDisplayID>()
        let row = source(label: "LG UltraFine", id: 99)

        let resolved = DisplayBoundCollectionMapping.resolveExplicitBinding(
            source: row,
            connected: [builtIn, external],
            claimed: &claimed
        )

        XCTAssertEqual(resolved, 2)
        XCTAssertTrue(claimed.contains(2))
    }

    func testMissingMonitorNameDoesNotFallBackToStaleID() {
        var claimed = Set<CGDirectDisplayID>()
        let row = source(label: "Old External Panel", id: 2)

        let resolved = DisplayBoundCollectionMapping.resolveExplicitBinding(
            source: row,
            connected: [builtIn, external],
            claimed: &claimed
        )

        XCTAssertNil(resolved)
        XCTAssertTrue(claimed.isEmpty)
    }

    func testTwoAutoDetectSourcesGetDifferentDisplays() {
        let claimed = Set<CGDirectDisplayID>()
        let first = source()
        let second = source(url: "file:///tmp/b.mp4")

        XCTAssertTrue(DisplayBoundCollectionMapping.isAutoDetect(first))
        XCTAssertTrue(DisplayBoundCollectionMapping.isAutoDetect(second))

        let autoIDs = DisplayBoundCollectionMapping.autoDetectDisplayIDs(
            count: 2,
            orderedDisplayIDs: [1, 2],
            claimed: claimed
        )
        XCTAssertEqual(autoIDs, [1, 2])
    }

    func testDisplaySignaturePersistenceKeyRoundTrips() {
        let key = "Built-in Retina Display|1728|1117"
        let decoded = DisplayConfigurationMigrator.DisplaySignature(persistenceKey: key)
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.persistenceKey, key)
    }

    func testIDOnlyFallbackResolvesWhenLabelNil() {
        var claimed = Set<CGDirectDisplayID>()
        let row = source(label: nil, id: 2)

        let resolved = DisplayBoundCollectionMapping.resolveExplicitBinding(
            source: row,
            connected: [builtIn, external],
            claimed: &claimed
        )

        XCTAssertEqual(resolved, 2)
        XCTAssertTrue(claimed.contains(2))
    }

    func testFuzzyLabelMatchViaSubstring() {
        var claimed = Set<CGDirectDisplayID>()
        let row = source(label: "UltraFine")

        let resolved = DisplayBoundCollectionMapping.resolveExplicitBinding(
            source: row,
            connected: [builtIn, external],
            claimed: &claimed
        )

        XCTAssertEqual(resolved, 2)
    }

    func testClaimedDisplayCannotBeResolvedTwice() {
        var claimed: Set<CGDirectDisplayID> = [2]
        let row = source(label: "LG UltraFine")

        let resolved = DisplayBoundCollectionMapping.resolveExplicitBinding(
            source: row,
            connected: [builtIn, external],
            claimed: &claimed
        )

        XCTAssertNil(resolved)
    }

    func testAutoDetectReturnsFewerIDsWhenDisplaysExhausted() {
        let claimed: Set<CGDirectDisplayID> = [1, 2]
        let assigned = DisplayBoundCollectionMapping.autoDetectDisplayIDs(
            count: 3,
            orderedDisplayIDs: [1, 2, 3],
            claimed: claimed
        )

        XCTAssertEqual(assigned, [3])
    }

    func testMoreAutoDetectSourcesThanFreeDisplaysIsDetectable() {
        let claimed: Set<CGDirectDisplayID> = [1]
        let autoIDs = DisplayBoundCollectionMapping.autoDetectDisplayIDs(
            count: 2,
            orderedDisplayIDs: [1, 2],
            claimed: claimed
        )
        XCTAssertEqual(autoIDs, [2])
        XCTAssertLessThan(autoIDs.count, 2)
    }
}
