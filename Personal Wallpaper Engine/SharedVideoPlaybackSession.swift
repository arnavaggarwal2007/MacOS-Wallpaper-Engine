import AppKit
import AVFoundation
import os.log

/// One `AVPlayer` decode shared across multiple desktop `AVPlayerLayer`s (Phase 7B P2).
@MainActor
final class SharedVideoPlaybackSession {
    private let logger = Logger(subsystem: "com.local.wallpaper", category: "SharedVideoPlaybackSession")

    private var player: AVPlayer?
    private var endObserver: NSObjectProtocol?
    private var activeVideoURL: URL?
    private var isAccessingSecurityScopedResource = false
    private var allowsPlaybackAdvance = true
    private var performanceProfile: PerformanceProfile = .balanced

    private struct LayerAttachment {
        weak var containerView: NSView?
        let playerLayer: AVPlayerLayer
        var videoGravity: AVLayerVideoGravity
    }

    private var layers: [CGDirectDisplayID: LayerAttachment] = [:]
    private var heroPreviewLayer: AVPlayerLayer?
    private weak var heroPreviewContainer: NSView?

    var attachedDisplayCount: Int { layers.count }

    func matchesURL(_ url: URL) -> Bool {
        guard let activeVideoURL else { return false }
        return normalizedPath(activeVideoURL) == normalizedPath(url)
    }

    func attachLayer(
        displayID: CGDirectDisplayID,
        containerView: NSView,
        scalingMode: VideoScalingMode
    ) -> Result<Void, WallpaperError> {
        ensurePlayerExists()

        containerView.layoutSubtreeIfNeeded()
        let bounds = containerView.bounds
        guard !bounds.isEmpty else {
            return .failure(.windowCreationFailed(reason: "Container view has zero bounds after layout"))
        }

        if let existing = layers[displayID] {
            existing.playerLayer.removeFromSuperlayer()
            layers.removeValue(forKey: displayID)
        }

        let gravity = scalingMode.avLayerVideoGravity
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = gravity
        layer.frame = bounds

        containerView.wantsLayer = true
        guard let contentLayer = containerView.layer else {
            return .failure(.rendererInitializationFailed(reason: "Container view layer initialization failed"))
        }
        contentLayer.addSublayer(layer)

        layers[displayID] = LayerAttachment(
            containerView: containerView,
            playerLayer: layer,
            videoGravity: gravity
        )
        logger.info("Shared video layer attached display=\(DisplayController.logLabel(for: displayID), privacy: .public) attachments=\(self.layers.count)")
        return .success(())
    }

    func detachLayer(displayID: CGDirectDisplayID) {
        guard let attachment = layers.removeValue(forKey: displayID) else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        attachment.playerLayer.removeFromSuperlayer()
        CATransaction.commit()
        logger.info("Shared video layer detached display=\(DisplayController.logLabel(for: displayID), privacy: .public) attachments=\(self.layers.count)")
        if layers.isEmpty {
            tearDownPlayback()
        }
    }

    func loadVideo(url: URL, autoPlay: Bool) async -> Result<Void, WallpaperError> {
        allowsPlaybackAdvance = autoPlay

        if matchesURL(url), player?.currentItem != nil {
            if autoPlay {
                startContinuousPlaybackIfAllowed()
            } else {
                player?.pause()
            }
            return .success(())
        }

        tearDownPlayback(keepLayers: true)
        ensurePlayerExists()

        isAccessingSecurityScopedResource = url.startAccessingSecurityScopedResource()
        activeVideoURL = url

        guard FileManager.default.fileExists(atPath: url.path) else {
            stopSecurityScopedAccessIfNeeded()
            return .failure(.videoFileNotFound(path: url.path))
        }

        guard FileManager.default.isReadableFile(atPath: url.path) else {
            stopSecurityScopedAccessIfNeeded()
            return .failure(.videoFileNotReadable(path: url.path))
        }

        let asset = AVURLAsset(url: url)
        do {
            let isPlayable = try await asset.load(.isPlayable)
            guard isPlayable else {
                stopSecurityScopedAccessIfNeeded()
                return .failure(.videoDecodingFailed(url: url, reason: "Asset is not playable"))
            }
        } catch {
            stopSecurityScopedAccessIfNeeded()
            return .failure(.videoDecodingFailed(url: url, reason: error.localizedDescription))
        }

        let playerItem = AVPlayerItem(asset: asset)
        PerformanceProfileConfiguration.apply(to: playerItem, profile: performanceProfile)
        updatePlaybackObserver(for: playerItem)
        player?.replaceCurrentItem(with: playerItem)

        for (displayID, attachment) in layers {
            attachment.playerLayer.player = player
            logger.debug("Shared session rebound player to display \(displayID)")
        }

        if autoPlay {
            startContinuousPlaybackIfAllowed()
            logger.info("Shared video loaded and playback started: \(url.lastPathComponent)")
        } else {
            player?.pause()
            logger.info("Shared video loaded paused: \(url.lastPathComponent)")
        }
        return .success(())
    }

    func pause() async {
        allowsPlaybackAdvance = false
        guard let player else { return }
        player.currentItem?.cancelPendingSeeks()
        player.pause()
        player.rate = 0
        logger.info("Shared video pause rate=\(player.rate)")
    }

    func resume() async {
        allowsPlaybackAdvance = true
        startContinuousPlaybackIfAllowed()
        logger.info("Shared video resume rate=\(self.player?.rate ?? -1)")
    }

    func applyPerformanceProfile(_ profile: PerformanceProfile) {
        performanceProfile = profile
        if let item = player?.currentItem {
            PerformanceProfileConfiguration.apply(to: item, profile: profile)
        }
        if allowsPlaybackAdvance {
            startContinuousPlaybackIfAllowed()
        }
    }

    func setMuted(_ isMuted: Bool) {
        player?.isMuted = isMuted
    }

    func setScalingMode(_ mode: VideoScalingMode, displayID: CGDirectDisplayID) {
        guard var attachment = layers[displayID] else { return }
        let gravity = mode.avLayerVideoGravity
        attachment.videoGravity = gravity
        attachment.playerLayer.videoGravity = gravity
        layers[displayID] = attachment
    }

    func resize(displayID: CGDirectDisplayID, to newSize: CGSize) {
        layers[displayID]?.playerLayer.frame = CGRect(origin: .zero, size: newSize)
    }

    func isMuted() -> Bool {
        player?.isMuted ?? true
    }

    func scalingMode(displayID: CGDirectDisplayID) -> VideoScalingMode {
        let gravity = layers[displayID]?.videoGravity ?? .resizeAspectFill
        switch gravity {
        case .resizeAspect: return .resizeAspect
        case .resize: return .resizeAspectHeight
        default: return .resizeAspectFill
        }
    }

    func isValid(displayID: CGDirectDisplayID) -> Bool {
        guard let player, player.currentItem != nil else { return false }
        guard let layer = layers[displayID]?.playerLayer, layer.superlayer != nil else { return false }
        return true
    }

    var currentPlaybackRate: Float {
        player?.rate ?? 0
    }

    var isActivelyPlaying: Bool {
        guard allowsPlaybackAdvance, let player else { return false }
        return player.rate > 0.01
    }

    func matchesHeroPreviewURL(_ url: URL) -> Bool {
        matchesURL(url) && player?.currentItem != nil
    }

    @discardableResult
    func attachHeroPreviewLayer(in containerView: NSView, videoGravity: AVLayerVideoGravity = .resizeAspectFill) -> Bool {
        guard let player else { return false }

        if containerView.bounds.isEmpty {
            containerView.layoutSubtreeIfNeeded()
        }
        let bounds = containerView.bounds
        guard !bounds.isEmpty else { return false }

        if heroPreviewContainer === containerView, let layer = heroPreviewLayer {
            layer.frame = bounds
            return true
        }

        detachHeroPreviewLayer()

        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = videoGravity
        layer.frame = bounds

        containerView.wantsLayer = true
        guard let contentLayer = containerView.layer else { return false }
        contentLayer.addSublayer(layer)
        heroPreviewLayer = layer
        heroPreviewContainer = containerView
        return true
    }

    func updateHeroPreviewLayerFrame(in containerView: NSView) {
        guard heroPreviewContainer === containerView, let layer = heroPreviewLayer else { return }
        layer.frame = containerView.bounds
    }

    func detachHeroPreviewLayer() {
        heroPreviewLayer?.removeFromSuperlayer()
        heroPreviewLayer = nil
        heroPreviewContainer = nil
    }

    private func ensurePlayerExists() {
        guard player == nil else { return }
        let newPlayer = AVPlayer()
        newPlayer.isMuted = true
        newPlayer.actionAtItemEnd = .pause
        newPlayer.automaticallyWaitsToMinimizeStalling = true
        player = newPlayer
    }

    private func startContinuousPlaybackIfAllowed() {
        guard allowsPlaybackAdvance, let player else { return }
        player.play()
    }

    /// Clears shared player state during engine restart (Phase 7C).
    func resetForEngineRestart() {
        tearDownPlayback(keepLayers: false)
    }

    private func tearDownPlayback(keepLayers: Bool = false) {
        detachHeroPreviewLayer()
        player?.pause()
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
            endObserver = nil
        }
        player?.replaceCurrentItem(with: nil)
        player = nil
        activeVideoURL = nil
        stopSecurityScopedAccessIfNeeded()
        if !keepLayers {
            for displayID in Array(layers.keys) {
                detachLayer(displayID: displayID)
            }
        }
    }

    private func updatePlaybackObserver(for playerItem: AVPlayerItem) {
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
            endObserver = nil
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handlePlaybackEnded()
            }
        }
    }

    private func handlePlaybackEnded() {
        guard allowsPlaybackAdvance else { return }
        player?.seek(to: .zero)
        player?.play()
    }

    private func stopSecurityScopedAccessIfNeeded() {
        if isAccessingSecurityScopedResource {
            activeVideoURL?.stopAccessingSecurityScopedResource()
            isAccessingSecurityScopedResource = false
        }
    }

    private func normalizedPath(_ url: URL) -> String {
        url.isFileURL ? url.standardizedFileURL.resolvingSymlinksInPath().path : url.absoluteString
    }
}

extension SharedVideoPlaybackSession: DesktopVideoPreviewProviding {}
