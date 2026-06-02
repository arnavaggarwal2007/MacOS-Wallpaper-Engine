import CryptoKit
import Foundation

/// A user-selected folder root indexed by the local library (Phase 8A).
struct LibraryRoot: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let path: String
    let bookmarkData: Data
    let displayName: String
    let addedAt: Date

    init(id: String = UUID().uuidString, url: URL, bookmarkData: Data, addedAt: Date = Date()) {
        self.id = id
        self.path = url.standardizedFileURL.path
        self.bookmarkData = bookmarkData
        self.displayName = url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent
        self.addedAt = addedAt
    }
}

/// A video file discovered under one or more library roots (Phase 8A).
struct LibraryItem: Codable, Identifiable, Equatable, Sendable {
    let id: String
    var filePath: String
    var bookmarkData: Data?
    let displayName: String
    let rootID: String
    let rootDisplayName: String
    var duration: TimeInterval?
    var width: Int?
    var height: Int?
    var codec: String?
    var favorited: Bool
    let addedAt: Date
    var isMissing: Bool
    var contentModificationDate: Date?

    var resolutionLabel: String? {
        guard let width, let height, width > 0, height > 0 else { return nil }
        if max(width, height) >= 3840 { return "4K" }
        if max(width, height) >= 2560 { return "1440p" }
        if max(width, height) >= 1920 { return "1080p" }
        return "\(width)×\(height)"
    }

    var durationLabel: String? {
        guard let duration, duration > 0 else { return nil }
        if duration < 60 { return "\(Int(duration.rounded()))s" }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return seconds == 0 ? "\(minutes)m" : "\(minutes)m \(seconds)s"
    }

    nonisolated static func makeID(forPath path: String) -> String {
        let digest = SHA256.hash(data: Data(path.utf8))
        return digest.map { String(format: "%02x", $0) }.joined().prefix(32).description
    }

    nonisolated static var supportedVideoExtensions: Set<String> {
        ["mp4", "mov", "m4v"]
    }

    nonisolated static func isSupportedVideoFile(_ url: URL) -> Bool {
        supportedVideoExtensions.contains(url.pathExtension.lowercased())
    }
}

// MARK: - WallpaperError Extensions (Phase 8)

extension WallpaperError {
    static func libraryRootNotFound(id: String) -> WallpaperError {
        .internalError(description: "Library folder not found. It may have been removed.")
    }

    static func libraryItemNotFound(id: String) -> WallpaperError {
        .internalError(description: "Library item not found. Try rescanning your library.")
    }

    static func libraryItemUnavailable(path: String) -> WallpaperError {
        .internalError(description: "Video is missing or unavailable: \(URL(fileURLWithPath: path).lastPathComponent)")
    }

    static func libraryBookmarkFailed(reason: String) -> WallpaperError {
        .internalError(description: "Could not access library folder: \(reason)")
    }
}
