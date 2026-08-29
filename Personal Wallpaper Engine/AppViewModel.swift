import AppKit
import AVFoundation
import Darwin
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
    /// Transient confirmation ("Wallpaper applied…"). Expires on its own; see `scheduleBannerExpiry`.
    @Published var statusMessage: String? {
        didSet { scheduleBannerExpiry(for: .status) }
    }
    /// Transient failure text. Given longer on screen than `statusMessage` since it is actionable.
    @Published var errorMessage: String? {
        didSet { scheduleBannerExpiry(for: .error) }
    }
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
    /// Deliberately not `@Published`: see `PerformanceDiagnosticsModel`. Observing this object from
    /// `AppViewModel` would reintroduce the 1 Hz invalidation of the whole shell.
    let diagnostics = PerformanceDiagnosticsModel()
    @Published var performanceSuggestion: PerformanceSuggestion?
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
    @Published var libraryFavoritesOnly: Bool = false
    @Published var libraryRootFilterID: String?
    @Published private(set) var isLibraryScanning = false
    @Published var libraryLastScanDate: Date?
    /// Temporary hero preview URL when browsing the library before apply.
    @Published var transientPreviewURL: URL?

    // MARK: - Phase 9 Quick Modes
    @Published private(set) var quickMode: QuickMode = .perDisplayCustom
    @Published var pinnedSetupName: String?
    @Published private(set) var recentLibraryItemIDs: [String] = []
    @Published var shellNavigationRequest: ShellNavigationRequest?
    /// Display whose menu bar was clicked — set by MenuBarController on menu open.
    @Published var menuBarContextDisplayID: CGDirectDisplayID?
    
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
    /// Keeps sandbox access open for the lifetime of playback, not just the apply call.
    private let securityScopes = SecurityScopedAccessRegistry()
    private var bannerExpiryTasks: [BannerKind: Task<Void, Never>] = [:]
    private var lastVideoRestoreFailure: String?
    private var lastDisplaySignatures: [CGDirectDisplayID: DisplayConfigurationMigrator.DisplaySignature] = [:]
    /// Maps physical display (name + resolution) to the last `perDisplaySources` UserDefaults key — survives disconnect.
    private var settingsKeyBySignature: [DisplayConfigurationMigrator.DisplaySignature: String] = [:]
    private var screenConfigurationTask: Task<Void, Never>?
    private let screenConfigurationDebounceNs: UInt64 = 150_000_000
    private let heroPreviewVisibility = AppPreviewVisibilityMonitor()
    /// Bumped when app/window visibility changes so hero pause state refreshes in SwiftUI (Home tab only).
    @Published private(set) var heroPreviewVisibilityRevision = 0
    /// Forces UnifiedVideoPreviewView remount after quick-mode transitions (avoids stale coordinator attach state).
    @Published private(set) var heroPreviewAttachToken = 0
    @Published var isHomeSidebarVisible = false
    private(set) var isQuickModeTransitionActive = false
    private var quickModeHeroRecoveryTask: Task<Void, Never>?
    private var shellHeroLayoutRecoveryTask: Task<Void, Never>?
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
        self.quickMode = settings.quickMode
        self.pinnedSetupName = settings.pinnedSetupName
        self.recentLibraryItemIDs = settings.recentLibraryItemIDs
        self.isHomeSidebarVisible = settings.homeSidebarVisible
        ensurePerDisplayMode()
        reconcileQuickModeOnLaunch()
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
        self.quickMode = settings.quickMode
        self.pinnedSetupName = settings.pinnedSetupName
        self.recentLibraryItemIDs = settings.recentLibraryItemIDs
        self.isHomeSidebarVisible = settings.homeSidebarVisible
        ensurePerDisplayMode()
        reconcileQuickModeOnLaunch()
    }

    /// Per-display is the only mode; migrates legacy unified preference on load.
    func ensurePerDisplayMode() {
        usePerDisplay = true
        settings.usePerDisplay = true
        syncFocusedDisplayIfNeeded()
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
        notifyDisplaySourcesChanged()
        evaluateQuickModeDrift(trigger: .perDisplaySourceChanged)
    }

    func selectPerDisplaySource(
        _ displayID: CGDirectDisplayID,
        at url: URL,
        notifyChanges: Bool = true
    ) {
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
        if notifyChanges {
            notifyDisplaySourcesChanged()
            evaluateQuickModeDrift(trigger: .perDisplaySourceChanged)
        }
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
        if isQuickModeTransitionActive {
            return false
        }

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

    func isHeroPreviewAttached(to containerView: NSView) -> Bool {
        wallpaperManager.isHeroPreviewAttached(to: containerView)
    }

    func setHomeSidebarVisible(_ visible: Bool) {
        isHomeSidebarVisible = visible
        settings.homeSidebarVisible = visible
    }

    /// Tracks main shell tab so visibility churn on management tabs does not relayout the hero.
    func setMainShellOnHomeTab(_ onHome: Bool) {
        let wasOnHome = isMainShellOnHomeTab
        isMainShellOnHomeTab = onHome
        if wasOnHome, !onHome, performanceProfile != .maxQuality {
            prepareManagementStaticHeroBackground()
        }
    }

    /// Detach unified hero layer before Balanced/Battery management-tab static background.
    /// Also bumps `heroPreviewAttachToken` (same remount signal as `refreshHeroPreviewAfterShellLayout()`, with detach).
    func prepareManagementStaticHeroBackground() {
        detachHeroPreviewLayer()
        heroPreviewAttachToken += 1
    }

    /// Re-mount hero preview after shell background reaches final layout (launch).
    /// Same attach-token mechanism as `prepareManagementStaticHeroBackground()` but without detaching first.
    func refreshHeroPreviewAfterShellLayout() {
        heroPreviewAttachToken += 1
    }

    /// Deferred hero remount after main shell layout settles (matches quick-mode recovery pattern).
    func scheduleShellHeroLayoutRecovery() {
        shellHeroLayoutRecoveryTask?.cancel()
        shellHeroLayoutRecoveryTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: 350_000_000)
            } catch {
                return
            }
            guard let self, !Task.isCancelled else { return }
            self.refreshHeroPreviewAfterShellLayout()
        }
    }

    /// Count of setup/collection entries tied to currently connected displays.
    func connectedDisplayCount(in perDisplaySources: [String: String]) -> Int {
        let connectedKeys = Set(NSScreen.screens.map { String($0.displayID) })
        return perDisplaySources.keys.filter { connectedKeys.contains($0) }.count
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
            // Held past this call so renderer reloads keep working; released when this display's
            // wallpaper is replaced or the display goes away.
            securityScopes.begin(url, owner: String(displayID))

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
            selectPerDisplaySource(displayID, at: url, notifyChanges: false)
            await applyPerDisplayWallpaper(displayID: displayID, sourceString: url.absoluteString)
        }

        await wallpaperManager.coalesceSharedVideoPlaybackIfNeeded(for: url.standardizedFileURL)

        focusedDisplayID = displayIDs.first
        let displayCount = displayIDs.count
        statusMessage = "Applied to \(displayCount) display\(displayCount == 1 ? "" : "s")"
        errorMessage = nil
        notifyDisplaySourcesChanged()
        evaluateQuickModeDrift(trigger: .perDisplaySourceChanged)
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

        migratePerDisplaySettingsOnColdStart()
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
        diagnostics.apply(metrics)

        if metrics.isReady {
            recentCPUSamples.append(metrics.smoothedPercent)
            if recentCPUSamples.count > 60 {
                recentCPUSamples.removeFirst(recentCPUSamples.count - 60)
            }
            evaluatePerformanceSuggestion()
        }

        // Only the Diagnostics card renders this snapshot, so there is nothing to keep warm while
        // the panel is closed. `setDiagnosticsPanelVisible(true)` refreshes on open.
        guard isDiagnosticsPanelVisible else { return }

        let elapsed = lastDiagnosticsRefreshAt.map { Date().timeIntervalSince($0) }
        if elapsed == nil || elapsed! >= 1 {
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
        diagnostics.apply(wallpaperManager.diagnosticsSnapshot())
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
            useTestMode: useTestPerformanceSuggestionThresholds
        )

        guard let gate = PerformanceSuggestionPolicy.systemPercentThreshold(
            leaving: performanceProfile,
            thresholds: policy
        ) else {
            performanceSuggestion = nil
            return
        }

        // `recentCPUSamples` is on the per-core scale; the policy converts to system-wide share.
        guard PerformanceSuggestionPolicy.isSustained(
            perCoreSamples: recentCPUSamples,
            aboveSystemPercent: gate.threshold,
            thresholds: policy
        ) else {
            // Clearing this lets a genuine future spike surface a banner again. Leaving it set was
            // why the banner never reappeared after its first showing.
            performanceSuggestion = nil
            lastSuggestedProfile = nil
            return
        }

        guard lastSuggestedProfile != gate.suggested else { return }

        let systemPercent = CPUMetricsFormatting.systemWidePercent(fromPerCore: diagnostics.averageCPUPercent)
        let message = "Wallpaper playback has averaged \(String(format: "%.1f", systemPercent))% of your Mac's CPU recently. Switch to \(gate.suggested.displayName) to reduce usage."
        performanceSuggestion = PerformanceSuggestion(message: message, suggestedProfile: gate.suggested)
        lastSuggestedProfile = gate.suggested
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
            // "Remind me later" means the banner should be allowed back once the snooze lapses.
            lastSuggestedProfile = nil
        }
    }

    /// Debug-only QA affordance for forcing the suggestion banner. Release builds always use
    /// production thresholds, even if a `true` value persisted from a Debug run.
    var useTestPerformanceSuggestionThresholds: Bool {
        get {
            #if DEBUG
            return settings.useTestPerformanceSuggestionThresholds
            #else
            return false
            #endif
        }
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
        releaseSecurityScopesForDisconnectedDisplays()
        await reapplyPersistedPerDisplayWallpapers()
    }

    /// Display IDs are reused after hotplug, so scopes keyed by a departed display must be released.
    private func releaseSecurityScopesForDisconnectedDisplays() {
        var live = Set(NSScreen.screens.map { String($0.displayID) })
        live.insert(SecurityScopedAccessRegistry.unifiedOwner)
        securityScopes.endAll(exceptOwners: live)
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

    /// Records which settings key owns data for a physical display (used when IDs change after hotplug).
    private func recordPerDisplaySettingsKey(for displayID: CGDirectDisplayID) {
        guard let screen = NSScreen.screens.first(where: { $0.displayID == displayID }) else { return }
        let signature = DisplayConfigurationMigrator.DisplaySignature(screen: screen)
        let key = String(displayID)
        settingsKeyBySignature[signature] = key
        settings.setPerDisplaySignatureKey(signature.persistenceKey, settingsKey: key)
    }

    /// Re-keys orphaned per-display settings when display IDs changed between sessions.
    private func migratePerDisplaySettingsOnColdStart() {
        let screens = NSScreen.screens
        let previousSnapshots = buildPreviousSignaturesForMigration(screens: screens)
        let mapping = DisplayConfigurationMigrator.migrationMapping(
            previousSignatures: previousSnapshots,
            currentScreens: screens
        )
        applyPerDisplaySettingsMigration(mapping: mapping, previousSnapshots: previousSnapshots)
    }

    private func buildPreviousSignaturesForMigration(
        screens: [NSScreen]
    ) -> [CGDirectDisplayID: DisplayConfigurationMigrator.DisplaySignature] {
        var persistedSettingsKeys = Set<String>()
        for screen in screens {
            let key = String(screen.displayID)
            if settings.perDisplaySources[key] != nil
                || settings.perDisplayBookmarks[key] != nil {
                persistedSettingsKeys.insert(key)
            }
        }

        let outcome = DisplayMigrationOrchestration.previousSignaturesForColdStart(
            perDisplaySignatureKeys: settings.perDisplaySignatureKeys,
            persistedSettingsKeys: persistedSettingsKeys,
            connectedSignatures: DisplayConfigurationMigrator.signatures(for: screens)
        )

        for (signature, key) in outcome.settingsKeyBySignature {
            settingsKeyBySignature[signature] = key
        }
        for displayID in outcome.connectedDisplayIDsToPersist {
            recordPerDisplaySettingsKey(for: displayID)
        }

        return outcome.previous
    }

    private func applyPerDisplaySettingsMigration(
        mapping: [String: String],
        previousSnapshots: [CGDirectDisplayID: DisplayConfigurationMigrator.DisplaySignature]
    ) {
        guard !mapping.isEmpty else { return }

        DisplayConfigurationMigrator.rekeyPerDisplaySettings(in: settings, mapping: mapping)
        logger.info("Re-keyed per-display settings for \(mapping.count) display(s) after configuration change")

        for (oldKey, newKey) in mapping {
            guard let oldID = UInt32(oldKey),
                  let signature = previousSnapshots[CGDirectDisplayID(oldID)] else { continue }
            settingsKeyBySignature[signature] = newKey
            settings.setPerDisplaySignatureKey(signature.persistenceKey, settingsKey: newKey)
        }

        notifyDisplaySourcesChanged()
    }

    /// Includes disconnected displays so unplugged monitor settings can remap on replug.
    private func augmentedPreviousSignatures(for screens: [NSScreen]) -> [CGDirectDisplayID: DisplayConfigurationMigrator.DisplaySignature] {
        DisplayMigrationOrchestration.augmentedPreviousSignatures(
            lastDisplaySignatures: lastDisplaySignatures,
            settingsKeyBySignature: settingsKeyBySignature,
            connectedDisplayIDs: Set(screens.map(\.displayID))
        )
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
            applyPerDisplaySettingsMigration(mapping: mapping, previousSnapshots: previousSnapshots)
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
        let currentSignatures = DisplayConfigurationMigrator.signatures(for: NSScreen.screens)
        switch DisplayMigrationOrchestration.migrateFocusedDisplayID(
            currentFocusedID: focusedDisplayID,
            mapping: mapping,
            focusedSignatureBefore: focusedSignatureBefore,
            currentSignatures: currentSignatures
        ) {
        case .resolved(let newID):
            focusedDisplayID = newID
        case .needsSync:
            syncFocusedDisplayIfNeeded()
        }
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
        // See `applyPerDisplayWallpaper`: the scope must outlive this call.
        securityScopes.begin(url, owner: String(displayID))

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
            guard let url = WebWallpaperURLValidator.validatedURL(from: trimmed) else {
                errorMessage = WebWallpaperURLValidator.validationHint
                statusMessage = nil
                return
            }
            for displayID in displayIDs {
                updatePerDisplaySource(displayID, url.absoluteString)
                await applyPerDisplayWallpaper(displayID: displayID, sourceString: url.absoluteString)
            }
            statusMessage = "Applied web wallpaper to \(displayIDs.count) display\(displayIDs.count == 1 ? "" : "s")"
            errorMessage = nil
        }
    }

    private func applyWallpaperFromSavedWebURL() async {
        guard rendererMode == .web else { return }
        let trimmed = settings.webURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = WebWallpaperURLValidator.validatedURL(from: trimmed) else { return }
        await applyWallpaper(url: url)
    }

    func stop() async {
        shellHeroLayoutRecoveryTask?.cancel()
        quickModeHeroRecoveryTask?.cancel()
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

    @discardableResult
    private func beginAccessingSelectedVideoURL(_ url: URL) -> Bool {
        securityScopes.begin(url, owner: SecurityScopedAccessRegistry.unifiedOwner)
    }

    private func endAccessingSelectedVideoURL() {
        securityScopes.end(owner: SecurityScopedAccessRegistry.unifiedOwner)
    }

    // MARK: - Transient banners

    private enum BannerKind: Hashable {
        case status
        case error

        /// Errors stay up longer because the user may need to act on them.
        var lifetime: TimeInterval {
            switch self {
            case .status: return 6
            case .error: return 15
            }
        }
    }

    /// Retires a banner after its lifetime so a confirmation from ten minutes ago stops looking
    /// like a description of the current state.
    private func scheduleBannerExpiry(for kind: BannerKind) {
        bannerExpiryTasks[kind]?.cancel()
        bannerExpiryTasks[kind] = nil

        let isVisible: Bool
        switch kind {
        case .status: isVisible = statusMessage != nil
        case .error: isVisible = errorMessage != nil
        }
        guard isVisible else { return }

        let lifetime = kind.lifetime
        bannerExpiryTasks[kind] = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(lifetime * 1_000_000_000))
            guard !Task.isCancelled, let self else { return }
            switch kind {
            case .status: self.statusMessage = nil
            case .error: self.errorMessage = nil
            }
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
        bringAppToFront(selecting: .settings)
    }

    func showMainWindow() {
        bringAppToFront()
    }

    func bringAppToFront(selecting tab: ShellTab? = nil) {
        NSApp.activate(ignoringOtherApps: true)
        let window = NSApp.windows.first(where: { $0.canBecomeKey })
            ?? NSApp.windows.first
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
        if let tab {
            shellNavigationRequest = .open(tab: tab)
        }
    }

    func clearShellNavigationRequest() {
        shellNavigationRequest = nil
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
            evaluateQuickModeDrift(trigger: .collectionApplied)
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
        evaluateQuickModeDrift(trigger: .collectionApplied)
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
        var claimedDisplayIDs = Set<CGDirectDisplayID>()
        var appliedCount = 0

        let orderedDisplayIDs = orderedConnectedDisplayIDs()
        let connectedDisplays = orderedDisplayIDs.map { displayID in
            DisplayBoundCollectionMapping.ConnectedDisplay(
                id: displayID,
                name: wallpaperManager.displayControllers[displayID]?.displayName ?? ""
            )
        }

        var explicitSources: [CollectionSource] = []
        var autoDetectSources: [CollectionSource] = []
        for source in collection.sources {
            if DisplayBoundCollectionMapping.isAutoDetect(source) {
                autoDetectSources.append(source)
            } else {
                explicitSources.append(source)
            }
        }

        for source in explicitSources {
            guard let displayID = DisplayBoundCollectionMapping.resolveExplicitBinding(
                source: source,
                connected: connectedDisplays,
                claimed: &claimedDisplayIDs
            ) else {
                let displayInfo = source.displayLabel
                    ?? source.displayIDFallback.map { String($0) }
                    ?? "?"
                let message = "Display \(displayInfo) not connected"
                unmatchedWarnings.append(message)
                logger.warning("Display-bound collection skip: \(message)")
                continue
            }

            if await applyDisplayBoundSource(
                source,
                collectionName: collection.name,
                displayID: displayID
            ) {
                appliedCount += 1
                recordPerDisplaySettingsKey(for: displayID)
            }
        }

        let autoDisplayIDs = DisplayBoundCollectionMapping.autoDetectDisplayIDs(
            count: autoDetectSources.count,
            orderedDisplayIDs: orderedDisplayIDs,
            claimed: claimedDisplayIDs
        )

        if autoDetectSources.count > autoDisplayIDs.count {
            let skipped = autoDetectSources.count - autoDisplayIDs.count
            unmatchedWarnings.append(
                "\(skipped) auto-detect source\(skipped == 1 ? "" : "s") skipped — not enough displays"
            )
        }

        for (source, displayID) in zip(autoDetectSources, autoDisplayIDs) {
            claimedDisplayIDs.insert(displayID)
            if await applyDisplayBoundSource(
                source,
                collectionName: collection.name,
                displayID: displayID
            ) {
                appliedCount += 1
                recordPerDisplaySettingsKey(for: displayID)
            }
        }

        settings.lastUsedCollectionName = collection.name

        refreshCollectionState()
        notifyDisplaySourcesChanged()
        evaluateQuickModeDrift(trigger: .collectionApplied)
        await refreshDisplayState()

        if unmatchedWarnings.isEmpty {
            statusMessage = "Collection '\(collection.name)' applied to \(appliedCount) display\(appliedCount == 1 ? "" : "s")."
            errorMessage = nil
            return .success(())
        }

        let warningText = unmatchedWarnings.joined(separator: "; ")
        if appliedCount > 0 {
            statusMessage = "Applied to \(appliedCount) display\(appliedCount == 1 ? "" : "s"). \(warningText)"
        } else {
            statusMessage = "Collection '\(collection.name)' could not be applied. \(warningText)"
        }
        errorMessage = appliedCount > 0 ? nil : warningText
        return appliedCount > 0 ? .success(()) : .failure(.internalError(description: warningText))
    }

    @MainActor
    private func applyDisplayBoundSource(
        _ source: CollectionSource,
        collectionName: String,
        displayID: CGDirectDisplayID
    ) async -> Bool {
        guard let url = resolvedSourceURL(from: source.url, collectionName: collectionName) else {
            return false
        }

        syncPerDisplayFromCollection(
            displayID: displayID,
            collectionName: collectionName,
            source: source
        )
        let rendererMode: WallpaperRendererMode = url.isFileURL ? .video : .web
        let scalingMode = source.scalingMode.flatMap { VideoScalingMode(rawValue: $0) } ?? settings.scalingMode
        let result = await wallpaperManager.setPerDisplayWallpaper(
            displayID: displayID,
            url: url,
            rendererMode: rendererMode,
            scalingMode: scalingMode
        )
        if case .success = result { return true }
        return false
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
        let connectedKeys = Set(NSScreen.screens.map { String($0.displayID) })

        // Collect per-display bookmarks for connected displays only (omit stale hotplug IDs).
        var perDisplayBookmarksBase64: [String: String] = [:]
        for (displayIDStr, bookmark) in settings.perDisplayBookmarks where connectedKeys.contains(displayIDStr) {
            perDisplayBookmarksBase64[displayIDStr] = bookmark.base64EncodedString()
        }

        let perDisplaySources = settings.perDisplaySources.filter { connectedKeys.contains($0.key) }
        let perDisplayScalingModes = settings.perDisplayScalingModes.filter { connectedKeys.contains($0.key) }

        return (
            rendererMode: rendererMode.rawValue,
            isMuted: isMuted,
            scalingMode: scalingMode.rawValue,
            usePerDisplay: true,
            unifiedSource: selectedVideoPath.isEmpty ? nil : selectedVideoPath,
            perDisplaySources: perDisplaySources,
            perDisplayScalingModes: perDisplayScalingModes,
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

        if quickMode == .pinnedSetup, pinnedSetupName != name {
            transitionToCustomMode()
        }

        evaluateQuickModeDrift(trigger: .setupRestored)

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
            if pinnedSetupName == name {
                pinnedSetupName = nil
                settings.pinnedSetupName = nil
                if quickMode == .pinnedSetup {
                    transitionToCustomMode()
                }
            }
            if selectedSetupName == name {
                selectedSetupName = nil
            }
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
    /// Applies wallpaper to selected displays after user picks a file.
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
        notifyDisplaySourcesChanged()
        evaluateQuickModeDrift(trigger: .perDisplaySourceChanged)
        statusMessage = "Wallpaper applied to \(displayIDs.count) display\(displayIDs.count == 1 ? "" : "s")"
        return .success(())
    }
    
    /// Notifies UI that per-display wallpaper sources changed (carousel, hero, menu bar).
    @MainActor
    func refreshDisplayState() async {
        notifyDisplaySourcesChanged()
    }
    
    /// Phase 7: Initialize display state on app start
    @MainActor
    func initializeDisplayState() async {
        await refreshDisplayState()
    }

    // MARK: - Phase 9 Quick Modes

    private enum QuickModeDriftTrigger {
        case perDisplaySourceChanged
        case collectionApplied
        case setupRestored
    }

    private func reconcileQuickModeOnLaunch() {
        quickMode = settings.quickMode
        pinnedSetupName = settings.pinnedSetupName
        recentLibraryItemIDs = settings.recentLibraryItemIDs
        if quickMode == .pinnedSetup,
           let name = pinnedSetupName,
           settings.savedSetups[name] == nil {
            transitionToCustomMode()
        } else if quickMode == .singleAllDisplays, !allConnectedDisplaysShareSameWallpaper() {
            transitionToCustomMode()
        }
    }

    func returnToLastCommittedQuickMode(activateApp: Bool = false) async {
        let mode = settings.lastNonCustomQuickMode
        if mode == .pinnedSetup, let name = pinnedSetupName ?? settings.pinnedSetupName {
            await applyQuickMode(.pinnedSetup, pinnedSetup: name, activateApp: activateApp)
        } else {
            await applyQuickMode(mode, activateApp: activateApp)
        }
    }

    func applyQuickMode(_ mode: QuickMode, pinnedSetup: String? = nil, activateApp: Bool = false) async {
        guard mode != .custom else { return }

        isQuickModeTransitionActive = true

        switch mode {
        case .singleAllDisplays:
            commitQuickMode(.singleAllDisplays)
            if allConnectedDisplaysShareSameWallpaper() {
                statusMessage = "Single-all mode active."
            } else if let focused = focusedDisplayID ?? NSScreen.screens.first?.displayID,
                      let url = resolvePlaybackURL(for: focused) {
                await selectVideoForDisplays(url: url, displayIDs: orderedConnectedDisplayIDs())
            } else {
                statusMessage = "Single-all mode active. Choose a wallpaper to mirror to every display."
            }

        case .perDisplayCustom:
            commitQuickMode(.perDisplayCustom)
            statusMessage = "Per-display mode active."

        case .pinnedSetup:
            let setupName = (pinnedSetup ?? pinnedSetupName)?.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let setupName, !setupName.isEmpty else {
                isQuickModeTransitionActive = false
                bringAppToFront(selecting: .setups)
                statusMessage = "Pin a setup in the Setups tab for quick access."
                return
            }
            guard settings.savedSetups[setupName] != nil else {
                isQuickModeTransitionActive = false
                errorMessage = "Setup '\(setupName)' not found."
                return
            }
            commitQuickMode(.pinnedSetup)
            _ = await restoreSetup(name: setupName)

        case .custom:
            break
        }

        refreshHeroPreviewAfterQuickMode(activateApp: activateApp)
    }

    private func refreshHeroPreviewAfterQuickMode(activateApp: Bool = false) {
        quickModeHeroRecoveryTask?.cancel()
        heroPreviewVisibility.publishImmediately()
        notifyDisplaySourcesChanged()
        heroPreviewAttachToken += 1
        heroPreviewVisibilityRevision += 1
        if activateApp {
            NSApp.activate(ignoringOtherApps: true)
        }
        quickModeHeroRecoveryTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: 350_000_000)
            } catch {
                return
            }
            guard let self, !Task.isCancelled else { return }
            self.heroPreviewVisibility.publishImmediately()
            self.heroPreviewAttachToken += 1
            self.heroPreviewVisibilityRevision += 1
            self.isQuickModeTransitionActive = false
        }
    }

    func pinSetup(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, settings.savedSetups[trimmed] != nil else {
            errorMessage = "Setup '\(name)' not found."
            return
        }
        pinnedSetupName = trimmed
        settings.pinnedSetupName = trimmed
        statusMessage = "Pinned \"\(trimmed)\" for Quick Modes."
        errorMessage = nil
    }

    func unpinSetup() {
        pinnedSetupName = nil
        settings.pinnedSetupName = nil
        if quickMode == .pinnedSetup {
            transitionToCustomMode()
        }
        statusMessage = "Setup unpinned from Quick Modes."
        errorMessage = nil
    }

    func isSetupPinned(_ name: String) -> Bool {
        pinnedSetupName == name
    }

    private func commitQuickMode(_ mode: QuickMode) {
        quickMode = mode
        settings.quickMode = mode
        if mode != .custom {
            settings.lastNonCustomQuickMode = mode
        }
    }

    private func transitionToCustomMode() {
        guard quickMode != .custom else { return }
        quickMode = .custom
        settings.quickMode = .custom
    }

    private func evaluateQuickModeDrift(trigger: QuickModeDriftTrigger) {
        switch quickMode {
        case .custom:
            return
        case .singleAllDisplays:
            if !allConnectedDisplaysShareSameWallpaper() {
                transitionToCustomMode()
            }
        case .pinnedSetup:
            if trigger == .perDisplaySourceChanged || trigger == .collectionApplied {
                transitionToCustomMode()
            }
        case .perDisplayCustom:
            break
        }
    }

    func allConnectedDisplaysShareSameWallpaper() -> Bool {
        let ids = orderedConnectedDisplayIDs()
        guard !ids.isEmpty else { return true }
        let paths = ids.compactMap { id -> String? in
            guard let url = shellHeroPreviewURL(forDisplayID: id) else { return nil }
            if url.isFileURL { return url.standardizedFileURL.path }
            return url.absoluteString
        }
        guard !paths.isEmpty else { return true }
        return Set(paths).count <= 1
    }

    /// Display ID used for menu-bar thumbnail resolution.
    func menuBarPreviewDisplayID() -> CGDirectDisplayID? {
        if allConnectedDisplaysShareSameWallpaper() {
            return focusedDisplayID ?? menuBarContextDisplayID ?? NSScreen.screens.first?.displayID
        }
        return menuBarContextDisplayID ?? focusedDisplayID ?? NSScreen.screens.first?.displayID
    }

    func menuBarPreviewURL() -> URL? {
        shellHeroPreviewURL(forDisplayID: menuBarPreviewDisplayID())
    }

    func menuBarPreviewCaption() -> String {
        guard let url = menuBarPreviewURL() else { return "No wallpaper" }
        let filename = url.lastPathComponent.isEmpty ? url.absoluteString : url.lastPathComponent
        if allConnectedDisplaysShareSameWallpaper() {
            return "All Displays · \(filename)"
        }
        if let displayID = menuBarPreviewDisplayID() {
            return "\(displayStatusLabel(for: displayID)) · \(filename)"
        }
        return filename
    }

    func menuBarStatusLine() -> String {
        let mode = quickMode.shortName
        let profile = performanceProfile.displayName
        let playback = isPlaying ? "Playing" : "Paused"
        return "\(mode) · \(profile) · \(playback)"
    }

    func enablePauseUntilPluggedIn() {
        if !pauseOnBattery {
            updatePauseOnBattery(true)
        }
        Task { await applyPowerPolicySettings() }
        statusMessage = "Wallpapers will pause on battery until plugged in."
    }

    func applyBatterySaverProfile() {
        updatePerformanceProfile(.batterySaver)
        statusMessage = "Battery Saver profile enabled."
    }

    func targetDisplayIDsForApply(focusedOnly: [CGDirectDisplayID]) -> [CGDirectDisplayID] {
        if quickMode == .singleAllDisplays {
            return orderedConnectedDisplayIDs()
        }
        return focusedOnly
    }

    func recordLibraryRecent(_ itemID: String) {
        settings.recordRecentLibraryItem(id: itemID)
        recentLibraryItemIDs = settings.recentLibraryItemIDs
    }

    func recentLibraryItems() -> [LibraryItem] {
        recentLibraryItemIDs.compactMap { id in
            libraryItems.first(where: { $0.id == id })
        }
    }

    func applyRecentLibraryItem(_ item: LibraryItem) async {
        let displayIDs = targetDisplayIDsForApply(
            focusedOnly: [focusedDisplayID ?? NSScreen.screens.first?.displayID].compactMap { $0 }
        )
        guard !displayIDs.isEmpty else {
            errorMessage = "No display available."
            return
        }
        _ = await applyLibraryItem(item, displayIDs: displayIDs)
    }

    /// Applies a dropped video file to the focused display (or all displays in Single All mode).
    func applyDroppedVideoURL(_ url: URL) async {
        guard VideoDropImport.isVideoFile(url) else {
            errorMessage = "Unsupported file type. Use MP4 or MOV."
            return
        }
        let focused = [focusedDisplayID ?? NSScreen.screens.first?.displayID].compactMap { $0 }
        let displayIDs = targetDisplayIDsForApply(focusedOnly: focused)
        guard !displayIDs.isEmpty else {
            errorMessage = "No display available."
            return
        }
        let result = await applyWallpaperToDisplays(url: url, displayIDs: displayIDs)
        if case .failure(let error) = result {
            errorMessage = error.errorDescription ?? "Could not apply wallpaper."
        }
    }

    func formattedDiagnosticsLine() -> String {
        let cpu = CPUMetricsFormatting.menuBarCPUText(
            perCoreAverage: diagnostics.averageCPUPercent,
            ready: diagnostics.isCPUMeasurementReady
        )
        return "\(cpu) · \(formattedMemoryUsageMB())"
    }

    func menuBarThumbnailImage(for url: URL) async -> NSImage? {
        if url.isFileURL, VideoWallpaperThumbnail.isVideoFile(url) {
            return await VideoWallpaperThumbnail.imageAsync(for: url, at: .zero)
        }
        if let item = libraryItems.first(where: { item in
            guard let resolved = localLibraryManager.resolveURL(for: item) else { return false }
            return resolved.standardizedFileURL == url.standardizedFileURL
        }) {
            return await libraryThumbnail(for: item)
        }
        return NSImage(contentsOf: url)
    }

    // MARK: - Phase 8 Local Library

    func loadLibraryFromSettings() {
        localLibraryManager.loadFromSettings()
        libraryRoots = localLibraryManager.roots
        libraryItems = localLibraryManager.items
        libraryLastScanDate = settings.libraryLastScanDate
        recentLibraryItemIDs = settings.recentLibraryItemIDs
        if recentLibraryItemIDs.isEmpty, let lastID = settings.lastUsedLibraryItemID {
            recordLibraryRecent(lastID)
        }
        selectedLibraryItemID = settings.lastUsedLibraryItemID
    }

    /// Library items matching the active chips and `searchText`.
    ///
    /// The query is owned by `LibraryBrowserView` rather than published here: as a `@Published`
    /// property every keystroke invalidated every view observing this object, which is most of the
    /// app.
    func filteredLibraryItems(searchText: String) -> [LibraryItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return libraryItems.filter { item in
            if libraryFavoritesOnly, !item.favorited { return false }
            if let rootID = libraryRootFilterID, item.rootID != rootID { return false }
            guard !query.isEmpty else { return true }
            let haystack = "\(item.displayName) \(item.rootDisplayName) \(item.filePath)".lowercased()
            return haystack.contains(query)
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
        recordLibraryRecent(item.id)
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
            recordLibraryRecent(item.id)
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
        let focusedID = focusedDisplayID ?? NSScreen.screens.first?.displayID
        let displayIDs = targetDisplayIDsForApply(focusedOnly: [focusedID].compactMap { $0 })
        guard !displayIDs.isEmpty else {
            errorMessage = "No display available."
            return
        }
        _ = await applyLibraryItem(item, displayIDs: displayIDs)
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

