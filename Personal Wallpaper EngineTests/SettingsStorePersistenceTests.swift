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
}
