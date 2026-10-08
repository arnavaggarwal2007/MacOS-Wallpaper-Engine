import AVFoundation
import AppKit
import ScreenSaver

/// Idle and preview playback for the Deskface screen saver.
/// One instance per display. This process does not load the desktop engine.
final class DeskfaceScreenSaverView: ScreenSaverView {
    private var queuePlayer: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?
    private var playerLayer: AVPlayerLayer?
    private let placeholder = NSTextField(wrappingLabelWithString: ScreensaverConfig.placeholderMessage)

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = 1.0 / 30.0
        wantsLayer = true
        configurePlaceholder()
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        animationTimeInterval = 1.0 / 30.0
        wantsLayer = true
        configurePlaceholder()
    }

    override var hasConfigureSheet: Bool { false }

    override func startAnimation() {
        super.startAnimation()
        beginPlayback()
    }

    override func stopAnimation() {
        tearDownPlayback()
        super.stopAnimation()
    }

    override func layout() {
        super.layout()
        playerLayer?.frame = bounds
        placeholder.frame = bounds.insetBy(dx: 24, dy: 24)
    }

    private func configurePlaceholder() {
        placeholder.alignment = .center
        placeholder.textColor = .white
        placeholder.backgroundColor = .clear
        placeholder.isBezeled = false
        placeholder.isEditable = false
        placeholder.isHidden = true
        placeholder.maximumNumberOfLines = 3
        addSubview(placeholder)
        layer?.backgroundColor = NSColor.black.cgColor
    }

    private func beginPlayback() {
        tearDownPlayback()
        guard let url = videoURLIfAvailable() else {
            showPlaceholder()
            return
        }

        let snapshot = ScreensaverConfig.Snapshot.read(from: suiteDefaults())
        let item = AVPlayerItem(url: url)
        if isPreview {
            item.preferredMaximumResolution = CGSize(width: 640, height: 360)
        }
        let player = AVQueuePlayer()
        player.isMuted = snapshot.muted
        player.actionAtItemEnd = .none
        let looper = AVPlayerLooper(player: player, templateItem: item)
        let videoLayer = AVPlayerLayer(player: player)
        videoLayer.frame = bounds
        videoLayer.videoGravity = videoGravity(for: snapshot.scalingMode)
        videoLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        wantsLayer = true
        layer?.addSublayer(videoLayer)

        queuePlayer = player
        playerLooper = looper
        playerLayer = videoLayer
        placeholder.isHidden = true
        player.play()
    }

    private func videoURLIfAvailable() -> URL? {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: ScreensaverConfig.appGroupIdentifier
        ) else {
            return nil
        }
        let snapshot = ScreensaverConfig.Snapshot.read(from: suiteDefaults())
        guard let url = ScreensaverConfig.resolvedMediaURL(relativePath: snapshot.videoPath, container: container),
              FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        return url
    }

    private func suiteDefaults() -> UserDefaults {
        UserDefaults(suiteName: ScreensaverConfig.appGroupIdentifier) ?? .standard
    }

    private func videoGravity(for raw: String) -> AVLayerVideoGravity {
        switch ScreensaverConfig.normalizedScaling(raw) {
        case ScreensaverConfig.Scaling.fit:
            return .resizeAspect
        case ScreensaverConfig.Scaling.stretch:
            return .resize
        default:
            return .resizeAspectFill
        }
    }

    private func showPlaceholder() {
        placeholder.stringValue = ScreensaverConfig.placeholderMessage
        placeholder.isHidden = false
        layer?.backgroundColor = NSColor.black.cgColor
    }

    private func tearDownPlayback() {
        queuePlayer?.pause()
        playerLooper?.disableLooping()
        playerLayer?.removeFromSuperlayer()
        queuePlayer = nil
        playerLooper = nil
        playerLayer = nil
    }
}
