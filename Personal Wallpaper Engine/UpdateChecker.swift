import AppKit
import Foundation

/// Lightweight update channel placeholder until Sparkle or App Store distribution is chosen.
/// Opens the configured release page; no background network polling in v1.0.
enum UpdateChecker {
    static let releaseNotesURL = URL(string: "https://github.com/Personal-Wallpaper-Engine/Personal-Wallpaper-Engine/releases")!

    static var currentMarketingVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    static var currentBuildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    static func openReleasePage() {
        NSWorkspace.shared.open(releaseNotesURL)
    }
}
