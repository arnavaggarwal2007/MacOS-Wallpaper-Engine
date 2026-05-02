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

    private var displayControllers: [CGDirectDisplayID: DisplayController] = [:]
    private var currentWallpaperURL: URL?
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
                logger.debug("Added display \(id)")
                do { try addDiagnostic("Added display \(id) frame=\(screen.frame)") } catch { logger.error("diag write failed: \(error.localizedDescription)") }

                if let currentWallpaperURL {
                    let result = await controller.startPlayback(
                        url: currentWallpaperURL,
                        isMuted: isMuted,
                        scalingMode: scalingMode
                    )

                    if case .failure(let error) = result {
                        logger.error("Failed to start playback on newly added display \(id): \(error.errorDescription ?? "unknown error")")
                    }
                }
            }
        }
    }

    @MainActor
    func handleSpaceChange() async {
        logger.debug("Active space changed")
        for controller in displayControllers.values { await controller.orderToBack() }
    }

    @MainActor
    func createDisplayController(for screen: NSScreen) async -> Result<DisplayController, WallpaperError> {
        let controller = DisplayController(screen: screen, manager: self)
        return .success(controller)
    }

    @MainActor
    func setWallpaper(url: URL) async -> Result<Void, WallpaperError> {
        // Validate file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            logger.error("Video file not found: \(url.path)")
            return .failure(.videoFileNotFound(path: url.path))
        }

        logger.info("Setting wallpaper: \(url.lastPathComponent)")
        currentWallpaperURL = url
        lifecycleState = .playing

        // Start playback on all connected displays
        for (displayID, controller) in displayControllers {
            let result = await controller.startPlayback(
                url: url,
                isMuted: isMuted,
                scalingMode: scalingMode
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
    }

    @MainActor
    func stop() async {
        if let obs = screenObserver { NotificationCenter.default.removeObserver(obs); screenObserver = nil }
        if let obs = spaceObserver { NSWorkspace.shared.notificationCenter.removeObserver(obs); spaceObserver = nil }
        if let obs = sleepObserver { NotificationCenter.default.removeObserver(obs); sleepObserver = nil }
        if let obs = wakeObserver { NotificationCenter.default.removeObserver(obs); wakeObserver = nil }
        for controller in displayControllers.values { await controller.stop() }
        displayControllers.removeAll()
        currentWallpaperURL = nil
        lifecycleState = .idle
        try? addDiagnostic("stop: cleared controllers")
    }
}

// Simple diagnostic writer
fileprivate func addDiagnostic(_ message: String) throws {
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
