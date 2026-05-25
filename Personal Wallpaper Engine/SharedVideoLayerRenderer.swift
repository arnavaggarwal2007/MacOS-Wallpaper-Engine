import AppKit

/// Per-display layer attachment into a shared `SharedVideoPlaybackSession`.
@MainActor
final class SharedVideoLayerRenderer: Renderer {
    private let displayID: CGDirectDisplayID
    private let session: SharedVideoPlaybackSession
    private var scalingMode: VideoScalingMode = .resizeAspectFill
    private var isAttached = false

    init(displayID: CGDirectDisplayID, session: SharedVideoPlaybackSession) {
        self.displayID = displayID
        self.session = session
    }

    func start(in containerView: NSView) async -> Result<Void, WallpaperError> {
        let result = session.attachLayer(
            displayID: displayID,
            containerView: containerView,
            scalingMode: scalingMode
        )
        if case .success = result {
            isAttached = true
        }
        return result
    }

    func loadVideo(url: URL, autoPlay: Bool = true) async -> Result<Void, WallpaperError> {
        await session.loadVideo(url: url, autoPlay: autoPlay)
    }

    func stop() async {
        await pause()
    }

    func pause() async {
        await session.pause()
    }

    func resume() async {
        await session.resume()
    }

    func applyPerformanceProfile(_ profile: PerformanceProfile) async {
        session.applyPerformanceProfile(profile)
    }

    var currentPlaybackRate: Float {
        session.currentPlaybackRate
    }

    var isActivelyPlaying: Bool {
        session.isActivelyPlaying
    }

    func isValid() -> Bool {
        guard isAttached else { return false }
        return session.isValid(displayID: displayID)
    }

    func isMuted() async -> Bool {
        session.isMuted()
    }

    func scalingMode() async -> VideoScalingMode {
        session.scalingMode(displayID: displayID)
    }

    func setMuted(_ isMuted: Bool) async {
        session.setMuted(isMuted)
    }

    func setScalingMode(_ mode: VideoScalingMode) async {
        scalingMode = mode
        session.setScalingMode(mode, displayID: displayID)
    }

    func resize(to newSize: CGSize) async {
        session.resize(displayID: displayID, to: newSize)
    }

    func dispose() async {
        session.detachLayer(displayID: displayID)
        isAttached = false
    }
}
