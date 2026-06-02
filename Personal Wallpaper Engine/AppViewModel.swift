import AppKit
import AVFoundation
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
    /// Mirrors engine pause flags; used for apply-path gating. Prefer shouldShowPausedChrome for UI overlays.
    @Published private(set) var isGloballyPaused: Bool = false
    /// Paused banner, carousel scrim, hero overlay — may differ from isPlaying when policy chrome applies.
    @Published private(set) var shouldShowPausedChrome: Bool = false
    @Published private(set) var isPlaybackCommandInFlight: Bool = false
    /// True briefly after a user pause so the play button cannot immediately undo it.
    @Published private(set) var isInPostPauseGrace: Bool = false
    private var playbackCommandInFlight: Bool = false
    private var playbackCommandTask: Task<Void, Never>?
    private var postPauseGraceTask: Task<Void, Never>?
    private var userResumeBlockedUntil: Date?
    private static let postPauseGraceInterval: TimeInterval = 2.5
    @Published var isLaunchOnLoginEnabled: Bool = false  // Phase 5G
    @Published var launchOnLoginStatusMessage: String?
    @Published var launchOnLoginErrorMessage: String?
    // MARK: - Phase 7A Power Policy
    @Published var pauseOnBattery: Bool = false
    @Published var pauseOnLowBattery: Bool = true
    @Published var lowBatteryThreshold: Int = 20
    @Published var powerPolicyStatusMessage: String?
    // MARK: - Phase 7B Performance
    @Published var performanceProfile: PerformanceProfile = .balanced
    // MARK: - Phase 7C Diagnostics
    @Published private(set) var estimatedCPUPercent: Double = 0
    @Published private(set) var currentCPUPercent: Double = 0
    @Published private(set) var instantCPUPercent: Double = 0
    @Published private(set) var isCPUMeasurementReady = false
    @Published var performanceSuggestion: PerformanceSuggestion?
    @Published private(set) var engineDiagnostics: WallpaperManager.EngineDiagnosticsSnapshot = .init(
        lifecycleState: .idle,
        isPlaybackActive: false,
        performanceProfile: .balanced,
        sharedSessionAttachments: 0,
        decodePathCount: 0,
        heroSharesDesktopDecode: false,
        coalesceTip: nil,
        displayRows: [],
        powerPolicyMessage: nil,
        anyDisplayVisible: false
    )
    private let performanceMonitor = PerformanceMonitor()
    private var recentCPUSamples: [Double] = []
    private var lastDiagnosticsRefreshAt: Date?
    private var isDiagnosticsPanelVisible = false
    private var diagnosticsRefreshScheduled = false
    private var lastSuggestedProfile: PerformanceProfile?
    private var performanceSuggestionSnoozedUntil: Date?
    private static let performanceSuggestionSnoozeSeconds: TimeInterval = 3600
    /// Always true — app uses per-display sources; "apply to all" duplicates the same file per screen.
    @Published private(set) var usePerDisplay: Bool = true
    @Published var focusedDisplayID: CGDirectDisplayID?

    // MARK: - Phase 6A Collection State
    @Published var savedCollections: [String: WallpaperCollection] = [:]
    @Published var lastUsedCollectionName: String?
    @Published var selectedCollectionName: String?
    
    // MARK: - Phase 6B Setup State
    @Published var savedSetups: [String: SavedSetup] = [:]
    @Published var selectedSetupName: String?
    
    // MARK: - Phase 8 Local Library
    @Published var libraryRoots: [LibraryRoot] = []
    @Published var libraryItems: [LibraryItem] = []
    @Published var selectedLibraryItemID: String?
    @Published var librarySearchText: String = ""
    @Published var libraryFavoritesOnly: Bool = false
    @Published var libraryRootFilterID: String?
    @Published private(set) var isLibraryScanning = false
    @Published var libraryLastScanDate: Date?
    /// Temporary hero preview URL when browsing the library before apply.
    @Published var transientPreviewURL: URL?
    
    // MARK: - Phase 7 Unified Display State
    @Published var displayWallpaperState: [CGDirectDisplayID: DisplayWallpaperInfo] = [:]
    /// Bumped when per-display sources/bookmarks change so Home previews refresh.
    @Published private(set) var displaySourcesVersion = 0
    
    // MARK: - System Health Tracking (Chunk 4E)
    @Published var systemHealthStatus: SystemHealthStatus = .healthy
    @Published var failureCount: Int = 0

    private let wallpaperManager: WallpaperManager
    private let settings: SettingsStore
    private let localLibraryManager = LocalLibraryManager.shared
    private let loginItemManager = LoginItemManager()  // Phase 5G
    private let logger = Logger(subsystem: "com.local.wallpaper", category: "AppViewModel")
    private var hasStarted = false
    private var selectedVideoURL: URL?
    private var activeSecurityScopedVideoURL: URL?
    private var lastVideoRestoreFailure: String?
    private var lastDisplaySignatures: [CGDirectDisplayID: DisplayConfigurationMigrator.DisplaySignature] = [:]
    /// Maps physical display (name + resolution) to the last `perDisplaySources` UserDefaults key — survives disconnect.
    private var settingsKeyBySignature: [DisplayConfigurationMigrator.DisplaySignature: String] = [:]
    private var screenConfigurationTask: Task<Void, Never>?
    private let screenConfigurationDebounceNs: UInt64 = 150_000_000
    private let heroPreviewVisibility = AppPreviewVisibilityMonitor()
    /// Bumped when app/window visibility changes so hero pause state refreshes in SwiftUI (Home tab only).
    @Published private(set) var heroPreviewVisibilityRevision = 0
    private(set) var isMainShellOnHomeTab = true

    init() {
        self.wallpaperManager = WallpaperManager()
        self.settings = SettingsStore.shared
        self.selectedVideoPath = settings.videoFilePath
        self.rendererMode = settings.rendererMode
        self.webURLString = settings.webURLString
        self.isMuted = settings.isMuted
        self.scalingMode = settings.scalingMode
        self.isLaunchOnLoginEnabled = settings.launchOnLoginEnabled
        self.pauseOnBattery = settings.pauseOnBattery
        self.pauseOnLowBattery = settings.pauseOnLowBattery
        self.lowBatteryThreshold = settings.lowBatteryThreshold
        self.performanceProfile = settings.performanceProfile
        ensurePerDisplayMode()
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
        self.pauseOnBattery = settings.pauseOnBattery
        self.pauseOnLowBattery = settings.pauseOnLowBattery
        self.lowBatteryThreshold = settings.lowBatteryThreshold
        self.performanceProfile = settings.performanceProfile
        ensurePerDisplayMode()
    }

    /// Per-display is the only mode; migrates legacy unified preference on load.
    func ensurePerDisplayMode() {
        usePerDisplay = true
        settings.usePerDisplay = true
        syncFocusedDisplayIfNeeded()
    }

    @available(*, deprecated, message: "Per-display is always enabled.")
    func toggleUsePerDisplay(_ enabled: Bool) {
        ensurePerDisplayMode()
    }

    func syncFocusedDisplayIfNeeded() {
        guard !NSScreen.screens.isEmpty else {
            focusedDisplayID = nil
            return
        }
        if let focusedDisplayID,
           NSScreen.screens.contains(where: { $0.displayID == focusedDisplayID }) {
            return
        }
        focusedDisplayID = NSScreen.screens.first?.displayID
    }

    /// Applies the focused display's stored source (Home toolbar / sidebar).
    func applyWallpaperToFocusedDisplay() async {
        syncFocusedDisplayIfNeeded()
        guard let displayID = focusedDisplayID ?? NSScreen.screens.first?.displayID else {
            errorMessage = "No display available."
            statusMessage = nil
            return
        }
        let source = perDisplaySource(for: displayID).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty else {
            errorMessage = "Choose a wallpaper for this display first."
            statusMessage = nil
            return
        }
        await applyPerDisplayWallpaper(displayID: displayID, sourceString: source)
    }

    // MARK: - Per-display helpers (Phase 5E)
    func perDisplaySource(for displayID: CGDirectDisplayID) -> String {
        return settings.perDisplaySources[String(displayID)] ?? ""
    }

    func updatePerDisplaySource(_ displayID: CGDirectDisplayID, _ urlString: String) {
        settings.perDisplaySources[String(displayID)] = urlString
    }

    func selectPerDisplaySource(_ displayID: CGDirectDisplayID, at url: URL) {
        if settings.debugDiagnosticsEnabled {
            logger.debug("selectPerDisplaySource display=\(displayID) url=\(url.absoluteString)")
        }
        let key = String(displayID)
        settings.perDisplaySources[key] = url.absoluteString
        recordPerDisplaySettingsKey(for: displayID)

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

        statusMessage = "Selected for \(displayStatusLabel(for: displayID)): \(url.lastPathComponent)"
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

        let collectionName = selectedCollectionName ?? lastUsedCollectionName
        guard let source = settings.perDisplaySources[String(displayID)] else {
            return nil
        }
        if let collectionName,
           let url = resolvedSourceURL(from: source, collectionName: collectionName) {
            return url
        }
        return resolvedSourceURL(from: source)
    }

    private var activeCollectionNameForResolution: String? {
        selectedCollectionName ?? lastUsedCollectionName
    }

    /// Canonical URL resolution for playback and previews (bookmarks, collection keys, paths).
    func resolvePlaybackURL(
        for displayID: CGDirectDisplayID,
        explicitSource: String? = nil,
        collectionName: String? = nil
    ) -> URL? {
        let collection = collectionName ?? activeCollectionNameForResolution

        if let bookmarkURL = perDisplayResolvedURL(for: displayID) {
            return bookmarkURL
        }

        let source = (explicitSource ?? perDisplaySource(for: displayID))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty else { return nil }

        if let collection,
           let url = resolvedSourceURL(from: source, collectionName: collection) {
            return url
        }
        return resolvedSourceURL(from: source)
    }

    func perDisplayRendererMode(for displayID: CGDirectDisplayID) -> WallpaperRendererMode {
        if let raw = settings.perDisplayRendererModes[String(displayID)],
           let mode = WallpaperRendererMode(rawValue: raw) {
            return mode
        }
        return rendererMode
    }

    func hasPersistedPerDisplayConfiguration() -> Bool {
        let connectedKeys = Set(NSScreen.screens.map { String($0.displayID) })
        if settings.perDisplayBookmarks.keys.contains(where: { connectedKeys.contains($0) }) {
            return true
        }
        return settings.perDisplaySources.contains { key, value in
            connectedKeys.contains(key) && !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    /// Notifies SwiftUI that per-display source data changed (Home carousel + hero).
    func notifyDisplaySourcesChanged() {
        displaySourcesVersion += 1
    }

    /// Resolved preview URL for a display (bookmarks, collection paths, then path fallback).
    func previewURL(forDisplayID displayID: CGDirectDisplayID) -> URL? {
        resolvePlaybackURL(for: displayID)
    }

    /// Resolved URL for hero preview — uses transient library preview, then bookmark/path resolution.
    func heroPreviewURL(forDisplayID displayID: CGDirectDisplayID?) -> URL? {
        if let transientPreviewURL {
            return transientPreviewURL
        }
        let targetID = displayID ?? focusedDisplayID ?? NSScreen.screens.first?.displayID
        guard let targetID else { return nil }
        return previewURL(forDisplayID: targetID)
    }

    /// Shell-level hero background — applied wallpaper on the display only (no library transient preview).
    func shellHeroPreviewURL(forDisplayID displayID: CGDirectDisplayID?) -> URL? {
        let targetID = displayID ?? focusedDisplayID ?? NSScreen.screens.first?.displayID
        guard let targetID else { return nil }
        return resolvePlaybackURL(for: targetID)
    }

    /// P1b / 7E: Pause live hero when unfocused or occluded. Max Quality keeps hero on all tabs when allowed.
    func shouldPauseHeroPreview(isOnHomeTab: Bool) -> Bool {
        if !isOnHomeTab {
            if performanceProfile == .maxQuality {
                if heroPreviewVisibility.isAppHidden { return true }
                if performanceProfile.pausesWhenOccluded, heroPreviewVisibility.isMainWindowOccluded {
                    return true
                }
                return false
            }
            return true
        }

        if heroPreviewVisibility.isAppHidden {
            return true
        }

        // Max Quality: ignore brief isAppActive flicker from embedded controls (7C.2).
        if performanceProfile != .maxQuality, !heroPreviewVisibility.isAppActive {
            return true
        }

        if performanceProfile.pausesWhenOccluded, heroPreviewVisibility.isMainWindowOccluded {
            return true
        }

        return false
    }

    /// Phase 7D: Hero can attach to desktop AVPlayer when previewing the same file (no second decode).
    func heroPreviewCanShareDesktopDecode(for url: URL?) -> Bool {
        guard let url else { return false }
        return wallpaperManager.canUnifyHeroPreview(with: url, focusedDisplayID: focusedDisplayID)
    }

    /// Still frame at desktop decode position for unified hero pause (not t=0 poster).
    func captureHeroPauseSnapshot(for url: URL) async -> NSImage? {
        let time = wallpaperManager.currentHeroPreviewPlaybackTime(
            for: url,
            focusedDisplayID: focusedDisplayID
        ) ?? .zero
        return await VideoWallpaperThumbnail.imageAsync(for: url, at: time)
    }

    @discardableResult
    func attachHeroPreviewLayer(in containerView: NSView, url: URL) -> Bool {
        wallpaperManager.attachHeroPreviewLayer(
            in: containerView,
            url: url,
            focusedDisplayID: focusedDisplayID
        )
    }

    func updateHeroPreviewLayerFrame(in containerView: NSView) {
        wallpaperManager.updateHeroPreviewLayerFrame(in: containerView)
    }

    func detachHeroPreviewLayer() {
        wallpaperManager.detachHeroPreviewLayers()
    }

    func setHeroPreviewLayerHidden(_ hidden: Bool) {
        wallpaperManager.setHeroPreviewLayerHidden(hidden)
    }

    /// Tracks main shell tab so visibility churn on management tabs does not relayout the hero.
    func setMainShellOnHomeTab(_ onHome: Bool) {
        isMainShellOnHomeTab = onHome
    }

    func applyPerDisplayWallpaper(displayID: CGDirectDisplayID, sourceString: String) async {
        let trimmed = sourceString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Please choose a wallpaper source for display \(displayID)."
            statusMessage = nil
            return
        }

        guard let primaryURL = resolvePlaybackURL(for: displayID, explicitSource: trimmed) else {
            errorMessage = "Please choose a wallpaper source for display \(displayID)."
            statusMessage = nil
            return
        }

        let key = String(displayID)
        var candidateURLs: [URL] = [primaryURL]
        if let bookmarkURL = perDisplayResolvedURL(for: displayID),
           bookmarkURL.absoluteString != primaryURL.absoluteString {
            candidateURLs.append(bookmarkURL)
        }

        settings.perDisplaySources[key] = trimmed
        let sourceURL = primaryURL

        if sourceURL.isFileURL {
            persistPerDisplayBookmark(displayID: displayID, url: sourceURL)
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

            let playbackMode = perDisplayRendererMode(for: displayID)
            let didStartScope = url.isFileURL ? url.startAccessingSecurityScopedResource() : false
            defer {
                if didStartScope {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            switch await wallpaperManager.setPerDisplayWallpaper(
                displayID: displayID,
                url: url,
                rendererMode: playbackMode,
                scalingMode: scaling
            ) {
            case .success:
                recordPerDisplaySettingsKey(for: displayID)
                if url.isFileURL {
                    persistPerDisplayBookmark(displayID: displayID, url: url)
                }
                statusMessage = "Applied to \(displayStatusLabel(for: displayID)): \(url.lastPathComponent)"
                errorMessage = nil
                notifyDisplaySourcesChanged()
                syncPlaybackStateFromEngine()
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

    /// Unified method for selecting a video for one or more displays.
    /// If all connected displays are selected, applies as unified wallpaper.
    /// If subset selected, applies per-display to each selected display.
    func selectVideoForDisplays(url: URL, displayIDs: [CGDirectDisplayID]) async {
        guard !displayIDs.isEmpty else {
            errorMessage = "No displays selected."
            statusMessage = nil
            return
        }

        for displayID in displayIDs {
            selectPerDisplaySource(displayID, at: url)
            await applyPerDisplayWallpaper(displayID: displayID, sourceString: url.absoluteString)
        }

        await wallpaperManager.coalesceSharedVideoPlaybackIfNeeded(for: url.standardizedFileURL)

        focusedDisplayID = displayIDs.first
        let displayCount = displayIDs.count
        statusMessage = "Applied to \(displayCount) display\(displayCount == 1 ? "" : "s")"
        errorMessage = nil
        notifyDisplaySourcesChanged()
    }

    /// Normalized filesystem path or trimmed string for stable collection bookmark keys.
    private func canonicalSourceKey(for source: String) -> String {
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }
        if trimmed.hasPrefix("/") {
            return URL(fileURLWithPath: trimmed).standardizedFileURL.path
        }
        if let url = URL(string: trimmed), url.isFileURL {
            return url.standardizedFileURL.path
        }
        if let url = URL(string: trimmed), url.scheme == nil, url.path.hasPrefix("/") {
            return URL(fileURLWithPath: url.path).standardizedFileURL.path
        }
        return trimmed
    }

    private func sourceFilename(for source: String) -> String? {
        let key = canonicalSourceKey(for: source)
        if key.hasPrefix("/") {
            let name = URL(fileURLWithPath: key).lastPathComponent
            return name.isEmpty ? nil : name
        }
        if let url = URL(string: source.trimmingCharacters(in: .whitespacesAndNewlines)), !url.lastPathComponent.isEmpty {
            return url.lastPathComponent
        }
        return nil
    }

    /// Looks up collection bookmark data by exact key, canonical path, or matching filename.
    private func lookupCollectionBookmark(
        in bookmarks: [String: Data],
        for source: String
    ) -> (matchedKey: String, data: Data)? {
        if let data = bookmarks[source] {
            return (source, data)
        }
        let canonical = canonicalSourceKey(for: source)
        if canonical != source, let data = bookmarks[canonical] {
            return (canonical, data)
        }
        for (key, data) in bookmarks where canonicalSourceKey(for: key) == canonical {
            return (key, data)
        }
        guard let filename = sourceFilename(for: source), !filename.isEmpty else { return nil }
        for (key, data) in bookmarks where sourceFilename(for: key) == filename {
            return (key, data)
        }
        return nil
    }

    /// Copies bookmark from an old collection key to the current per-display source string.
    private func healCollectionBookmarkKey(
        collectionName: String,
        source: String,
        matchedKey: String,
        bookmarkData: Data
    ) {
        guard matchedKey != source else { return }
        var bookmarks = settings.collectionBookmarks[collectionName] ?? [:]
        bookmarks[source] = bookmarkData
        settings.collectionBookmarks[collectionName] = bookmarks
        logger.info("Re-keyed collection '\(collectionName)' bookmark from '\(matchedKey)' to current source")
    }

    private func persistPerDisplayBookmark(displayID: CGDirectDisplayID, url: URL) {
        guard url.isFileURL else { return }
        let key = String(displayID)
        do {
            guard url.startAccessingSecurityScopedResource() else {
                logger.warning("Failed to access security-scoped resource for bookmarking display \(displayID)")
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            let bookmark = try url.bookmarkData(
                options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            settings.perDisplayBookmarks[key] = bookmark
            logger.debug("Saved per-display bookmark for display \(displayID)")
        } catch {
            logger.warning("Failed to save per-display bookmark for display \(displayID): \(error.localizedDescription)")
        }
    }

    private func resolvedSourceURL(from source: String, collectionName: String? = nil) -> URL? {
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Attempt bookmark restoration if collection name is provided
        if let collectionName = collectionName {
            logger.debug("Resolving collection source: collection=\(collectionName), source=\(trimmed)")
            if let collectionBookmarks = settings.collectionBookmarks[collectionName] {
                logger.debug("  Available bookmarks in collection: \(collectionBookmarks.keys.joined(separator: ", "))")
                if let match = lookupCollectionBookmark(in: collectionBookmarks, for: trimmed) {
                    logger.debug("  Found bookmark for source (key=\(match.matchedKey)), attempting restoration...")
                    var isStale = false
                    do {
                        let resolvedURL = try URL(
                            resolvingBookmarkData: match.data,
                            options: [.withSecurityScope],
                            relativeTo: nil,
                            bookmarkDataIsStale: &isStale
                        )
                        logger.debug("  Successfully restored bookmark: \(resolvedURL.path), stale=\(isStale)")

                        healCollectionBookmarkKey(
                            collectionName: collectionName,
                            source: trimmed,
                            matchedKey: match.matchedKey,
                            bookmarkData: match.data
                        )

                        if isStale {
                            do {
                                guard resolvedURL.startAccessingSecurityScopedResource() else {
                                    return resolvedURL
                                }
                                defer { resolvedURL.stopAccessingSecurityScopedResource() }
                                let refreshedBookmark = try resolvedURL.bookmarkData(
                                    options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                                    includingResourceValuesForKeys: nil,
                                    relativeTo: nil
                                )
                                var updatedBookmarks = settings.collectionBookmarks[collectionName] ?? [:]
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

        loadSavedCollections()
        refreshSetupState()
        loadLibraryFromSettings()

        await wallpaperManager.setMuted(isMuted)
        await wallpaperManager.setScalingMode(scalingMode)
        await wallpaperManager.setRendererMode(rendererMode)
        await wallpaperManager.setPerformanceProfile(performanceProfile)

        seedSettingsKeyBySignatureFromConnectedScreens()
        updateDisplaySignatureSnapshot()
        await wallpaperManager.startMonitoring()

        wallpaperManager.onScreenConfigurationChanged = { [weak self] in
            self?.handleDisplayConfigurationChanged()
        }

        wallpaperManager.onPowerPolicyChanged = { [weak self] in
            self?.syncPlaybackStateFromEngine()
        }

        await restorePersistedWallpapersOnLaunch()
        Task { @MainActor in
            notifyDisplaySourcesChanged()
            syncPlaybackStateFromEngine()
        }

        heroPreviewVisibility.onChange = { [weak self] in
            guard let self, self.isMainShellOnHomeTab else { return }
            Task { @MainActor in
                self.heroPreviewVisibilityRevision += 1
            }
        }
        heroPreviewVisibility.start()

        startPerformanceMonitoring()
        Task { @MainActor in
            refreshEngineDiagnostics()
        }
    }

    // MARK: - Phase 7C Performance Monitoring

    private func startPerformanceMonitoring() {
        performanceMonitor.onSample = { [weak self] metrics in
            self?.applyPerformanceSample(metrics)
        }
        performanceMonitor.start()
    }

    func setDiagnosticsPanelVisible(_ visible: Bool) {
        isDiagnosticsPanelVisible = visible
        if visible {
            scheduleEngineDiagnosticsRefresh()
        }
    }

    private func applyPerformanceSample(_ metrics: PerformanceCPUMetrics) {
        Task { @MainActor [weak self] in
            self?.applyPerformanceSampleDeferred(metrics)
        }
    }

    private func applyPerformanceSampleDeferred(_ metrics: PerformanceCPUMetrics) {
        isCPUMeasurementReady = metrics.isReady
        if metrics.isReady {
            instantCPUPercent = metrics.instantPercent
            currentCPUPercent = metrics.smoothedPercent
            estimatedCPUPercent = metrics.averagePercent
        }

        if metrics.isReady {
            recentCPUSamples.append(metrics.smoothedPercent)
            if recentCPUSamples.count > 60 {
                recentCPUSamples.removeFirst(recentCPUSamples.count - 60)
            }
            evaluatePerformanceSuggestion()
        }

        let shouldRefreshDiagnostics: Bool
        if isDiagnosticsPanelVisible {
            if let lastRefresh = lastDiagnosticsRefreshAt {
                shouldRefreshDiagnostics = Date().timeIntervalSince(lastRefresh) >= 1
            } else {
                shouldRefreshDiagnostics = true
            }
        } else if let lastRefresh = lastDiagnosticsRefreshAt {
            shouldRefreshDiagnostics = Date().timeIntervalSince(lastRefresh) >= 5
        } else {
            shouldRefreshDiagnostics = true
        }

        if shouldRefreshDiagnostics {
            scheduleEngineDiagnosticsRefresh()
        }
    }

    private func scheduleEngineDiagnosticsRefresh() {
        guard !diagnosticsRefreshScheduled else { return }
        diagnosticsRefreshScheduled = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.diagnosticsRefreshScheduled = false
            self.refreshEngineDiagnostics()
        }
    }

    private func refreshEngineDiagnostics() {
        engineDiagnostics = wallpaperManager.diagnosticsSnapshot()
        lastDiagnosticsRefreshAt = Date()
    }

    private func evaluatePerformanceSuggestion() {
        guard !settings.dismissPerformanceSuggestions else {
            performanceSuggestion = nil
            return
        }

        if let snoozedUntil = performanceSuggestionSnoozedUntil, Date() < snoozedUntil {
            performanceSuggestion = nil
            return
        }

        let policy = PerformanceSuggestionPolicy.thresholds(
            useTestMode: settings.useTestPerformanceSuggestionThresholds
        )

        let suggestedProfile: PerformanceProfile?
        let threshold: Double
        switch performanceProfile {
        case .maxQuality:
            threshold = policy.maxToBalanced
            suggestedProfile = .balanced
        case .balanced:
            guard PerformanceSuggestionPolicy.balancedSuggestionsEnabled else {
                performanceSuggestion = nil
                return
            }
            threshold = policy.balancedToBatterySaver
            suggestedProfile = .batterySaver
        case .batterySaver:
            performanceSuggestion = nil
            return
        }

        let window = Array(recentCPUSamples.suffix(policy.sustainedSampleWindow))
        guard window.count >= policy.sustainedSampleWindow else {
            performanceSuggestion = nil
            return
        }

        let aboveCount = window.filter { $0 > threshold }.count
        let required = Int(ceil(Double(policy.sustainedSampleWindow) * policy.sustainedFraction))
        guard aboveCount >= required else {
            performanceSuggestion = nil
            return
        }

        guard lastSuggestedProfile != suggestedProfile else { return }

        let message = "Wallpaper CPU has averaged \(String(format: "%.0f", estimatedCPUPercent))% recently. Switch to \(suggestedProfile!.displayName) to reduce usage."
        performanceSuggestion = PerformanceSuggestion(message: message, suggestedProfile: suggestedProfile!)
        lastSuggestedProfile = suggestedProfile
    }

    func applySuggestedPerformanceProfile() {
        guard let suggestion = performanceSuggestion else { return }
        updatePerformanceProfile(suggestion.suggestedProfile)
        performanceSuggestion = nil
        performanceSuggestionSnoozedUntil = nil
        lastSuggestedProfile = nil
    }

    func dismissPerformanceSuggestion(permanently: Bool = false) {
        performanceSuggestion = nil
        if permanently {
            settings.dismissPerformanceSuggestions = true
            performanceSuggestionSnoozedUntil = nil
            logger.info("Performance suggestions permanently dismissed")
        } else {
            performanceSuggestionSnoozedUntil = Date().addingTimeInterval(
                Self.performanceSuggestionSnoozeSeconds
            )
        }
    }

    var useTestPerformanceSuggestionThresholds: Bool {
        get { settings.useTestPerformanceSuggestionThresholds }
        set { settings.useTestPerformanceSuggestionThresholds = newValue }
    }

    func restartWallpaperEngine() async {
        isApplyingWallpaper = true
        defer { isApplyingWallpaper = false }

        let resumeAfter = await wallpaperManager.restartEngine()
        await reapplyPersistedPerDisplayWallpapers()
        if resumeAfter {
            await wallpaperManager.resume(reason: .reconciliation, userInitiated: false, source: .system)
        }
        syncPlaybackStateFromEngine()
        refreshEngineDiagnostics()
        statusMessage = "Wallpaper engine restarted."
        errorMessage = nil
    }

    func resetToSafeDefault() async {
        updatePerformanceProfile(.balanced)
        await pauseWallpaperPlayback(source: .system)
        performanceSuggestion = nil
        lastSuggestedProfile = nil
        performanceSuggestionSnoozedUntil = nil
        recentCPUSamples.removeAll()
        errorMessage = nil
        statusMessage = "Reset to safe default — Balanced profile, playback paused."
        refreshEngineDiagnostics()
    }

    /// Migrates per-display settings after hotplug and reapplies wallpapers to all connected displays.
    func handleDisplayConfigurationChanged() {
        screenConfigurationTask?.cancel()
        screenConfigurationTask = Task {
            do {
                try await Task.sleep(nanoseconds: screenConfigurationDebounceNs)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            await performDisplayConfigurationChange()
        }
    }

    private func performDisplayConfigurationChange() async {
        let focusedSignatureBefore = focusedDisplayID.flatMap { lastDisplaySignatures[$0] }
        let mapping = migrateDisplayConfigurationOnScreenChange()
        migrateFocusedDisplayAfterConfigurationChange(
            mapping: mapping,
            focusedSignatureBefore: focusedSignatureBefore
        )
        await reapplyPersistedPerDisplayWallpapers()
    }

    /// User-facing label for status messages (UI order + screen name, not raw `CGDirectDisplayID`).
    func displayStatusLabel(for displayID: CGDirectDisplayID) -> String {
        if let index = NSScreen.screens.firstIndex(where: { $0.displayID == displayID }),
           let screen = NSScreen.screens.first(where: { $0.displayID == displayID }) {
            return "Display \(index + 1) (\(screen.localizedName))"
        }
        return "display \(displayID)"
    }

    private func updateDisplaySignatureSnapshot() {
        lastDisplaySignatures = DisplayConfigurationMigrator.signatures(for: NSScreen.screens)
    }

    private func seedSettingsKeyBySignatureFromConnectedScreens() {
        for screen in NSScreen.screens {
            let displayID = screen.displayID
            let key = String(displayID)
            guard settings.perDisplaySources[key] != nil
                || settings.perDisplayBookmarks[key] != nil else { continue }
            recordPerDisplaySettingsKey(for: displayID)
        }
    }

    /// Records which settings key owns data for a physical display (used when IDs change after hotplug).
    private func recordPerDisplaySettingsKey(for displayID: CGDirectDisplayID) {
        guard let screen = NSScreen.screens.first(where: { $0.displayID == displayID }) else { return }
        let signature = DisplayConfigurationMigrator.DisplaySignature(screen: screen)
        settingsKeyBySignature[signature] = String(displayID)
    }

    /// Includes disconnected displays so unplugged monitor settings can remap on replug.
    private func augmentedPreviousSignatures(for screens: [NSScreen]) -> [CGDirectDisplayID: DisplayConfigurationMigrator.DisplaySignature] {
        var augmented = lastDisplaySignatures
        let currentIDs = Set(screens.map(\.displayID))

        for (signature, key) in settingsKeyBySignature {
            guard let oldID = UInt32(key) else { continue }
            let displayID = CGDirectDisplayID(oldID)
            if augmented[displayID] == nil {
                augmented[displayID] = signature
            }
        }

        for (displayID, signature) in lastDisplaySignatures where !currentIDs.contains(displayID) {
            if augmented[displayID] == nil {
                augmented[displayID] = signature
            }
        }

        return augmented
    }

    @discardableResult
    private func migrateDisplayConfigurationOnScreenChange() -> [String: String] {
        let screens = NSScreen.screens
        let previousSnapshots = augmentedPreviousSignatures(for: screens)
        let mapping = DisplayConfigurationMigrator.migrationMapping(
            previousSignatures: previousSnapshots,
            currentScreens: screens
        )
        if !mapping.isEmpty {
            DisplayConfigurationMigrator.rekeyPerDisplaySettings(in: settings, mapping: mapping)
            logger.info("Re-keyed per-display settings for \(mapping.count) display(s) after configuration change")
            notifyDisplaySourcesChanged()
            for (oldKey, newKey) in mapping {
                guard let oldID = UInt32(oldKey), UInt32(newKey) != nil,
                      let signature = previousSnapshots[CGDirectDisplayID(oldID)] else { continue }
                settingsKeyBySignature[signature] = newKey
            }
        }
        var nextSnapshots = DisplayConfigurationMigrator.signatures(for: screens)
        let representedSignatures = Set(nextSnapshots.values)
        for (displayID, signature) in previousSnapshots where !screens.map(\.displayID).contains(displayID) {
            if !representedSignatures.contains(signature) {
                nextSnapshots[displayID] = signature
            }
        }
        for oldKey in mapping.keys {
            if let id = UInt32(oldKey) {
                nextSnapshots.removeValue(forKey: CGDirectDisplayID(id))
            }
        }
        lastDisplaySignatures = nextSnapshots
        return mapping
    }

    /// Keeps the focused display on the same physical screen when IDs shuffle or are reused.
    private func migrateFocusedDisplayAfterConfigurationChange(
        mapping: [String: String],
        focusedSignatureBefore: DisplayConfigurationMigrator.DisplaySignature?
    ) {
        guard let focused = focusedDisplayID else {
            syncFocusedDisplayIfNeeded()
            return
        }

        if let newKey = mapping[String(focused)], let newID = UInt32(newKey) {
            focusedDisplayID = CGDirectDisplayID(newID)
            return
        }

        if let previousSignature = focusedSignatureBefore {
            for screen in NSScreen.screens {
                let signature = DisplayConfigurationMigrator.DisplaySignature(screen: screen)
                if signature == previousSignature {
                    focusedDisplayID = screen.displayID
                    return
                }
            }
        }

        syncFocusedDisplayIfNeeded()
    }

    private func restorePersistedWallpapersOnLaunch() async {
        if hasPersistedPerDisplayConfiguration() {
            await reapplyPersistedPerDisplayWallpapers()
            return
        }

        if rendererMode == .video, restoreSelectedVideoReference() != nil {
            await applyWallpaperFromSavedPath()
        } else if rendererMode == .video, !selectedVideoPath.isEmpty {
            let details = lastVideoRestoreFailure.map { " (\($0))" } ?? ""
            errorMessage = "Saved video access expired. Please reselect the video file.\(details)"
            statusMessage = nil
        } else if rendererMode == .web {
            statusMessage = "Web wallpaper mode is ready"
            errorMessage = nil
            if !webURLString.isEmpty {
                await applyWallpaperFromSavedWebURL()
            }
        }
    }

    /// Reapplies persisted per-display sources to every connected display (launch + hotplug).
    func reapplyPersistedPerDisplayWallpapers() async {
        let displayIDs = orderedConnectedDisplayIDs()
        guard !displayIDs.isEmpty else { return }

        if wallpaperManager.isGloballyPaused {
            logger.info("reapplyPersistedPerDisplayWallpapers while globally paused (autoPlay=false expected)")
        }

        isApplyingWallpaper = true
        defer { isApplyingWallpaper = false }

        var appliedCount = 0
        var errors: [String] = []

        var appliedFileURLs: [URL] = []
        for displayID in displayIDs {
            if await applyPlaybackToDisplay(displayID: displayID) {
                appliedCount += 1
                if let url = resolvePlaybackURL(for: displayID), url.isFileURL {
                    appliedFileURLs.append(url.standardizedFileURL)
                }
            } else if !perDisplaySource(for: displayID).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors.append("Display \(displayID)")
            }
        }

        for url in Dictionary(grouping: appliedFileURLs, by: \.path).values.compactMap(\.first) {
            await wallpaperManager.coalesceSharedVideoPlaybackIfNeeded(for: url)
        }

        await refreshDisplayState()
        notifyDisplaySourcesChanged()

        if appliedCount > 0 {
            await startDesktopPlaybackAfterLaunchIfAllowed()
        }

        syncPlaybackStateFromEngine()

        if appliedCount > 0 {
            statusMessage = "Wallpaper applied to \(appliedCount) display\(appliedCount == 1 ? "" : "s")."
            errorMessage = errors.isEmpty ? nil : "Could not apply to: \(errors.joined(separator: ", "))"
        } else if !errors.isEmpty {
            errorMessage = "Could not apply wallpaper to connected displays."
            statusMessage = nil
        }
    }

    @discardableResult
    private func applyPlaybackToDisplay(displayID: CGDirectDisplayID) async -> Bool {
        guard let url = resolvePlaybackURL(for: displayID) else { return false }

        let mode = perDisplayRendererMode(for: displayID)
        let scaling = perDisplayScalingMode(for: displayID)
        let didStartScope = url.isFileURL ? url.startAccessingSecurityScopedResource() : false
        defer {
            if didStartScope {
                url.stopAccessingSecurityScopedResource()
            }
        }

        switch await wallpaperManager.setPerDisplayWallpaper(
            displayID: displayID,
            url: url,
            rendererMode: mode,
            scalingMode: scaling
        ) {
        case .success:
            recordPerDisplaySettingsKey(for: displayID)
            if url.isFileURL {
                persistPerDisplayBookmark(displayID: displayID, url: url)
            }
            return true
        case .failure(let error):
            logger.warning("applyPlaybackToDisplay failed for \(displayID): \(error.errorDescription ?? "unknown")")
            return false
        }
    }

    func selectVideo(at url: URL) {
        if settings.debugDiagnosticsEnabled {
            logger.debug("selectVideo path=\(url.path)")
        }
        endAccessingSelectedVideoURL()
        _ = beginAccessingSelectedVideoURL(url)
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
            let trimmed = webURLString.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                statusMessage = "Web mode enabled. Enter a URL and tap Apply."
            } else {
                statusMessage = "Web mode enabled."
            }
            errorMessage = nil
        }
    }

    /// Applies the current Settings selection to every connected display (same file/URL per screen).
    func applyWallpaperFromSelection() async {
        let displayIDs = NSScreen.screens.map(\.displayID)
        guard !displayIDs.isEmpty else {
            errorMessage = "No displays connected."
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
            await selectVideoForDisplays(url: url, displayIDs: displayIDs)
            return
        }

        if rendererMode == .web {
            let trimmed = webURLString.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, URL(string: trimmed) != nil else {
                errorMessage = "Please enter a valid web URL."
                statusMessage = nil
                return
            }
            for displayID in displayIDs {
                updatePerDisplaySource(displayID, trimmed)
                await applyPerDisplayWallpaper(displayID: displayID, sourceString: trimmed)
            }
            statusMessage = "Applied web wallpaper to \(displayIDs.count) display\(displayIDs.count == 1 ? "" : "s")"
            errorMessage = nil
        }
    }

    private func applyWallpaperFromSavedWebURL() async {
        guard rendererMode == .web else { return }
        let trimmed = settings.webURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed) else { return }
        await applyWallpaper(url: url)
    }

    func stop() async {
        heroPreviewVisibility.stop()
        performanceMonitor.stop()
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
        await startDesktopPlaybackAfterLaunchIfAllowed()
        syncPlaybackStateFromEngine()
    }

    /// Starts desktop playback after cold launch when power policy allows.
    private func startDesktopPlaybackAfterLaunchIfAllowed() async {
        await wallpaperManager.reevaluatePowerPolicy()
        if wallpaperManager.isPowerPolicyRequiringPause() {
            logger.info("Launch auto-play skipped — power policy requires pause")
            return
        }
        guard !wallpaperManager.isPlaybackActive else { return }
        logger.info("Launch auto-play — starting desktop playback after restore")
        await wallpaperManager.resume(reason: .reconciliation, userInitiated: false, source: .system)
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

    /// Single entry point for toolbar/menu play-pause; serializes rapid presses and reads engine state inside the chain.
    func handlePlayPauseButtonPressed(source: WallpaperManager.PlaybackCommandSource = .toolbar) {
        let intent = wallpaperManager.isPlaybackActive ? "pause" : "resume"
        logger.info(
            "Play/Pause pressed intent=\(intent, privacy: .public) source=\(source.rawValue, privacy: .public) playbackActive=\(self.wallpaperManager.isPlaybackActive) uiPlaying=\(self.isPlaying) inFlight=\(self.playbackCommandInFlight)"
        )
        let previous = playbackCommandTask
        playbackCommandTask = Task { @MainActor [weak self] in
            await previous?.value
            guard let self else { return }
            if self.wallpaperManager.isPlaybackActive {
                await self.pauseWallpaperPlayback(source: source)
            } else {
                await self.resumeWallpaperPlayback(source: source)
            }
        }
    }

    func pauseWallpaperPlayback(source: WallpaperManager.PlaybackCommandSource = .toolbar) async {
        logger.info("pauseWallpaperPlayback started source=\(source.rawValue, privacy: .public) playbackActive=\(self.wallpaperManager.isPlaybackActive)")
        guard !playbackCommandInFlight else {
            logger.info("pauseWallpaperPlayback skipped — command already in flight")
            return
        }
        playbackCommandInFlight = true
        isPlaybackCommandInFlight = true
        defer {
            playbackCommandInFlight = false
            isPlaybackCommandInFlight = false
            syncPlaybackStateFromEngine()
            logger.info("pauseWallpaperPlayback finished playbackActive=\(self.wallpaperManager.isPlaybackActive) isPlaying=\(self.isPlaying) chromePaused=\(self.shouldShowPausedChrome) inFlight=false")
        }
        await wallpaperManager.pause(userInitiated: true, source: source)
        beginPostPauseGrace()
    }

    func resumeWallpaperPlayback(source: WallpaperManager.PlaybackCommandSource = .toolbar) async {
        logger.info("resumeWallpaperPlayback started source=\(source.rawValue, privacy: .public) playbackActive=\(self.wallpaperManager.isPlaybackActive)")
        if let blockedUntil = userResumeBlockedUntil, Date() < blockedUntil {
            let remainingMs = max(0, Int(blockedUntil.timeIntervalSince(Date()) * 1000))
            logger.info("Resume ignored — post-pause grace (remainingMs=\(max(0, remainingMs)) source=\(source.rawValue, privacy: .public))")
            syncPlaybackStateFromEngine()
            return
        }
        guard !playbackCommandInFlight else {
            logger.info("resumeWallpaperPlayback skipped — command already in flight")
            return
        }
        playbackCommandInFlight = true
        isPlaybackCommandInFlight = true
        defer {
            playbackCommandInFlight = false
            isPlaybackCommandInFlight = false
            syncPlaybackStateFromEngine()
            logger.info("resumeWallpaperPlayback finished playbackActive=\(self.wallpaperManager.isPlaybackActive) isPlaying=\(self.isPlaying) chromePaused=\(self.shouldShowPausedChrome) inFlight=false")
        }
        guard !wallpaperManager.isPlaybackActive else {
            logger.info("resumeWallpaperPlayback skipped — desktop playback already active")
            return
        }
        clearPostPauseGrace()
        await wallpaperManager.resume(reason: .user, userInitiated: true, source: source)
    }

    func togglePlayback() async {
        handlePlayPauseButtonPressed(source: .toggle)
        await playbackCommandTask?.value
    }

    private func beginPostPauseGrace() {
        userResumeBlockedUntil = Date().addingTimeInterval(Self.postPauseGraceInterval)
        isInPostPauseGrace = true
        postPauseGraceTask?.cancel()
        postPauseGraceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(Self.postPauseGraceInterval))
            guard let self, !Task.isCancelled else { return }
            if let blockedUntil = self.userResumeBlockedUntil, Date() >= blockedUntil {
                self.userResumeBlockedUntil = nil
                self.isInPostPauseGrace = false
            }
        }
    }

    private func clearPostPauseGrace() {
        postPauseGraceTask?.cancel()
        postPauseGraceTask = nil
        userResumeBlockedUntil = nil
        isInPostPauseGrace = false
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

    // MARK: - Phase 7A Power Policy

    func updatePauseOnBattery(_ enabled: Bool) {
        pauseOnBattery = enabled
        settings.pauseOnBattery = enabled
        Task { await applyPowerPolicySettings() }
    }

    func updatePauseOnLowBattery(_ enabled: Bool) {
        pauseOnLowBattery = enabled
        settings.pauseOnLowBattery = enabled
        Task { await applyPowerPolicySettings() }
    }

    func updateLowBatteryThreshold(_ value: Int) {
        let clamped = min(100, max(1, value))
        lowBatteryThreshold = clamped
        settings.lowBatteryThreshold = clamped
        Task { await applyPowerPolicySettings() }
    }

    private func applyPowerPolicySettings() async {
        await wallpaperManager.reevaluatePowerPolicy()
        syncPlaybackStateFromEngine()
    }

    // MARK: - Phase 7B Performance

    func updatePerformanceProfile(_ profile: PerformanceProfile) {
        settings.performanceProfile = profile
        Task { @MainActor in
            performanceProfile = profile
            await wallpaperManager.setPerformanceProfile(profile)
        }
    }

    func syncPowerPolicyStatus() {
        syncPlaybackStateFromEngine()
    }

    /// Keeps UI play/pause and pause banners aligned with engine state (transport vs chrome split).
    func syncPlaybackStateFromEngine() {
        let previousPlaying = isPlaying
        let previousChrome = shouldShowPausedChrome
        powerPolicyStatusMessage = wallpaperManager.powerPolicyStatusMessage
        isGloballyPaused = wallpaperManager.isGloballyPaused
        shouldShowPausedChrome = wallpaperManager.shouldShowPausedChrome
        isPlaying = wallpaperManager.isPlaybackActive
        if previousPlaying != isPlaying || previousChrome != shouldShowPausedChrome {
            logger.info(
                """
                Playback state snapshot: lifecycle=\(String(describing: self.wallpaperManager.lifecycleState)) \
                isPlaybackActive=\(self.wallpaperManager.isPlaybackActive) userPaused=\(self.wallpaperManager.isUserPausedForDiagnostics) \
                policyPaused=\(self.wallpaperManager.isPausedForPowerPolicyForDiagnostics) \
                policyOverride=\(self.wallpaperManager.userOverrodePowerPolicyPause) \
                isPlaying=\(self.isPlaying) chromePaused=\(self.shouldShowPausedChrome) \
                desktopRates=[\(self.wallpaperManager.desktopPlaybackSnapshot())]
                """
            )
        }
    }
    
    // MARK: - Phase 6A Collection Methods
    
    /// Load saved collections from settings on init/start
    func loadSavedCollections() {
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

        // Single-source: apply the same wallpaper to every connected display (per-display entries).
        if collection.sources.count == 1 {
            guard let firstURL = resolvedSourceURL(from: firstSource.url, collectionName: collection.name) else {
                let error = WallpaperError.invalidCollectionSource(url: firstSource.url, reason: "Invalid source URL.")
                errorMessage = error.errorDescription
                statusMessage = nil
                return .failure(error)
            }

            let displayIDs = orderedConnectedDisplayIDs()
            guard !displayIDs.isEmpty else {
                let error = WallpaperError.internalError(description: "No displays are currently available.")
                errorMessage = error.errorDescription
                statusMessage = nil
                return .failure(error)
            }

            seedPerDisplayBookmarksFromCollection(
                collectionName: collection.name,
                sourceKey: firstSource.url,
                displayIDs: displayIDs
            )

            await selectVideoForDisplays(url: firstURL, displayIDs: displayIDs)

            for displayID in displayIDs {
                settings.perDisplaySources[String(displayID)] = firstSource.url
            }

            settings.lastUsedCollectionName = collection.name

            if firstURL.isFileURL {
                selectedVideoPath = firstURL.path
                rendererMode = .video
                settings.videoFilePath = firstURL.path
                settings.rendererMode = .video
            } else {
                webURLString = firstURL.absoluteString
                rendererMode = .web
                settings.webURLString = firstURL.absoluteString
                settings.rendererMode = .web
            }

            refreshCollectionState()
            notifyDisplaySourcesChanged()
            await refreshDisplayState()
            statusMessage = "Collection '\(collection.name)' applied to all displays."
            errorMessage = nil
            return .success(())
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
            let displayID = displayIDs[index]
            guard let sourceURL = resolvedSourceURL(from: source.url, collectionName: collection.name) else { continue }

            syncPerDisplayFromCollection(
                displayID: displayID,
                collectionName: collection.name,
                source: source
            )

            let mode: WallpaperRendererMode = sourceURL.isFileURL ? .video : .web
            let scaling = source.scalingMode.flatMap { VideoScalingMode(rawValue: $0) } ?? settings.scalingMode
            let result = await wallpaperManager.setPerDisplayWallpaper(
                displayID: displayID,
                url: sourceURL,
                rendererMode: mode,
                scalingMode: scaling
            )

            if case .success = result {
                appliedCount += 1
            }
        }

        settings.lastUsedCollectionName = collection.name
        refreshCollectionState()
        notifyDisplaySourcesChanged()
        let overflowCount = max(collection.sources.count - displayIDs.count, 0)
        if overflowCount > 0 {
            statusMessage = "Applied \(appliedCount) source(s). \(overflowCount) extra source(s) were skipped because fewer displays are available."
        } else {
            statusMessage = "Collection '\(collection.name)' applied to \(appliedCount) display(s)."
        }
        errorMessage = nil
        
        // PHASE 7: Sync display state for unified preview
        await refreshDisplayState()
        
        return .success(())
    }

    private func seedPerDisplayBookmarksFromCollection(
        collectionName: String,
        sourceKey: String,
        displayIDs: [CGDirectDisplayID]
    ) {
        guard let collectionBookmarks = settings.collectionBookmarks[collectionName],
              let match = lookupCollectionBookmark(in: collectionBookmarks, for: sourceKey) else { return }
        var bookmarks = settings.perDisplayBookmarks
        for displayID in displayIDs {
            bookmarks[String(displayID)] = match.data
        }
        settings.perDisplayBookmarks = bookmarks
    }

    private func syncPerDisplayFromCollection(
        displayID: CGDirectDisplayID,
        collectionName: String,
        source: CollectionSource
    ) {
        let key = String(displayID)
        settings.perDisplaySources[key] = source.url

        if let collectionBookmarks = settings.collectionBookmarks[collectionName],
           let match = lookupCollectionBookmark(in: collectionBookmarks, for: source.url) {
            var bookmarks = settings.perDisplayBookmarks
            bookmarks[key] = match.data
            settings.perDisplayBookmarks = bookmarks
            healCollectionBookmarkKey(
                collectionName: collectionName,
                source: source.url,
                matchedKey: match.matchedKey,
                bookmarkData: match.data
            )
        } else if let url = resolvedSourceURL(from: source.url, collectionName: collectionName), url.isFileURL {
            selectPerDisplaySource(displayID, at: url)
            settings.perDisplaySources[key] = source.url
        } else {
            var bookmarks = settings.perDisplayBookmarks
            bookmarks.removeValue(forKey: key)
            settings.perDisplayBookmarks = bookmarks
        }

        if let scalingMode = source.scalingMode, let mode = VideoScalingMode(rawValue: scalingMode) {
            settings.perDisplayScalingModes[key] = mode.rawValue
        }
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
                    syncPerDisplayFromCollection(
                        displayID: displayID,
                        collectionName: collection.name,
                        source: source
                    )
                    let rendererMode: WallpaperRendererMode = url.isFileURL ? .video : .web
                    let scalingMode = source.scalingMode.flatMap { VideoScalingMode(rawValue: $0) } ?? settings.scalingMode
                    _ = await wallpaperManager.setPerDisplayWallpaper(
                        displayID: displayID,
                        url: url,
                        rendererMode: rendererMode,
                        scalingMode: scalingMode
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
        notifyDisplaySourcesChanged()

        if unmatchedWarnings.isEmpty {
            statusMessage = "Collection '\(collection.name)' applied to matched displays."
            errorMessage = nil
            
            // PHASE 7: Sync display state for unified preview
            await refreshDisplayState()
            
            return .success(())
        }

        let warningText = unmatchedWarnings.joined(separator: ", ")
        statusMessage = "Applied to matched displays. Warnings:\n\(warningText)"
        errorMessage = nil
        
        // PHASE 7: Sync display state for unified preview
        await refreshDisplayState()
        
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
    
    // MARK: - Phase 6B Setup Methods
    
    /// Load saved setups from settings
    func loadSavedSetups() async {
        refreshSetupState()
    }
    
    /// Refresh setup state from settings
    private func refreshSetupState() {
        savedSetups = settings.savedSetups
        selectedSetupName = settings.currentSetupName
    }
    
    /// Get current app state as a SavedSetup
    private func getCurrentSetupStateData() -> (
        rendererMode: String,
        isMuted: Bool,
        scalingMode: String,
        usePerDisplay: Bool,
        unifiedSource: String?,
        perDisplaySources: [String: String],
        perDisplayScalingModes: [String: String],
        unifiedBookmarkBase64: String?,
        perDisplayBookmarksBase64: [String: String]
    ) {
        let unifiedBookmarkBase64 = settings.videoBookmarkData.flatMap { $0.base64EncodedString() }
        
        // Collect per-display bookmarks
        var perDisplayBookmarksBase64: [String: String] = [:]
        for (displayIDStr, bookmark) in settings.perDisplayBookmarks {
            perDisplayBookmarksBase64[displayIDStr] = bookmark.base64EncodedString()
        }
        
        return (
            rendererMode: rendererMode.rawValue,
            isMuted: isMuted,
            scalingMode: scalingMode.rawValue,
            usePerDisplay: true,
            unifiedSource: selectedVideoPath.isEmpty ? nil : selectedVideoPath,
            perDisplaySources: settings.perDisplaySources,
            perDisplayScalingModes: settings.perDisplayScalingModes,
            unifiedBookmarkBase64: unifiedBookmarkBase64,
            perDisplayBookmarksBase64: perDisplayBookmarksBase64
        )
    }
    
    /// Save current wallpaper engine state as a new setup with validation
    func saveCurrentStateAsSetup(
        name: String,
        description: String = ""
    ) async -> Result<SavedSetup, WallpaperError> {
        // Validate setup name
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            let error = WallpaperError.internalError(description: "Setup name cannot be empty.")
            errorMessage = error.errorDescription
            statusMessage = nil
            return .failure(error)
        }
        
        if trimmedName.count > 100 {
            let error = WallpaperError.internalError(description: "Setup name must be less than 100 characters.")
            errorMessage = error.errorDescription
            statusMessage = nil
            return .failure(error)
        }
        
        // Check if setup already exists
        if settings.savedSetups[trimmedName] != nil {
            let error = WallpaperError.internalError(description: "Setup '\(trimmedName)' already exists.")
            errorMessage = error.errorDescription
            statusMessage = nil
            return .failure(error)
        }
        
        // Validate that we have at least one source
        let hasSource = !settings.perDisplaySources.values.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            || !selectedVideoPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        if !hasSource {
            let error = WallpaperError.internalError(description: "No wallpaper source selected. Please set a wallpaper before saving.")
            errorMessage = error.errorDescription
            statusMessage = nil
            return .failure(error)
        }
        
        let stateData = getCurrentSetupStateData()
        
        let result = settings.saveSetup(
            name: trimmedName,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            rendererMode: stateData.rendererMode,
            isMuted: stateData.isMuted,
            scalingMode: stateData.scalingMode,
            usePerDisplay: true,
            unifiedSource: stateData.unifiedSource,
            perDisplaySources: stateData.perDisplaySources,
            perDisplayScalingModes: stateData.perDisplayScalingModes,
            unifiedBookmarkBase64: stateData.unifiedBookmarkBase64,
            perDisplayBookmarksBase64: stateData.perDisplayBookmarksBase64
        )
        
        switch result {
        case .success(let setup):
            refreshSetupState()
            statusMessage = "Setup '\(setup.name)' saved successfully."
            errorMessage = nil
            logger.info("Setup '\(setup.name)' created with ID \(setup.id)")
            return .success(setup)
        case .failure(let error):
            errorMessage = error.errorDescription
            statusMessage = nil
            logger.error("Failed to save setup: \(error.errorDescription ?? "unknown")")
            return .failure(error)
        }
    }
    
    /// Restore a saved setup (applies full state) with enhanced error handling
    func restoreSetup(name: String) async -> Result<Void, WallpaperError> {
        let loadResult = settings.loadSetup(name: name)
        guard case .success(let setup) = loadResult else {
            let error = WallpaperError.internalError(description: "Setup '\(name)' not found.")
            errorMessage = error.errorDescription
            statusMessage = nil
            return .failure(error)
        }
        
        // Validate setup data integrity
        guard !setup.rendererMode.isEmpty, !setup.scalingMode.isEmpty else {
            let error = WallpaperError.internalError(description: "Setup '\(name)' has corrupted data. Please recreate it.")
            errorMessage = error.errorDescription
            statusMessage = nil
            return .failure(error)
        }
        
        // Apply setup state
        rendererMode = WallpaperRendererMode(rawValue: setup.rendererMode) ?? .video
        isMuted = setup.isMuted
        scalingMode = VideoScalingMode(rawValue: setup.scalingMode) ?? .resizeAspectFill
        ensurePerDisplayMode()

        // Migrate legacy unified setups into per-display sources
        if !setup.usePerDisplay, let unifiedSource = setup.unifiedSource, !unifiedSource.isEmpty {
            for screen in NSScreen.screens {
                settings.perDisplaySources[String(screen.displayID)] = unifiedSource
            }
        }

        // Restore bookmarks with validation
        if let unifiedBookmarkBase64 = setup.unifiedBookmarkBase64,
           let bookmarkData = Data(base64Encoded: unifiedBookmarkBase64) {
            do {
                var isStale = false
                _ = try URL(resolvingBookmarkData: bookmarkData, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
                
                if isStale {
                    logger.debug("Unified bookmark is stale, will refresh on next access")
                }
                settings.videoBookmarkData = bookmarkData
            } catch {
                logger.warning("Failed to validate unified bookmark: \(error.localizedDescription). Will fall back to path.")
                settings.videoBookmarkData = nil
            }
        } else {
            settings.videoBookmarkData = nil
        }
        
        // Restore per-display bookmarks with validation
        var restoredPerDisplayBookmarks: [String: Data] = [:]
        var failedDisplayIDs: [String] = []
        
        for (displayIDStr, bookmarkBase64) in setup.perDisplayBookmarksBase64 {
            if let bookmarkData = Data(base64Encoded: bookmarkBase64) {
                do {
                    var isStale = false
                    _ = try URL(resolvingBookmarkData: bookmarkData, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
                    
                    if isStale {
                        logger.debug("Per-display bookmark for \(displayIDStr) is stale, will refresh on next access")
                    }
                    restoredPerDisplayBookmarks[displayIDStr] = bookmarkData
                } catch {
                    logger.warning("Failed to validate bookmark for display \(displayIDStr): \(error.localizedDescription). Will fall back to path.")
                    failedDisplayIDs.append(displayIDStr)
                }
            }
        }
        settings.perDisplayBookmarks = restoredPerDisplayBookmarks
        
        // Restore per-display sources and scaling modes
        settings.perDisplaySources = setup.perDisplaySources
        settings.perDisplayScalingModes = setup.perDisplayScalingModes
        
        // Restore unified source
        if let unifiedSource = setup.unifiedSource, !unifiedSource.isEmpty {
            selectedVideoPath = unifiedSource
            settings.videoFilePath = unifiedSource
        }
        
        // Mark setup as current
        settings.currentSetupName = name
        selectedSetupName = name

        await wallpaperManager.setMuted(isMuted)
        await wallpaperManager.setScalingMode(scalingMode)
        await wallpaperManager.setRendererMode(rendererMode)

        migrateDisplayConfigurationOnScreenChange()
        notifyDisplaySourcesChanged()

        var wallpaperApplicationErrors: [String] = []
        var appliedDisplays: [CGDirectDisplayID] = []
        let displayIDs = orderedConnectedDisplayIDs()

        for displayID in displayIDs {
            let key = String(displayID)
            let hasSource = !(settings.perDisplaySources[key] ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
            let hasBookmark = settings.perDisplayBookmarks[key] != nil

            guard hasSource || hasBookmark else { continue }

            if await applyPlaybackToDisplay(displayID: displayID) {
                appliedDisplays.append(displayID)
            } else {
                wallpaperApplicationErrors.append("Display \(displayID)")
            }
        }

        refreshSetupState()
        await refreshDisplayState()

        if wallpaperApplicationErrors.isEmpty {
            if appliedDisplays.isEmpty {
                statusMessage = "Setup '\(name)' settings restored. No wallpapers were configured for connected displays."
            } else {
                statusMessage = "Setup '\(name)' restored to \(appliedDisplays.count) display\(appliedDisplays.count == 1 ? "" : "s")."
            }
            errorMessage = nil
            return .success(())
        }

        let errorDetail = wallpaperApplicationErrors.prefix(2).joined(separator: ", ")
        statusMessage = "Setup '\(name)' settings restored with warnings."
        errorMessage = "Could not apply wallpaper to: \(errorDetail)"
        if wallpaperApplicationErrors.count > 2 {
            errorMessage?.append(" (+\(wallpaperApplicationErrors.count - 2) more)")
        }
        return appliedDisplays.isEmpty ? .failure(.internalError(description: errorMessage ?? "Setup restore failed")) : .success(())
    }
    
    /// Delete a setup with validation
    func deleteSetup(name: String) async -> Result<Void, WallpaperError> {
        let result = settings.deleteSetup(name: name)
        
        switch result {
        case .success:
            refreshSetupState()
            statusMessage = "Setup '\(name)' deleted."
            errorMessage = nil
            logger.info("Setup '\(name)' deleted successfully")
            return .success(())
        case .failure(let error):
            errorMessage = error.errorDescription
            statusMessage = nil
            logger.error("Failed to delete setup '\(name)': \(error.errorDescription ?? "unknown")")
            return .failure(error)
        }
    }
    
    /// Get list of all saved setup names
    func allSetupNames() -> [String] {
        settings.allSetupNames()
    }
    
    /// Validate setup integrity
    /// - Returns: nil if valid, error message if invalid
    private func validateSetupIntegrity(_ setup: SavedSetup) -> String? {
        if setup.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Setup name is empty"
        }
        
        if setup.rendererMode.isEmpty || WallpaperRendererMode(rawValue: setup.rendererMode) == nil {
            return "Invalid renderer mode: \(setup.rendererMode)"
        }
        
        if setup.scalingMode.isEmpty || VideoScalingMode(rawValue: setup.scalingMode) == nil {
            return "Invalid scaling mode: \(setup.scalingMode)"
        }
        
        if setup.perDisplaySources.isEmpty && (setup.unifiedSource == nil || setup.unifiedSource?.isEmpty == true) {
            return "No wallpaper sources defined"
        }
        
        return nil
    }
    
    // MARK: - Phase 7 Unified Display State Management
    
    /// Phase 7: Apply wallpaper to specific displays
    /// Shows ApplyWallpaperModal in HomeTabView if called from manual selection
    /// Collections call this directly with predetermined displayIDs
    @MainActor
    func applyWallpaperToDisplays(url: URL, displayIDs: [CGDirectDisplayID]) async -> Result<Void, WallpaperError> {
        isApplyingWallpaper = true
        defer { isApplyingWallpaper = false }
        
        let rendererMode = self.rendererMode
        let scalingMode = self.scalingMode

        // Persist source and bookmarks so preview/state can resolve a security-scoped URL.
        var resolvedApplyURL = url
        if url.isFileURL {
            do {
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }

                    let bookmark = try url.bookmarkData(
                        options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    )

                    var stale = false
                    let restoredURL = try URL(
                        resolvingBookmarkData: bookmark,
                        options: [.withSecurityScope],
                        relativeTo: nil,
                        bookmarkDataIsStale: &stale
                    )
                    resolvedApplyURL = restoredURL

                    for displayID in displayIDs {
                        settings.perDisplaySources[String(displayID)] = url.absoluteString
                        settings.perDisplayBookmarks[String(displayID)] = bookmark
                        settings.perDisplayRendererModes[String(displayID)] = rendererMode.rawValue
                        settings.perDisplayScalingModes[String(displayID)] = scalingMode.rawValue
                    }
                } else {
                    logger.warning("Could not start security scope for selected URL in applyWallpaperToDisplays: \(url.path)")
                    for displayID in displayIDs {
                        settings.perDisplaySources[String(displayID)] = url.absoluteString
                        settings.perDisplayRendererModes[String(displayID)] = rendererMode.rawValue
                        settings.perDisplayScalingModes[String(displayID)] = scalingMode.rawValue
                    }
                }
            } catch {
                logger.warning("Failed to create per-display bookmark in applyWallpaperToDisplays: \(error.localizedDescription)")
                for displayID in displayIDs {
                    settings.perDisplaySources[String(displayID)] = url.absoluteString
                    settings.perDisplayRendererModes[String(displayID)] = rendererMode.rawValue
                    settings.perDisplayScalingModes[String(displayID)] = scalingMode.rawValue
                }
            }
        } else {
            for displayID in displayIDs {
                settings.perDisplaySources[String(displayID)] = url.absoluteString
                settings.perDisplayRendererModes[String(displayID)] = rendererMode.rawValue
                settings.perDisplayScalingModes[String(displayID)] = scalingMode.rawValue
            }
        }
        
        for displayID in displayIDs {
            let result = await wallpaperManager.setPerDisplayWallpaper(
                displayID: displayID,
                url: resolvedApplyURL,
                rendererMode: rendererMode,
                scalingMode: scalingMode
            )
            
            switch result {
            case .success:
                logger.debug("Applied wallpaper to display \(displayID)")
            case .failure(let error):
                logger.error("Failed to apply to display \(displayID): \(error)")
                errorMessage = "Failed to apply wallpaper to display \(displayID)"
                return .failure(error)
            }
        }
        
        // Sync preview state after successful apply
        await refreshDisplayState()
        statusMessage = "Wallpaper applied to \(displayIDs.count) display\(displayIDs.count == 1 ? "" : "s")"
        return .success(())
    }
    
    /// Phase 7: Refresh display wallpaper state from wallpaperManager
    /// Called after any wallpaper apply to sync displayWallpaperState with reality
    @MainActor
    func refreshDisplayState() async {
        var newState: [CGDirectDisplayID: DisplayWallpaperInfo] = [:]
        
        // Get all connected displays
        let screens = NSScreen.screens
        let displayIDs = screens.map { $0.displayID }
        
        for (index, displayID) in displayIDs.enumerated() {
            let screen = screens[index]
            let displayName = screen.localizedName
            let resolution = screen.frame.size
            let isPrimary = screen == NSScreen.main
            
            // Get current wallpaper URL from settings
            let wallpaperURL: URL? = {
                // Prefer per-display resolved URL when present
                if let resolved = perDisplayResolvedURL(for: displayID) {
                    return resolved
                }

                if let urlString = settings.perDisplaySources[String(displayID)], !urlString.isEmpty {
                    return resolvedSourceURL(from: urlString)
                }

                return nil
            }()
            
            // Get current renderer mode
            let rendererMode: WallpaperRendererMode = {
                if let modeString = settings.perDisplayRendererModes[String(displayID)],
                   let mode = WallpaperRendererMode(rawValue: modeString) {
                    return mode
                }
                return self.rendererMode == .web ? .web : .video
            }()
            
            // Get current scaling mode
            let scalingMode: VideoScalingMode = {
                if let modeString = settings.perDisplayScalingModes[String(displayID)],
                   let mode = VideoScalingMode(rawValue: modeString) {
                    return mode
                }
                return self.scalingMode
            }()
            
            let info = DisplayWallpaperInfo(
                displayID: displayID,
                displayName: displayName,
                resolution: resolution,
                wallpaperURL: wallpaperURL,
                rendererMode: rendererMode,
                scalingMode: scalingMode,
                isPrimary: isPrimary
            )
            
            newState[displayID] = info
        }
        
        displayWallpaperState = newState
        notifyDisplaySourcesChanged()
    }
    
    /// Phase 7: Initialize display state on app start
    @MainActor
    func initializeDisplayState() async {
        await refreshDisplayState()
    }

    // MARK: - Phase 8 Local Library

    func loadLibraryFromSettings() {
        localLibraryManager.loadFromSettings()
        libraryRoots = localLibraryManager.roots
        libraryItems = localLibraryManager.items
        libraryLastScanDate = settings.libraryLastScanDate
        selectedLibraryItemID = settings.lastUsedLibraryItemID
    }

    var filteredLibraryItems: [LibraryItem] {
        libraryItems.filter { item in
            if libraryFavoritesOnly, !item.favorited { return false }
            if let rootID = libraryRootFilterID, item.rootID != rootID { return false }
            let query = librarySearchText.trimmingCharacters(in: .whitespacesAndNewlines)
            if query.isEmpty { return true }
            let haystack = "\(item.displayName) \(item.rootDisplayName) \(item.filePath)".lowercased()
            return haystack.contains(query.lowercased())
        }
    }

    func addLibraryRoot(at url: URL) async {
        switch localLibraryManager.addLibraryRoot(at: url) {
        case .success:
            libraryRoots = localLibraryManager.roots
            errorMessage = nil
            statusMessage = "Added library folder: \(url.lastPathComponent)"
            _ = await rescanLibrary()
        case .failure(let error):
            errorMessage = error.errorDescription
            statusMessage = nil
        }
    }

    func removeLibraryRoot(id: String) async {
        switch localLibraryManager.removeLibraryRoot(id: id) {
        case .success:
            libraryRoots = localLibraryManager.roots
            libraryItems = localLibraryManager.items
            if libraryRootFilterID == id {
                libraryRootFilterID = nil
            }
            if let selected = selectedLibraryItemID,
               libraryItems.first(where: { $0.id == selected }) == nil {
                selectedLibraryItemID = nil
                transientPreviewURL = nil
            }
            statusMessage = "Removed library folder."
            errorMessage = nil
        case .failure(let error):
            errorMessage = error.errorDescription
            statusMessage = nil
        }
    }

    @discardableResult
    func rescanLibrary() async -> Result<[LibraryItem], WallpaperError> {
        isLibraryScanning = true
        defer { isLibraryScanning = false }
        let result = await localLibraryManager.rescanLibrary()
        switch result {
        case .success(let items):
            libraryItems = items
            libraryLastScanDate = settings.libraryLastScanDate
            statusMessage = "Library scan complete — \(items.filter { !$0.isMissing }.count) videos indexed."
            errorMessage = nil
        case .failure(let error):
            errorMessage = error.errorDescription
        }
        return result
    }

    func toggleLibraryFavorite(itemID: String) {
        switch localLibraryManager.toggleFavorite(itemID: itemID) {
        case .success(let item):
            if let index = libraryItems.firstIndex(where: { $0.id == itemID }) {
                libraryItems[index] = item
            }
        case .failure(let error):
            errorMessage = error.errorDescription
        }
    }

    func previewLibraryItem(_ item: LibraryItem) {
        guard !item.isMissing else {
            errorMessage = WallpaperError.libraryItemUnavailable(path: item.filePath).errorDescription
            return
        }
        guard let url = localLibraryManager.resolveURL(for: item) else {
            errorMessage = WallpaperError.libraryItemUnavailable(path: item.filePath).errorDescription
            return
        }
        selectedLibraryItemID = item.id
        transientPreviewURL = url
        localLibraryManager.markLastUsed(itemID: item.id)
        localLibraryManager.refreshBookmark(for: item.id, url: url)
        libraryItems = localLibraryManager.items
        selectVideo(at: url)
        statusMessage = "Previewing: \(item.displayName)"
        errorMessage = nil
    }

    func clearLibraryPreview() {
        transientPreviewURL = nil
    }

    func applyLibraryItem(_ item: LibraryItem, displayIDs: [CGDirectDisplayID]) async -> Result<Void, WallpaperError> {
        guard !item.isMissing else {
            return .failure(.libraryItemUnavailable(path: item.filePath))
        }
        guard let url = localLibraryManager.resolveURL(for: item) else {
            return .failure(.libraryItemUnavailable(path: item.filePath))
        }
        previewLibraryItem(item)
        let result = await applyWallpaperToDisplays(url: url, displayIDs: displayIDs)
        if case .success = result {
            transientPreviewURL = nil
            notifyDisplaySourcesChanged()
        }
        return result
    }

    func applySelectedLibraryItemToFocusedDisplay() async {
        guard let itemID = selectedLibraryItemID,
              let item = libraryItems.first(where: { $0.id == itemID }) else {
            errorMessage = "Select a library video to apply."
            return
        }
        guard let displayID = focusedDisplayID ?? NSScreen.screens.first?.displayID else {
            errorMessage = "No display available."
            return
        }
        _ = await applyLibraryItem(item, displayIDs: [displayID])
    }

    func libraryThumbnail(for item: LibraryItem) async -> NSImage? {
        await localLibraryManager.thumbnail(for: item)
    }

    func libraryCacheSummary() -> String {
        let bytes = localLibraryManager.cacheByteCount()
        let count = localLibraryManager.cacheEntryCount()
        let megabytes = Double(bytes) / (1024 * 1024)
        return String(format: "%d thumbnails · %.1f MB", count, megabytes)
    }

    func clearLibraryThumbnailCache() {
        LibraryThumbnailCache.shared.clearAll()
        statusMessage = "Library thumbnail cache cleared."
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

