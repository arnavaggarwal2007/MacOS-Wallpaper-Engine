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
    private var lastRendererMode: WallpaperRendererMode = .video
    private var lastMutedState: Bool = true
    private var lastScalingMode: VideoScalingMode = .resizeAspectFill

    var loadedVideoURL: URL? { lastLoadedVideoURL }
    var currentScalingMode: VideoScalingMode { lastScalingMode }

    // MARK: - Resize Handling (Chunk 4C)
    private var resizeObserver: NSObjectProtocol?
    private var resizeTask: Task<Void, Never>?
    private let resizeDebounceInterval: UInt64 = 100_000_000  // 0.1 seconds in nanoseconds
    private var lastFrameSize: CGSize = .zero

    var displayID: CGDirectDisplayID { screen.displayID }

    /// Desktop wallpaper window used for P3 visibility tracking.
    var desktopWindow: NSWindow? { window }

    private var pausedForVisibilityPolicy = false

    /// User-facing log label: `3 (Display 1, T24v-20)` — not raw `CGDirectDisplayID` alone.
    static func logLabel(for displayID: CGDirectDisplayID) -> String {
        let screens = NSScreen.screens.sorted { $0.frame.origin.x < $1.frame.origin.x }
        guard let index = screens.firstIndex(where: { $0.displayID == displayID }) else {
            return String(displayID)
        }
        let name = screens[index].localizedName
        return "\(displayID) (Display \(index + 1), \(name))"
    }

    var isUsingSharedVideoRenderer: Bool {
        renderer is SharedVideoLayerRenderer
    }

    var heroPreviewProvider: (any DesktopVideoPreviewProviding)? {
        renderer as? DesktopVideoPreviewProviding
    }

    var isPausedForVisibilityPolicy: Bool { pausedForVisibilityPolicy }

    /// True when a renderer exists and can accept pause/resume.
    var isRendererActive: Bool {
        guard let renderer else { return false }
        return renderer.isValid()
    }

    private let boundSignature: DisplayConfigurationMigrator.DisplaySignature

    /// Computed property exposing the screen's localizedName for matching collection sources
    var displayName: String? { screen.localizedName }

    init(screen: NSScreen, manager: WallpaperManager?) {
        self.screen = screen
        self.manager = manager
        self.boundSignature = DisplayConfigurationMigrator.DisplaySignature(screen: screen)
        setupWindow()
    }

    /// Returns false when macOS reused this display ID for a different monitor after hotplug.
    func matchesCurrentScreen(_ screen: NSScreen) -> Bool {
        screen.displayID == displayID
            && DisplayConfigurationMigrator.DisplaySignature(screen: screen) == boundSignature
    }

    private func setupWindow() {
        let frame = screen.frame
        let window = NSWindow(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isOpaque = true
        window.backgroundColor = .black
        window.ignoresMouseEvents = true

        let desktopLevel = CGWindowLevelForKey(.desktopWindow)
        window.level = NSWindow.Level(rawValue: Int(desktopLevel))

        let contentView = NSView(frame: localContentRect(for: frame))
        contentView.autoresizingMask = [.width, .height]
        contentView.wantsLayer = true
        window.contentView = contentView
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.orderBack(nil)

        self.window = window
        self.contentView = contentView
        self.lastFrameSize = frame.size
        logger.info("Window created for display \(self.displayID)")

        resizeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.handleWindowResize()
        }

        logGeometryDiagnostics(for: screen, event: "Window created")
    }

    /// Window-local content rect; `NSScreen.frame` is global and must not be used as the content view frame.
    private func localContentRect(for screenFrame: NSRect) -> NSRect {
        NSRect(origin: .zero, size: screenFrame.size)
    }

    /// Aligns the desktop window and content view with the current screen (required after hotplug / primary swap).
    func syncWindowGeometry(for screen: NSScreen) {
        guard screen.displayID == displayID, let window, let contentView else { return }

        let screenFrame = screen.frame
        window.setFrame(screenFrame, display: true)
        contentView.frame = localContentRect(for: screenFrame)
        lastFrameSize = screenFrame.size
        logGeometryDiagnostics(for: screen, event: "Geometry synced")
    }

    private func currentScreen() -> NSScreen {
        NSScreen.screens.first(where: { $0.displayID == displayID }) ?? screen
    }

    private func logGeometryDiagnostics(for screen: NSScreen, event: String) {
        guard SettingsStore.shared.debugDiagnosticsEnabled else { return }
        let bounds = contentView?.bounds ?? .zero
        let windowFrame = window?.frame ?? .zero
        let diag = "\(Date()): \(event) display=\(displayID) screen.frame=\(screen.frame) window.frame=\(windowFrame) contentView.bounds=\(bounds)\n"
        if let data = diag.data(using: .utf8) {
            let path = "/tmp/pwe_display.log"
            if !FileManager.default.fileExists(atPath: path) {
                FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
            }
            if let handle = FileHandle(forWritingAtPath: path) {
                handle.seekToEndOfFile()
                handle.write(data)
                try? handle.close()
            }
        }
    }

    func startPlayback(
        url: URL,
        isMuted: Bool,
        scalingMode: VideoScalingMode,
        rendererMode: WallpaperRendererMode,
        autoPlay: Bool? = nil
    ) async -> Result<Void, WallpaperError> {
        let shouldAutoPlay = autoPlay ?? (manager?.shouldAdvanceDesktopPlayback ?? false)
        guard contentView != nil else {
            logger.error("Content view not available for playback")
            return .failure(.windowCreationFailed(reason: "No content view"))
        }

        let activeScreen = currentScreen()
        syncWindowGeometry(for: activeScreen)

        guard let contentView = contentView else {
            return .failure(.windowCreationFailed(reason: "No content view"))
        }

        // Dispose old renderer before starting new playback
        if let oldRenderer = renderer {
            logger.debug("Disposing old renderer before starting new playback on display \(self.displayID)")
            await oldRenderer.dispose()
            self.renderer = nil
        }
        
        // Instantiate the appropriate renderer based on mode or URL scheme
        if rendererMode == .web || (url.scheme?.lowercased().hasPrefix("http") == true) {
            let web = WebRenderer()
            let initResult = await web.start(in: contentView)
            guard case .success = initResult else {
                logger.error("Failed to initialize WebRenderer")
                return initResult
            }

            await web.setMuted(isMuted)
            await web.setScalingMode(scalingMode)

            let loadResult = await web.load(url: url)
            guard case .success = loadResult else {
                logger.error("Failed to load web content: \(url.absoluteString)")
                await web.dispose()
                return loadResult
            }

            self.renderer = web
            self.lastLoadedVideoURL = url
            self.lastMutedState = isMuted
            self.lastScalingMode = scalingMode
            self.lastRendererMode = .web
            self.recoveryCount = 0
            logger.info("Web playback started for display \(self.displayID)")
            return .success(())
        } else {
            let videoRenderer = manager?.makeVideoRenderer(for: displayID, url: url, rendererMode: rendererMode)
                ?? VideoRenderer()
            let initResult = await videoRenderer.start(in: contentView)

            guard case .success = initResult else {
                logger.error("Failed to initialize video renderer")
                return initResult
            }

            await videoRenderer.setMuted(isMuted)
            await videoRenderer.setScalingMode(scalingMode)

            let videoResult: Result<Void, WallpaperError>
            if let shared = videoRenderer as? SharedVideoLayerRenderer {
                videoResult = await shared.loadVideo(url: url, autoPlay: shouldAutoPlay)
            } else if let standalone = videoRenderer as? VideoRenderer {
                videoResult = await standalone.loadVideo(url: url, autoPlay: shouldAutoPlay)
            } else {
                videoResult = .failure(.rendererInitializationFailed(reason: "Unknown video renderer type"))
            }

            guard case .success = videoResult else {
                logger.error("Failed to load video: \(url.lastPathComponent)")
                await videoRenderer.dispose()
                return videoResult
            }

            self.renderer = videoRenderer
            await applyPerformanceProfile(SettingsStore.shared.performanceProfile)
            self.lastLoadedVideoURL = url
            self.lastMutedState = isMuted
            self.lastScalingMode = scalingMode
            self.lastRendererMode = .video
            self.recoveryCount = 0
            if shouldAutoPlay {
                logger.info("Playback started for display \(Self.logLabel(for: self.displayID)) shared=\(videoRenderer is SharedVideoLayerRenderer)")
            } else {
                logger.info("Playback loaded paused for display \(Self.logLabel(for: self.displayID)) shared=\(videoRenderer is SharedVideoLayerRenderer)")
            }
            return .success(())
        }
    }

    func setMuted(_ isMuted: Bool) async {
        lastMutedState = isMuted
        await renderer?.setMuted(isMuted)
    }

    func setScalingMode(_ mode: VideoScalingMode) async {
        lastScalingMode = mode
        if let renderer = renderer {
            await renderer.setScalingMode(mode)
            logger.debug("Applied scaling mode \(mode.rawValue) to renderer on display \(self.displayID)")
        } else {
            logger.warning("No renderer present when attempting to set scaling mode \(mode.rawValue) on display \(self.displayID)")
        }
    }

    // MARK: - Lifecycle Control (Chunk 4A)
    func pause() async {
        logger.debug("DisplayController pause display=\(Self.logLabel(for: self.displayID))")
        syncWindowGeometry(for: currentScreen())
        pausedForVisibilityPolicy = false
        await renderer?.pause()
    }

    /// P3: Pause decode when desktop is not visible — does not change global lifecycle / chrome.
    func pauseForVisibilityPolicy() async {
        guard isRendererActive else { return }
        guard !pausedForVisibilityPolicy else { return }
        pausedForVisibilityPolicy = true
        await renderer?.pause()
        logger.info("Desktop visibility pause display=\(Self.logLabel(for: self.displayID))")
    }

    func resumeFromVisibilityPolicy() async {
        guard pausedForVisibilityPolicy else { return }
        pausedForVisibilityPolicy = false
        guard let renderer, renderer.isValid() else { return }
        await renderer.resume()
        logger.info("Desktop visibility resume display=\(Self.logLabel(for: self.displayID))")
    }

    /// True when the video renderer is still advancing after a pause request.
    var isRendererStillPlaying: Bool {
        if let shared = renderer as? SharedVideoLayerRenderer {
            return shared.isActivelyPlaying
        }
        return (renderer as? VideoRenderer)?.isActivelyPlaying ?? false
    }

    /// Current AVPlayer rate for diagnostics (0 when paused).
    var desktopPlaybackRate: Float {
        if let shared = renderer as? SharedVideoLayerRenderer {
            return shared.currentPlaybackRate
        }
        return (renderer as? VideoRenderer)?.currentPlaybackRate ?? 0
    }

    // MARK: - Resume with Fallback Recovery (Chunk 4B)
    func resume() async {
        pausedForVisibilityPolicy = false
        // First, check if renderer is still valid
        guard let renderer = renderer, renderer.isValid() else {
            logger.warning("Renderer invalid on resume attempt - attempting recovery on display \(self.displayID)")
            await attemptRecovery()
            return
        }
        
        // Renderer is valid, attempt resume
        await renderer.resume()
        logger.info("Resumed playback on display \(self.displayID)")
    }

    func applyPerformanceProfile(_ profile: PerformanceProfile) async {
        if let video = renderer as? VideoRenderer {
            await video.applyPerformanceProfile(profile)
        } else if let shared = renderer as? SharedVideoLayerRenderer {
            await shared.applyPerformanceProfile(profile)
        } else if let web = renderer as? WebRenderer {
            await web.applyPerformanceProfile(profile)
        }
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
            scalingMode: lastScalingMode,
            rendererMode: lastRendererMode
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
        
        if let contentView = contentView, contentView.bounds.size != newSize {
            contentView.frame = NSRect(origin: .zero, size: newSize)
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

    /// Disposes the active renderer but keeps the desktop window (Phase 7C engine restart).
    func disposeRendererForRestart() async {
        pausedForVisibilityPolicy = false
        if let renderer = renderer {
            await renderer.dispose()
            self.renderer = nil
        }
        lastLoadedVideoURL = nil
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
        scalingMode: VideoScalingMode,
        rendererMode: WallpaperRendererMode
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
            let shouldAutoPlay = manager?.shouldAdvanceDesktopPlayback ?? false
            let result = await startPlayback(
                url: url,
                isMuted: savedMuted,
                scalingMode: savedScaling,
                rendererMode: rendererMode,
                autoPlay: shouldAutoPlay
            )
            
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
