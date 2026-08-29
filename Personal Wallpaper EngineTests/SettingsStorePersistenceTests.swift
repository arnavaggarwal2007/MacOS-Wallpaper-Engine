import XCTest
@testable import Personal_Wallpaper_Engine

final class SettingsStorePersistenceTests: XCTestCase {
    func testQuickModeWritesUserDefaultsKey() {
        let store = SettingsStore.shared
        let original = store.quickMode
        defer { store.quickMode = original }

        store.quickMode = .singleAllDisplays
        XCTAssertEqual(
            UserDefaults.standard.string(forKey: "quickMode"),
            QuickMode.singleAllDisplays.rawValue
        )
    }

    func testHomeSidebarVisiblePersists() {
        let store = SettingsStore.shared
        let original = store.homeSidebarVisible
        defer { store.homeSidebarVisible = original }

        store.homeSidebarVisible = true
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "homeSidebarVisible"))
    }

    // MARK: - Unreadable stored data

    private func withTemporaryKey(_ key: String, _ body: (String) -> Void) {
        let defaults = UserDefaults.standard
        defer {
            defaults.removeObject(forKey: key)
            defaults.removeObject(forKey: SettingsStore.quarantineKey(for: key))
        }
        body(key)
    }

    func testMissingKeyReturnsFallbackWithoutQuarantine() {
        withTemporaryKey("test.decode.missing") { key in
            let decoded = SettingsStore.decodePersisted([String: String].self, forKey: key, default: [:])
            XCTAssertTrue(decoded.isEmpty)
            XCTAssertNil(UserDefaults.standard.data(forKey: SettingsStore.quarantineKey(for: key)))
        }
    }

    func testValidDataDecodesAndIsNotQuarantined() {
        withTemporaryKey("test.decode.valid") { key in
            let stored = ["1": "wallpaper.mp4"]
            UserDefaults.standard.set(try! JSONEncoder().encode(stored), forKey: key)

            let decoded = SettingsStore.decodePersisted([String: String].self, forKey: key, default: [:])
            XCTAssertEqual(decoded, stored)
            XCTAssertNil(UserDefaults.standard.data(forKey: SettingsStore.quarantineKey(for: key)))
        }
    }

    /// Unreadable data must not vanish: the fallback gets written straight back by the property's
    /// `didSet`, so the only copy of the user's setups would otherwise be gone for good.
    func testUnreadableDataIsQuarantinedRatherThanDiscarded() {
        withTemporaryKey("test.decode.corrupt") { key in
            let garbage = Data("not json at all".utf8)
            UserDefaults.standard.set(garbage, forKey: key)

            let decoded = SettingsStore.decodePersisted([String: String].self, forKey: key, default: [:])
            XCTAssertTrue(decoded.isEmpty, "Falls back so the app still launches")
            XCTAssertEqual(
                UserDefaults.standard.data(forKey: SettingsStore.quarantineKey(for: key)),
                garbage,
                "Original bytes must be recoverable"
            )
        }
    }

    func testTypeMismatchIsAlsoQuarantined() {
        withTemporaryKey("test.decode.mismatch") { key in
            let wrongShape = try! JSONEncoder().encode(["a", "b"])
            UserDefaults.standard.set(wrongShape, forKey: key)

            let decoded = SettingsStore.decodePersisted([String: String].self, forKey: key, default: [:])
            XCTAssertTrue(decoded.isEmpty)
            XCTAssertEqual(
                UserDefaults.standard.data(forKey: SettingsStore.quarantineKey(for: key)),
                wrongShape
            )
        }
    }

    // MARK: - Per-display signature keys

    func testPerDisplaySignatureKeyRoundTrips() {
        let store = SettingsStore.shared
        let original = store.perDisplaySignatureKeys
        defer { store.perDisplaySignatureKeys = original }

        store.setPerDisplaySignatureKey("Built-in Retina Display|1728|1117", settingsKey: "1")
        XCTAssertEqual(store.perDisplaySignatureKeys["Built-in Retina Display|1728|1117"], "1")

        store.setPerDisplaySignatureKey("Built-in Retina Display|1728|1117", settingsKey: "3")
        XCTAssertEqual(store.perDisplaySignatureKeys["Built-in Retina Display|1728|1117"], "3")
    }

    // MARK: - Collection CRUD

    private func withIsolatedCollections(_ body: () -> Void) {
        let store = SettingsStore.shared
        let originalCollections = store.savedCollections
        let originalLastUsed = store.lastUsedCollectionName
        defer {
            store.savedCollections = originalCollections
            store.lastUsedCollectionName = originalLastUsed
        }
        body()
    }

    func testSaveAndLoadCollection() {
        withIsolatedCollections {
            let store = SettingsStore.shared
            let name = "Test Collection \(UUID().uuidString)"

            let saveResult = store.saveCollection(name: name, description: "desc")
            guard case .success(let collection) = saveResult else {
                return XCTFail("Expected save success")
            }
            XCTAssertEqual(collection.name, name)

            guard case .success(let loaded) = store.loadCollection(name: name) else {
                return XCTFail("Expected load success")
            }
            XCTAssertEqual(loaded.id, collection.id)
            XCTAssertEqual(loaded.description, "desc")
        }
    }

    func testUpdateCollectionRenamesAndUpdatesLastUsed() {
        withIsolatedCollections {
            let store = SettingsStore.shared
            let oldName = "Old \(UUID().uuidString)"
            let newName = "New \(UUID().uuidString)"

            _ = store.saveCollection(name: oldName)
            store.lastUsedCollectionName = oldName

            guard case .success(let updated) = store.updateCollection(name: oldName, newName: newName) else {
                return XCTFail("Expected update success")
            }
            XCTAssertEqual(updated.name, newName)
            XCTAssertNil(store.savedCollections[oldName])
            XCTAssertNotNil(store.savedCollections[newName])
            XCTAssertEqual(store.lastUsedCollectionName, newName)
        }
    }

    func testDeleteCollectionClearsLastUsed() {
        withIsolatedCollections {
            let store = SettingsStore.shared
            let name = "Delete Me \(UUID().uuidString)"

            _ = store.saveCollection(name: name)
            store.lastUsedCollectionName = name

            guard case .success = store.deleteCollection(name: name) else {
                return XCTFail("Expected delete success")
            }
            XCTAssertNil(store.savedCollections[name])
            XCTAssertNil(store.lastUsedCollectionName)
        }
    }

    func testSaveCollectionRejectsInvalidName() {
        withIsolatedCollections {
            let store = SettingsStore.shared
            let result = store.saveCollection(name: "bad/name")
            guard case .failure = result else {
                return XCTFail("Expected failure for invalid name")
            }
        }
    }

    // MARK: - Setup CRUD

    private func withIsolatedSetups(_ body: () -> Void) {
        let store = SettingsStore.shared
        let originalSetups = store.savedSetups
        let originalCurrent = store.currentSetupName
        defer {
            store.savedSetups = originalSetups
            store.currentSetupName = originalCurrent
        }
        body()
    }

    private func minimalSetupParams(name: String) -> (
        rendererMode: String,
        isMuted: Bool,
        scalingMode: String,
        usePerDisplay: Bool,
        unifiedSource: String?,
        perDisplaySources: [String: String],
        perDisplayScalingModes: [String: String],
        unifiedBookmarkBase64: String?,
        perDisplayBookmarksBase64: [String: String]
    ) {
        (
            WallpaperRendererMode.video.rawValue,
            false,
            VideoScalingMode.resizeAspectFill.rawValue,
            false,
            "file:///tmp/wallpaper.mp4",
            [:],
            [:],
            nil,
            [:]
        )
    }

    func testSaveLoadAndDeleteSetup() {
        withIsolatedSetups {
            let store = SettingsStore.shared
            let name = "Setup \(UUID().uuidString)"
            let params = minimalSetupParams(name: name)

            guard case .success(let saved) = store.saveSetup(
                name: name,
                rendererMode: params.rendererMode,
                isMuted: params.isMuted,
                scalingMode: params.scalingMode,
                usePerDisplay: params.usePerDisplay,
                unifiedSource: params.unifiedSource,
                perDisplaySources: params.perDisplaySources,
                perDisplayScalingModes: params.perDisplayScalingModes,
                unifiedBookmarkBase64: params.unifiedBookmarkBase64,
                perDisplayBookmarksBase64: params.perDisplayBookmarksBase64
            ) else {
                return XCTFail("Expected save success")
            }
            XCTAssertEqual(saved.name, name)

            store.currentSetupName = name

            guard case .success(let loaded) = store.loadSetup(name: name) else {
                return XCTFail("Expected load success")
            }
            XCTAssertEqual(loaded.unifiedSource, params.unifiedSource)

            guard case .success = store.deleteSetup(name: name) else {
                return XCTFail("Expected delete success")
            }
            XCTAssertNil(store.savedSetups[name])
            XCTAssertNil(store.currentSetupName)
        }
    }

    func testSaveSetupRejectsEmptyName() {
        withIsolatedSetups {
            let store = SettingsStore.shared
            let params = minimalSetupParams(name: "")
            let result = store.saveSetup(
                name: "   ",
                rendererMode: params.rendererMode,
                isMuted: params.isMuted,
                scalingMode: params.scalingMode,
                usePerDisplay: params.usePerDisplay,
                unifiedSource: params.unifiedSource,
                perDisplaySources: params.perDisplaySources,
                perDisplayScalingModes: params.perDisplayScalingModes,
                unifiedBookmarkBase64: params.unifiedBookmarkBase64,
                perDisplayBookmarksBase64: params.perDisplayBookmarksBase64
            )
            guard case .failure = result else {
                return XCTFail("Expected failure for empty setup name")
            }
        }
    }

    // MARK: - Recent library items

    func testRecordRecentLibraryItemDedupesAndCaps() {
        let store = SettingsStore.shared
        let original = store.recentLibraryItemIDs
        defer { store.recentLibraryItemIDs = original }

        store.recentLibraryItemIDs = []
        store.recordRecentLibraryItem(id: "a", maxCount: 3)
        store.recordRecentLibraryItem(id: "b", maxCount: 3)
        store.recordRecentLibraryItem(id: "c", maxCount: 3)
        store.recordRecentLibraryItem(id: "d", maxCount: 3)
        XCTAssertEqual(store.recentLibraryItemIDs, ["d", "c", "b"])

        store.recordRecentLibraryItem(id: "b", maxCount: 3)
        XCTAssertEqual(store.recentLibraryItemIDs, ["b", "d", "c"])
    }
}
