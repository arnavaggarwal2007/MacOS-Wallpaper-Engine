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
    
    // MARK: - Phase 6A Collection State
    @Published var savedCollections: [String: WallpaperCollection] = [:]
    @Published var lastUsedCollectionName: String?
    @Published var selectedCollectionName: String?
    
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

    func selectPerDisplaySource(_ displayID: CGDirectDisplayID, at url: URL) {
        print("AppViewModel.selectPerDisplaySource: called display=\(displayID), url=\(url.absoluteString)")
        let key = String(displayID)
        settings.perDisplaySources[key] = url.absoluteString

        if url.isFileURL {
            do {
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    let bookmark = try url.bookmarkData(
                        options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    )
                    settings.perDisplayBookmarks[key] = bookmark
                }
            } catch {
                logger.warning("Failed to stage per-display bookmark for display \(displayID): \(error.localizedDescription)")
            }
        }

        statusMessage = "Selected for display \(displayID): \(url.lastPathComponent)"
        errorMessage = nil
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
                    // When refreshing a stale bookmark, we must access the resource first
                    guard resolvedURL.startAccessingSecurityScopedResource() else {
                        logger.warning("Failed to access security-scoped resource while refreshing bookmark for display \(displayID)")
                        return resolvedURL  // Return the resolved URL anyway, even if we can't refresh the bookmark
                    }
                    defer { resolvedURL.stopAccessingSecurityScopedResource() }

                    do {
                        let refreshedBookmark = try resolvedURL.bookmarkData(
                            options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                            includingResourceValuesForKeys: nil,
                            relativeTo: nil
                        )
                        settings.perDisplayBookmarks[String(displayID)] = refreshedBookmark
                        logger.debug("Refreshed stale per-display bookmark for display \(displayID)")
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
        guard !trimmed.isEmpty else {
            errorMessage = "Please choose a wallpaper source for display \(displayID)."
            statusMessage = nil
            return
        }

        let key = String(displayID)
        var candidateURLs: [URL] = []
        let previousBookmarkedURL = perDisplayResolvedURL(for: displayID)

        // Then try resolving the source string
        guard let sourceURL = resolvedSourceURL(from: trimmed) else {
            errorMessage = "Please choose a wallpaper source for display \(displayID)."
            statusMessage = nil
            return
        }

        // Always try the newly selected source first.
        candidateURLs.append(sourceURL)

        // Keep the prior bookmark as a fallback in case the new source fails.
        if let previousBookmarkedURL,
           previousBookmarkedURL.absoluteString != sourceURL.absoluteString {
            candidateURLs.append(previousBookmarkedURL)
        }

        // Always update the source path storage
        settings.perDisplaySources[key] = sourceURL.absoluteString

        // For file URLs, save/refresh the bookmark
        if sourceURL.isFileURL {
            do {
                if sourceURL.startAccessingSecurityScopedResource() {
                    defer { sourceURL.stopAccessingSecurityScopedResource() }

                    let bookmark = try sourceURL.bookmarkData(
                        options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    )
                    settings.perDisplayBookmarks[key] = bookmark
                    logger.debug("Saved per-display bookmark for display \(displayID)")
                } else {
                    logger.warning("Failed to access security-scoped resource for bookmarking display \(displayID)")
                }
            } catch {
                logger.warning("Failed to save per-display bookmark for display \(displayID): \(error.localizedDescription)")
            }
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
            let didStartScope = url.isFileURL ? url.startAccessingSecurityScopedResource() : false
            defer {
                if didStartScope {
                    url.stopAccessingSecurityScopedResource()
                }
            }

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

        // If all candidates fail for a file URL, clear stale bookmark so next manual selection seeds a fresh one
        if sourceURL.isFileURL {
            var bookmarks = settings.perDisplayBookmarks
            bookmarks.removeValue(forKey: key)
            settings.perDisplayBookmarks = bookmarks
        }

        errorMessage = lastError?.errorDescription ?? "Unable to apply wallpaper for display \(displayID)."
        statusMessage = nil
    }

    private func resolvedSourceURL(from source: String, collectionName: String? = nil) -> URL? {
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Attempt bookmark restoration if collection name is provided
        if let collectionName = collectionName {
            logger.debug("Resolving collection source: collection=\(collectionName), source=\(trimmed)")
            if let collectionBookmarks = settings.collectionBookmarks[collectionName] {
                logger.debug("  Available bookmarks in collection: \(collectionBookmarks.keys.joined(separator: ", "))")
                if let bookmarkData = collectionBookmarks[trimmed] {
                    logger.debug("  Found bookmark for source, attempting restoration...")
                    var isStale = false
                    do {
                        let resolvedURL = try URL(
                            resolvingBookmarkData: bookmarkData,
                            options: [.withSecurityScope],
                            relativeTo: nil,
                            bookmarkDataIsStale: &isStale
                        )
                        logger.debug("  Successfully restored bookmark: \(resolvedURL.path), stale=\(isStale)")

                        if isStale {
                            do {
                                let refreshedBookmark = try resolvedURL.bookmarkData(
                                    options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                                    includingResourceValuesForKeys: nil,
                                    relativeTo: nil
                                )
                                var updatedBookmarks = collectionBookmarks
                                updatedBookmarks[trimmed] = refreshedBookmark
                                settings.collectionBookmarks[collectionName] = updatedBookmarks
                                logger.debug("  Refreshed stale bookmark")
                            } catch {
                                logger.warning("Failed to refresh stale collection bookmark for \(collectionName): \(error.localizedDescription)")
                            }
                        }

                        return resolvedURL
                    } catch {
                        logger.warning("Failed to restore collection bookmark for \(collectionName): \(error.localizedDescription)")
                        // Fall through to URL parsing below
                    }
                } else {
                    let availableKeys = collectionBookmarks.keys.joined(separator: ", ")
                    logger.warning("No bookmark found for source in collection \(collectionName). Available keys: \(availableKeys), looking for: \(trimmed)")
                }
            } else {
                let availableCollections = settings.collectionBookmarks.keys.joined(separator: ", ")
                logger.warning("No bookmarks stored for collection: \(collectionName). Available collections: \(availableCollections)")
            }
        }

        // Fallback: parse URL string (UNSAFE - no security scope)
        logger.debug("Using fallback URL parsing (no bookmark - file access may fail): \(trimmed)")
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

        await loadSavedCollections()

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
        print("AppViewModel.selectVideo: called with \(url.path)")
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
    
    // MARK: - Phase 6A Collection Methods
    
    /// Load saved collections from settings on init/start
    func loadSavedCollections() async {
        refreshCollectionState()
    }

    func bookmarksForCollection(name: String) -> [String: Data] {
        settings.collectionBookmarks[name] ?? [:]
    }
    
    /// Select a collection for preview or apply
    func selectCollection(name: String) {
        selectedCollectionName = name
    }
    
    func createCollection(
        name: String,
        description: String,
        collectionType: WallpaperCollection.CollectionType,
        sources: [CollectionSource],
        bookmarks: [String: Data] = [:]
    ) async -> Result<WallpaperCollection, WallpaperError> {
        if settings.savedCollections[name] != nil {
            let error = WallpaperError.invalidCollectionName(reason: "Collection '\(name)' already exists.")
            errorMessage = error.errorDescription
            statusMessage = nil
            return .failure(error)
        }

        let result = settings.saveCollection(
            name: name,
            description: description,
            collectionType: collectionType,
            sources: sources
        )

        switch result {
        case .success(let collection):
            // Store bookmarks for this collection if provided
            logger.debug("createCollection: collection=\(collection.name), bookmarks passed: \(!bookmarks.isEmpty), count: \(bookmarks.count)")
            if !bookmarks.isEmpty {
                settings.collectionBookmarks[collection.name] = bookmarks
                logger.debug("  Stored \(bookmarks.count) bookmarks for collection")
            } else {
                logger.warning("  No bookmarks provided for collection (first apply may fail on reload)")
            }
            refreshCollectionState()
            selectedCollectionName = collection.name
            statusMessage = "Collection '\(collection.name)' saved."
            errorMessage = nil
            return .success(collection)
        case .failure(let error):
            errorMessage = error.errorDescription
            statusMessage = nil
            return .failure(error)
        }
    }

    func updateCollection(
        existingName: String,
        newName: String,
        description: String,
        collectionType: WallpaperCollection.CollectionType,
        sources: [CollectionSource],
        bookmarks: [String: Data] = [:]
    ) async -> Result<WallpaperCollection, WallpaperError> {
        let result = settings.updateCollection(
            name: existingName,
            newName: newName,
            description: description,
            collectionType: collectionType,
            sources: sources
        )

        switch result {
        case .success(let collection):
            // Handle bookmarks: if collection was renamed, move bookmarks to new name
            if existingName != newName, !bookmarks.isEmpty {
                settings.collectionBookmarks.removeValue(forKey: existingName)
                settings.collectionBookmarks[collection.name] = bookmarks
            } else if !bookmarks.isEmpty {
                settings.collectionBookmarks[collection.name] = bookmarks
            }
            
            refreshCollectionState()
            selectedCollectionName = collection.name
            statusMessage = "Collection '\(collection.name)' updated."
            errorMessage = nil
            return .success(collection)
        case .failure(let error):
            errorMessage = error.errorDescription
            statusMessage = nil
            return .failure(error)
        }
    }
    
    /// Load selected collection for preview
    func loadSelectedCollection() async -> Result<WallpaperCollection, WallpaperError> {
        guard let name = selectedCollectionName else { return .failure(.collectionNotFound(name: "")) }
        return settings.loadCollection(name: name)
    }
    
    /// Delete selected collection
    func deleteCollection(name: String) async -> Result<Void, WallpaperError> {
        let result = settings.deleteCollection(name: name)

        switch result {
        case .success:
            // Clean up bookmarks for deleted collection
            settings.collectionBookmarks.removeValue(forKey: name)
            
            refreshCollectionState()
            if selectedCollectionName == name {
                selectedCollectionName = settings.allCollectionNames().first
            }
            statusMessage = "Collection '\(name)' deleted."
            errorMessage = nil
            return .success(())
        case .failure(let error):
            errorMessage = error.errorDescription
            statusMessage = nil
            return .failure(error)
        }
    }
    
    // MARK: - Phase 6A Collection Apply
    
    @MainActor
    func applyCollection(
        name: String,
        useUnified: Bool = false
    ) async -> Result<Void, WallpaperError> {
        _ = useUnified // Kept for API compatibility; apply behavior is now collection-driven.
        let loadedCollection = settings.loadCollection(name: name)
        guard case .success(let collection) = loadedCollection else {
            let error = WallpaperError.collectionNotFound(name: name)
            errorMessage = error.errorDescription
            statusMessage = nil
            return .failure(error)
        }

        selectedCollectionName = name
        
        switch collection.collectionType {
        case .simple:
            return await applySimpleCollection(collection)
        case .displayBound:
            return await applyDisplayBoundCollection(collection)
        }
    }
    
    @MainActor
    private func applySimpleCollection(_ collection: WallpaperCollection) async -> Result<Void, WallpaperError> {
        guard let firstSource = collection.sources.first else {
            settings.lastUsedCollectionName = collection.name
            refreshCollectionState()
            statusMessage = "Collection '\(collection.name)' has no sources to apply."
            errorMessage = nil
            return .success(())
        }

        // A single-source simple collection always applies globally to all displays,
        // independent of the current UI mode toggle.
        if collection.sources.count == 1 {
            guard let firstURL = resolvedSourceURL(from: firstSource.url, collectionName: collection.name) else {
                let error = WallpaperError.invalidCollectionSource(url: firstSource.url, reason: "Invalid source URL.")
                errorMessage = error.errorDescription
                statusMessage = nil
                return .failure(error)
            }

            let result = await wallpaperManager.setWallpaper(url: firstURL)
            switch result {
            case .success:
                settings.lastUsedCollectionName = collection.name
                refreshCollectionState()
                statusMessage = "Collection '\(collection.name)' applied to all displays."
                errorMessage = nil
                return .success(())
            case .failure(let error):
                errorMessage = error.errorDescription
                statusMessage = nil
                return .failure(error)
            }
        }

        // Multi-source simple collections map in current screen order for consistency with UI.
        let displayIDs = orderedConnectedDisplayIDs()
        guard !displayIDs.isEmpty else {
            let error = WallpaperError.internalError(description: "No displays are currently available.")
            errorMessage = error.errorDescription
            statusMessage = nil
            return .failure(error)
        }

        var appliedCount = 0
        for (index, source) in collection.sources.enumerated() {
            guard index < displayIDs.count else { break }
            guard let sourceURL = resolvedSourceURL(from: source.url, collectionName: collection.name) else { continue }

            let mode: WallpaperRendererMode = sourceURL.isFileURL ? .video : .web
            let result = await wallpaperManager.setPerDisplayWallpaper(
                displayID: displayIDs[index],
                url: sourceURL,
                rendererMode: mode,
                scalingMode: settings.scalingMode
            )

            if case .success = result {
                appliedCount += 1
            }
        }

        settings.lastUsedCollectionName = collection.name
        refreshCollectionState()
        let overflowCount = max(collection.sources.count - displayIDs.count, 0)
        if overflowCount > 0 {
            statusMessage = "Applied \(appliedCount) source(s). \(overflowCount) extra source(s) were skipped because fewer displays are available."
        } else {
            statusMessage = "Collection '\(collection.name)' applied to \(appliedCount) display(s)."
        }
        errorMessage = nil
        return .success(())
    }

    private func orderedConnectedDisplayIDs() -> [CGDirectDisplayID] {
        // Use NSScreen order so collection mapping matches the per-display UI ordering.
        let controllerIDs = Set(wallpaperManager.displayControllers.keys)
        let inScreenOrder = NSScreen.screens
            .map { $0.displayID }
            .filter { controllerIDs.contains($0) }

        if !inScreenOrder.isEmpty {
            return inScreenOrder
        }

        // Fallback if screens are temporarily unavailable.
        return wallpaperManager.displayControllers.keys.sorted()
    }
    
    @MainActor
    private func applyDisplayBoundCollection(_ collection: WallpaperCollection) async -> Result<Void, WallpaperError> {
        var unmatchedWarnings: [String] = []
        
        for source in collection.sources {
            let matchedDisplayID = resolveDisplayForSource(source: source)
            
            if let displayID = matchedDisplayID {
                if let url = resolvedSourceURL(from: source.url, collectionName: collection.name) {
                    let rendererMode: WallpaperRendererMode = url.isFileURL ? .video : .web
                    _ = await wallpaperManager.setPerDisplayWallpaper(
                        displayID: displayID,
                        url: url,
                        rendererMode: rendererMode,
                        scalingMode: source.scalingMode.flatMap { VideoScalingMode(rawValue: $0) } ?? settings.scalingMode
                    )
                }
            } else {
                let displayInfo = source.displayLabel ?? source.displayIDFallback.map { String($0) } ?? "?"
                let message = "Display \(displayInfo) not found"
                unmatchedWarnings.append(message)
                logger.warning("Display-bound collection skip: \(message)")
            }
        }

        settings.lastUsedCollectionName = collection.name
        refreshCollectionState()

        if unmatchedWarnings.isEmpty {
            statusMessage = "Collection '\(collection.name)' applied to matched displays."
            errorMessage = nil
            return .success(())
        }

        let warningText = unmatchedWarnings.joined(separator: ", ")
        statusMessage = "Applied to matched displays. Warnings:\n\(warningText)"
        errorMessage = nil
        return .success(())
    }
    
    private func resolveDisplayForSource(source: CollectionSource) -> CGDirectDisplayID? {
        // First attempt: ID match
        if let displayIDFallback = source.displayIDFallback,
           let controller = wallpaperManager.displayControllers.values.first(where: { $0.displayID == displayIDFallback }) {
            return controller.displayID
        }
        
        // Fallback: label match (case-insensitive partial or exact)
        if let label = source.displayLabel {
            for controller in wallpaperManager.displayControllers.values {
                let screenName = controller.displayName ?? ""
                // Exact match first
                if screenName == label {
                    return controller.displayID
                }
                // Fuzzy match: label appears anywhere in screen name
                if screenName.contains(label) || label.contains(screenName) {
                    logger.debug("Display-bound label fallback: '\(label)' matched '\(screenName)'")
                    return controller.displayID
                }
            }
        }
        
        // Auto-detect: both label and ID are nil, so apply to primary (first available) display
        if source.displayLabel == nil && source.displayIDFallback == nil {
            let displayIDs = orderedConnectedDisplayIDs()
            if let primaryDisplayID = displayIDs.first {
                logger.debug("Display-bound auto-detect: applying to primary display \(primaryDisplayID)")
                return primaryDisplayID
            }
        }
        
        return nil
    }

    private func refreshCollectionState() {
        savedCollections = settings.savedCollections
        lastUsedCollectionName = settings.lastUsedCollectionName

        // Prefer last used collection if nothing is selected
        if selectedCollectionName == nil {
            if let last = lastUsedCollectionName, savedCollections[last] != nil {
                selectedCollectionName = last
            } else {
                selectedCollectionName = settings.allCollectionNames().first
            }
            return
        }

        // If a selected collection no longer exists, fallback to first available
        if let selectedName = selectedCollectionName,
           savedCollections[selectedName] == nil {
            selectedCollectionName = settings.allCollectionNames().first
        }
    }
}

// MARK: - System Health Status (Chunk 4E)

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
