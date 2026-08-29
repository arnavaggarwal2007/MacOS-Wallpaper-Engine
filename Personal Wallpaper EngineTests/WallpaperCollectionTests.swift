import XCTest
@testable import Personal_Wallpaper_Engine

final class WallpaperCollectionTests: XCTestCase {
    // MARK: - Collection name validation

    func testValidCollectionNames() {
        XCTAssertTrue(isValidCollectionName("Silver Surfer"))
        XCTAssertTrue(isValidCollectionName("A"))
        XCTAssertTrue(isValidCollectionName(String(repeating: "x", count: 255)))
    }

    func testInvalidCollectionNames() {
        XCTAssertFalse(isValidCollectionName(""))
        XCTAssertFalse(isValidCollectionName("   "))
        XCTAssertFalse(isValidCollectionName("bad/name"))
        XCTAssertFalse(isValidCollectionName("bad\\name"))
        XCTAssertFalse(isValidCollectionName("bad*name"))
        XCTAssertFalse(isValidCollectionName(String(repeating: "x", count: 256)))
    }

    // MARK: - Source URL validation

    func testValidSourceURLs() {
        XCTAssertTrue(isValidSourceURL("file:///Users/me/wallpaper.mp4"))
        XCTAssertTrue(isValidSourceURL("https://example.com/page"))
        XCTAssertTrue(isValidSourceURL("http://example.com/page"))
        XCTAssertTrue(isValidSourceURL("/Users/me/wallpaper.mp4"))
        XCTAssertTrue(isValidSourceURL("wallpaper.mp4"))
    }

    func testInvalidSourceURLs() {
        XCTAssertFalse(isValidSourceURL(""))
        XCTAssertFalse(isValidSourceURL("   "))
        XCTAssertFalse(isValidSourceURL("not a url"))
    }

    // MARK: - Init and update

    func testInitThrowsForInvalidName() {
        XCTAssertThrowsError(try WallpaperCollection(name: "bad/name")) { error in
            guard case WallpaperError.internalError = error else {
                return XCTFail("Expected internalError")
            }
        }
    }

    func testInitSucceedsForValidCollection() throws {
        let collection = try WallpaperCollection(name: "Valid", collectionType: .displayBound)
        XCTAssertEqual(collection.name, "Valid")
        XCTAssertEqual(collection.collectionType, .displayBound)
        XCTAssertFalse(collection.id.isEmpty)
    }

    func testUpdatedRejectsInvalidRename() throws {
        let collection = try WallpaperCollection(name: "Original")
        XCTAssertThrowsError(try collection.updated(name: "bad/name"))
    }

    func testUpdatedPreservesID() throws {
        let collection = try WallpaperCollection(name: "Original", description: "old")
        let updated = try collection.updated(name: "Renamed", description: "new")
        XCTAssertEqual(updated.id, collection.id)
        XCTAssertEqual(updated.name, "Renamed")
        XCTAssertEqual(updated.description, "new")
    }

    func testCollectionSourceInitValidatesURL() {
        XCTAssertThrowsError(
            try CollectionSource(url: "not valid", order: 0)
        )
        XCTAssertNoThrow(
            try CollectionSource(url: "https://example.com", order: 0)
        )
    }

    // MARK: - Codable round-trip

    func testWallpaperCollectionCodableRoundTrip() throws {
        let source = CollectionSource(
            id: "src-1",
            url: "file:///tmp/a.mp4",
            displayLabel: "Built-in",
            displayIDFallback: 1,
            scalingMode: VideoScalingMode.resizeAspectFill.rawValue,
            order: 0
        )
        let original = WallpaperCollection(
            id: "col-1",
            name: "Test",
            description: "desc",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_700_000_100),
            collectionType: .displayBound,
            sources: [source]
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WallpaperCollection.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.description, original.description)
        XCTAssertEqual(decoded.collectionType, original.collectionType)
        XCTAssertEqual(decoded.sources.count, 1)
        XCTAssertEqual(decoded.sources[0].url, source.url)
        XCTAssertEqual(decoded.sources[0].displayLabel, source.displayLabel)
    }
}
