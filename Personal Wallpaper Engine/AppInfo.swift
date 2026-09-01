import Foundation

/// Bundle identity shown in the UI. Reads Info.plist so a display-name change
/// (`INFOPLIST_KEY_CFBundleDisplayName`) never requires touching Swift code.
enum AppInfo {
    static let fallbackDisplayName = "Loopscape"

    static var displayName: String {
        let info = Bundle.main.infoDictionary
        let candidates = [
            info?["CFBundleDisplayName"] as? String,
            info?["CFBundleName"] as? String
        ]
        return candidates
            .compactMap { $0 }
            .first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            ?? fallbackDisplayName
    }

    static var marketingVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
