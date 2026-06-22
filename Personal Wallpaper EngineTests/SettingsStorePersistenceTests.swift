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
}
