import AppKit

protocol Renderer: AnyObject {
    func start(in containerView: NSView) async -> Result<Void, WallpaperError>
    func stop() async
    func pause() async
    func resume() async
    func setMuted(_ isMuted: Bool) async
    func setScalingMode(_ mode: VideoScalingMode) async
    func resize(to newSize: CGSize) async
    func dispose() async
    
    // MARK: - Chunk 4B: Renderer Validity Check
    /// Check if the renderer is still valid for playback (for recovery fallback logic)
    func isValid() -> Bool}