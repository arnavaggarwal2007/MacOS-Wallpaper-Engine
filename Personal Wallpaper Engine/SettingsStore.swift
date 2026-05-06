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
        static let usePerDisplay = "usePerDisplay" // Bool: whether to use per-display wallpapers
        static let perDisplayBookmarks = "perDisplayBookmarks" // Per-display security-scoped bookmarks
        static let savedCollections = "savedCollections"  // Phase 6A: Saved wallpaper collections
        static let lastUsedCollectionName = "lastUsedCollectionName"  // Phase 6A: Most recently used collection
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
        usePerDisplay = UserDefaults.standard.bool(forKey: Keys.usePerDisplay)
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
        lastUsedCollectionName = UserDefaults.standard.string(forKey: Keys.lastUsedCollectionName)
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
