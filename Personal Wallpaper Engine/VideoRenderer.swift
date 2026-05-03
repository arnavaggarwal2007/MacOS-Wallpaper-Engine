import AppKit
import AVFoundation
import os.log

final class VideoRenderer: Renderer {
    private let logger = Logger(subsystem: "com.local.wallpaper", category: "VideoRenderer")
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private weak var containerView: NSView?
    private var endObserver: NSObjectProtocol?
    private var videoGravity: AVLayerVideoGravity = .resizeAspectFill
    private var isAccessingSecurityScopedResource = false
    private var activeVideoURL: URL?

    func start(in containerView: NSView) async -> Result<Void, WallpaperError> {
        self.containerView = containerView

        // Step 1: Create AVPlayer instance
        let player = AVPlayer()
        player.isMuted = true  // Default: muted playback
        self.player = player

        // Step 2: Create AVPlayerLayer and attach to container view
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = videoGravity
        layer.frame = containerView.bounds

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
    func loadVideo(url: URL) async -> Result<Void, WallpaperError> {
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
        
        // Replace current item in player and begin playback
        guard let player = player else {
            logger.error("AVPlayer not initialized")
            return .failure(.rendererInitializationFailed(reason: "Player not initialized"))
        }

        updatePlaybackObserver(for: playerItem)
        player.replaceCurrentItem(with: playerItem)
        player.play()

        logger.info("Video loaded and playback started: \(url.lastPathComponent)")
        return .success(())
    }

    func stop() async {
        player?.pause()
        logger.debug("VideoRenderer stopped")
    }

    func pause() async { player?.pause() }
    func resume() async { player?.play() }
    
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
            self?.player?.seek(to: .zero)
            self?.player?.play()
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
