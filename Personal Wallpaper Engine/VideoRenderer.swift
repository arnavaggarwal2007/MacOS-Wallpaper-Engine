import AppKit
import AVFoundation
import os.log

@MainActor
final class VideoRenderer: Renderer {
    private let logger = Logger(subsystem: "com.local.wallpaper", category: "VideoRenderer")
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private weak var containerView: NSView?
    private var endObserver: NSObjectProtocol?
    private var videoGravity: AVLayerVideoGravity = .resizeAspectFill
    private var isAccessingSecurityScopedResource = false
    private var activeVideoURL: URL?
    private var allowsPlaybackAdvance = true
    private var performanceProfile: PerformanceProfile = .balanced
    private var heroPreviewLayer: AVPlayerLayer?
    private weak var heroPreviewContainer: NSView?

    func start(in containerView: NSView) async -> Result<Void, WallpaperError> {
        self.containerView = containerView

        containerView.layoutSubtreeIfNeeded()
        let bounds = containerView.bounds
        guard !bounds.isEmpty else {
            logger.error("Container view has zero bounds: \(String(describing: bounds))")
            return .failure(.windowCreationFailed(reason: "Container view has zero bounds after layout"))
        }

        // Step 1: Create AVPlayer instance
        let player = AVPlayer()
        player.isMuted = true
        player.actionAtItemEnd = .pause
        player.automaticallyWaitsToMinimizeStalling = true
        self.player = player

        // Step 2: Create AVPlayerLayer and attach to container view
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = videoGravity
        layer.frame = bounds

        containerView.wantsLayer = true
        if let contentLayer = containerView.layer {
            contentLayer.addSublayer(layer)
            logger.debug("AVPlayerLayer attached to container view")
        } else {
            logger.error("Container view has no CALayer backing")
            return .failure(.rendererInitializationFailed(reason: "Container view layer initialization failed"))
        }

        self.playerLayer = layer

        logger.info("VideoRenderer initialized successfully with layer attached")
        return .success(())
    }

    // CHUNK 1: Load video URL into player (called before/during start)
    func loadVideo(url: URL, autoPlay: Bool = true) async -> Result<Void, WallpaperError> {
        allowsPlaybackAdvance = autoPlay
        activeVideoURL = url
        isAccessingSecurityScopedResource = url.startAccessingSecurityScopedResource()

        // Validate file exists and is readable
        guard FileManager.default.fileExists(atPath: url.path) else {
            logger.error("Video file not found: \(url.path)")
            stopSecurityScopedAccessIfNeeded()
            return .failure(.videoFileNotFound(path: url.path))
        }

        guard FileManager.default.isReadableFile(atPath: url.path) else {
            logger.error("Video file is not readable: \(url.path)")
            stopSecurityScopedAccessIfNeeded()
            return .failure(.videoFileNotReadable(path: url.path))
        }

        let asset = AVURLAsset(url: url)
        do {
            let isPlayable = try await asset.load(.isPlayable)
            guard isPlayable else {
                logger.error("Video asset is not playable: \(url.path)")
                stopSecurityScopedAccessIfNeeded()
                return .failure(.videoDecodingFailed(url: url, reason: "Asset is not playable"))
            }
        } catch {
            logger.error("Failed to inspect video asset: \(error.localizedDescription)")
            stopSecurityScopedAccessIfNeeded()
            return .failure(.videoDecodingFailed(url: url, reason: error.localizedDescription))
        }

        // Create AVPlayerItem from URL
        let playerItem = AVPlayerItem(asset: asset)
        PerformanceProfileConfiguration.apply(to: playerItem, profile: performanceProfile)

        // Replace current item in player and begin playback
        guard let player = player else {
            logger.error("AVPlayer not initialized")
            return .failure(.rendererInitializationFailed(reason: "Player not initialized"))
        }

        updatePlaybackObserver(for: playerItem)
        player.replaceCurrentItem(with: playerItem)
        await MainActor.run {
            if autoPlay {
                startContinuousPlaybackIfAllowed()
                logger.info("Video loaded and playback started: \(url.lastPathComponent) profile=\(self.performanceProfile.rawValue, privacy: .public)")
            } else {
                player.pause()
                logger.info("Video loaded paused: \(url.lastPathComponent)")
            }
        }
        return .success(())
    }

    func stop() async {
        player?.pause()
        logger.debug("VideoRenderer stopped")
    }

    func pause() async {
        allowsPlaybackAdvance = false
        await applyLayerFrameBeforePause()
        await MainActor.run {
            guard let player else {
                logger.warning("VideoRenderer pause: no player instance")
                return
            }
            player.currentItem?.cancelPendingSeeks()
            player.pause()
            player.rate = 0
        }
        let rate = await MainActor.run { player?.rate ?? -1 }
        if isActivelyPlaying {
            logger.warning("VideoRenderer pause completed but rate still > 0 (rate=\(rate)); seeking to hold frame")
            await MainActor.run {
                guard let player, player.currentItem != nil else { return }
                let time = player.currentTime()
                player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
                player.pause()
                player.rate = 0
            }
        } else {
            logger.info("Desktop pause verified rate=\(rate)")
        }
        await MainActor.run {
            ensurePlayerAttachedToLayer()
            logger.info("Desktop pause: holding frame (layer attached) rate=\(self.player?.rate ?? -1)")
        }
        scheduleNonBlockingPrerollAtZero()
    }

    func resume() async {
        allowsPlaybackAdvance = true
        let rate = await MainActor.run { () -> Float in
            ensurePlayerAttachedToLayer()
            startContinuousPlaybackIfAllowed()
            return player?.rate ?? -1
        }
        logger.info("Desktop resume: playback started rate=\(rate) profile=\(self.performanceProfile.rawValue, privacy: .public)")
    }

    func applyPerformanceProfile(_ profile: PerformanceProfile) async {
        performanceProfile = profile
        await MainActor.run {
            if let item = player?.currentItem {
                PerformanceProfileConfiguration.apply(to: item, profile: profile)
            }
            if allowsPlaybackAdvance {
                startContinuousPlaybackIfAllowed()
            }
        }
        logger.info("VideoRenderer performance profile=\(profile.rawValue, privacy: .public)")
    }

    /// Continuous hardware decode when allowed; visibility policy pauses via DisplayController (P3).
    private func startContinuousPlaybackIfAllowed() {
        guard allowsPlaybackAdvance, let player else { return }
        player.play()
    }

    /// Exposed for WallpaperManager desktop playback diagnostics.
    var currentPlaybackRate: Float {
        player?.rate ?? 0
    }

    private func ensurePlayerAttachedToLayer() {
        guard let player, let playerLayer else { return }
        if playerLayer.player !== player {
            playerLayer.player = player
            logger.debug("Desktop playback: AVPlayer attached to layer")
        }
    }

    private func applyLayerFrameBeforePause() async {
        let needsDeferredLayout = await MainActor.run { () -> Bool in
            guard let containerView else { return false }
            let bounds = containerView.bounds
            if !bounds.isEmpty {
                applyPlayerLayerFrame(in: containerView)
                return false
            }
            return true
        }
        guard needsDeferredLayout else { return }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.main.async { [weak self] in
                guard let self, let containerView = self.containerView else {
                    continuation.resume()
                    return
                }
                if containerView.bounds.isEmpty {
                    containerView.layoutSubtreeIfNeeded()
                }
                self.applyPlayerLayerFrame(in: containerView)
                continuation.resume()
            }
        }
    }

    /// Best-effort frame commit; must not block the pause command path (preroll can hang on some assets).
    private func scheduleNonBlockingPrerollAtZero() {
        DispatchQueue.main.async { [weak self] in
            guard let player = self?.player else { return }
            player.preroll(atRate: 0) { finished in
                Task { @MainActor [weak self] in
                    let rate = self?.player?.rate ?? -1
                    self?.logger.debug("Desktop preroll(atRate:0) finished=\(finished) rate=\(rate)")
                }
            }
        }
    }

    private func applyPlayerLayerFrame(in containerView: NSView) {
        let bounds = containerView.bounds
        guard let playerLayer else { return }
        if bounds.isEmpty {
            logger.warning("Pausing with zero container bounds: \(String(describing: bounds))")
        } else {
            playerLayer.frame = bounds
            logger.debug("Player layer frame set before pause: \(bounds.width)x\(bounds.height)")
        }
    }

    /// True when AVPlayer is advancing (used to verify pause stuck).
    var isActivelyPlaying: Bool {
        guard allowsPlaybackAdvance, let player else { return false }
        return player.rate > 0.01
    }

    /// Playback position for hero pause snapshots (aligned with desktop-held frame).
    func currentPlaybackTime() -> CMTime? {
        guard player?.currentItem != nil else { return nil }
        return player?.currentTime()
    }

    func matchesHeroPreviewURL(_ url: URL) -> Bool {
        guard let activeVideoURL, player?.currentItem != nil else { return false }
        let activePath = activeVideoURL.isFileURL
            ? activeVideoURL.standardizedFileURL.resolvingSymlinksInPath().path
            : activeVideoURL.absoluteString
        let targetPath = url.isFileURL
            ? url.standardizedFileURL.resolvingSymlinksInPath().path
            : url.absoluteString
        return activePath == targetPath
    }

    @discardableResult
    func attachHeroPreviewLayer(in containerView: NSView, videoGravity: AVLayerVideoGravity = .resizeAspectFill) -> Bool {
        guard let player else { return false }

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

    func setHeroPreviewLayerHidden(_ hidden: Bool) {
        heroPreviewLayer?.isHidden = hidden
    }

    func detachHeroPreviewLayer() {
        heroPreviewLayer?.removeFromSuperlayer()
        heroPreviewLayer = nil
        heroPreviewContainer = nil
    }
    
    // MARK: - Reconciliation Query Methods (Chunk 4D)
    func isMuted() async -> Bool {
        player?.isMuted ?? true
    }
    
    func scalingMode() async -> VideoScalingMode {
        let currentGravity = playerLayer?.videoGravity ?? .resizeAspectFill
        switch currentGravity {
        case .resizeAspect:
            return .resizeAspect
        case .resize:
            return .resizeAspectHeight
        default:
            return .resizeAspectFill
        }
    }
    
    // MARK: - Renderer Validity Check (Chunk 4B)
    /// Checks if the renderer is still in a valid state for playback
    func isValid() -> Bool {
        // Renderer is valid if player exists and has a current item
        guard let player = player, let _ = player.currentItem else {
            logger.debug("Renderer validity check failed: player or currentItem is nil")
            return false
        }
        
        // Verify the player layer is still attached to the view hierarchy
        guard let playerLayer = playerLayer, playerLayer.superlayer != nil else {
            logger.debug("Renderer validity check failed: playerLayer not in hierarchy")
            return false
        }
        
        return true
    }
    
    func setMuted(_ isMuted: Bool) async { player?.isMuted = isMuted }

    func setScalingMode(_ mode: VideoScalingMode) async {
        videoGravity = mode.avLayerVideoGravity
        playerLayer?.videoGravity = videoGravity
    }

    func resize(to newSize: CGSize) async {
        playerLayer?.frame = CGRect(origin: .zero, size: newSize)
    }

    func dispose() async {
        detachHeroPreviewLayer()
        player?.pause()
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
            endObserver = nil
        }
        if let layer = playerLayer {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer.removeFromSuperlayer()
            CATransaction.commit()
            playerLayer = nil
        }
        player = nil
        containerView = nil
        stopSecurityScopedAccessIfNeeded()
        logger.debug("VideoRenderer disposed")
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
                guard let self, self.allowsPlaybackAdvance else { return }
                self.player?.seek(to: .zero)
                self.player?.play()
            }
        }
    }

    private func stopSecurityScopedAccessIfNeeded() {
        if isAccessingSecurityScopedResource {
            activeVideoURL?.stopAccessingSecurityScopedResource()
            isAccessingSecurityScopedResource = false
        }
        activeVideoURL = nil
    }
}

extension VideoRenderer: DesktopVideoPreviewProviding {}
