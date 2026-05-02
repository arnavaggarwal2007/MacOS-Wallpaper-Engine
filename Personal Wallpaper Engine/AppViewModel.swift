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

    private let wallpaperManager: WallpaperManager
    private let settings: SettingsStore
    private var hasStarted = false
    private var selectedVideoURL: URL?

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

        if !selectedVideoPath.isEmpty {
            await applyWallpaperFromSavedPath()
        }
    }

    func selectVideo(at url: URL) {
        selectedVideoURL = url
        selectedVideoPath = url.path
        settings.videoFilePath = url.path

        do {
            settings.videoBookmarkData = try url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        } catch {
            settings.videoBookmarkData = nil
        }

        statusMessage = "Selected: \(url.lastPathComponent)"
        errorMessage = nil
    }

    func applyWallpaperFromSelection() async {
        guard !selectedVideoPath.isEmpty else {
            errorMessage = "Please select a video file first."
            statusMessage = nil
            return
        }

        let url = resolveSelectedVideoURL() ?? URL(fileURLWithPath: selectedVideoPath)
        await applyWallpaper(url: url)
    }

    func stop() async {
        await wallpaperManager.stop()
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
        let url = resolveSelectedVideoURL() ?? URL(fileURLWithPath: selectedVideoPath)
        await applyWallpaper(url: url)
    }

    private func resolveSelectedVideoURL() -> URL? {
        if let selectedVideoURL {
            return selectedVideoURL
        }

        guard let bookmarkData = settings.videoBookmarkData else {
            return nil
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
                settings.videoBookmarkData = try resolvedURL.bookmarkData(
                    options: [.withSecurityScope],
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
            }

            selectedVideoURL = resolvedURL
            return resolvedURL
        } catch {
            return nil
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
