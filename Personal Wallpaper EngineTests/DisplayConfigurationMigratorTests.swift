import XCTest
@testable import Personal_Wallpaper_Engine

final class DisplayConfigurationMigratorTests: XCTestCase {
    private func rekey(_ dict: [String: String], _ mapping: [String: String]) -> [String: String] {
        DisplayConfigurationMigrator.rekeyDictionary(dict, mapping: mapping)
    }

    func testEmptyMappingLeavesDictionaryUnchanged() {
        let sources = ["1": "a", "2": "b"]
        XCTAssertEqual(rekey(sources, [:]), sources)
    }

    func testSimpleRemapMovesValue() {
        XCTAssertEqual(rekey(["1": "a"], ["1": "5"]), ["5": "a"])
    }

    func testUnmappedEntriesArePreserved() {
        XCTAssertEqual(rekey(["1": "a", "9": "z"], ["1": "5"]), ["5": "a", "9": "z"])
    }

    func testIdentityMappingIsANoOp() {
        XCTAssertEqual(rekey(["1": "a"], ["1": "1"]), ["1": "a"])
    }

    /// Regression: mutating a copy while iterating `mapping` made this depend on `Dictionary`'s
    /// arbitrary iteration order, so display 1's wallpaper was sometimes silently discarded.
    func testChainedRemapKeepsBothDisplays() {
        // Run repeatedly because the old bug only appeared for certain iteration orders.
        for _ in 0..<200 {
            XCTAssertEqual(
                rekey(["1": "a", "2": "b"], ["1": "2", "2": "3"]),
                ["2": "a", "3": "b"]
            )
        }
    }

    func testSwappedDisplaysKeepBothValues() {
        for _ in 0..<200 {
            XCTAssertEqual(
                rekey(["1": "a", "2": "b"], ["1": "2", "2": "1"]),
                ["2": "a", "1": "b"]
            )
        }
    }

    func testRemappedEntryDisplacesStaleResident() {
        // Display 2 has just been reassigned, so the incoming value wins.
        XCTAssertEqual(rekey(["1": "a", "2": "stale"], ["1": "2"]), ["2": "a"])
    }

    func testNoValuesAreLostForInjectiveMappings() {
        let sources = ["1": "a", "2": "b", "3": "c"]
        let result = rekey(sources, ["1": "4", "2": "5", "3": "6"])
        XCTAssertEqual(result, ["4": "a", "5": "b", "6": "c"])
        XCTAssertEqual(Set(result.values), Set(sources.values))
    }

    func testWorksForNonStringValues() {
        let bookmarks = ["1": Data([0x01]), "2": Data([0x02])]
        let result = DisplayConfigurationMigrator.rekeyDictionary(bookmarks, mapping: ["1": "2", "2": "3"])
        XCTAssertEqual(result, ["2": Data([0x01]), "3": Data([0x02])])
    }

    // MARK: - migrationMapping

    private func signature(_ name: String, width: Int, height: Int) -> DisplayConfigurationMigrator.DisplaySignature {
        let key = "\(name)|\(width)|\(height)"
        return DisplayConfigurationMigrator.DisplaySignature(persistenceKey: key)!
    }

    func testMigrationMappingKeepsUnchangedDisplayIDs() {
        let builtIn = signature("Built-in Retina Display", width: 1728, height: 1117)
        let previous: [CGDirectDisplayID: DisplayConfigurationMigrator.DisplaySignature] = [1: builtIn]
        let current: [CGDirectDisplayID: DisplayConfigurationMigrator.DisplaySignature] = [1: builtIn]

        XCTAssertTrue(
            DisplayConfigurationMigrator.migrationMapping(
                previousSignatures: previous,
                currentSignatures: current
            ).isEmpty
        )
    }

    func testMigrationMappingRemapsRepluggedExternalToNewID() {
        let external = signature("LG UltraFine", width: 2560, height: 1440)
        let previous: [CGDirectDisplayID: DisplayConfigurationMigrator.DisplaySignature] = [
            1: signature("Built-in Retina Display", width: 1728, height: 1117),
            2: external,
        ]
        let current: [CGDirectDisplayID: DisplayConfigurationMigrator.DisplaySignature] = [
            1: signature("Built-in Retina Display", width: 1728, height: 1117),
            3: external,
        ]

        XCTAssertEqual(
            DisplayConfigurationMigrator.migrationMapping(
                previousSignatures: previous,
                currentSignatures: current
            ),
            ["2": "3"]
        )
    }

    func testMigrationMappingHandlesIDReuseAcrossMonitors() {
        let builtIn = signature("Built-in Retina Display", width: 1728, height: 1117)
        let external = signature("LG UltraFine", width: 2560, height: 1440)
        let previous: [CGDirectDisplayID: DisplayConfigurationMigrator.DisplaySignature] = [
            1: builtIn,
            2: external,
        ]
        // Same IDs, swapped physical panels (common after hotplug).
        let current: [CGDirectDisplayID: DisplayConfigurationMigrator.DisplaySignature] = [
            1: external,
            2: builtIn,
        ]

        XCTAssertEqual(
            DisplayConfigurationMigrator.migrationMapping(
                previousSignatures: previous,
                currentSignatures: current
            ),
            ["1": "2", "2": "1"]
        )
    }

    func testMigrationMappingSkipsOrphanedPreviousDisplays() {
        let missing = signature("Disconnected Panel", width: 1920, height: 1080)
        let previous: [CGDirectDisplayID: DisplayConfigurationMigrator.DisplaySignature] = [5: missing]
        let current: [CGDirectDisplayID: DisplayConfigurationMigrator.DisplaySignature] = [
            1: signature("Built-in Retina Display", width: 1728, height: 1117),
        ]

        XCTAssertTrue(
            DisplayConfigurationMigrator.migrationMapping(
                previousSignatures: previous,
                currentSignatures: current
            ).isEmpty
        )
    }
}
