import XCTest
@testable import Personal_Wallpaper_Engine

final class QuickModeTests: XCTestCase {
    func testSelectableModesExcludeCustom() {
        XCTAssertFalse(QuickMode.selectableCases.contains(.custom))
    }

    func testSelectableModesIncludeCorePresets() {
        XCTAssertTrue(QuickMode.selectableCases.contains(.singleAllDisplays))
        XCTAssertTrue(QuickMode.selectableCases.contains(.perDisplayCustom))
        XCTAssertTrue(QuickMode.selectableCases.contains(.pinnedSetup))
    }

    func testQuickModeRawValuesRoundTrip() {
        for mode in [QuickMode.singleAllDisplays, .perDisplayCustom, .pinnedSetup, .custom] {
            XCTAssertEqual(QuickMode(rawValue: mode.rawValue), mode)
        }
    }
}
