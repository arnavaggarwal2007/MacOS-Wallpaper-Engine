import AppKit
import os.log

final class DisplayController {
    private let logger = Logger(subsystem: "com.local.wallpaper", category: "DisplayController")
    private let screen: NSScreen
    private weak var manager: WallpaperManager?

    private(set) var window: NSWindow?
    private(set) var contentView: NSView?
    private var renderer: Renderer?
    
    // MARK: - Recovery Tracking (Chunk 4B)
    private var recoveryCount: Int = 0
    private let maxRecoveryAttempts: Int = 3
    private var lastLoadedVideoURL: URL?
    private var lastMutedState: Bool = true
    private var lastScalingMode: VideoScalingMode = .resizeAspectFill

    // MARK: - Resize Handling (Chunk 4C)
    private var resizeObserver: NSObjectProtocol?
    private var resizeTask: Task<Void, Never>?
    private let resizeDebounceInterval: UInt64 = 100_000_000  // 0.1 seconds in nanoseconds
    private var lastFrameSize: CGSize = .zero

    var displayID: CGDirectDisplayID { screen.displayID }

    init(screen: NSScreen, manager: WallpaperManager?) {
        self.screen = screen
        self.manager = manager
        setupWindow()
    }

    private func setupWindow() {
        let frame = screen.frame
        let window = NSWindow(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isOpaque = true
        window.backgroundColor = .black
        window.ignoresMouseEvents = true

        let desktopLevel = CGWindowLevelForKey(.desktopWindow)
        window.level = NSWindow.Level(rawValue: Int(desktopLevel))

        // Prevent activation: cannot assign to canBecomeKey/canBecomeMain (get-only)

        // Content view
        let contentView = NSView(frame: frame)
        contentView.wantsLayer = true
        window.contentView = contentView
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.orderBack(nil)

        self.window = window
        self.contentView = contentView
        self.lastFrameSize = frame.size
        logger.info("Window created for display \(self.displayID)")
        
        // MARK: - Setup Resize Observer (Chunk 4C)
        resizeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.handleWindowResize()
        }
        
        // Write a diagnostic entry so external checks can verify runtime behavior
        // MARK: - Conditional Diagnostics (Chunk 4E)
        if SettingsStore.shared.debugDiagnosticsEnabled {
            let diag = "\(Date()): Window created for display \(self.displayID) frame=\(frame)\n"
            if let data = diag.data(using: .utf8) {
                let path = "/tmp/pwe_display.log"
                if !FileManager.default.fileExists(atPath: path) { FileManager.default.createFile(atPath: path, contents: nil, attributes: nil) }
                if let handle = FileHandle(forWritingAtPath: path) { handle.seekToEndOfFile(); handle.write(data); try? handle.close() }
            }
        }
    }

    func startPlayback(
        url: URL,
        isMuted: Bool,
        scalingMode: VideoScalingMode
    ) async -> Result<Void, WallpaperError> {
        guard let contentView = contentView else {
            logger.error("Content view not available for playback")
            return .failure(.windowCreationFailed(reason: "No content view"))
        }

        // Step 1: Create and initialize renderer
        let renderer = VideoRenderer()
        let initResult = await renderer.start(in: contentView)

        // Check initialization succeeded
        guard case .success = initResult else {
            logger.error("Failed to initialize VideoRenderer")
            return initResult
        }

        await renderer.setMuted(isMuted)
        await renderer.setScalingMode(scalingMode)

        // Step 2: Load video into the initialized renderer
        let videoResult = await renderer.loadVideo(url: url)

        // If video loading failed, dispose renderer and return error
        guard case .success = videoResult else {
            logger.error("Failed to load video: \(url.lastPathComponent)")
            await renderer.dispose()
            return videoResult
        }

        // Step 3: Keep renderer alive for this display
        self.renderer = renderer
        self.lastLoadedVideoURL = url
        self.lastMutedState = isMuted
        self.lastScalingMode = scalingMode
        self.recoveryCount = 0
        logger.info("Playback started for display \(self.displayID)")
        return .success(())
    }

    func setMuted(_ isMuted: Bool) async {
        lastMutedState = isMuted
        await renderer?.setMuted(isMuted)
    }

    func setScalingMode(_ mode: VideoScalingMode) async {
        lastScalingMode = mode
        await renderer?.setScalingMode(mode)
    }

    // MARK: - Lifecycle Control (Chunk 4A)
    func pause() async {
        await renderer?.pause()
    }

    // MARK: - Resume with Fallback Recovery (Chunk 4B)
    func resume() async {
        // First, check if renderer is still valid
        guard let renderer = renderer, renderer.isValid() else {
            logger.warning("Renderer invalid on resume attempt - attempting recovery on display \(self.displayID)")
            await attemptRecovery()
            return
        }
        
        // Renderer is valid, attempt resume
        await renderer.resume()
        logger.debug("Resumed playback on display \(self.displayID)")
    }
    
    /// Attempt to recover by re-initializing the renderer with the last known video
    private func attemptRecovery() async {
        // Check if we have a stored video URL to recover with
        guard let videoURL = lastLoadedVideoURL else {
            logger.error("Cannot recover: no stored video URL for display \(self.displayID)")
            return
        }
        
        // Check if we've exceeded max recovery attempts
        guard recoveryCount < self.maxRecoveryAttempts else {
            logger.error("Recovery failed: exceeded max attempts (\(self.maxRecoveryAttempts)) for display \(self.displayID)")
            recoveryCount = 0
            return
        }
        
        recoveryCount += 1
        logger.info("Starting recovery attempt \(self.recoveryCount)/\(self.maxRecoveryAttempts) for display \(self.displayID)")
        
        // Dispose old renderer
        if let oldRenderer = renderer {
            await oldRenderer.dispose()
            renderer = nil
        }
        
        // Attempt to start fresh playback with the same video
        let result = await startPlayback(
            url: videoURL,
            isMuted: lastMutedState,
            scalingMode: lastScalingMode
        )
        
        switch result {
        case .success:
            logger.info("Recovery successful on display \(self.displayID)")
            recoveryCount = 0  // Reset counter on successful recovery
        case .failure(let error):
            logger.error("Recovery attempt \(self.recoveryCount) failed for display \(self.displayID): \(error.errorDescription ?? "unknown error")")
        }
    }

    // MARK: - Resize Handling with Debounce (Chunk 4C)
    private func handleWindowResize() {
        // Check if frame size has actually changed
        guard let window = window else { return }
        let newSize = window.frame.size
        
        guard newSize != lastFrameSize else {
            return  // No actual size change, ignore
        }
        
        lastFrameSize = newSize
        logger.debug("Window resized to \(newSize.width)x\(newSize.height) for display \(self.displayID)")
        
        // Cancel pending resize task to debounce
        resizeTask?.cancel()
        
        // Schedule new resize with debounce delay
        resizeTask = Task {
            do {
                try await Task.sleep(nanoseconds: resizeDebounceInterval)
                
                // Task wasn't cancelled, proceed with resize
                if !Task.isCancelled {
                    await applyResize(newSize)
                }
            } catch {
                logger.debug("Resize debounce task cancelled")
            }
        }
    }
    
    /// Apply the resize change to the renderer and layer
    private func applyResize(_ newSize: CGSize) async {
        logger.info("Applying resize to \(newSize.width)x\(newSize.height) for display \(self.displayID)")
        
        // Update content view bounds if needed
        if let contentView = contentView, contentView.bounds.size != newSize {
            contentView.frame.size = newSize
        }
        
        // Notify renderer about size change
        await renderer?.resize(to: newSize)
        
        logger.debug("Resize applied successfully for display \(self.displayID)")
    }

    func stop() async {
        // Cancel pending resize task
        resizeTask?.cancel()
        resizeTask = nil
        
        // Remove resize observer
        if let observer = resizeObserver {
            NotificationCenter.default.removeObserver(observer)
            resizeObserver = nil
        }
        
        // Dispose renderer
        if let renderer = renderer { await renderer.dispose() }
        renderer = nil
        window?.orderOut(nil)
        window = nil
        contentView = nil
    }

    func orderToBack() async {
        window?.orderBack(nil)
    }

    // MARK: - State Reconciliation and Self-Healing (Chunk 4D)
    enum ReconciliationResult {
        case valid
        case healed(reason: String)
        case failed(reason: String)
    }
    
    /// Verify and repair controller/renderer/window consistency
    func reconcileState(
        expectedLifecycleState: WallpaperManager.LifecycleState,
        expectedVideoURL: URL?,
        expectedMuted: Bool,
        expectedScalingMode: VideoScalingMode
    ) async -> ReconciliationResult {
        // Check 1: Window exists and is visible
        guard let window = window else {
            return .failed(reason: "window is nil")
        }
        
        // Check 2: Content view exists and is in window
        guard let contentView = contentView, window.contentView == contentView else {
            return .failed(reason: "content view missing or not in window")
        }
        
        // Check 3: Window is at correct level
        let expectedLevel = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        if window.level != expectedLevel {
            logger.warning("Window level mismatch for display \(self.displayID), correcting...")
            window.level = expectedLevel
            return .healed(reason: "window level restored")
        }
        
        // Check 4: Renderer exists and is valid
        guard let renderer = renderer, renderer.isValid() else {
            // Renderer is missing or invalid, but we need it
            if expectedLifecycleState == .playing && expectedVideoURL != nil {
                return .failed(reason: "renderer invalid while should be playing")
            } else {
                // Not supposed to be playing anyway
                return .valid
            }
        }
        
        // Check 5: Verify settings parity
        let mutedMatches = (await renderer.isMuted()) == expectedMuted
        let scalingMatches = (await renderer.scalingMode()) == expectedScalingMode
        
        if !mutedMatches {
            logger.debug("Muted setting mismatch for display \(self.displayID), reapplying...")
            await renderer.setMuted(expectedMuted)
            lastMutedState = expectedMuted
        }
        
        if !scalingMatches {
            logger.debug("Scaling mode mismatch for display \(self.displayID), reapplying...")
            await renderer.setScalingMode(expectedScalingMode)
            lastScalingMode = expectedScalingMode
        }
        
        // Check 6: Window visibility
        if window.isVisible {
            logger.debug("Window should not be visible (desktop window), ordering to back...")
            window.orderBack(nil)
            return .healed(reason: "window reordered to back")
        }
        
        // All checks passed
        if !mutedMatches || !scalingMatches {
            return .healed(reason: "settings synchronized")
        }
        
        return .valid
    }
    
    /// Fallback recreation of window and/or renderer if reconciliation failed
    func fallbackRecreate(
        videoURL: URL?,
        isMuted: Bool,
        scalingMode: VideoScalingMode
    ) async {
        logger.info("Starting fallback recreation for display \(self.displayID)")
        
        // Preserve state before cleanup
        let savedURL = videoURL ?? lastLoadedVideoURL
        let savedMuted = isMuted
        let savedScaling = scalingMode
        
        // Stop current playback
        if let renderer = renderer { await renderer.dispose() }
        renderer = nil
        
        // Rebuild window
        if let window = window {
            window.orderOut(nil)
        }
        window = nil
        contentView = nil
        
        setupWindow()
        
        // Restart playback if we have a video URL
        if let url = savedURL {
            let result = await startPlayback(url: url, isMuted: savedMuted, scalingMode: savedScaling)
            
            switch result {
            case .success:
                logger.info("Fallback recreation succeeded for display \(self.displayID)")
            case .failure(let error):
                let errorMsg = error.errorDescription ?? "unknown error"
                logger.error("Fallback recreation failed for display \(self.displayID): \(errorMsg)")
            }
        } else {
            logger.warning("Fallback recreation: no video URL available for display \(self.displayID)")
        }
    }

    deinit {
        logger.info("DisplayController deinit for \(self.displayID)")
        Task { [weak self] in await self?.stop() }
    }
}
