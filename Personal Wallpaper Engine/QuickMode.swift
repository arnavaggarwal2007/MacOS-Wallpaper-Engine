import Foundation

/// High-level wallpaper configuration intent (Phase 9A).
enum QuickMode: String, Codable, CaseIterable, Identifiable {
    case singleAllDisplays
    case perDisplayCustom
    case pinnedSetup
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .singleAllDisplays: return "Single — All Displays"
        case .perDisplayCustom: return "Per Display"
        case .pinnedSetup: return "Pinned Setup"
        case .custom: return "Custom"
        }
    }

    var shortName: String {
        switch self {
        case .singleAllDisplays: return "Single All"
        case .perDisplayCustom: return "Per Display"
        case .pinnedSetup: return "Pinned Setup"
        case .custom: return "Custom"
        }
    }

    var caption: String {
        switch self {
        case .singleAllDisplays:
            return "One wallpaper mirrored to every connected display."
        case .perDisplayCustom:
            return "Configure and apply wallpapers independently per display."
        case .pinnedSetup:
            return "Restore a favorite saved desktop setup in one step."
        case .custom:
            return "Manual changes differ from the selected quick mode."
        }
    }

    /// Modes the user can pick from the selector (excludes derived Custom).
    static var selectableCases: [QuickMode] {
        [.singleAllDisplays, .perDisplayCustom, .pinnedSetup]
    }
}

/// Shell tab targets for menu-bar and deep-link navigation.
enum ShellTab: String, Hashable {
    case home
    case collections
    case setups
    case settings
}

struct ShellNavigationRequest: Equatable {
    let tab: ShellTab?
    let activateWindow: Bool

    static func open(tab: ShellTab) -> ShellNavigationRequest {
        ShellNavigationRequest(tab: tab, activateWindow: true)
    }
}
