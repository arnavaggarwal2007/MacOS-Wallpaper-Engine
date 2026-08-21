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
}
