import XCTest
@testable import Personal_Wallpaper_Engine

final class AppInfoTests: XCTestCase {
    func testDisplayNameIsNeverEmpty() {
        XCTAssertFalse(AppInfo.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    func testVersionAndBuildAreNeverEmpty() {
        XCTAssertFalse(AppInfo.marketingVersion.isEmpty)
        XCTAssertFalse(AppInfo.buildNumber.isEmpty)
    }
}
