import AppKit
import Foundation

/// Update channel: Direct opens the release page; Mac App Store relies on
/// App Store updates only (App Review guideline 3.1.1).
enum UpdateChecker {
    static var isAppStoreBuild: Bool {
        #if APP_STORE_BUILD
        true
        #else
        false
        #endif
    }

    static var currentMarketingVersion: String {
        AppInfo.marketingVersion
    }

    static var currentBuildNumber: String {
        AppInfo.buildNumber
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
        NSWorkspace.shared.open(AppLinks.releaseNotes)
        #endif
    }
}
