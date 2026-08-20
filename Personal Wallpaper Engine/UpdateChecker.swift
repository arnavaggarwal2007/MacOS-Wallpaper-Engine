import AppKit
import Foundation

/// Update channel: Direct opens release page; Mac App Store uses App Store updates only.
enum UpdateChecker {
    #if !APP_STORE_BUILD
    static let releaseNotesURL = URL(string: "https://github.com/Personal-Wallpaper-Engine/Personal-Wallpaper-Engine/releases")!
    #endif

    static var isAppStoreBuild: Bool {
        #if APP_STORE_BUILD
        true
        #else
        false
        #endif
    }

    static var currentMarketingVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    static var currentBuildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    static var updatesDescription: String {
        if isAppStoreBuild {
            return "Updates are delivered through the Mac App Store."
        }
        return "Check GitHub releases for updates (Sparkle integration planned)."
    }

    static func openReleasePage() {
        #if APP_STORE_BUILD
        return
        #else
        NSWorkspace.shared.open(releaseNotesURL)
        #endif
    }
}
