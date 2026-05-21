import Foundation

/// Represents a complete snapshot of the wallpaper engine state.
/// Includes wallpaper sources, renderer mode, scaling, mute status, and per-display mappings.
struct SavedSetup: Codable, Identifiable {
    let id: String  // UUID
    let name: String
    let description: String
    let createdAt: Date
    let updatedAt: Date
    
    // Full state snapshot
    let rendererMode: String                    // WallpaperRendererMode.rawValue (.video or .web)
    let isMuted: Bool
    let scalingMode: String                     // VideoScalingMode.rawValue
    let usePerDisplay: Bool
    
    // Wallpaper sources
    let unifiedSource: String?                  // File path or URL (if unified mode)
    let perDisplaySources: [String: String]     // displayID (as string) → source
    let perDisplayScalingModes: [String: String] // displayID → scaling mode
    
    // Bookmarks (serialized as base64 for JSON compatibility)
    let unifiedBookmarkBase64: String?
    let perDisplayBookmarksBase64: [String: String]
    
    // MARK: - Initialization
    
    init(
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
    ) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.rendererMode = rendererMode
        self.isMuted = isMuted
        self.scalingMode = scalingMode
        self.usePerDisplay = usePerDisplay
        self.unifiedSource = unifiedSource
        self.perDisplaySources = perDisplaySources
        self.perDisplayScalingModes = perDisplayScalingModes
        self.unifiedBookmarkBase64 = unifiedBookmarkBase64
        self.perDisplayBookmarksBase64 = perDisplayBookmarksBase64
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, createdAt, updatedAt
        case rendererMode, isMuted, scalingMode, usePerDisplay
        case unifiedSource, perDisplaySources, perDisplayScalingModes
        case unifiedBookmarkBase64, perDisplayBookmarksBase64
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(rendererMode, forKey: .rendererMode)
        try container.encode(isMuted, forKey: .isMuted)
        try container.encode(scalingMode, forKey: .scalingMode)
        try container.encode(usePerDisplay, forKey: .usePerDisplay)
        try container.encode(unifiedSource, forKey: .unifiedSource)
        try container.encode(perDisplaySources, forKey: .perDisplaySources)
        try container.encode(perDisplayScalingModes, forKey: .perDisplayScalingModes)
        try container.encode(unifiedBookmarkBase64, forKey: .unifiedBookmarkBase64)
        try container.encode(perDisplayBookmarksBase64, forKey: .perDisplayBookmarksBase64)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        rendererMode = try container.decode(String.self, forKey: .rendererMode)
        isMuted = try container.decode(Bool.self, forKey: .isMuted)
        scalingMode = try container.decode(String.self, forKey: .scalingMode)
        usePerDisplay = try container.decode(Bool.self, forKey: .usePerDisplay)
        unifiedSource = try container.decodeIfPresent(String.self, forKey: .unifiedSource)
        perDisplaySources = try container.decode([String: String].self, forKey: .perDisplaySources)
        perDisplayScalingModes = try container.decode([String: String].self, forKey: .perDisplayScalingModes)
        unifiedBookmarkBase64 = try container.decodeIfPresent(String.self, forKey: .unifiedBookmarkBase64)
        perDisplayBookmarksBase64 = try container.decode([String: String].self, forKey: .perDisplayBookmarksBase64)
    }
}
