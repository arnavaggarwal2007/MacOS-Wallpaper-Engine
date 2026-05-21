import AppKit
import os.log

@MainActor
final class WallpaperManager {
    // MARK: - Lifecycle State Enum (Chunk 4A)
    enum LifecycleState {
        case idle
        case playing
        case paused
        case recovering
    }

    private(set) var displayControllers: [CGDirectDisplayID: DisplayController] = [:]
    private var currentWallpaperURL: URL?
    private var currentRendererMode: WallpaperRendererMode = .video
    private var isMuted = true
    private var scalingMode: VideoScalingMode = .resizeAspectFill
    private let logger = Logger(subsystem: "com.local.wallpaper", category: "WallpaperManager")
    private var screenTask: Task<Void, Never>?
    private var spaceTask: Task<Void, Never>?

    private var screenObserver: NSObjectProtocol?
    private var spaceObserver: NSObjectProtocol?
    private var lockObserver: NSObjectProtocol?
    private var unlockObserver: NSObjectProtocol?
    private var sleepObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?

    private(set) var lifecycleState: LifecycleState = .idle
    
    // MARK: - State Reconciliation (Chunk 4D)
    private var reconciliationTask: Task<Void, Never>?
    private let reconciliationDebounceInterval: UInt64 = 200_000_000  // 0.2 seconds
    private var reconciliationRetryCount: [CGDirectDisplayID: Int] = [:]
    private let maxReconciliationRetries: Int = 2
    
    // MARK: - System Health Tracking (Chunk 4E)
    private(set) var failureCount: Int = 0
    private(set) var lastFailureReason: String = ""
    private let maxFailureThreshold: Int = 5  // Threshold for degraded status

    @MainActor
    func startMonitoring() async {
        logger.debug("WallpaperManager startMonitoring")

        // Observe screen parameter changes on main queue and call actor-safe handler
        screenObserver = NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            Task { await self?.handleScreenChange() }
        }

        // Observe active space changes
        spaceObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { await self?.handleSpaceChange() }
        }

        // MARK: - Lifecycle Observers (Chunk 4A)
        // Pause when screen sleeps or locks
        sleepObserver = NotificationCenter.default.addObserver(
            forName: NSWorkspace.screensDidSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.pause() }
        }

        wakeObserver = NotificationCenter.default.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.resume() }
        }

        await handleScreenChange()
    }

    @MainActor
    func handleScreenChange() async {
        logger.debug("Handling screen change")
        let screens = NSScreen.screens
        logger.debug("Found screens: \(screens.map { $0.displayID })")
        // Diagnostic log to /tmp for runtime verification
        do { try addDiagnostic("handleScreenChange: found screens: \(screens.count)") } catch { logger.error("Failed writing diagnostic: \(error.localizedDescription)") }
        let currentIDs = Set(screens.map { $0.displayID })
        let existingIDs = Set(displayControllers.keys)

        // Remove disconnected displays
        for removed in existingIDs.subtracting(currentIDs) {
            if let controller = displayControllers.removeValue(forKey: removed) {
                await controller.stop()
                logger.debug("Removed display \(removed)")
            }
        }

        // Add new displays
        for screen in screens {
            let id = screen.displayID
            if !existingIDs.contains(id) {
                let controller = DisplayController(screen: screen, manager: self)
                displayControllers[id] = controller
                logger.debug("Added display \(id) -> controller.displayID=\(controller.displayID)")
                do { try addDiagnostic("Added display \(id) frame=\(screen.frame)") } catch { logger.error("diag write failed: \(error.localizedDescription)") }

                    if let currentWallpaperURL {
                    let result = await controller.startPlayback(
                        url: currentWallpaperURL,
                        isMuted: isMuted,
                        scalingMode: scalingMode,
                        rendererMode: currentRendererMode
                    )

                    if case .failure(let error) = result {
                        logger.error("Failed to start playback on newly added display \(id): \(error.errorDescription ?? "unknown error")")
                    }
                }
            }
        }
        // Log current mapping for diagnostics
        logger.debug("Current displayControllers keys: \(self.displayControllers.keys)")
        
        // MARK: - Reconciliation After Screen Change (Chunk 4D)
        scheduleReconciliation(reason: "screen change")
    }

    @MainActor
    func handleSpaceChange() async {
        logger.debug("Active space changed")
        for controller in displayControllers.values { await controller.orderToBack() }
        
        // MARK: - Reconciliation After Space Change (Chunk 4D)
        scheduleReconciliation(reason: "space change")
    }

    @MainActor
    func createDisplayController(for screen: NSScreen) async -> Result<DisplayController, WallpaperError> {
        let controller = DisplayController(screen: screen, manager: self)
        return .success(controller)
    }

    /// Apply a wallpaper to a single display by display ID. Used for per-display overrides.
    @MainActor
    func setPerDisplayWallpaper(displayID: CGDirectDisplayID, url: URL, rendererMode: WallpaperRendererMode, scalingMode: VideoScalingMode) async -> Result<Void, WallpaperError> {
        var controller = displayControllers[displayID]
        if controller == nil {
            // Fallback: try finding a controller with matching displayID (handle any key-type or mapping mismatches)
            controller = displayControllers.values.first(where: { $0.displayID == displayID })
        }

        guard let found = controller else {
            logger.error("Display controller not found for id: \(displayID)")
            return .failure(.screenNotFound(id: displayID))
        }

        let result = await found.startPlayback(url: url, isMuted: isMuted, scalingMode: scalingMode, rendererMode: rendererMode)
        switch result {
        case .success:
            logger.info("Per-display wallpaper applied to \(displayID)")
            return .success(())
        case .failure(let error):
            logger.error("Failed to apply per-display wallpaper to \(displayID): \(error.errorDescription ?? "unknown")")
            return .failure(error)
        }
    }

    @MainActor
    func setWallpaper(url: URL) async -> Result<Void, WallpaperError> {
        // Validate: if local file URL, ensure it exists; remote URLs are allowed for WebRenderer
        if url.isFileURL {
            guard FileManager.default.fileExists(atPath: url.path) else {
                logger.error("Video file not found: \(url.path)")
                return .failure(.videoFileNotFound(path: url.path))
            }
        } else {
            // For non-file URLs accept http/https; otherwise reject
            if let scheme = url.scheme?.lowercased(), !(scheme == "http" || scheme == "https") {
                logger.error("Unsupported URL scheme for wallpaper: \(url.scheme ?? "nil")")
                return .failure(.internalError(description: "Unsupported URL scheme: \(url.scheme ?? "unknown")"))
            }
        }

        logger.info("Setting wallpaper: \(url.lastPathComponent)")
        currentWallpaperURL = url
        lifecycleState = .playing

        // Start playback on all connected displays
        for (displayID, controller) in displayControllers {
            let result = await controller.startPlayback(
                url: url,
                isMuted: isMuted,
                scalingMode: scalingMode,
                rendererMode: currentRendererMode
            )
            switch result {
            case .success:
                logger.info("Wallpaper playback started on display \(displayID)")
            case .failure(let error):
                logger.error("Failed to start playback on display \(displayID): \(error.errorDescription ?? "unknown error")")
                return .failure(error)
            }
        }

        return .success(())
    }

    @MainActor
    func setRendererMode(_ mode: WallpaperRendererMode) async {
        currentRendererMode = mode
        logger.debug("Renderer mode updated to \(mode.rawValue, privacy: .public)")
    }

    @MainActor
    func setMuted(_ isMuted: Bool) async {
        self.isMuted = isMuted
        for controller in displayControllers.values {
            await controller.setMuted(isMuted)
        }
    }

    @MainActor
    func setScalingMode(_ mode: VideoScalingMode) async {
        scalingMode = mode
        for controller in displayControllers.values {
            await controller.setScalingMode(mode)
        }
    }

    @MainActor
    func setScalingModeForDisplay(displayID: CGDirectDisplayID, mode: VideoScalingMode) async {
        logger.debug("setScalingModeForDisplay called for \(displayID) -> \(mode.rawValue)")
        var controller = displayControllers[displayID]
        if controller == nil {
            controller = displayControllers.values.first(where: { $0.displayID == displayID })
        }

        guard let found = controller else {
            logger.warning("Display controller not found for scaling mode update: \(displayID)")
            return
        }

        await found.setScalingMode(mode)
    }

    // MARK: - Lifecycle Control (Chunk 4A)
    @MainActor
    func pause() async {
        guard lifecycleState != .paused else { return }
        logger.debug("WallpaperManager pausing playback")
        lifecycleState = .paused
        for controller in displayControllers.values {
            await controller.pause()
        }
    }

    @MainActor
    func resume() async {
        guard lifecycleState != .playing else { return }
        logger.debug("WallpaperManager resuming playback")
        lifecycleState = .playing
        for controller in displayControllers.values {
            await controller.resume()
        }
        
        // MARK: - Reconciliation After Resume (Chunk 4D)
        scheduleReconciliation(reason: "resume event")
    }

    // MARK: - State Reconciliation and Self-Healing (Chunk 4D)
    @MainActor
    private func scheduleReconciliation(reason: String) {
        // Cancel pending reconciliation to coalesce rapid events
        reconciliationTask?.cancel()
        
        reconciliationTask = Task {
            do {
                try await Task.sleep(nanoseconds: reconciliationDebounceInterval)
                
                if !Task.isCancelled {
                    await reconcileDisplayState(reason: reason)
                }
            } catch {
                logger.debug("Reconciliation task cancelled")
            }
        }
    }
    
    /// Verify controller/renderer/window consistency and self-heal mismatches
    @MainActor
    private func reconcileDisplayState(reason: String) async {
        logger.info("Starting display state reconciliation (triggered by: \(reason))")
        let usePerDisplay = true
        
        var healed: [CGDirectDisplayID] = []
        
        for (displayID, controller) in displayControllers {
            let expectedVideoURL: URL? = usePerDisplay
                ? expectedPerDisplayURL(for: displayID) ?? currentWallpaperURL
                : currentWallpaperURL
            let expectedScalingMode = expectedPerDisplayScalingMode(for: displayID) ?? scalingMode

            let healResult = await controller.reconcileState(
                expectedLifecycleState: lifecycleState,
                expectedVideoURL: expectedVideoURL,
                expectedMuted: isMuted,
                expectedScalingMode: expectedScalingMode
            )
            
            if case .healed(let reason) = healResult {
                healed.append(displayID)
                logger.info("Display \(displayID) healed: \(reason)")
            } else if case .valid = healResult {
                // No action needed
                logger.debug("Display \(displayID) state valid")
            } else if case .failed(let error) = healResult {
                logger.warning("Display \(displayID) reconciliation failed: \(error)")
                
                // MARK: - Track Failure (Chunk 4E)
                failureCount += 1
                lastFailureReason = "Display \(displayID): \(error)"
                
                // Track retry count and potentially recreate display
                let retryCount = reconciliationRetryCount[displayID] ?? 0
                if retryCount < self.maxReconciliationRetries {
                    reconciliationRetryCount[displayID] = retryCount + 1
                    logger.info("Queuing display \(displayID) for fallback recreation (attempt \(retryCount + 1)/\(self.maxReconciliationRetries))")
                    
                    // Schedule async recreation
                    Task {
                        await controller.fallbackRecreate(
                            videoURL: expectedVideoURL,
                            isMuted: isMuted,
                            scalingMode: expectedScalingMode,
                            rendererMode: currentRendererMode
                        )
                    }
                } else {
                    logger.error("Display \(displayID) exceeded max reconciliation retries, giving up")
                    reconciliationRetryCount[displayID] = 0
                }
            }
        }
        
        if !healed.isEmpty {
            logger.info("Reconciliation complete: healed \(healed.count) display(s)")
        } else {
            logger.debug("Reconciliation complete: no repairs needed")
        }
    }

    private func expectedPerDisplayScalingMode(for displayID: CGDirectDisplayID) -> VideoScalingMode {
        guard let rawValue = SettingsStore.shared.perDisplayScalingModes[String(displayID)],
              let mode = VideoScalingMode(rawValue: rawValue) else {
            return scalingMode
        }
        return mode
    }

    private func expectedPerDisplayURL(for displayID: CGDirectDisplayID) -> URL? {
        let key = String(displayID)

        // Prefer bookmark-resolved file URL when available for long-term sandbox reliability.
        if let bookmarkData = SettingsStore.shared.perDisplayBookmarks[key] {
            var isStale = false
            if let resolvedURL = try? URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ) {
                return resolvedURL
            }
        }

        guard let source = SettingsStore.shared.perDisplaySources[String(displayID)],
              !source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("/") {
            return URL(fileURLWithPath: trimmed)
        }

        guard let url = URL(string: trimmed) else { return nil }
        if url.scheme == nil, url.path.hasPrefix("/") {
            return URL(fileURLWithPath: url.path)
        }

        return url
    }

    @MainActor
    func stop() async {
        if let obs = screenObserver { NotificationCenter.default.removeObserver(obs); screenObserver = nil }
        if let obs = spaceObserver { NSWorkspace.shared.notificationCenter.removeObserver(obs); spaceObserver = nil }
        if let obs = sleepObserver { NotificationCenter.default.removeObserver(obs); sleepObserver = nil }
        if let obs = wakeObserver { NotificationCenter.default.removeObserver(obs); wakeObserver = nil }
        
        // MARK: - Cancel Reconciliation Task (Chunk 4D)
        reconciliationTask?.cancel()
        reconciliationTask = nil
        
        for controller in displayControllers.values { await controller.stop() }
        displayControllers.removeAll()
        currentWallpaperURL = nil
        lifecycleState = .idle
        try? addDiagnostic("stop: cleared controllers")
    }
}

// Simple diagnostic writer
fileprivate func addDiagnostic(_ message: String) throws {
    // MARK: - Conditional Diagnostics (Chunk 4E)
    guard SettingsStore.shared.debugDiagnosticsEnabled else { return }
    
    let fm = FileManager.default
    let path = "/tmp/pwe_manager.log"
    let text = "\(Date()): \(message)\n"
    if !fm.fileExists(atPath: path) { fm.createFile(atPath: path, contents: nil, attributes: nil) }
    guard let handle = FileHandle(forWritingAtPath: path) else { throw WallpaperError.internalError(description: "unable to open diag file") }
    handle.seekToEndOfFile()
    if let data = text.data(using: .utf8) { handle.write(data) }
    try handle.close()
}

// Convenience extension to obtain display ID from NSScreen
extension NSScreen {
    var displayID: CGDirectDisplayID {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
    }
}
