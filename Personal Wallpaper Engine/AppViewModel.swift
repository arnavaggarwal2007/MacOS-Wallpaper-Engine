import Foundation
import SwiftUI
import Combine

@MainActor
final class AppViewModel: ObservableObject {
    @Published var selectedVideoPath: String
    @Published var isMuted: Bool
    @Published var scalingMode: VideoScalingMode
    @Published var isApplyingWallpaper = false
    @Published var statusMessage: String?
    @Published var errorMessage: String?
    
    // MARK: - System Health Tracking (Chunk 4E)
    @Published var systemHealthStatus: SystemHealthStatus = .healthy
    @Published var failureCount: Int = 0

    private let wallpaperManager: WallpaperManager
    private let settings: SettingsStore
    private var hasStarted = false
    private var selectedVideoURL: URL?
    private var activeSecurityScopedVideoURL: URL?
    private var lastVideoRestoreFailure: String?

    init() {
        self.wallpaperManager = WallpaperManager()
        self.settings = SettingsStore.shared
        self.selectedVideoPath = settings.videoFilePath
        self.isMuted = settings.isMuted
        self.scalingMode = settings.scalingMode
    }

    init(
        wallpaperManager: WallpaperManager? = nil,
        settings: SettingsStore
    ) {
        self.wallpaperManager = wallpaperManager ?? WallpaperManager()
        self.settings = settings
        self.selectedVideoPath = settings.videoFilePath
        self.isMuted = settings.isMuted
        self.scalingMode = settings.scalingMode
    }

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true

        await wallpaperManager.setMuted(isMuted)
        await wallpaperManager.setScalingMode(scalingMode)
        await wallpaperManager.startMonitoring()

        if restoreSelectedVideoReference() != nil {
            await applyWallpaperFromSavedPath()
        } else if !selectedVideoPath.isEmpty {
            let details = lastVideoRestoreFailure.map { " (\($0))" } ?? ""
            errorMessage = "Saved video access expired. Please reselect the video file.\(details)"
            statusMessage = nil
        }
    }

    func selectVideo(at url: URL) {
        endAccessingSelectedVideoURL()
        beginAccessingSelectedVideoURL(url)
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

    func applyWallpaperFromSelection() async {
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
