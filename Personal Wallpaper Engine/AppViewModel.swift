import Foundation
import os
import SwiftUI
import Combine

@MainActor
final class AppViewModel: ObservableObject {
    @Published var selectedVideoPath: String
    @Published var rendererMode: WallpaperRendererMode
    @Published var webURLString: String
    @Published var isMuted: Bool
    @Published var scalingMode: VideoScalingMode
    @Published var isApplyingWallpaper = false
    @Published var statusMessage: String?
    @Published var errorMessage: String?
    @Published var isPlaying: Bool = true
    @Published var isLaunchOnLoginEnabled: Bool = false  // Phase 5G
    @Published var launchOnLoginStatusMessage: String?
    @Published var launchOnLoginErrorMessage: String?
    @Published var usePerDisplay: Bool
    
    // MARK: - System Health Tracking (Chunk 4E)
    @Published var systemHealthStatus: SystemHealthStatus = .healthy
    @Published var failureCount: Int = 0

    private let wallpaperManager: WallpaperManager
    private let settings: SettingsStore
    private let loginItemManager = LoginItemManager()  // Phase 5G
    private let logger = Logger(subsystem: "com.local.wallpaper", category: "AppViewModel")
    private var hasStarted = false
    private var selectedVideoURL: URL?
    private var activeSecurityScopedVideoURL: URL?
    private var lastVideoRestoreFailure: String?

    init() {
        self.wallpaperManager = WallpaperManager()
        self.settings = SettingsStore.shared
        self.selectedVideoPath = settings.videoFilePath
        self.rendererMode = settings.rendererMode
        self.webURLString = settings.webURLString
        self.isMuted = settings.isMuted
        self.scalingMode = settings.scalingMode
        self.isLaunchOnLoginEnabled = settings.launchOnLoginEnabled
        self.usePerDisplay = settings.usePerDisplay
    }

    init(
        wallpaperManager: WallpaperManager? = nil,
        settings: SettingsStore
    ) {
        self.wallpaperManager = wallpaperManager ?? WallpaperManager()
        self.settings = settings
        self.selectedVideoPath = settings.videoFilePath
        self.rendererMode = settings.rendererMode
        self.webURLString = settings.webURLString
        self.isMuted = settings.isMuted
        self.scalingMode = settings.scalingMode
        self.isLaunchOnLoginEnabled = settings.launchOnLoginEnabled
        self.usePerDisplay = settings.usePerDisplay
    }

    func toggleUsePerDisplay(_ enabled: Bool) {
        usePerDisplay = enabled
        settings.usePerDisplay = enabled
        // If switching to unified and we have a selected video/URL, apply it globally
        if !enabled {
            Task { @MainActor in
                if rendererMode == .video {
                    await applyWallpaperFromSelection()
                } else if rendererMode == .web {
                    await applyWallpaperFromSelection()
                }
            }
        }
    }

    // MARK: - Per-display helpers (Phase 5E)
    func perDisplaySource(for displayID: CGDirectDisplayID) -> String {
        return settings.perDisplaySources[String(displayID)] ?? ""
    }

    func updatePerDisplaySource(_ displayID: CGDirectDisplayID, _ urlString: String) {
        settings.perDisplaySources[String(displayID)] = urlString
    }

    func perDisplayResolvedURL(for displayID: CGDirectDisplayID) -> URL? {
        if let bookmarkData = settings.perDisplayBookmarks[String(displayID)] {
            var isStale = false
            do {
                let resolvedURL = try URL(
                    resolvingBookmarkData: bookmarkData,
                    options: [.withSecurityScope],
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )

                if isStale {
                    do {
                        settings.perDisplayBookmarks[String(displayID)] = try resolvedURL.bookmarkData(
                            options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                            includingResourceValuesForKeys: nil,
                            relativeTo: nil
                        )
                    } catch {
                        logger.warning("Failed to refresh stale per-display bookmark for display \(displayID): \(error.localizedDescription)")
                    }
                }

                return resolvedURL
            } catch {
                logger.warning("Failed to resolve per-display bookmark for display \(displayID): \(error.localizedDescription)")
            }
        }

        guard let source = settings.perDisplaySources[String(displayID)],
              let url = resolvedSourceURL(from: source) else {
            return nil
        }
        return url
    }

    func applyPerDisplayWallpaper(displayID: CGDirectDisplayID, sourceString: String) async {
        let trimmed = sourceString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let sourceURL = resolvedSourceURL(from: trimmed) else {
            errorMessage = "Please choose a wallpaper source for display \(displayID)."
            statusMessage = nil
            return
        }

        let key = String(displayID)
        let previousSource = settings.perDisplaySources[key]
        let previousURL = previousSource.flatMap { resolvedSourceURL(from: $0) }
        let isChangingSource = previousURL?.absoluteString != sourceURL.absoluteString

        settings.perDisplaySources[key] = sourceURL.absoluteString
        var candidateURLs: [URL] = []

        if sourceURL.isFileURL {
            // When user changes source, always try the newly selected source first.
            candidateURLs.append(sourceURL)

            // Only use old bookmark as fallback when source is unchanged.
            if !isChangingSource, let bookmarkedURL = perDisplayResolvedURL(for: displayID) {
                candidateURLs.append(bookmarkedURL)
            }

            do {
                settings.perDisplayBookmarks[key] = try sourceURL.bookmarkData(
                    options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                // Add freshly written bookmark URL as an additional fallback.
                if let refreshedURL = perDisplayResolvedURL(for: displayID) {
                    candidateURLs.append(refreshedURL)
                }
            } catch {
                logger.warning("Failed to save per-display bookmark for display \(displayID): \(error.localizedDescription)")
            }
        } else {
            candidateURLs = [sourceURL]
        }

        let scaling = perDisplayScalingMode(for: displayID)

        isApplyingWallpaper = true
        defer { isApplyingWallpaper = false }

        var lastError: WallpaperError?
        var attempted = Set<String>()

        for url in candidateURLs {
            // De-duplicate candidates that may resolve to the same absolute string
            let marker = url.absoluteString
            if attempted.contains(marker) { continue }
            attempted.insert(marker)

            let rendererMode: WallpaperRendererMode = url.isFileURL ? .video : .web
            switch await wallpaperManager.setPerDisplayWallpaper(displayID: displayID, url: url, rendererMode: rendererMode, scalingMode: scaling) {
            case .success:
                statusMessage = "Applied to display \(displayID): \(url.lastPathComponent)"
                errorMessage = nil
                return
            case .failure(let error):
                lastError = error
                let errorText = error.errorDescription ?? "unknown"
                logger.warning("Per-display apply attempt failed for display \(displayID) using \(url.absoluteString): \(errorText)")
            }
        }

        // If all candidates fail for a file URL, clear stale bookmark so next manual selection seeds a fresh one.
        if sourceURL.isFileURL {
            var bookmarks = settings.perDisplayBookmarks
            bookmarks.removeValue(forKey: key)
            settings.perDisplayBookmarks = bookmarks
        }

        errorMessage = lastError?.errorDescription ?? "Unable to apply wallpaper for display \(displayID)."
        statusMessage = nil
    }

    private func resolvedSourceURL(from source: String) -> URL? {
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.hasPrefix("/") {
            return URL(fileURLWithPath: trimmed)
        }

        guard let url = URL(string: trimmed) else { return nil }

        if url.scheme == nil, url.path.hasPrefix("/") {
            return URL(fileURLWithPath: url.path)
        }

        return url
    }

    // MARK: - Per-display scaling modes
    func perDisplayScalingMode(for displayID: CGDirectDisplayID) -> VideoScalingMode {
        guard let modeString = settings.perDisplayScalingModes[String(displayID)],
              let mode = VideoScalingMode(rawValue: modeString) else {
            return scalingMode  // Default to global scaling mode
        }
        return mode
    }

    func updatePerDisplayScalingMode(_ displayID: CGDirectDisplayID, _ mode: VideoScalingMode) {
        settings.perDisplayScalingModes[String(displayID)] = mode.rawValue
        
        // Apply to display if it exists
        Task { @MainActor in
            logger.debug("Requesting scaling update for display \(displayID): \(mode.rawValue)")
            await wallpaperManager.setScalingModeForDisplay(displayID: displayID, mode: mode)
        }
    }

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true

        await wallpaperManager.setMuted(isMuted)
        await wallpaperManager.setScalingMode(scalingMode)
        await wallpaperManager.setRendererMode(rendererMode)
        await wallpaperManager.startMonitoring()

        if rendererMode == .video, restoreSelectedVideoReference() != nil {
            await applyWallpaperFromSavedPath()
        } else if rendererMode == .video, !selectedVideoPath.isEmpty {
            let details = lastVideoRestoreFailure.map { " (\($0))" } ?? ""
            errorMessage = "Saved video access expired. Please reselect the video file.\(details)"
            statusMessage = nil
        } else if rendererMode == .web {
            statusMessage = "Web wallpaper mode is ready"
            errorMessage = nil
            // Attempt to restore web selection across relaunch
            if !webURLString.isEmpty {
                Task { await applyWallpaperFromSavedWebURL() }
            }
        }
    }

    func selectVideo(at url: URL) {
        endAccessingSelectedVideoURL()
        beginAccessingSelectedVideoURL(url)
        rendererMode = .video
        settings.rendererMode = .video
        selectedVideoURL = url
        selectedVideoPath = url.path
        settings.videoFilePath = url.path

        do {
            settings.videoBookmarkData = try url.bookmarkData(
                options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        } catch {
            lastVideoRestoreFailure = "bookmark save failed: \(error.localizedDescription)"
        }

        statusMessage = "Selected: \(url.lastPathComponent)"
        errorMessage = nil
    }

    func updateWebURL(_ urlString: String) {
        webURLString = urlString
        settings.webURLString = urlString
    }

    func updateRendererMode(_ mode: WallpaperRendererMode) {
        rendererMode = mode
        settings.rendererMode = mode

        Task {
            await wallpaperManager.setRendererMode(mode)
        }

        if mode == .web {
            statusMessage = "Web wallpapers are planned for the next chunk."
            errorMessage = nil
        }
    }

    func applyWallpaperFromSelection() async {
        if usePerDisplay {
            errorMessage = "Unified wallpaper apply is disabled while per-display mode is enabled."
            statusMessage = nil
            return
        }

        if rendererMode == .video {
            guard let url = restoreSelectedVideoReference() else {
                if selectedVideoPath.isEmpty {
                    errorMessage = "Please select a video file first."
                } else {
                    let details = lastVideoRestoreFailure.map { " (\($0))" } ?? ""
                    errorMessage = "Saved video access expired. Please reselect the video file.\(details)"
                }
                statusMessage = nil
                return
            }

            await applyWallpaper(url: url)
            return
        }

        if rendererMode == .web {
            guard !webURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  let url = URL(string: webURLString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                errorMessage = "Please enter a valid web URL."
                statusMessage = nil
                return
            }

            await applyWallpaper(url: url)
            return
        }
    }

    private func applyWallpaperFromSavedWebURL() async {
        guard rendererMode == .web else { return }
        let trimmed = settings.webURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed) else { return }
        await applyWallpaper(url: url)
    }

    func stop() async {
        await wallpaperManager.stop()
        endAccessingSelectedVideoURL()
        hasStarted = false
    }

    func updateMuted(_ isMuted: Bool) {
        self.isMuted = isMuted
        settings.isMuted = isMuted

        Task {
            await wallpaperManager.setMuted(isMuted)
        }
    }

    func updateScalingMode(_ mode: VideoScalingMode) {
        scalingMode = mode
        settings.scalingMode = mode

        Task {
            await wallpaperManager.setScalingMode(mode)
        }
    }

    private func applyWallpaperFromSavedPath() async {
        guard rendererMode == .video else { return }
        guard let url = restoreSelectedVideoReference() else { return }
        await applyWallpaper(url: url)
    }

    private func restoreSelectedVideoReference() -> URL? {
        lastVideoRestoreFailure = nil

        if let selectedVideoURL {
            _ = beginAccessingSelectedVideoURL(selectedVideoURL)
            return selectedVideoURL
        }

        guard let bookmarkData = settings.videoBookmarkData else {
            guard !selectedVideoPath.isEmpty else {
                return nil
            }

            let fileURL = URL(fileURLWithPath: selectedVideoPath)
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                lastVideoRestoreFailure = "file no longer exists"
                return nil
            }

            guard FileManager.default.isReadableFile(atPath: fileURL.path) else {
                lastVideoRestoreFailure = "file is not readable without renewed access"
                return nil
            }

            selectedVideoURL = fileURL
            _ = beginAccessingSelectedVideoURL(fileURL)

            if settings.videoBookmarkData == nil {
                do {
                    settings.videoBookmarkData = try fileURL.bookmarkData(
                        options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    )
                } catch {
                    lastVideoRestoreFailure = "bookmark refresh failed: \(error.localizedDescription)"
                }
            }

            return fileURL
        }

        var isStale = false
        do {
            let resolvedURL = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                do {
                    settings.videoBookmarkData = try resolvedURL.bookmarkData(
                        options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    )
                } catch {
                    // Keep using resolved URL even if bookmark refresh fails for now.
                }
            }

            selectedVideoURL = resolvedURL
            selectedVideoPath = resolvedURL.path
            settings.videoFilePath = resolvedURL.path
            let hasScopeAccess = beginAccessingSelectedVideoURL(resolvedURL)
            guard hasScopeAccess else {
                lastVideoRestoreFailure = "security-scoped access denied"
                return nil
            }
            return resolvedURL
        } catch {
            lastVideoRestoreFailure = "bookmark resolve failed: \(error.localizedDescription)"
            guard !selectedVideoPath.isEmpty else {
                return nil
            }

            let fileURL = URL(fileURLWithPath: selectedVideoPath)
            guard FileManager.default.fileExists(atPath: fileURL.path),
                  FileManager.default.isReadableFile(atPath: fileURL.path) else {
                return nil
            }

            selectedVideoURL = fileURL
            _ = beginAccessingSelectedVideoURL(fileURL)
            return fileURL
        }
    }

    private func beginAccessingSelectedVideoURL(_ url: URL) -> Bool {
        if activeSecurityScopedVideoURL != url {
            endAccessingSelectedVideoURL()
            let didStart = url.startAccessingSecurityScopedResource()
            if didStart {
                activeSecurityScopedVideoURL = url
            }
            return didStart
        }

        return true
    }

    private func endAccessingSelectedVideoURL() {
        if let activeSecurityScopedVideoURL {
            activeSecurityScopedVideoURL.stopAccessingSecurityScopedResource()
            self.activeSecurityScopedVideoURL = nil
        }
    }

    private func applyWallpaper(url: URL) async {
        isApplyingWallpaper = true
        defer { isApplyingWallpaper = false }

        switch await wallpaperManager.setWallpaper(url: url) {
        case .success:
            statusMessage = "Wallpaper applied: \(url.lastPathComponent)"
            errorMessage = nil
        case .failure(let error):
            errorMessage = error.errorDescription ?? "Unable to apply wallpaper."
            statusMessage = nil
        }
    }
    
    // MARK: - Menu Bar Actions (Phase 5F)
    
    func togglePlayback() async {
        isPlaying.toggle()
        if isPlaying {
            await applyWallpaperFromSelection()
        } else {
            await wallpaperManager.stop()
        }
    }
    
    func toggleMute() async {
        updateMuted(!isMuted)
    }
    
    @MainActor
    func openPreferences() async {
        // Show preferences window or switch to preferences view
        // For now, this can be expanded to show a preferences window
        statusMessage = "Preferences window would open here (Phase 5F+)"
    }
    // MARK: - Launch-on-Login (Phase 5G)
    func updateLaunchOnLoginStatus() {
        isLaunchOnLoginEnabled = loginItemManager.isLaunchOnLoginEnabled
        settings.launchOnLoginEnabled = isLaunchOnLoginEnabled
        launchOnLoginStatusMessage = loginItemManager.statusMessage
        launchOnLoginErrorMessage = loginItemManager.errorMessage
    }
    
    func toggleLaunchOnLogin() async {
        loginItemManager.toggleLaunchOnLogin()
        try? await Task.sleep(nanoseconds: 500_000_000)
        updateLaunchOnLoginStatus()
    }
}

// MARK: - System Health Status (Chunk 4E)
enum SystemHealthStatus {
    case healthy
    case degraded(reason: String)
    case failed(reason: String)
    
    var displayText: String {
        switch self {
        case .healthy:
            return "System Healthy"
        case .degraded(let reason):
            return "Degraded: \(reason)"
        case .failed(let reason):
            return "Failed: \(reason)"
        }
    }
}
