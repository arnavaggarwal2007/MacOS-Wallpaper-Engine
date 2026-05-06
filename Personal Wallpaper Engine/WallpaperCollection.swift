import Foundation

// MARK: - Wallpaper Collection Models

/// A named collection of wallpaper sources that can be applied across displays.
/// Supports two collection types: simple (sequential) and display-bound (mapped).
struct WallpaperCollection: Codable, Identifiable {
    let id: String                           // UUID string for unique identification
    let name: String                         // User-provided; validated: non-empty, max 255 chars, no /, \, *
    let description: String                  // User-provided description (optional)
    let createdAt: Date                      // Timestamp of creation
    let updatedAt: Date                      // Timestamp of last update
    let collectionType: CollectionType       // .simple or .displayBound
    let sources: [CollectionSource]          // Ordered list of sources

    /// Collection type determines how sources are applied to displays.
    enum CollectionType: String, Codable {
        case simple       // Sources apply sequentially to available displays (1:1 by index)
        case displayBound // Each source tagged with display ID or label; applied only to matching displays
    }

    /// Creates a new wallpaper collection with auto-generated ID and current timestamp.
    /// Use this to create collections for persistence.
    init(
        name: String,
        description: String = "",
        collectionType: CollectionType = .simple,
        sources: [CollectionSource] = []
    ) throws {
        // Validate name before accepting
        guard isValidCollectionName(name) else {
            throw WallpaperError.invalidCollectionName(
                reason: "Name must be non-empty, max 255 characters, and contain no special characters (/, \\, *)."
            )
        }

        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.collectionType = collectionType
        self.sources = sources
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// Creates a collection from explicit values (used for decoding or testing).
    init(
        id: String,
        name: String,
        description: String,
        createdAt: Date,
        updatedAt: Date,
        collectionType: CollectionType,
        sources: [CollectionSource]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.collectionType = collectionType
        self.sources = sources
    }

    /// Returns a copy of this collection with updated fields.
    /// Used for editing collections before persistence.
    func updated(
        name: String? = nil,
        description: String? = nil,
        collectionType: CollectionType? = nil,
        sources: [CollectionSource]? = nil
    ) throws -> WallpaperCollection {
        let newName = name ?? self.name

        // Validate name if it's being changed
        if name != nil {
            guard isValidCollectionName(newName) else {
                throw WallpaperError.invalidCollectionName(
                    reason: "Name must be non-empty, max 255 characters, and contain no special characters (/, \\, *)."
                )
            }
        }

        return WallpaperCollection(
            id: self.id,
            name: newName,
            description: description ?? self.description,
            createdAt: self.createdAt,
            updatedAt: Date(),
            collectionType: collectionType ?? self.collectionType,
            sources: sources ?? self.sources
        )
    }
}

// MARK: - Wallpaper Collection Source

/// A single source (video file or web URL) within a collection.
/// Used by WallpaperCollection to track sources and optional display bindings.
struct CollectionSource: Codable, Identifiable {
    let id: String               // UUID string for unique identification
    let url: String              // File path (file:///) or HTTP(S) URL
    let displayLabel: String?    // For display-bound: human-readable label (e.g., "LG 4K", "Built-in Retina")
    let displayIDFallback: Int?  // For display-bound: numeric display ID fallback if label fails
    let scalingMode: String?     // Optional scaling mode (raw value of VideoScalingMode); if nil, use global default
    let order: Int               // Sequence in collection (for sorting)

    /// Creates a new source with auto-generated ID.
    init(
        url: String,
        displayLabel: String? = nil,
        displayIDFallback: Int? = nil,
        scalingMode: String? = nil,
        order: Int
    ) throws {
        // Validate URL format
        guard isValidSourceURL(url) else {
            throw WallpaperError.invalidCollectionSource(
                url: url,
                reason: "URL must be a valid file path (file:///) or HTTP(S) URL."
            )
        }

        self.id = UUID().uuidString
        self.url = url
        self.displayLabel = displayLabel
        self.displayIDFallback = displayIDFallback
        self.scalingMode = scalingMode
        self.order = order
    }

    /// Creates a source from explicit values (used for decoding or testing).
    init(
        id: String,
        url: String,
        displayLabel: String?,
        displayIDFallback: Int?,
        scalingMode: String?,
        order: Int
    ) {
        self.id = id
        self.url = url
        self.displayLabel = displayLabel
        self.displayIDFallback = displayIDFallback
        self.scalingMode = scalingMode
        self.order = order
    }
}

// MARK: - Validation Helpers

/// Validates that a collection name is acceptable for user input.
/// Rules:
/// - Non-empty string
/// - Maximum 255 characters
/// - No special characters: /, \, *
func isValidCollectionName(_ name: String) -> Bool {
    // Check not empty and within length limit
    guard !name.trimmingCharacters(in: .whitespaces).isEmpty && name.count <= 255 else {
        return false
    }

    // Check for forbidden characters
    let forbiddenCharacters = CharacterSet(charactersIn: "/\\*")
    return name.rangeOfCharacter(from: forbiddenCharacters) == nil
}

/// Validates that a source URL is acceptable for collection sources.
/// Rules:
/// - Non-empty string
/// - Either a file:// URL or HTTP(S) URL
func isValidSourceURL(_ urlString: String) -> Bool {
    // Check not empty
    guard !urlString.trimmingCharacters(in: .whitespaces).isEmpty else {
        return false
    }

    // Check for valid file or web URL format
    if urlString.hasPrefix("file:///") {
        return true // File URL
    }

    if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
        return true // Web URL
    }

    // Could be a local file path without file:// prefix; accept if it looks like a path
    // This is lenient but allows common user inputs
    if urlString.hasPrefix("/") || urlString.contains(".") {
        return true
    }

    return false
}

// MARK: - WallpaperError Extensions

extension WallpaperError {
    /// Collection was not found in saved collections.
    static func collectionNotFound(name: String) -> WallpaperError {
        return .internalError(description: "Collection '\(name)' not found. It may have been deleted.")
    }

    /// Collection name validation failed.
    static func invalidCollectionName(reason: String) -> WallpaperError {
        return .internalError(description: "Invalid collection name: \(reason)")
    }

    /// Source URL validation failed.
    static func invalidCollectionSource(url: String, reason: String) -> WallpaperError {
        return .internalError(description: "Invalid source URL '\(url)': \(reason)")
    }

    /// Display was not found or could not be matched for a display-bound collection.
    static func displayMismatchWarning(message: String) -> WallpaperError {
        return .internalError(description: "Display mismatch: \(message)")
    }
}
