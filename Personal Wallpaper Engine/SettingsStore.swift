import Foundation
import AVFoundation

final class SettingsStore {
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
        static let savedCollections = "savedCollections"  // Phase 6A: Saved wallpaper collections
        static let collectionBookmarks = "collectionBookmarks"  // Phase 6A: Security-scoped bookmarks for collection sources
        static let lastUsedCollectionName = "lastUsedCollectionName"  // Phase 6A: Most recently used collection
        static let savedSetups = "savedSetups"  // Phase 6B: Saved desktop state snapshots
        static let currentSetupName = "currentSetupName"  // Phase 6B: Currently active setup name
    }

    private init() {
        videoFilePath = UserDefaults.standard.string(forKey: Keys.videoPath) ?? ""
        videoBookmarkData = UserDefaults.standard.data(forKey: Keys.videoBookmark)
        rendererMode = WallpaperRendererMode(rawValue: UserDefaults.standard.string(forKey: Keys.rendererMode) ?? WallpaperRendererMode.video.rawValue) ?? .video
        webURLString = UserDefaults.standard.string(forKey: Keys.webURL) ?? ""
        // Load per-display sources (JSON encoded dictionary)
        if let data = UserDefaults.standard.data(forKey: Keys.perDisplaySources) {
            if let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
                perDisplaySources = decoded
            } else {
                perDisplaySources = [:]
            }
        } else {
            perDisplaySources = [:]
        }
        isMuted = UserDefaults.standard.bool(forKey: Keys.isMuted)
        scalingMode = VideoScalingMode(rawValue: UserDefaults.standard.string(forKey: Keys.scalingMode) ?? VideoScalingMode.resizeAspectFill.rawValue) ?? .resizeAspectFill
        debugDiagnosticsEnabled = UserDefaults.standard.bool(forKey: Keys.debugDiagnostics)  // Chunk 4E
        launchOnLoginEnabled = UserDefaults.standard.bool(forKey: Keys.launchOnLogin)  // Phase 5G
        // Load per-display scaling modes (JSON encoded dictionary)
        if let data = UserDefaults.standard.data(forKey: Keys.perDisplayScalingModes) {
            if let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
                perDisplayScalingModes = decoded
            } else {
                perDisplayScalingModes = [:]
            }
        } else {
            perDisplayScalingModes = [:]
        }
        // Load per-display renderer modes (JSON encoded dictionary) - Phase 7
        if let data = UserDefaults.standard.data(forKey: Keys.perDisplayRendererModes) {
            if let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
                perDisplayRendererModes = decoded
            } else {
                perDisplayRendererModes = [:]
            }
        } else {
            perDisplayRendererModes = [:]
        }
        usePerDisplay = true
        UserDefaults.standard.set(true, forKey: Keys.usePerDisplay)
        if let data = UserDefaults.standard.data(forKey: Keys.perDisplayBookmarks) {
            if let decoded = try? JSONDecoder().decode([String: Data].self, from: data) {
                perDisplayBookmarks = decoded
            } else {
                perDisplayBookmarks = [:]
            }
        } else {
            perDisplayBookmarks = [:]
        }
        // Load saved collections (Phase 6A): JSON encoded dictionary of collections keyed by name
        if let data = UserDefaults.standard.data(forKey: Keys.savedCollections) {
            if let decoded = try? JSONDecoder().decode([String: WallpaperCollection].self, from: data) {
                savedCollections = decoded
            } else {
                savedCollections = [:]
            }
        } else {
            savedCollections = [:]
        }
        // Load collection bookmarks (Phase 6A): JSON encoded dictionary keyed by collection name, then source URL
        if let data = UserDefaults.standard.data(forKey: Keys.collectionBookmarks) {
            if let decoded = try? JSONDecoder().decode([String: [String: Data]].self, from: data) {
                collectionBookmarks = decoded
            } else {
                collectionBookmarks = [:]
            }
        } else {
            collectionBookmarks = [:]
        }
        lastUsedCollectionName = UserDefaults.standard.string(forKey: Keys.lastUsedCollectionName)
        // Load saved setups (Phase 6B): JSON encoded dictionary of setups keyed by name
        if let data = UserDefaults.standard.data(forKey: Keys.savedSetups) {
            if let decoded = try? JSONDecoder().decode([String: SavedSetup].self, from: data) {
                savedSetups = decoded
            } else {
                savedSetups = [:]
            }
        } else {
            savedSetups = [:]
        }
        currentSetupName = UserDefaults.standard.string(forKey: Keys.currentSetupName)
    }

    // Per-display mapping: displayID (as string) -> URL string
    var perDisplaySources: [String: String] {
        didSet {
            if let encoded = try? JSONEncoder().encode(perDisplaySources) {
                UserDefaults.standard.set(encoded, forKey: Keys.perDisplaySources)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.perDisplaySources)
            }
        }
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

    // Per-display mapping: displayID (as string) -> scaling mode
    var perDisplayScalingModes: [String: String] {
        didSet {
            if let encoded = try? JSONEncoder().encode(perDisplayScalingModes) {
                UserDefaults.standard.set(encoded, forKey: Keys.perDisplayScalingModes)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.perDisplayScalingModes)
            }
        }
    }

    // Per-display mapping: displayID (as string) -> renderer mode (Phase 7)
    var perDisplayRendererModes: [String: String] {
        didSet {
            if let encoded = try? JSONEncoder().encode(perDisplayRendererModes) {
                UserDefaults.standard.set(encoded, forKey: Keys.perDisplayRendererModes)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.perDisplayRendererModes)
            }
        }
    }

    // Per-display mapping: displayID (as string) -> security-scoped bookmark data
    var perDisplayBookmarks: [String: Data] {
        didSet {
            if let encoded = try? JSONEncoder().encode(perDisplayBookmarks) {
                UserDefaults.standard.set(encoded, forKey: Keys.perDisplayBookmarks)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.perDisplayBookmarks)
            }
        }
    }

    // Whether the app should use per-display wallpapers (true) or a single unified wallpaper (false)
    var usePerDisplay: Bool {
        didSet { UserDefaults.standard.set(usePerDisplay, forKey: Keys.usePerDisplay) }
    }

    // Saved collections: keyed by collection name (unique identifier for user)
    var savedCollections: [String: WallpaperCollection] {
        didSet {
            if let encoded = try? JSONEncoder().encode(savedCollections) {
                UserDefaults.standard.set(encoded, forKey: Keys.savedCollections)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.savedCollections)
            }
        }
    }

    // Collection bookmarks: keyed by collection name, then source URL; stores security-scoped bookmark data
    var collectionBookmarks: [String: [String: Data]] {
        didSet {
            if let encoded = try? JSONEncoder().encode(collectionBookmarks) {
                UserDefaults.standard.set(encoded, forKey: Keys.collectionBookmarks)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.collectionBookmarks)
            }
        }
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
        didSet {
            if let encoded = try? JSONEncoder().encode(savedSetups) {
                UserDefaults.standard.set(encoded, forKey: Keys.savedSetups)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.savedSetups)
            }
        }
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
