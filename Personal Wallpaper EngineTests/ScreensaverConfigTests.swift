import XCTest
@testable import Personal_Wallpaper_Engine

final class ScreensaverConfigTests: XCTestCase {
    private var container: URL!
    private var defaults: UserDefaults!
    private let suiteName = "test.screensaver.config.\(UUID().uuidString)"

    override func setUp() {
        super.setUp()
        container = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: container, withIntermediateDirectories: true)
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: container)
        super.tearDown()
    }

    func testVideoFileRejectsWebAndUnknownExtensions() {
        XCTAssertTrue(ScreensaverConfig.isVideoFile(URL(fileURLWithPath: "/tmp/clip.MP4")))
        XCTAssertTrue(ScreensaverConfig.isVideoFile(URL(fileURLWithPath: "/tmp/clip.mov")))
        XCTAssertFalse(ScreensaverConfig.isVideoFile(URL(string: "https://example.com/clip.mp4")!))
        XCTAssertFalse(ScreensaverConfig.isVideoFile(URL(fileURLWithPath: "/tmp/page.html")))
    }

    func testUnknownScalingFallsBackToFill() {
        XCTAssertEqual(ScreensaverConfig.normalizedScaling("resizeAspect"), ScreensaverConfig.Scaling.fit)
        XCTAssertEqual(ScreensaverConfig.normalizedScaling("nope"), ScreensaverConfig.Scaling.fill)
    }

    func testSnapshotRoundTrip() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let snapshot = ScreensaverConfig.Snapshot(
            videoPath: "Screensaver/clip.mp4",
            scalingMode: ScreensaverConfig.Scaling.fit,
            syncWithDesktop: true,
            muted: true,
            lastUpdated: now,
            sourceIdentity: "id-1"
        )
        snapshot.write(to: defaults)
        XCTAssertEqual(ScreensaverConfig.Snapshot.read(from: defaults), snapshot)
    }

    func testMissingMuteDefaultsToMuted() {
        defaults.set("resizeAspectFill", forKey: ScreensaverConfig.Key.scalingMode)
        let snapshot = ScreensaverConfig.Snapshot.read(from: defaults)
        XCTAssertTrue(snapshot.muted)
        XCTAssertNil(snapshot.lastUpdated)
        XCTAssertNil(snapshot.videoPath)
    }

    func testPublishCopiesVideoAndStoresRelativePath() throws {
        let source = try makeVideo(named: "clip.mp4", contents: "hello")
        let now = Date(timeIntervalSince1970: 1_700_000_100)
        let snapshot = try ScreensaverConfig.publish(
            source: source,
            scalingRaw: "resizeAspect",
            syncWithDesktop: true,
            sourceIdentity: "clip-v1",
            container: container,
            defaults: defaults,
            now: now
        )

        XCTAssertEqual(snapshot.videoPath, "Screensaver/clip.mp4")
        XCTAssertEqual(snapshot.scalingMode, ScreensaverConfig.Scaling.fit)
        XCTAssertTrue(snapshot.muted)
        XCTAssertEqual(snapshot.lastUpdated, now)
        let copied = container.appendingPathComponent("Screensaver/clip.mp4")
        XCTAssertEqual(try String(contentsOf: copied, encoding: .utf8), "hello")
        XCTAssertEqual(ScreensaverConfig.Snapshot.read(from: defaults), snapshot)
    }

    func testMatchingIdentitySkipsCopy() throws {
        let source = try makeVideo(named: "clip.mp4", contents: "hello")
        _ = try ScreensaverConfig.publish(
            source: source,
            scalingRaw: ScreensaverConfig.Scaling.fill,
            syncWithDesktop: true,
            sourceIdentity: "same",
            container: container,
            defaults: defaults,
            now: Date(timeIntervalSince1970: 10)
        )
        let copied = container.appendingPathComponent("Screensaver/clip.mp4")
        try "stale-marker".write(to: copied, atomically: true, encoding: .utf8)

        let refreshed = try ScreensaverConfig.publish(
            source: source,
            scalingRaw: ScreensaverConfig.Scaling.stretch,
            syncWithDesktop: true,
            sourceIdentity: "same",
            container: container,
            defaults: defaults,
            now: Date(timeIntervalSince1970: 20)
        )

        XCTAssertEqual(refreshed.scalingMode, ScreensaverConfig.Scaling.stretch)
        XCTAssertEqual(try String(contentsOf: copied, encoding: .utf8), "stale-marker")
    }

    func testNewIdentityReplacesFileAndRemovesPreviousName() throws {
        let first = try makeVideo(named: "one.mp4", contents: "one")
        _ = try ScreensaverConfig.publish(
            source: first,
            scalingRaw: ScreensaverConfig.Scaling.fill,
            syncWithDesktop: false,
            sourceIdentity: "one",
            container: container,
            defaults: defaults
        )
        let second = try makeVideo(named: "two.mov", contents: "two")
        let snapshot = try ScreensaverConfig.publish(
            source: second,
            scalingRaw: ScreensaverConfig.Scaling.fill,
            syncWithDesktop: false,
            sourceIdentity: "two",
            container: container,
            defaults: defaults
        )

        XCTAssertEqual(snapshot.videoPath, "Screensaver/two.mov")
        XCTAssertFalse(FileManager.default.fileExists(atPath: container.appendingPathComponent("Screensaver/one.mp4").path))
        XCTAssertEqual(
            try String(contentsOf: container.appendingPathComponent("Screensaver/two.mov"), encoding: .utf8),
            "two"
        )
    }

    func testFailedCopyLeavesPreviousSnapshotUntouched() throws {
        let source = try makeVideo(named: "clip.mp4", contents: "hello")
        let published = try ScreensaverConfig.publish(
            source: source,
            scalingRaw: ScreensaverConfig.Scaling.fill,
            syncWithDesktop: true,
            sourceIdentity: "ok",
            container: container,
            defaults: defaults,
            now: Date(timeIntervalSince1970: 5)
        )
        let missing = container.appendingPathComponent("missing.mp4")

        XCTAssertThrowsError(
            try ScreensaverConfig.publish(
                source: missing,
                scalingRaw: ScreensaverConfig.Scaling.fit,
                syncWithDesktop: false,
                sourceIdentity: "missing",
                container: container,
                defaults: defaults
            )
        ) { error in
            XCTAssertEqual(error as? ScreensaverConfig.PublishError, .unreadableSource)
        }
        XCTAssertEqual(ScreensaverConfig.Snapshot.read(from: defaults), published)
    }

    func testNonVideoDoesNotWriteSnapshot() {
        let source = URL(fileURLWithPath: "/tmp/page.html")
        XCTAssertThrowsError(
            try ScreensaverConfig.publish(
                source: source,
                scalingRaw: ScreensaverConfig.Scaling.fill,
                syncWithDesktop: true,
                sourceIdentity: "web",
                container: container,
                defaults: defaults
            )
        ) { error in
            XCTAssertEqual(error as? ScreensaverConfig.PublishError, .notAVideo)
        }
        XCTAssertNil(ScreensaverConfig.Snapshot.read(from: defaults).videoPath)
    }

    func testResolvedMediaURLAndMissingFileStatus() throws {
        let source = try makeVideo(named: "clip.mp4", contents: "hello")
        let snapshot = try ScreensaverConfig.publish(
            source: source,
            scalingRaw: ScreensaverConfig.Scaling.fill,
            syncWithDesktop: false,
            sourceIdentity: "id",
            container: container,
            defaults: defaults
        )
        let resolved = ScreensaverConfig.resolvedMediaURL(relativePath: snapshot.videoPath, container: container)
        XCTAssertEqual(resolved?.lastPathComponent, "clip.mp4")
        XCTAssertTrue(ScreensaverConfig.mediaExists(relativePath: snapshot.videoPath, container: container))
        XCTAssertFalse(ScreensaverConfig.mediaExists(relativePath: snapshot.videoPath, container: nil))

        let missing = ScreensaverConfig.statusMessage(
            fileName: nil,
            mediaExists: false,
            lastUpdated: nil,
            syncWithDesktop: false,
            desktopVideoAvailable: true
        )
        XCTAssertTrue(missing.contains("No screen saver video yet"))

        let web = ScreensaverConfig.statusMessage(
            fileName: "clip.mp4",
            mediaExists: true,
            lastUpdated: Date(timeIntervalSince1970: 5),
            syncWithDesktop: true,
            desktopVideoAvailable: false
        )
        XCTAssertTrue(web.contains("not using a video"))
        XCTAssertTrue(web.contains("left unchanged"))
    }

    private func makeVideo(named: String, contents: String) throws -> URL {
        let url = container.appendingPathComponent("sources", isDirectory: true)
            .appendingPathComponent(named)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
