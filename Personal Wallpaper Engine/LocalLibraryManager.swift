import AppKit
import AVFoundation
import Foundation
import os

/// Indexes user-selected folders and maintains the wallpaper library catalog (Phase 8A–8B).
@MainActor
final class LocalLibraryManager {
    static let shared = LocalLibraryManager()

    private let settings = SettingsStore.shared
    private let thumbnailCache = LibraryThumbnailCache.shared
    private let logger = Logger(subsystem: "com.local.wallpaper", category: "LocalLibraryManager")

    private init() {}

    var roots: [LibraryRoot] {
        settings.libraryRoots
    }

    var items: [LibraryItem] {
        settings.libraryItems
    }

    func loadFromSettings() {
        // Catalog is already in SettingsStore; prune orphaned thumbnails on load.
        let ids = Set(settings.libraryItems.map(\.id))
        thumbnailCache.removeAll(notIn: ids)
    }

    func addLibraryRoot(at url: URL) -> Result<LibraryRoot, WallpaperError> {
        let standardized = url.standardizedFileURL
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: standardized.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return .failure(.libraryBookmarkFailed(reason: "Selected path is not a folder."))
        }

        if settings.libraryRoots.contains(where: { $0.path == standardized.path }) {
            return .failure(.libraryBookmarkFailed(reason: "That folder is already in your library."))
        }

        let didAccess = standardized.startAccessingSecurityScopedResource()
        defer {
            if didAccess { standardized.stopAccessingSecurityScopedResource() }
        }

        do {
            let bookmark = try standardized.bookmarkData(
                options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            let root = LibraryRoot(url: standardized, bookmarkData: bookmark)
            settings.libraryRoots.append(root)
            return .success(root)
        } catch {
            return .failure(.libraryBookmarkFailed(reason: error.localizedDescription))
        }
    }

    func removeLibraryRoot(id: String) -> Result<Void, WallpaperError> {
        guard let index = settings.libraryRoots.firstIndex(where: { $0.id == id }) else {
            return .failure(.libraryRootNotFound(id: id))
        }
        let root = settings.libraryRoots[index]
        settings.libraryRoots.remove(at: index)

        let removedIDs = settings.libraryItems.filter { $0.rootID == root.id }.map(\.id)
        settings.libraryItems.removeAll { $0.rootID == root.id }
        for itemID in removedIDs {
            thumbnailCache.remove(itemID: itemID)
        }
        return .success(())
    }

    func rescanLibrary() async -> Result<[LibraryItem], WallpaperError> {
        let roots = settings.libraryRoots
        guard !roots.isEmpty else {
            settings.libraryItems = []
            settings.libraryLastScanDate = Date()
            thumbnailCache.clearAll()
            return .success([])
        }

        let existingByID = Dictionary(uniqueKeysWithValues: settings.libraryItems.map { ($0.id, $0) })
        let existingByPath = Dictionary(uniqueKeysWithValues: settings.libraryItems.map { ($0.filePath, $0) })

        let scanned = await Task.detached(priority: .utility) {
            Self.scanLibrary(roots: roots, existingByPath: existingByPath)
        }.value

        var merged: [LibraryItem] = []
        var seenIDs = Set<String>()

        for var item in scanned {
            if let previous = existingByID[item.id] {
                item.favorited = previous.favorited
            }
            merged.append(item)
            seenIDs.insert(item.id)
        }

        for previous in settings.libraryItems where !seenIDs.contains(previous.id) {
            var stale = previous
            stale.isMissing = true
            merged.append(stale)
        }

        merged.sort { lhs, rhs in
            if lhs.isMissing != rhs.isMissing { return !lhs.isMissing }
            return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
        }

        settings.libraryItems = merged
        settings.libraryLastScanDate = Date()
        thumbnailCache.removeAll(notIn: Set(merged.filter { !$0.isMissing }.map(\.id)))

        await enrichMetadata(for: merged.filter { !$0.isMissing })

        logger.info("Library scan complete — \(merged.filter { !$0.isMissing }.count) items, \(merged.filter(\.isMissing).count) missing")
        return .success(settings.libraryItems)
    }

    func toggleFavorite(itemID: String) -> Result<LibraryItem, WallpaperError> {
        guard let index = settings.libraryItems.firstIndex(where: { $0.id == itemID }) else {
            return .failure(.libraryItemNotFound(id: itemID))
        }
        settings.libraryItems[index].favorited.toggle()
        return .success(settings.libraryItems[index])
    }

    func markLastUsed(itemID: String) {
        settings.lastUsedLibraryItemID = itemID
    }

    func resolveURL(for item: LibraryItem) -> URL? {
        Self.resolveFileURL(for: item)
    }

    func refreshBookmark(for itemID: String, url: URL) {
        guard let index = settings.libraryItems.firstIndex(where: { $0.id == itemID }) else { return }
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess { url.stopAccessingSecurityScopedResource() }
        }
        guard let bookmark = try? url.bookmarkData(
            options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else { return }
        settings.libraryItems[index].bookmarkData = bookmark
        settings.libraryItems[index].isMissing = false
        settings.libraryItems[index].filePath = url.standardizedFileURL.path
    }

    func thumbnail(for item: LibraryItem) async -> NSImage? {
        guard let url = resolveURL(for: item) else { return nil }
        return await thumbnailCache.image(for: item, resolvedURL: url)
    }

    func cacheByteCount() -> Int64 {
        thumbnailCache.totalByteCount()
    }

    func cacheEntryCount() -> Int {
        thumbnailCache.entryCount()
    }

    // MARK: - Metadata (8B)

    private func enrichMetadata(for items: [LibraryItem]) async {
        guard !items.isEmpty else { return }
        var updates: [String: LibraryItem] = [:]

        await withTaskGroup(of: (String, LibraryItem?).self) { group in
            for item in items {
                group.addTask {
                    guard let url = Self.resolveFileURL(for: item) else {
                        return (item.id, nil)
                    }
                    let enriched = await Self.extractMetadata(for: item, url: url)
                    return (item.id, enriched)
                }
            }
            for await (id, enriched) in group {
                if let enriched { updates[id] = enriched }
            }
        }

        guard !updates.isEmpty else { return }
        var catalog = settings.libraryItems
        for index in catalog.indices {
            if let updated = updates[catalog[index].id] {
                catalog[index].duration = updated.duration
                catalog[index].width = updated.width
                catalog[index].height = updated.height
                catalog[index].codec = updated.codec
                catalog[index].contentModificationDate = updated.contentModificationDate
            }
        }
        settings.libraryItems = catalog
    }

    nonisolated private static func resolveFileURL(for item: LibraryItem) -> URL? {
        if let bookmarkData = item.bookmarkData {
            var stale = false
            if let url = try? URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &stale
            ), FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        let pathURL = URL(fileURLWithPath: item.filePath)
        if FileManager.default.fileExists(atPath: pathURL.path) {
            return pathURL
        }
        return nil
    }

    nonisolated private static func extractMetadata(for item: LibraryItem, url: URL) async -> LibraryItem? {
        var updated = item
        let values = try? url.resourceValues(forKeys: [.contentModificationDateKey])
        updated.contentModificationDate = values?.contentModificationDate

        let asset = AVURLAsset(url: url)
        let duration = try? await asset.load(.duration)
        if let duration, duration.isNumeric {
            updated.duration = CMTimeGetSeconds(duration)
        }

        if let track = try? await asset.loadTracks(withMediaType: .video).first {
            let size = try? await track.load(.naturalSize)
            if let size {
                updated.width = Int(abs(size.width.rounded()))
                updated.height = Int(abs(size.height.rounded()))
            }
            let descriptions = try? await track.load(.formatDescriptions)
            if let format = descriptions?.first {
                let codec = CMFormatDescriptionGetMediaSubType(format)
                updated.codec = fourCCString(codec)
            }
        }
        return updated
    }

    nonisolated private static func fourCCString(_ code: FourCharCode) -> String {
        let bytes: [UInt8] = [
            UInt8((code >> 24) & 0xFF),
            UInt8((code >> 16) & 0xFF),
            UInt8((code >> 8) & 0xFF),
            UInt8(code & 0xFF)
        ]
        return String(bytes: bytes, encoding: .macOSRoman) ?? "video"
    }

    nonisolated private static func scanLibrary(
        roots: [LibraryRoot],
        existingByPath: [String: LibraryItem]
    ) -> [LibraryItem] {
        var items: [LibraryItem] = []
        var seenPaths = Set<String>()

        for root in roots {
            guard let rootURL = resolveRootURL(root) else { continue }
            let didAccess = rootURL.startAccessingSecurityScopedResource()
            defer {
                if didAccess { rootURL.stopAccessingSecurityScopedResource() }
            }

            guard let enumerator = FileManager.default.enumerator(
                at: rootURL,
                includingPropertiesForKeys: [.isRegularFileKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { continue }

            for case let fileURL as URL in enumerator {
                guard LibraryItem.isSupportedVideoFile(fileURL) else { continue }
                let standardizedPath = fileURL.standardizedFileURL.path
                guard seenPaths.insert(standardizedPath).inserted else { continue }

                let modDate = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                let bookmark = try? fileURL.bookmarkData(
                    options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )

                if var existing = existingByPath[standardizedPath] {
                    existing.isMissing = false
                    existing.bookmarkData = bookmark ?? existing.bookmarkData
                    existing.contentModificationDate = modDate
                    items.append(existing)
                    continue
                }

                let item = LibraryItem(
                    id: LibraryItem.makeID(forPath: standardizedPath),
                    filePath: standardizedPath,
                    bookmarkData: bookmark,
                    displayName: fileURL.lastPathComponent,
                    rootID: root.id,
                    rootDisplayName: root.displayName,
                    duration: nil,
                    width: nil,
                    height: nil,
                    codec: nil,
                    favorited: false,
                    addedAt: Date(),
                    isMissing: false,
                    contentModificationDate: modDate
                )
                items.append(item)
            }
        }

        return items
    }

    nonisolated private static func resolveRootURL(_ root: LibraryRoot) -> URL? {
        var stale = false
        if let url = try? URL(
            resolvingBookmarkData: root.bookmarkData,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &stale
        ), FileManager.default.fileExists(atPath: url.path) {
            return url
        }
        let pathURL = URL(fileURLWithPath: root.path)
        if FileManager.default.fileExists(atPath: pathURL.path) {
            return pathURL
        }
        return nil
    }
}
