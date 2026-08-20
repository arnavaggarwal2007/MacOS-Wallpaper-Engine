import XCTest
@testable import Personal_Wallpaper_Engine

final class UpdateCheckerTests: XCTestCase {
    func testUpdatesDescriptionMentionsAppStoreWhenBuiltForMAS() {
        #if APP_STORE_BUILD
        XCTAssertTrue(UpdateChecker.updatesDescription.contains("Mac App Store"))
        XCTAssertTrue(UpdateChecker.isAppStoreBuild)
        #else
        XCTAssertTrue(UpdateChecker.updatesDescription.contains("GitHub"))
        XCTAssertFalse(UpdateChecker.isAppStoreBuild)
        #endif
    }
}
