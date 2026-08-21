import Foundation
import os.log

/// Holds security-scoped file access open for as long as a wallpaper is in use.
///
/// Access must outlive the call that applies a wallpaper. Renderers reopen the file well after that
/// call returns — on window resize, fallback recreation, engine restart, and resume from pause — and
/// in a sandboxed build those reopens fail once the scope has been closed. Closing the scope in a
/// `defer` around the apply call is therefore not sufficient.
///
/// Each owner (a display ID, or the unified wallpaper) holds at most one URL. `startAccessing…` is
/// balanced per call by the system, so two owners sharing one file each keep their own scope.
@MainActor
final class SecurityScopedAccessRegistry {
    /// Owner key for the single/unified wallpaper path.
    static let unifiedOwner = "unified"

    private var accessedURLs: [String: URL] = [:]
    private let logger = Logger(subsystem: "com.local.wallpaper", category: "SecurityScope")

    /// Begins access for `owner`, releasing whatever it held before.
    ///
    /// - Returns: `true` when the owner holds access to `url` afterwards. Non-file URLs need no
    ///   scope and return `false` without being tracked.
    @discardableResult
    func begin(_ url: URL, owner: String) -> Bool {
        guard url.isFileURL else {
            end(owner: owner)
            return false
        }

        if accessedURLs[owner] == url { return true }

        end(owner: owner)
        guard url.startAccessingSecurityScopedResource() else {
            logger.warning("Could not begin security-scoped access for owner \(owner, privacy: .public)")
            return false
        }

        accessedURLs[owner] = url
        return true
    }

    func end(owner: String) {
        guard let url = accessedURLs.removeValue(forKey: owner) else { return }
        url.stopAccessingSecurityScopedResource()
    }

    /// Releases owners outside `owners`, so scopes for disconnected displays are not held forever.
    func endAll(exceptOwners owners: Set<String>) {
        for owner in accessedURLs.keys where !owners.contains(owner) {
            end(owner: owner)
        }
    }

    func endAll() {
        for url in accessedURLs.values {
            url.stopAccessingSecurityScopedResource()
        }
        accessedURLs.removeAll()
    }

    func url(for owner: String) -> URL? { accessedURLs[owner] }

    var activeOwners: Set<String> { Set(accessedURLs.keys) }
}
