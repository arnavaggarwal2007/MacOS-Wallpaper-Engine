import AppKit
import AVFoundation
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

    enum ResumeReason: String {
        case user
        case powerPolicy
        case wake
        case reconciliation
    }

    enum PlaybackCommandSource: String {
        case toolbar
        case menuBar
        case toggle
        case powerPolicy
        case wake
        case sleep
        case system
    }

    private static let userResumeDebounceInterval: TimeInterval = 1.0
    private var playbackCommandCounter: UInt64 = 0
    private var lastUserPauseTimestamp: Date?
    private var lastPlaybackTransitionAt: Date?
    private var lastPlaybackTransitionWasPause: Bool?

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

    // MARK: - Power Policy (Phase 7A)
    private let powerPolicyManager = PowerPolicyManager()
    private var powerTask: Task<Void, Never>?
    private var pausedForPowerPolicy = false
    private var userPausedPlayback = false
    /// User explicitly resumed while on battery; do not show policy-pause chrome until next unplug.
    private(set) var userOverrodePowerPolicyPause = false
    private(set) var powerPolicyStatusMessage: String?

    private(set) var lifecycleState: LifecycleState = .idle

    /// True when desktop AVPlayers are in the playing lifecycle state.
    var isPlaybackActive: Bool { lifecycleState == .playing }

    /// True when renderers should actively decode (excludes visibility / user / power pauses).
    var shouldAdvanceDesktopPlayback: Bool {
        lifecycleState == .playing
            && !userPausedPlayback
            && !pausedForPowerPolicy
            && desktopVisibilityTracker.anyDisplayVisible
    }

    var isPausedForVisibilityPolicyForDiagnostics: Bool {
        displayControllers.values.contains { $0.isPausedForVisibilityPolicy }
    }

    /// True when desktop and apply paths must not call `play()` or force `.playing`.
    var isGloballyPaused: Bool {
        lifecycleState == .paused || userPausedPlayback || pausedForPowerPolicy
    }

    /// Paused overlays, carousel scrim, and hero banner — separate from transport (play/pause icon).
    var shouldShowPausedChrome: Bool {
        lifecycleState == .paused || userPausedPlayback
            || (pausedForPowerPolicy && !userOverrodePowerPolicyPause)
    }

    var isUserPausedForDiagnostics: Bool { userPausedPlayback }
    var isPausedForPowerPolicyForDiagnostics: Bool { pausedForPowerPolicy }

    /// Per-display AVPlayer rate for diagnostics (`displayID:rate`).
    func desktopPlaybackSnapshot() -> String {
        let parts = displayControllers.map { id, controller in
            let rate = controller.desktopPlaybackRate
            return "\(id):\(String(format: "%.3f", rate))"
        }.sorted()
        return parts.isEmpty ? "none" : parts.joined(separator: ",")
    }

    private var hasActiveRendererPlayback: Bool {
        displayControllers.values.contains { $0.isRendererActive }
    }

    private var hasDesktopPlaybackActivity: Bool {
        displayControllers.values.contains { $0.isRendererStillPlaying }
    }

    /// True when current settings and power snapshot require pausing (launch auto-play gate).
    func isPowerPolicyRequiringPause() -> Bool {
        Self.shouldPauseForPowerPolicy(
            settings: SettingsStore.shared,
            snapshot: powerPolicyManager.currentSnapshot
        )
    }
    
    // MARK: - State Reconciliation (Chunk 4D)
    private var reconciliationTask: Task<Void, Never>?
    private let reconciliationDebounceInterval: UInt64 = 350_000_000  // 0.35 seconds (7B: coalesce heal churn)
    private var reconciliationRetryCount: [CGDirectDisplayID: Int] = [:]
    private let maxReconciliationRetries: Int = 2
    
    // MARK: - System Health Tracking (Chunk 4E)
    private(set) var failureCount: Int = 0
    private(set) var lastFailureReason: String = ""
    private let maxFailureThreshold: Int = 5  // Threshold for degraded status

    /// Called after controllers are added/removed for a screen configuration change.
    var onScreenConfigurationChanged: (@MainActor () async -> Void)?

    /// Called when power-policy pause state or status message changes (Phase 7A).
    var onPowerPolicyChanged: (@MainActor () async -> Void)?

    private(set) var performanceProfile: PerformanceProfile = SettingsStore.shared.performanceProfile
    private let sharedVideoSession = SharedVideoPlaybackSession()
    private let desktopVisibilityTracker = DesktopVisibilityTracker()

    /// P2: Shared decode when multiple displays play the same local video file.
    func makeVideoRenderer(
        for displayID: CGDirectDisplayID,
        url: URL,
        rendererMode: WallpaperRendererMode
    ) -> Renderer {
        if shouldUseSharedVideoPlayback(for: url, updatingDisplayID: displayID, rendererMode: rendererMode) {
            logger.info("Using shared video session display=\(DisplayController.logLabel(for: displayID), privacy: .public) file=\(url.lastPathComponent, privacy: .public)")
            return SharedVideoLayerRenderer(displayID: displayID, session: sharedVideoSession)
        }
        return VideoRenderer()
    }

    private func shouldUseSharedVideoPlayback(
        for url: URL,
        updatingDisplayID: CGDirectDisplayID,
        rendererMode: WallpaperRendererMode
    ) -> Bool {
        guard rendererMode == .video else { return false }
        guard url.isFileURL else { return false }
        guard displayControllers.count >= 2 else { return false }

        if sharedVideoSession.matchesURL(url) {
            return true
        }

        let targetPath = normalizedVideoPath(url)

        // Exclude the display being updated — it still carries stale `lastLoadedVideoURL` during apply.
        let peerPaths = displayControllers
            .filter { $0.key != updatingDisplayID }
            .compactMap { normalizedVideoPath($0.value.loadedVideoURL) }

        if peerPaths.isEmpty {
            return true
        }
        return peerPaths.allSatisfy { $0 == targetPath }
    }

    /// After batch or per-display apply, migrate standalone decoders onto one shared session when paths match.
    @MainActor
    func coalesceSharedVideoPlaybackIfNeeded(for url: URL) async {
        guard url.isFileURL else { return }
        guard displayControllers.count >= 2 else { return }

        let targetPath = normalizedVideoPath(url)
        let matchingIDs = displayControllers.compactMap { id, controller -> CGDirectDisplayID? in
            guard let loaded = controller.loadedVideoURL,
                  normalizedVideoPath(loaded) == targetPath else { return nil }
            return id
        }.sorted()

        guard matchingIDs.count >= 2 else { return }

        let needsCoalesce = matchingIDs.contains { id in
            displayControllers[id]?.isUsingSharedVideoRenderer != true
        }
        guard needsCoalesce else { return }

        logger.info("Coalescing shared video playback file=\(url.lastPathComponent, privacy: .public) displays=\(matchingIDs.map { DisplayController.logLabel(for: $0) }.joined(separator: ", "), privacy: .public)")

        let autoPlay = shouldAdvanceDesktopPlayback
        for displayID in matchingIDs {
            guard let controller = displayControllers[displayID] else { continue }
            _ = await controller.startPlayback(
                url: url,
                isMuted: isMuted,
                scalingMode: controller.currentScalingMode,
                rendererMode: .video,
                autoPlay: autoPlay
            )
        }

        logger.info("Shared coalesce complete attachments=\(self.sharedVideoSession.attachedDisplayCount)")
    }

    private func normalizedVideoPath(_ url: URL) -> String {
        url.isFileURL ? url.standardizedFileURL.resolvingSymlinksInPath().path : url.absoluteString
    }

    private func normalizedVideoPath(_ url: URL?) -> String? {
        url.map { normalizedVideoPath($0) }
    }

    @MainActor
    func setPerformanceProfile(_ profile: PerformanceProfile) async {
        performanceProfile = profile
        logger.info("WallpaperManager performance profile=\(profile.rawValue, privacy: .public) pausesWhenOccluded=\(profile.pausesWhenOccluded)")
        for controller in displayControllers.values {
            await controller.applyPerformanceProfile(profile)
        }
        await applyDesktopVisibilityPolicy()
    }

    private func syncDesktopVisibilityTracking() {
        var windows: [CGDirectDisplayID: NSWindow] = [:]
        for (displayID, controller) in displayControllers {
            if let window = controller.desktopWindow {
                windows[displayID] = window
            }
        }
        desktopVisibilityTracker.onChange = { [weak self] in
            Task { await self?.applyDesktopVisibilityPolicy() }
        }
        desktopVisibilityTracker.syncWindows(windows)
    }

    /// P3/P4-A: Profile-driven per-display decode pause when wallpaper window is not visible.
    @MainActor
    func applyDesktopVisibilityPolicy() async {
        guard performanceProfile.pausesWhenOccluded else {
            for controller in displayControllers.values {
                await controller.resumeFromVisibilityPolicy()
            }
            return
        }

        guard lifecycleState == .playing else { return }
        guard !userPausedPlayback && !pausedForPowerPolicy else { return }

        desktopVisibilityTracker.evaluateAll()

        var sharedDisplayIDs: [CGDirectDisplayID] = []
        for (displayID, controller) in displayControllers {
            guard controller.isUsingSharedVideoRenderer else {
                let visible = desktopVisibilityTracker.displayVisible[displayID] ?? true
                if visible {
                    await controller.resumeFromVisibilityPolicy()
                } else {
                    await controller.pauseForVisibilityPolicy()
                }
                continue
            }
            sharedDisplayIDs.append(displayID)
        }

        if !sharedDisplayIDs.isEmpty {
            let anySharedVisible = sharedDisplayIDs.contains { desktopVisibilityTracker.displayVisible[$0] ?? true }
            for displayID in sharedDisplayIDs {
                guard let controller = displayControllers[displayID] else { continue }
                if anySharedVisible {
                    await controller.resumeFromVisibilityPolicy()
                } else {
                    await controller.pauseForVisibilityPolicy()
                }
            }
        }
    }

    @MainActor
    private func resumeDesktopFromVisibilityPolicy() async {
        guard lifecycleState == .playing else { return }
        guard !userPausedPlayback && !pausedForPowerPolicy else { return }

        logger.info("Desktop visibility policy: resuming all visibility-paused displays")
        for controller in displayControllers.values {
            await controller.resumeFromVisibilityPolicy()
        }
    }

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
            Task { await self?.pause(source: .sleep) }
        }

        wakeObserver = NotificationCenter.default.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.resumeFromSystemWake() }
        }

        startPowerPolicyMonitoring()
        desktopVisibilityTracker.onChange = { [weak self] in
            Task { await self?.applyDesktopVisibilityPolicy() }
        }
        await handleScreenChange()
    }

    // MARK: - Power Policy (Phase 7A)
    private func startPowerPolicyMonitoring() {
        powerPolicyManager.startObserving()
        let stream = powerPolicyManager.makeEventStream()
        powerTask = Task { [weak self] in
            for await event in stream {
                guard let self else { return }
                await self.handlePowerEvent(event)
            }
        }
        Task { await reevaluatePowerPolicy() }
    }

    func reevaluatePowerPolicy() async {
        let settings = SettingsStore.shared
        let snapshot = powerPolicyManager.currentSnapshot
        let shouldPause = Self.shouldPauseForPowerPolicy(settings: settings, snapshot: snapshot)

        if shouldPause {
            let reason = Self.powerPolicyPauseReason(settings: settings, snapshot: snapshot)
            powerPolicyStatusMessage = reason
            userOverrodePowerPolicyPause = false
            pausedForPowerPolicy = true
            if lifecycleState == .playing || hasActiveRendererPlayback {
                await pause(source: .powerPolicy)
            } else {
                logger.info("Power policy: desktops already paused; pausedForPowerPolicy=true (lifecycle=\(String(describing: self.lifecycleState)))")
            }
            if let onPowerPolicyChanged {
                await onPowerPolicyChanged()
            }
            return
        }

        powerPolicyStatusMessage = nil
        if pausedForPowerPolicy {
            pausedForPowerPolicy = false
            if userPausedPlayback {
                logger.info("Skipping powerPolicy resume — user paused playback")
            } else if lifecycleState == .paused {
                await resume(reason: .powerPolicy, source: .powerPolicy)
            }
        }
        if let onPowerPolicyChanged {
            await onPowerPolicyChanged()
        }
    }

    private func handlePowerEvent(_ event: PowerEvent) async {
        logger.debug("Power event received")
        await reevaluatePowerPolicy()
    }

    private static func shouldPauseForPowerPolicy(
        settings: SettingsStore,
        snapshot: PowerStateSnapshot
    ) -> Bool {
        if settings.pauseOnBattery, !snapshot.isOnACPower, snapshot.batteryLevelPercent != nil {
            return true
        }
        if settings.pauseOnLowBattery,
           let level = snapshot.batteryLevelPercent,
           level < settings.lowBatteryThreshold {
            return true
        }
        return false
    }

    private static func powerPolicyPauseReason(
        settings: SettingsStore,
        snapshot: PowerStateSnapshot
    ) -> String {
        if settings.pauseOnLowBattery,
           let level = snapshot.batteryLevelPercent,
           level < settings.lowBatteryThreshold {
            return "Wallpapers paused — battery below \(settings.lowBatteryThreshold)%."
        }
        if settings.pauseOnBattery, !snapshot.isOnACPower {
            return "Wallpapers paused to save battery."
        }
        return "Wallpapers paused for power policy."
    }

    private func resumeFromSystemWake() async {
        if userPausedPlayback {
            await reevaluatePowerPolicy()
            return
        }
        if pausedForPowerPolicy || Self.shouldPauseForPowerPolicy(
            settings: SettingsStore.shared,
            snapshot: powerPolicyManager.currentSnapshot
        ) {
            await reevaluatePowerPolicy()
            return
        }
        await resume(reason: .wake, source: .wake)
        await reevaluatePowerPolicy()
        await applyDesktopVisibilityPolicy()
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

        // Add or refresh displays (ID reuse after hotplug can point at a different physical screen)
        for screen in screens {
            let id = screen.displayID
            if let controller = displayControllers[id], controller.matchesCurrentScreen(screen) {
                controller.syncWindowGeometry(for: screen)
                continue
            }

            if let controller = displayControllers.removeValue(forKey: id) {
                await controller.stop()
                logger.debug("Replaced display controller \(id) after screen identity change")
            }

            let controller = DisplayController(screen: screen, manager: self)
            displayControllers[id] = controller
            controller.syncWindowGeometry(for: screen)
            logger.debug("Added display \(id) -> controller.displayID=\(controller.displayID)")
            do { try addDiagnostic("Added display \(id) frame=\(screen.frame)") } catch { logger.error("diag write failed: \(error.localizedDescription)") }
        }
        // Log current mapping for diagnostics
        logger.debug("Current displayControllers keys: \(self.displayControllers.keys)")

        syncDesktopVisibilityTracking()

        if let onScreenConfigurationChanged {
            await onScreenConfigurationChanged()
        }

        // MARK: - Reconciliation After Screen Change (Chunk 4D)
        scheduleReconciliation(reason: "screen change")
        await applyDesktopVisibilityPolicy()
    }

    @MainActor
    func handleSpaceChange() async {
        logger.debug("Active space changed")
        for controller in displayControllers.values { await controller.orderToBack() }

        desktopVisibilityTracker.evaluateAll()
        await applyDesktopVisibilityPolicy()
        
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

        let autoPlay = shouldAdvanceDesktopPlayback
        logger.info("setPerDisplayWallpaper display=\(DisplayController.logLabel(for: displayID), privacy: .public) autoPlay=\(autoPlay) lifecycle=\(String(describing: self.lifecycleState))")
        let result = await found.startPlayback(
            url: url,
            isMuted: isMuted,
            scalingMode: scalingMode,
            rendererMode: rendererMode,
            autoPlay: autoPlay
        )
        switch result {
        case .success:
            lifecycleState = autoPlay ? .playing : .paused
            logger.info("Per-display wallpaper applied to \(DisplayController.logLabel(for: displayID), privacy: .public) (autoPlay=\(autoPlay))")
            if url.isFileURL {
                await coalesceSharedVideoPlaybackIfNeeded(for: url)
            }
            await applyDesktopVisibilityPolicy()
            return .success(())
        case .failure(let error):
            logger.error("Failed to apply per-display wallpaper to \(displayID): \(error.errorDescription ?? "unknown")")
            if !hasActiveRendererPlayback {
                lifecycleState = .idle
            }
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

        let autoPlay = shouldAdvanceDesktopPlayback
        logger.info("Setting wallpaper: \(url.lastPathComponent) autoPlay=\(autoPlay)")
        currentWallpaperURL = url
        lifecycleState = autoPlay ? .playing : .paused

        // Start playback on all connected displays
        for (displayID, controller) in displayControllers {
            let result = await controller.startPlayback(
                url: url,
                isMuted: isMuted,
                scalingMode: scalingMode,
                rendererMode: currentRendererMode,
                autoPlay: autoPlay
            )
            switch result {
            case .success:
                logger.info("Wallpaper playback started on display \(DisplayController.logLabel(for: displayID), privacy: .public)")
            case .failure(let error):
                logger.error("Failed to start playback on display \(DisplayController.logLabel(for: displayID), privacy: .public): \(error.errorDescription ?? "unknown error")")
                return .failure(error)
            }
        }

        if url.isFileURL {
            await coalesceSharedVideoPlaybackIfNeeded(for: url)
        }

        await applyDesktopVisibilityPolicy()

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
    func pause(userInitiated: Bool = false, source: PlaybackCommandSource = .system) async {
        playbackCommandCounter += 1
        let commandID = playbackCommandCounter
        if userInitiated {
            userPausedPlayback = true
            lastUserPauseTimestamp = Date()
        }
        if let lastAt = lastPlaybackTransitionAt, lastPlaybackTransitionWasPause == false {
            let deltaMs = Int(Date().timeIntervalSince(lastAt) * 1000)
            logger.info("Playback pause (command=\(commandID)) Δms since last resume=\(deltaMs)")
        }
        lastPlaybackTransitionAt = Date()
        lastPlaybackTransitionWasPause = true
        guard !displayControllers.isEmpty else {
            logger.info("WallpaperManager pause skipped — no display controllers (command=\(commandID) source=\(source.rawValue))")
            return
        }
        if lifecycleState == .paused, !hasDesktopPlaybackActivity, !userInitiated {
            logger.info("WallpaperManager pause skipped — already paused with no active desktop playback (command=\(commandID))")
            return
        }
        if lifecycleState == .paused {
            logger.info("WallpaperManager re-enforcing pause (command=\(commandID) source=\(source.rawValue))")
        } else {
            logger.info("WallpaperManager pausing playback (command=\(commandID) userInitiated=\(userInitiated) source=\(source.rawValue))")
        }
        lifecycleState = .paused
        let controllers = Array(displayControllers.values)
        logger.info("Pausing \(controllers.count) desktop renderer(s) in parallel (command=\(commandID))")
        for controller in controllers {
            if let screen = NSScreen.screens.first(where: { $0.displayID == controller.displayID }) {
                controller.syncWindowGeometry(for: screen)
            }
        }
        await withTaskGroup(of: CGDirectDisplayID.self) { group in
            for controller in controllers {
                let displayID = controller.displayID
                group.addTask {
                    await controller.pause()
                    return displayID
                }
            }
            for await displayID in group {
                logger.debug("Desktop pause task completed for display \(displayID) (command=\(commandID))")
            }
        }
        await verifyDesktopPaused(commandID: commandID)
    }

    @MainActor
    private func verifyDesktopPaused(commandID: UInt64) async {
        var stillPlaying = displayControllers.filter { $0.value.isRendererStillPlaying }
        if stillPlaying.isEmpty { return }

        for (displayID, _) in stillPlaying {
            logger.warning("Display \(displayID) still playing after pause (command=\(commandID)); retrying")
        }
        try? await Task.sleep(nanoseconds: 80_000_000)
        for controller in displayControllers.values {
            await controller.pause()
        }
        stillPlaying = displayControllers.filter { $0.value.isRendererStillPlaying }
        for (displayID, _) in stillPlaying {
            logger.error("Display \(displayID) still playing after pause retry (command=\(commandID))")
        }
    }

    @MainActor
    func resume(reason: ResumeReason = .user, userInitiated: Bool = false, source: PlaybackCommandSource = .system) async {
        playbackCommandCounter += 1
        let commandID = playbackCommandCounter

        if userInitiated || reason == .user {
            if let lastPause = lastUserPauseTimestamp {
                let deltaMs = Int(Date().timeIntervalSince(lastPause) * 1000)
                if Date().timeIntervalSince(lastPause) < Self.userResumeDebounceInterval {
                    logger.info("Resume ignored — debounce after user pause (command=\(commandID) Δms=\(deltaMs) source=\(source.rawValue, privacy: .public))")
                    return
                }
                logger.info("Playback resume (command=\(commandID)) Δms since user pause=\(deltaMs) source=\(source.rawValue, privacy: .public)")
            }
            userPausedPlayback = false
            userOverrodePowerPolicyPause = true
            logger.info("User resume — power policy chrome override until next unplug (command=\(commandID))")
        } else if userPausedPlayback {
            logger.info("Skipping resume (\(reason.rawValue)) — user paused playback (command=\(commandID))")
            return
        }
        guard lifecycleState != .playing else {
            logger.info("Resume skipped — lifecycle already playing (command=\(commandID) reason=\(reason.rawValue, privacy: .public) source=\(source.rawValue, privacy: .public))")
            return
        }
        if let lastAt = lastPlaybackTransitionAt, lastPlaybackTransitionWasPause == true {
            let deltaMs = Int(Date().timeIntervalSince(lastAt) * 1000)
            logger.info("Playback resume (command=\(commandID)) Δms since last pause=\(deltaMs) reason=\(reason.rawValue, privacy: .public)")
        }
        lastPlaybackTransitionAt = Date()
        lastPlaybackTransitionWasPause = false
        logger.info("WallpaperManager resuming playback (command=\(commandID) reason=\(reason.rawValue) source=\(source.rawValue))")
        lifecycleState = .playing
        for controller in displayControllers.values {
            await controller.resume()
        }

        await applyDesktopVisibilityPolicy()

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

                if Task.isCancelled { return }
                if lifecycleState == .paused, userPausedPlayback || pausedForPowerPolicy {
                    logger.debug("Skipping reconciliation while paused (\(reason, privacy: .public))")
                    return
                }
                if displayControllers.values.allSatisfy({ $0.isPausedForVisibilityPolicy }) {
                    logger.debug("Skipping reconciliation while visibility-paused (\(reason, privacy: .public))")
                    return
                }
                await reconcileDisplayState(reason: reason)
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
            let expectedScalingMode = expectedPerDisplayScalingMode(for: displayID)

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
                    if isGloballyPaused {
                        logger.info("Skipping fallback recreate for display \(displayID) — globally paused")
                    } else {
                        logger.info("Queuing display \(displayID) for fallback recreation (attempt \(retryCount + 1)/\(self.maxReconciliationRetries))")
                        Task {
                            await controller.fallbackRecreate(
                                videoURL: expectedVideoURL,
                                isMuted: isMuted,
                                scalingMode: expectedScalingMode,
                                rendererMode: currentRendererMode
                            )
                        }
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

        desktopVisibilityTracker.stop()
        
        for controller in displayControllers.values { await controller.stop() }
        displayControllers.removeAll()
        currentWallpaperURL = nil
        lifecycleState = .idle
        try? addDiagnostic("stop: cleared controllers")
    }

    // MARK: - Phase 7C Diagnostics & Restart

    struct EngineDiagnosticsDisplayRow: Identifiable {
        var id: CGDirectDisplayID { displayID }
        let displayID: CGDirectDisplayID
        let label: String
        let sourceName: String
        let usesSharedRenderer: Bool
        let visibilityPaused: Bool
        let playbackRate: Float
    }

    struct EngineDiagnosticsSnapshot {
        let lifecycleState: LifecycleState
        let isPlaybackActive: Bool
        let performanceProfile: PerformanceProfile
        let sharedSessionAttachments: Int
        let decodePathCount: Int
        let heroSharesDesktopDecode: Bool
        let coalesceTip: String?
        let displayRows: [EngineDiagnosticsDisplayRow]
        let powerPolicyMessage: String?
        let anyDisplayVisible: Bool
    }

    var sharedSessionAttachmentCount: Int { sharedVideoSession.attachedDisplayCount }

    // MARK: - Phase 7D Hero preview / desktop decode unification

    func canUnifyHeroPreview(with url: URL, focusedDisplayID: CGDirectDisplayID?) -> Bool {
        heroPreviewProvider(for: url, focusedDisplayID: focusedDisplayID) != nil
    }

    @discardableResult
    func attachHeroPreviewLayer(
        in containerView: NSView,
        url: URL,
        focusedDisplayID: CGDirectDisplayID?
    ) -> Bool {
        let containerID = ObjectIdentifier(containerView)
        let urlPath = normalizedVideoPath(url)

        guard let provider = heroPreviewProvider(for: url, focusedDisplayID: focusedDisplayID) else {
            detachHeroPreviewLayers()
            logHeroAttachFailureIfNeeded(
                containerView: containerView,
                url: url,
                focusedDisplayID: focusedDisplayID,
                provider: nil,
                reason: "no_provider"
            )
            return false
        }

        if activeHeroContainerID == containerID,
           activeHeroURLPath == urlPath,
           activeHeroPreviewProvider === provider {
            provider.updateHeroPreviewLayerFrame(in: containerView)
            provider.setHeroPreviewLayerHidden(false)
            return true
        }

        activeHeroPreviewProvider?.detachHeroPreviewLayer()

        guard provider.attachHeroPreviewLayer(in: containerView, videoGravity: .resizeAspectFill) else {
            clearHeroPreviewAttachmentState()
            logHeroAttachFailureIfNeeded(
                containerView: containerView,
                url: url,
                focusedDisplayID: focusedDisplayID,
                provider: provider,
                reason: "provider_attach_failed"
            )
            return false
        }

        activeHeroContainerID = containerID
        activeHeroURLPath = urlPath
        activeHeroPreviewProvider = provider
        lastHeroAttachFailureLogKey = nil
        logger.debug("Hero preview attached to shared desktop decode file=\(url.lastPathComponent, privacy: .public)")
        return true
    }

    func updateHeroPreviewLayerFrame(in containerView: NSView) {
        guard activeHeroContainerID == ObjectIdentifier(containerView) else { return }
        activeHeroPreviewProvider?.updateHeroPreviewLayerFrame(in: containerView)
    }

    func setHeroPreviewLayerHidden(_ hidden: Bool) {
        activeHeroPreviewProvider?.setHeroPreviewLayerHidden(hidden)
    }

    func detachHeroPreviewLayers() {
        activeHeroPreviewProvider?.detachHeroPreviewLayer()
        clearHeroPreviewAttachmentState()
    }

    private func clearHeroPreviewAttachmentState() {
        activeHeroContainerID = nil
        activeHeroURLPath = nil
        activeHeroPreviewProvider = nil
    }

    func decodePathCountForDiagnostics() -> Int {
        let standalonePlayers = displayControllers.values.filter {
            !$0.isUsingSharedVideoRenderer && $0.loadedVideoURL != nil
        }.count
        let sharedPaths = sharedVideoSession.attachedDisplayCount > 0 ? 1 : 0
        return standalonePlayers + sharedPaths
    }

    func coalesceTipForDiagnostics() -> String? {
        guard displayControllers.count >= 2 else { return nil }
        let paths = Set(displayControllers.compactMap { normalizedVideoPath($0.value.loadedVideoURL) })
        guard paths.count > 1 else { return nil }
        return "Different files per display → \(paths.count) decode paths. Apply the same 1080p file to all displays to coalesce (~2–3% CPU vs ~2× decode)."
    }

    private weak var activeHeroPreviewProvider: (any DesktopVideoPreviewProviding)?
    private var activeHeroContainerID: ObjectIdentifier?
    private var activeHeroURLPath: String?
    private var lastHeroAttachFailureLogKey: String?

    private func logHeroAttachFailureIfNeeded(
        containerView: NSView,
        url: URL,
        focusedDisplayID: CGDirectDisplayID?,
        provider: (any DesktopVideoPreviewProviding)?,
        reason: String
    ) {
        let bounds = containerView.bounds
        guard !bounds.isEmpty || reason == "no_provider" else { return }

        let logKey = "\(reason)-\(normalizedVideoPath(url))-\(focusedDisplayID.map(String.init) ?? "nil")"
        guard lastHeroAttachFailureLogKey != logKey else { return }
        lastHeroAttachFailureLogKey = logKey

        let providerLabel: String
        if let provider {
            providerLabel = provider is SharedVideoPlaybackSession ? "shared" : "standalone"
        } else {
            providerLabel = "none"
        }
        let displayLabel = focusedDisplayID.map { String($0) } ?? "nil"
        logger.debug(
            "Hero preview attach failed reason=\(reason, privacy: .public) bounds=\(NSStringFromSize(bounds.size), privacy: .public) provider=\(providerLabel, privacy: .public) display=\(displayLabel, privacy: .public) file=\(url.lastPathComponent, privacy: .public)"
        )
    }

    private func heroPreviewProvider(for url: URL, focusedDisplayID: CGDirectDisplayID?) -> (any DesktopVideoPreviewProviding)? {
        guard url.isFileURL else { return nil }

        if sharedVideoSession.matchesHeroPreviewURL(url) {
            return sharedVideoSession
        }

        if let displayID = focusedDisplayID ?? displayControllers.keys.sorted().first,
           let controller = displayControllers[displayID],
           let video = controller.heroPreviewProvider,
           video.matchesHeroPreviewURL(url) {
            return video
        }

        return nil
    }

    func diagnosticsSnapshot() -> EngineDiagnosticsSnapshot {
        let rows = displayControllers.map { displayID, controller -> EngineDiagnosticsDisplayRow in
            let source = controller.loadedVideoURL?.lastPathComponent ?? "—"
            return EngineDiagnosticsDisplayRow(
                displayID: displayID,
                label: DisplayController.logLabel(for: displayID),
                sourceName: source,
                usesSharedRenderer: controller.isUsingSharedVideoRenderer,
                visibilityPaused: controller.isPausedForVisibilityPolicy,
                playbackRate: controller.desktopPlaybackRate
            )
        }.sorted { $0.displayID < $1.displayID }

        return EngineDiagnosticsSnapshot(
            lifecycleState: lifecycleState,
            isPlaybackActive: isPlaybackActive,
            performanceProfile: performanceProfile,
            sharedSessionAttachments: sharedVideoSession.attachedDisplayCount,
            decodePathCount: decodePathCountForDiagnostics(),
            heroSharesDesktopDecode: activeHeroPreviewProvider != nil,
            coalesceTip: coalesceTipForDiagnostics(),
            displayRows: rows,
            powerPolicyMessage: powerPolicyStatusMessage,
            anyDisplayVisible: desktopVisibilityTracker.anyDisplayVisible
        )
    }

    /// Tears down renderers and shared decode; caller should reapply persisted wallpapers then optionally resume.
    @discardableResult
    func restartEngine() async -> Bool {
        let resumeAfter = lifecycleState == .playing && !userPausedPlayback && !pausedForPowerPolicy
        logger.info("Engine restart requested resumeAfter=\(resumeAfter)")

        detachHeroPreviewLayers()
        reconciliationTask?.cancel()
        reconciliationTask = nil

        for controller in displayControllers.values {
            await controller.disposeRendererForRestart()
        }
        sharedVideoSession.resetForEngineRestart()
        lifecycleState = .idle
        syncDesktopVisibilityTracking()

        logger.info("Engine restart: renderers cleared, awaiting wallpaper reapply")
        return resumeAfter
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
