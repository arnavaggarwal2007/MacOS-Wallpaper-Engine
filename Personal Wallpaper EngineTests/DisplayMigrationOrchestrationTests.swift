import XCTest
@testable import Personal_Wallpaper_Engine

final class DisplayMigrationOrchestrationTests: XCTestCase {
    private func signature(_ name: String, width: Int, height: Int) -> DisplayConfigurationMigrator.DisplaySignature {
        DisplayConfigurationMigrator.DisplaySignature(persistenceKey: "\(name)|\(width)|\(height)")!
    }

    // MARK: - previousSignaturesForColdStart

    func testColdStartBuildsFromPersistedSignatureKeys() {
        let builtIn = signature("Built-in Retina Display", width: 1728, height: 1117)
        let outcome = DisplayMigrationOrchestration.previousSignaturesForColdStart(
            perDisplaySignatureKeys: [builtIn.persistenceKey: "1"],
            persistedSettingsKeys: [],
            connectedSignatures: [:]
        )

        XCTAssertEqual(outcome.previous, [1: builtIn])
        XCTAssertEqual(outcome.settingsKeyBySignature, [builtIn: "1"])
        XCTAssertTrue(outcome.connectedDisplayIDsToPersist.isEmpty)
    }

    func testColdStartMergesConnectedDisplaysWithPersistedSettings() {
        let builtIn = signature("Built-in Retina Display", width: 1728, height: 1117)
        let external = signature("LG UltraFine", width: 2560, height: 1440)
        let outcome = DisplayMigrationOrchestration.previousSignaturesForColdStart(
            perDisplaySignatureKeys: [builtIn.persistenceKey: "1"],
            persistedSettingsKeys: ["2"],
            connectedSignatures: [1: builtIn, 2: external]
        )

        XCTAssertEqual(outcome.previous, [1: builtIn, 2: external])
        XCTAssertEqual(outcome.settingsKeyBySignature, [builtIn: "1", external: "2"])
        XCTAssertEqual(outcome.connectedDisplayIDsToPersist, [2])
    }

    func testColdStartSkipsInvalidPersistenceKeys() {
        let outcome = DisplayMigrationOrchestration.previousSignaturesForColdStart(
            perDisplaySignatureKeys: ["not-a-key": "1", "Built-in|bad|data": "2"],
            persistedSettingsKeys: [],
            connectedSignatures: [:]
        )

        XCTAssertTrue(outcome.previous.isEmpty)
        XCTAssertTrue(outcome.settingsKeyBySignature.isEmpty)
    }

    // MARK: - augmentedPreviousSignatures

    func testAugmentedIncludesDisconnectedLastSignatures() {
        let builtIn = signature("Built-in Retina Display", width: 1728, height: 1117)
        let external = signature("LG UltraFine", width: 2560, height: 1440)
        let augmented = DisplayMigrationOrchestration.augmentedPreviousSignatures(
            lastDisplaySignatures: [1: builtIn, 2: external],
            settingsKeyBySignature: [:],
            connectedDisplayIDs: [1]
        )

        XCTAssertEqual(augmented, [1: builtIn, 2: external])
    }

    func testAugmentedFillsFromSettingsKeyBySignature() {
        let external = signature("LG UltraFine", width: 2560, height: 1440)
        let augmented = DisplayMigrationOrchestration.augmentedPreviousSignatures(
            lastDisplaySignatures: [:],
            settingsKeyBySignature: [external: "2"],
            connectedDisplayIDs: [1]
        )

        XCTAssertEqual(augmented, [2: external])
    }

    func testAugmentedDoesNotOverwriteExistingEntries() {
        let external = signature("LG UltraFine", width: 2560, height: 1440)
        let stale = signature("LG UltraFine", width: 1920, height: 1080)
        let augmented = DisplayMigrationOrchestration.augmentedPreviousSignatures(
            lastDisplaySignatures: [2: stale],
            settingsKeyBySignature: [external: "2"],
            connectedDisplayIDs: [1]
        )

        XCTAssertEqual(augmented[2], stale)
    }

    // MARK: - migrateFocusedDisplayID

    func testFocusedDisplayRemapsViaMapping() {
        let builtIn = signature("Built-in Retina Display", width: 1728, height: 1117)
        let result = DisplayMigrationOrchestration.migrateFocusedDisplayID(
            currentFocusedID: 2,
            mapping: ["2": "3"],
            focusedSignatureBefore: builtIn,
            currentSignatures: [3: builtIn]
        )

        XCTAssertEqual(result, .resolved(3))
    }

    func testFocusedDisplayMatchesBySignatureWhenMappingMisses() {
        let builtIn = signature("Built-in Retina Display", width: 1728, height: 1117)
        let result = DisplayMigrationOrchestration.migrateFocusedDisplayID(
            currentFocusedID: 5,
            mapping: [:],
            focusedSignatureBefore: builtIn,
            currentSignatures: [1: builtIn]
        )

        XCTAssertEqual(result, .resolved(1))
    }

    func testFocusedDisplayNeedsSyncWhenUnresolved() {
        let builtIn = signature("Built-in Retina Display", width: 1728, height: 1117)
        let external = signature("LG UltraFine", width: 2560, height: 1440)
        let result = DisplayMigrationOrchestration.migrateFocusedDisplayID(
            currentFocusedID: 2,
            mapping: [:],
            focusedSignatureBefore: builtIn,
            currentSignatures: [1: external]
        )

        XCTAssertEqual(result, .needsSync)
    }

    func testFocusedDisplayNeedsSyncWhenNil() {
        XCTAssertEqual(
            DisplayMigrationOrchestration.migrateFocusedDisplayID(
                currentFocusedID: nil,
                mapping: ["1": "2"],
                focusedSignatureBefore: nil,
                currentSignatures: [:]
            ),
            .needsSync
        )
    }
}
