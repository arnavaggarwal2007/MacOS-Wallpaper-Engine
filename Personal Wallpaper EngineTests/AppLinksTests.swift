import XCTest
@testable import Personal_Wallpaper_Engine

final class AppLinksTests: XCTestCase {
    func testUserFacingLinksUseHTTPS() {
        for url in [AppLinks.privacyPolicy, AppLinks.support] {
            XCTAssertEqual(url.scheme, "https", "\(url) must use https")
        }
    }

    func testSupportLinkPointsAtTheProjectRepository() {
        XCTAssertEqual(AppLinks.support.host, "github.com")
        XCTAssertTrue(
            AppLinks.support.path.hasPrefix("/arnavaggarwal2007/MacOS-Wallpaper-Engine"),
            "Support link must resolve to the real repository, not a placeholder"
        )
    }

    /// Guideline 3.1.1: App Store builds must not expose an external update channel.
    func testReleaseNotesLinkIsCompiledOutOfAppStoreBuilds() {
        #if APP_STORE_BUILD
        XCTAssertTrue(UpdateChecker.isAppStoreBuild)
        #else
        XCTAssertTrue(AppLinks.releaseNotes.path.hasSuffix("/releases"))
        XCTAssertEqual(AppLinks.releaseNotes.host, "github.com")
        #endif
    }
}
