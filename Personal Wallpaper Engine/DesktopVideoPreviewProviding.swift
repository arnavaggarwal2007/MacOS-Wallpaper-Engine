import AppKit
import AVFoundation

/// Hero preview layer attached to an existing desktop decode path (Phase 7D).
@MainActor
protocol DesktopVideoPreviewProviding: AnyObject {
    func matchesHeroPreviewURL(_ url: URL) -> Bool
    @discardableResult
    func attachHeroPreviewLayer(in containerView: NSView, videoGravity: AVLayerVideoGravity) -> Bool
    func updateHeroPreviewLayerFrame(in containerView: NSView)
    func setHeroPreviewLayerHidden(_ hidden: Bool)
    func detachHeroPreviewLayer()
}
