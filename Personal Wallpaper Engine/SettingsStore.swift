import AVFoundation
import Foundation
import os.log

final class SettingsStore {
    private static let persistenceLogger = Logger(subsystem: "com.local.wallpaper", category: "SettingsStore")

    /// Persists JSON-encoded values without deleting existing data on encode failure.
    private static func persistEncoded<T: Encodable>(_ value: T, forKey key: String) {
        do {
            let encoded = try JSONEncoder().encode(value)
            UserDefaults.standard.set(encoded, forKey: key)
        } catch {
            persistenceLogger.error("Failed to encode UserDefaults key \(key, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    static func quarantineKey(for key: String) -> String { "\(key).unreadableBackup" }

    /// Decodes a JSON-encoded value, quarantining data it cannot read.
    ///
    /// `try?` would hide the failure here, and that is worse than it looks: the empty fallback is
    /// assigned to a property whose `didSet` immediately writes it back, overwriting still-intact
    /// stored data. A single decode hiccup would therefore erase the user's setups, collections, or
    /// library permanently. Copying the raw bytes aside first keeps them recoverable and gives
    /// support something to diagnose.
    static func decodePersisted<T: Decodable>(
        _ type: T.Type,
        forKey key: String,
        default fallback: T
    ) -> T {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: key) else { return fallback }

        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            persistenceLogger.error(
                "Could not decode UserDefaults key \(key, privacy: .public); quarantined \(data.count) bytes: \(error.localizedDescription, privacy: .public)"
            )
            defaults.set(data, forKey: quarantineKey(for: key))
            return fallback
        }
    }
    static let shared = SettingsStore()

    private enum Keys {
        static let videoPath = "videoPath"
        static let videoBookmark = "videoBookmark"
        static let rendererMode = "rendererMode"
        static let webURL = "webURL"
        static let perDisplaySources = "perDisplaySources"
        static let isMuted = "isMuted"
        static let scalingMode = "scalingMode"
        static let debugDiagnostics = "debugDiagnostics"  // Chunk 4E: Debug flag
        static let launchOnLogin = "launchOnLogin"  // Phase 5G: Launch-on-login flag
        static let perDisplayScalingModes = "perDisplayScalingModes"  // Per-display scaling modes
        static let perDisplayRendererModes = "perDisplayRendererModes"  // Phase 7: Per-display renderer modes
        static let usePerDisplay = "usePerDisplay" // Bool: whether to use per-display wallpapers
        static let perDisplayBookmarks = "perDisplayBookmarks" // Per-display security-scoped bookmarks
        static let perDisplaySignatureKeys = "perDisplaySignatureKeys" // Screen signature → settings key (cold-start remap)
        static let savedCollections = "savedCollections"  // Phase 6A: Saved wallpaper collections
        static let collectionBookmarks = "collectionBookmarks"  // Phase 6A: Security-scoped bookmarks for collection sources
        static let lastUsedCollectionName = "lastUsedCollectionName"  // Phase 6A: Most recently used collection
        static let savedSetups = "savedSetups"  // Phase 6B: Saved desktop state snapshots
        static let currentSetupName = "currentSetupName"  // Phase 6B: Currently active setup name
        static let pauseOnBattery = "pauseOnBattery"  // Phase 7A
        static let pauseOnLowBattery = "pauseOnLowBattery"  // Phase 7A
        static let lowBatteryThreshold = "lowBatteryThreshold"  // Phase 7A
        static let performanceProfile = "performanceProfile"  // Phase 7B
        static let dismissPerformanceSuggestions = "dismissPerformanceSuggestions"  // Phase 7C
        static let useTestPerformanceSuggestionThresholds = "useTestPerformanceSuggestionThresholds"  // Phase 7C.1
        static let libraryRoots = "libraryRoots"  // Phase 8A
        static let libraryItems = "libraryItems"  // Phase 8A
        static let libraryLastScanDate = "libraryLastScanDate"  // Phase 8A
        static let lastUsedLibraryItemID = "lastUsedLibraryItemID"  // Phase 8A
        static let quickMode = "quickMode"  // Phase 9A
        static let lastNonCustomQuickMode = "lastNonCustomQuickMode"  // Phase 9A
        static let pinnedSetupName = "pinnedSetupName"  // Phase 9A
        static let recentLibraryItemIDs = "recentLibraryItemIDs"  // Phase 9B
        static let homeSidebarVisible = "homeSidebarVisible"
    }

    private init() {
        videoFilePath = UserDefaults.standard.string(forKey: Keys.videoPath) ?? ""
        videoBookmarkData = UserDefaults.standard.data(forKey: Keys.videoBookmark)
        rendererMode = WallpaperRendererMode(rawValue: UserDefaults.standard.string(forKey: Keys.rendererMode) ?? WallpaperRendererMode.video.rawValue) ?? .video
        webURLString = UserDefaults.standard.string(forKey: Keys.webURL) ?? ""
        perDisplaySources = Self.decodePersisted(
            [String: String].self, forKey: Keys.perDisplaySources, default: [:]
        )
        isMuted = UserDefaults.standard.bool(forKey: Keys.isMuted)
        scalingMode = VideoScalingMode(rawValue: UserDefaults.standard.string(forKey: Keys.scalingMode) ?? VideoScalingMode.resizeAspectFill.rawValue) ?? .resizeAspectFill
        debugDiagnosticsEnabled = UserDefaults.standard.bool(forKey: Keys.debugDiagnostics)  // Chunk 4E
        launchOnLoginEnabled = UserDefaults.standard.bool(forKey: Keys.launchOnLogin)  // Phase 5G
        perDisplayScalingModes = Self.decodePersisted(
            [String: String].self, forKey: Keys.perDisplayScalingModes, default: [:]
        )
        perDisplayRendererModes = Self.decodePersisted(
            [String: String].self, forKey: Keys.perDisplayRendererModes, default: [:]
        )
        usePerDisplay = true
        UserDefaults.standard.set(true, forKey: Keys.usePerDisplay)
        perDisplayBookmarks = Self.decodePersisted(
            [String: Data].self, forKey: Keys.perDisplayBookmarks, default: [:]
        )
        perDisplaySignatureKeys = Self.decodePersisted(
            [String: String].self, forKey: Keys.perDisplaySignatureKeys, default: [:]
        )
        savedCollections = Self.decodePersisted(
            [String: WallpaperCollection].self, forKey: Keys.savedCollections, default: [:]
        )
        collectionBookmarks = Self.decodePersisted(
            [String: [String: Data]].self, forKey: Keys.collectionBookmarks, default: [:]
        )
        lastUsedCollectionName = UserDefaults.standard.string(forKey: Keys.lastUsedCollectionName)
        savedSetups = Self.decodePersisted(
            [String: SavedSetup].self, forKey: Keys.savedSetups, default: [:]
        )
        currentSetupName = UserDefaults.standard.string(forKey: Keys.currentSetupName)
        pauseOnBattery = UserDefaults.standard.object(forKey: Keys.pauseOnBattery) as? Bool ?? false
        pauseOnLowBattery = UserDefaults.standard.object(forKey: Keys.pauseOnLowBattery) as? Bool ?? true
        let storedThreshold = UserDefaults.standard.object(forKey: Keys.lowBatteryThreshold) as? Int
        lowBatteryThreshold = storedThreshold ?? 20
        if let raw = UserDefaults.standard.string(forKey: Keys.performanceProfile),
           let profile = PerformanceProfile(rawValue: raw) {
            performanceProfile = profile
        } else {
            performanceProfile = .balanced
        }
        dismissPerformanceSuggestions = UserDefaults.standard.bool(forKey: Keys.dismissPerformanceSuggestions)
        useTestPerformanceSuggestionThresholds = UserDefaults.standard.bool(forKey: Keys.useTestPerformanceSuggestionThresholds)
        libraryRoots = Self.decodePersisted([LibraryRoot].self, forKey: Keys.libraryRoots, default: [])
        libraryItems = Self.decodePersisted([LibraryItem].self, forKey: Keys.libraryItems, default: [])
        if let scanDate = UserDefaults.standard.object(forKey: Keys.libraryLastScanDate) as? Date {
            libraryLastScanDate = scanDate
        } else {
            libraryLastScanDate = nil
        }
        lastUsedLibraryItemID = UserDefaults.standard.string(forKey: Keys.lastUsedLibraryItemID)
        if let raw = UserDefaults.standard.string(forKey: Keys.quickMode),
           let mode = QuickMode(rawValue: raw) {
            quickMode = mode
        } else {
            quickMode = .perDisplayCustom
        }
        if let raw = UserDefaults.standard.string(forKey: Keys.lastNonCustomQuickMode),
           let mode = QuickMode(rawValue: raw), mode != .custom {
            lastNonCustomQuickMode = mode
        } else {
            lastNonCustomQuickMode = .perDisplayCustom
        }
        pinnedSetupName = UserDefaults.standard.string(forKey: Keys.pinnedSetupName)
        recentLibraryItemIDs = Self.decodePersisted(
            [String].self, forKey: Keys.recentLibraryItemIDs, default: []
        )
        homeSidebarVisible = UserDefaults.standard.object(forKey: Keys.homeSidebarVisible) as? Bool ?? false
    }

    // Per-display mapping: displayID (as string) -> URL string
    var perDisplaySources: [String: String] {
        didSet { Self.persistEncoded(perDisplaySources, forKey: Keys.perDisplaySources) }
    }

    var videoFilePath: String {
        didSet { UserDefaults.standard.set(videoFilePath, forKey: Keys.videoPath) }
    }

    var videoBookmarkData: Data? {
        didSet { UserDefaults.standard.set(videoBookmarkData, forKey: Keys.videoBookmark) }
    }

    var rendererMode: WallpaperRendererMode {
        didSet { UserDefaults.standard.set(rendererMode.rawValue, forKey: Keys.rendererMode) }
    }

    var webURLString: String {
        didSet { UserDefaults.standard.set(webURLString, forKey: Keys.webURL) }
    }

    var isMuted: Bool {
        didSet { UserDefaults.standard.set(isMuted, forKey: Keys.isMuted) }
    }

    var scalingMode: VideoScalingMode {
        didSet { UserDefaults.standard.set(scalingMode.rawValue, forKey: Keys.scalingMode) }
    }
    
    var debugDiagnosticsEnabled: Bool {  // Chunk 4E: Debug diagnostics flag
        didSet { UserDefaults.standard.set(debugDiagnosticsEnabled, forKey: Keys.debugDiagnostics) }
    }

    var launchOnLoginEnabled: Bool {  // Phase 5G: Launch-on-login preference
        didSet { UserDefaults.standard.set(launchOnLoginEnabled, forKey: Keys.launchOnLogin) }
    }

    /// Phase 7A: Pause wallpapers when running on battery power.
    var pauseOnBattery: Bool {
        didSet { UserDefaults.standard.set(pauseOnBattery, forKey: Keys.pauseOnBattery) }
    }

    /// Phase 7A: Pause when internal battery is below `lowBatteryThreshold`.
    var pauseOnLowBattery: Bool {
        didSet { UserDefaults.standard.set(pauseOnLowBattery, forKey: Keys.pauseOnLowBattery) }
    }

    /// Phase 7A: Battery percentage threshold (1–100).
    var lowBatteryThreshold: Int {
        didSet {
            let clamped = min(100, max(1, lowBatteryThreshold))
            if clamped != lowBatteryThreshold {
                lowBatteryThreshold = clamped
                return
            }
            UserDefaults.standard.set(lowBatteryThreshold, forKey: Keys.lowBatteryThreshold)
        }
    }

    /// Phase 7B: Engine performance preset (visibility pause + decode tuning per profile).
    var performanceProfile: PerformanceProfile {
        didSet { UserDefaults.standard.set(performanceProfile.rawValue, forKey: Keys.performanceProfile) }
    }

    /// Phase 7C: User opted out of automatic performance profile suggestions.
    var dismissPerformanceSuggestions: Bool {
        didSet { UserDefaults.standard.set(dismissPerformanceSuggestions, forKey: Keys.dismissPerformanceSuggestions) }
    }

    /// Phase 7C.1: Lower suggestion thresholds for manual testing (Release builds).
    var useTestPerformanceSuggestionThresholds: Bool {
        didSet {
            UserDefaults.standard.set(useTestPerformanceSuggestionThresholds, forKey: Keys.useTestPerformanceSuggestionThresholds)
        }
    }

    /// Phase 8A: Security-scoped library root folders.
    var libraryRoots: [LibraryRoot] {
        didSet { Self.persistEncoded(libraryRoots, forKey: Keys.libraryRoots) }
    }

    /// Phase 8A: Indexed library catalog (ordered array for stable UI).
    var libraryItems: [LibraryItem] {
        didSet { Self.persistEncoded(libraryItems, forKey: Keys.libraryItems) }
    }

    /// Phase 8A: Timestamp of the last full library rescan.
    var libraryLastScanDate: Date? {
        didSet {
            if let libraryLastScanDate {
                UserDefaults.standard.set(libraryLastScanDate, forKey: Keys.libraryLastScanDate)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.libraryLastScanDate)
            }
        }
    }

    /// Phase 8A: Most recently previewed or applied library item.
    var lastUsedLibraryItemID: String? {
        didSet {
            if let lastUsedLibraryItemID {
                UserDefaults.standard.set(lastUsedLibraryItemID, forKey: Keys.lastUsedLibraryItemID)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.lastUsedLibraryItemID)
            }
        }
    }

    /// Phase 9A: Active quick mode preset (`.custom` when manual changes diverge).
    var quickMode: QuickMode {
        didSet { UserDefaults.standard.set(quickMode.rawValue, forKey: Keys.quickMode) }
    }

    /// Phase 9A: Last user-selected mode before drifting to `.custom`.
    var lastNonCustomQuickMode: QuickMode {
        didSet {
            let stored = lastNonCustomQuickMode == .custom ? QuickMode.perDisplayCustom : lastNonCustomQuickMode
            UserDefaults.standard.set(stored.rawValue, forKey: Keys.lastNonCustomQuickMode)
        }
    }

    /// Phase 9A: Setup name used when `quickMode == .pinnedSetup`.
    var pinnedSetupName: String? {
        didSet {
            if let pinnedSetupName {
                UserDefaults.standard.set(pinnedSetupName, forKey: Keys.pinnedSetupName)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.pinnedSetupName)
            }
        }
    }

    /// Phase 9B: Recent library items (most recent first, capped in `recordRecentLibraryItem`).
    var recentLibraryItemIDs: [String] {
        didSet { Self.persistEncoded(recentLibraryItemIDs, forKey: Keys.recentLibraryItemIDs) }
    }

    /// Home overlay sidebar visibility (persisted; default closed).
    var homeSidebarVisible: Bool {
        didSet { UserDefaults.standard.set(homeSidebarVisible, forKey: Keys.homeSidebarVisible) }
    }

    func recordRecentLibraryItem(id: String, maxCount: Int = 10) {
        var recents = recentLibraryItemIDs.filter { $0 != id }
        recents.insert(id, at: 0)
        if recents.count > maxCount {
            recents = Array(recents.prefix(maxCount))
        }
        recentLibraryItemIDs = recents
    }

    // Per-display mapping: displayID (as string) -> scaling mode
    var perDisplayScalingModes: [String: String] {
        didSet { Self.persistEncoded(perDisplayScalingModes, forKey: Keys.perDisplayScalingModes) }
    }

    // Per-display mapping: displayID (as string) -> renderer mode (Phase 7)
    var perDisplayRendererModes: [String: String] {
        didSet { Self.persistEncoded(perDisplayRendererModes, forKey: Keys.perDisplayRendererModes) }
    }

    // Per-display mapping: displayID (as string) -> security-scoped bookmark data
    var perDisplayBookmarks: [String: Data] {
        didSet { Self.persistEncoded(perDisplayBookmarks, forKey: Keys.perDisplayBookmarks) }
    }

    /// Maps a physical screen signature (name + resolution) to the UserDefaults key holding its wallpaper.
    var perDisplaySignatureKeys: [String: String] {
        didSet { Self.persistEncoded(perDisplaySignatureKeys, forKey: Keys.perDisplaySignatureKeys) }
    }

    func setPerDisplaySignatureKey(_ persistenceKey: String, settingsKey: String) {
        var map = perDisplaySignatureKeys
        map[persistenceKey] = settingsKey
        perDisplaySignatureKeys = map
    }

    // Whether the app should use per-display wallpapers (true) or a single unified wallpaper (false)
    var usePerDisplay: Bool {
        didSet { UserDefaults.standard.set(usePerDisplay, forKey: Keys.usePerDisplay) }
    }

    // Saved collections: keyed by collection name (unique identifier for user)
    var savedCollections: [String: WallpaperCollection] {
        didSet { Self.persistEncoded(savedCollections, forKey: Keys.savedCollections) }
    }

    // Collection bookmarks: keyed by collection name, then source URL; stores security-scoped bookmark data
    var collectionBookmarks: [String: [String: Data]] {
        didSet { Self.persistEncoded(collectionBookmarks, forKey: Keys.collectionBookmarks) }
    }

    // Most recently used collection name (for convenience in UI)
    var lastUsedCollectionName: String? {
        didSet {
            if let name = lastUsedCollectionName {
                UserDefaults.standard.set(name, forKey: Keys.lastUsedCollectionName)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.lastUsedCollectionName)
            }
        }
    }

    // MARK: - Collection CRUD Helpers

    /// Returns sorted list of all saved collection names.
    func allCollectionNames() -> [String] {
        savedCollections.keys.sorted()
    }

    /// Creates and persists a new collection with given parameters.
    func saveCollection(
        name: String,
        description: String = "",
        collectionType: WallpaperCollection.CollectionType = .simple,
        sources: [CollectionSource] = []
    ) -> Result<WallpaperCollection, WallpaperError> {
        do {
            let collection = try WallpaperCollection(
                name: name,
                description: description,
                collectionType: collectionType,
                sources: sources
            )
            savedCollections[name] = collection
            return .success(collection)
        } catch let error as WallpaperError {
            return .failure(error)
        } catch {
            return .failure(.internalError(description: "Failed to create collection: \(error.localizedDescription)"))
        }
    }

    /// Loads an existing collection by name.
    func loadCollection(name: String) -> Result<WallpaperCollection, WallpaperError> {
        guard let collection = savedCollections[name] else {
            return .failure(.collectionNotFound(name: name))
        }
        return .success(collection)
    }

    /// Updates an existing collection with new values.
    func updateCollection(
        name: String,
        newName: String? = nil,
        description: String? = nil,
        collectionType: WallpaperCollection.CollectionType? = nil,
        sources: [CollectionSource]? = nil
    ) -> Result<WallpaperCollection, WallpaperError> {
        guard let collection = savedCollections[name] else {
            return .failure(.collectionNotFound(name: name))
        }

        do {
            let updated = try collection.updated(
                name: newName,
                description: description,
                collectionType: collectionType,
                sources: sources
            )
            
            // If name changed, remove old entry and add with new name
            if let newName = newName, newName != name {
                savedCollections.removeValue(forKey: name)
                savedCollections[newName] = updated
                // Update lastUsedCollectionName if it was this collection
                if lastUsedCollectionName == name {
                    lastUsedCollectionName = newName
                }
            } else {
                savedCollections[name] = updated
            }
            
            return .success(updated)
        } catch let error as WallpaperError {
            return .failure(error)
        } catch {
            return .failure(.internalError(description: "Failed to update collection: \(error.localizedDescription)"))
        }
    }

    /// Deletes a collection by name.
    func deleteCollection(name: String) -> Result<Void, WallpaperError> {
        guard savedCollections.removeValue(forKey: name) != nil else {
            return .failure(.collectionNotFound(name: name))
        }
        
        // Clear lastUsedCollectionName if it was this collection
        if lastUsedCollectionName == name {
            lastUsedCollectionName = nil
        }
        
        return .success(())
    }

    // MARK: - Phase 6B: Setup Persistence

    // Saved setups: keyed by setup name (unique identifier for user)
    var savedSetups: [String: SavedSetup] {
        didSet { Self.persistEncoded(savedSetups, forKey: Keys.savedSetups) }
    }

    // Currently active setup name (for tracking which setup was last loaded)
    var currentSetupName: String? {
        didSet {
            if let name = currentSetupName {
                UserDefaults.standard.set(name, forKey: Keys.currentSetupName)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.currentSetupName)
            }
        }
    }

    // MARK: - Setup CRUD Helpers

    /// Returns sorted list of all saved setup names.
    func allSetupNames() -> [String] {
        savedSetups.keys.sorted()
    }

    /// Creates and persists a new setup with given parameters.
    func saveSetup(
        name: String,
        description: String = "",
        rendererMode: String,
        isMuted: Bool,
        scalingMode: String,
        usePerDisplay: Bool,
        unifiedSource: String?,
        perDisplaySources: [String: String],
        perDisplayScalingModes: [String: String],
        unifiedBookmarkBase64: String?,
        perDisplayBookmarksBase64: [String: String]
    ) -> Result<SavedSetup, WallpaperError> {
        // Validate name is not empty and unique
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.internalError(description: "Setup name cannot be empty."))
        }

        let setup = SavedSetup(
            name: name,
            description: description,
            rendererMode: rendererMode,
            isMuted: isMuted,
            scalingMode: scalingMode,
            usePerDisplay: usePerDisplay,
            unifiedSource: unifiedSource,
            perDisplaySources: perDisplaySources,
            perDisplayScalingModes: perDisplayScalingModes,
            unifiedBookmarkBase64: unifiedBookmarkBase64,
            perDisplayBookmarksBase64: perDisplayBookmarksBase64
        )
        savedSetups[name] = setup
        return .success(setup)
    }

    /// Loads an existing setup by name.
    func loadSetup(name: String) -> Result<SavedSetup, WallpaperError> {
        guard let setup = savedSetups[name] else {
            return .failure(.internalError(description: "Setup '\(name)' not found."))
        }
        return .success(setup)
    }

    /// Deletes a setup by name.
    func deleteSetup(name: String) -> Result<Void, WallpaperError> {
        guard savedSetups.removeValue(forKey: name) != nil else {
            return .failure(.internalError(description: "Setup '\(name)' not found."))
        }

        // Clear currentSetupName if it was this setup
        if currentSetupName == name {
            currentSetupName = nil
        }

        return .success(())
    }
}

enum VideoScalingMode: String, CaseIterable {
    case resizeAspectFill = "resizeAspectFill"
    case resizeAspect = "resizeAspect"
    case resizeAspectHeight = "resizeAspectHeight"

    var displayName: String {
        switch self {
        case .resizeAspectFill:
            return "Fill"
        case .resizeAspect:
            return "Fit"
        case .resizeAspectHeight:
            return "Stretch"
        }
    }

    var avLayerVideoGravity: AVLayerVideoGravity {
        switch self {
        case .resizeAspectFill:
            return .resizeAspectFill
        case .resizeAspect:
            return .resizeAspect
        case .resizeAspectHeight:
            return .resize
        }
    }
}

enum WallpaperRendererMode: String, CaseIterable {
    case video
    case web

    var displayName: String {
        switch self {
        case .video:
            return "Video"
        case .web:
            return "Web"
        }
    }
}
