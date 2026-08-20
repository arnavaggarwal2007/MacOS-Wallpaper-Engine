import XCTest
@testable import Personal_Wallpaper_Engine

final class WebWallpaperURLValidatorTests: XCTestCase {
    func testAllowsHTTPSURL() {
        let url = URL(string: "https://example.com/wallpaper.html")!
        XCTAssertTrue(WebWallpaperURLValidator.isAllowed(url))
        XCTAssertEqual(
            WebWallpaperURLValidator.validatedURL(from: "https://example.com/wallpaper.html")?.absoluteString,
            url.absoluteString
        )
    }

    func testRejectsHTTPURL() {
        XCTAssertNil(WebWallpaperURLValidator.validatedURL(from: "http://example.com/page.html"))
    }

    func testRejectsJavaScriptScheme() {
        XCTAssertNil(WebWallpaperURLValidator.validatedURL(from: "javascript:alert(1)"))
    }

    func testAllowsLocalFilePath() {
        let url = WebWallpaperURLValidator.validatedURL(from: "/Users/test/wallpaper.html")
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.isFileURL == true)
    }

    func testRejectsEmptyString() {
        XCTAssertNil(WebWallpaperURLValidator.validatedURL(from: "   "))
    }
}
