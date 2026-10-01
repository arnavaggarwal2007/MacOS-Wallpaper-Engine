import XCTest
@testable import Personal_Wallpaper_Engine

final class AppLinksTests: XCTestCase {
    func testUserFacingLinksUseHTTPS() {
        for url in [AppLinks.privacyPolicy, AppLinks.support] {
            XCTAssertEqual(url.scheme, "https", "\(url) must use https")
        }
    }

    func testSupportLinkPointsAtHostedSupportPage() {
        XCTAssertEqual(AppLinks.support.host, "arnavaggarwal2007.github.io")
        XCTAssertTrue(
            AppLinks.support.path.hasPrefix("/MacOS-Wallpaper-Engine/support"),
            "Support link must resolve to the GitHub Pages support site, not Issues"
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
