import Foundation

/// User-facing performance preset (Phase 7B).
enum PerformanceProfile: String, CaseIterable, Codable, Identifiable {
    case maxQuality
    case balanced
    case batterySaver

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .maxQuality: return "Max Quality"
        case .balanced: return "Balanced"
        case .batterySaver: return "Battery Saver"
        }
    }

    var caption: String {
        switch self {
        case .maxQuality:
            return "Full resolution, live hero on every tab (dimmed on Settings), desktop keeps playing when covered."
        case .balanced:
            return "Recommended — 1080p decode cap on 4K sources, static hero on Settings tabs, pauses when not visible."
        case .batterySaver:
            return "Lowest power — 1080p cap + lower bitrate, same pause rules as Balanced, Web idle when paused."
        }
    }

    /// Balanced/Battery Saver: pause hero when window occluded (P1b); desktop occlusion pause in P3.
    var pausesWhenOccluded: Bool {
        switch self {
        case .maxQuality: return false
        case .balanced, .batterySaver: return true
        }
    }
}
