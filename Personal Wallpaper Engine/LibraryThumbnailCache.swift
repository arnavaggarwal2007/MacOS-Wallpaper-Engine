import AppKit
import AVFoundation
import Foundation

/// Disk-backed thumbnail cache for library items with LRU eviction (Phase 8B).
final class LibraryThumbnailCache: @unchecked Sendable {
    static let shared = LibraryThumbnailCache()

    private struct IndexEntry: Codable {
        let itemID: String
        let fileName: String
        let byteCount: Int64
        var lastAccess: Date
        var contentModificationDate: TimeInterval?
    }

    private struct IndexFile: Codable {
        var entries: [IndexEntry]
    }

    private let maxCacheBytes: Int64 = 500 * 1024 * 1024
    private let thumbnailSize = CGSize(width: 512, height: 512)
    private let cacheDirectory: URL
    private let indexURL: URL
    private let lock = NSLock()
    private var index = IndexFile(entries: [])

    private init() {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("com.local.wallpaper", isDirectory: true)
        cacheDirectory = base.appendingPathComponent("library-thumbnails", isDirectory: true)
        indexURL = base.appendingPathComponent("library-thumbnails-index.json")
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        loadIndex()
    }

    func cachedImage(for itemID: String) -> NSImage? {
        lock.lock()
        defer { lock.unlock() }
        guard let entry = index.entries.first(where: { $0.itemID == itemID }) else { return nil }
        let fileURL = cacheDirectory.appendingPathComponent(entry.fileName)
        guard let data = try? Data(contentsOf: fileURL), let image = NSImage(data: data) else {
            removeEntry(itemID: itemID)
            return nil
        }
        touchEntry(itemID: itemID)
        persistIndexLocked()
        return image
    }

    func image(for item: LibraryItem, resolvedURL: URL) async -> NSImage? {
        if item.isMissing { return nil }
        if let mod = item.contentModificationDate,
           isStale(itemID: item.id, contentModificationDate: mod),
           cachedImage(for: item.id) != nil {
            remove(itemID: item.id)
        }
        if let cached = cachedImage(for: item.id) {
            return cached
        }
        return await generateAndStore(itemID: item.id, url: resolvedURL, contentModificationDate: item.contentModificationDate)
    }

    func remove(itemID: String) {
        lock.lock()
        defer { lock.unlock() }
        removeEntry(itemID: itemID)
        persistIndexLocked()
    }

    func removeAll(notIn itemIDs: Set<String>) {
        lock.lock()
        defer { lock.unlock() }
        let stale = index.entries.filter { !itemIDs.contains($0.itemID) }
        for entry in stale {
            let fileURL = cacheDirectory.appendingPathComponent(entry.fileName)
            try? FileManager.default.removeItem(at: fileURL)
        }
        index.entries.removeAll { !itemIDs.contains($0.itemID) }
        persistIndexLocked()
    }

    func totalByteCount() -> Int64 {
        lock.lock()
        defer { lock.unlock() }
        return index.entries.reduce(0) { $0 + $1.byteCount }
    }

    func entryCount() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return index.entries.count
    }

    func clearAll() {
        lock.lock()
        defer { lock.unlock() }
        for entry in index.entries {
            let fileURL = cacheDirectory.appendingPathComponent(entry.fileName)
            try? FileManager.default.removeItem(at: fileURL)
        }
        index.entries = []
        persistIndexLocked()
    }

    // MARK: - Private

    private func isStale(itemID: String, contentModificationDate: Date) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard let entry = index.entries.first(where: { $0.itemID == itemID }),
              let stored = entry.contentModificationDate else { return false }
        return abs(stored - contentModificationDate.timeIntervalSince1970) > 0.5
    }

    private func generateAndStore(itemID: String, url: URL, contentModificationDate: Date?) async -> NSImage? {
        let image = await Self.generateThumbnail(for: url, maximumSize: thumbnailSize)
        guard let image, let data = jpegData(from: image) else { return nil }
        storeJPEG(data, itemID: itemID, contentModificationDate: contentModificationDate)
        return image
    }

    private func storeJPEG(_ data: Data, itemID: String, contentModificationDate: Date?) {
        lock.lock()
        defer { lock.unlock() }
        removeEntry(itemID: itemID)
        let fileName = "\(itemID).jpg"
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            return
        }
        let entry = IndexEntry(
            itemID: itemID,
            fileName: fileName,
            byteCount: Int64(data.count),
            lastAccess: Date(),
            contentModificationDate: contentModificationDate?.timeIntervalSince1970
        )
        index.entries.append(entry)
        enforceSizeLimitLocked()
        persistIndexLocked()
    }

    private func touchEntry(itemID: String) {
        guard let idx = index.entries.firstIndex(where: { $0.itemID == itemID }) else { return }
        index.entries[idx].lastAccess = Date()
    }

    private func removeEntry(itemID: String) {
        guard let idx = index.entries.firstIndex(where: { $0.itemID == itemID }) else { return }
        let fileURL = cacheDirectory.appendingPathComponent(index.entries[idx].fileName)
        try? FileManager.default.removeItem(at: fileURL)
        index.entries.remove(at: idx)
    }

    private func enforceSizeLimitLocked() {
        var total = index.entries.reduce(Int64(0)) { $0 + $1.byteCount }
        guard total > maxCacheBytes else { return }
        index.entries.sort { $0.lastAccess < $1.lastAccess }
        while total > maxCacheBytes, let oldest = index.entries.first {
            let fileURL = cacheDirectory.appendingPathComponent(oldest.fileName)
            try? FileManager.default.removeItem(at: fileURL)
            total -= oldest.byteCount
            index.entries.removeFirst()
        }
    }

    private func loadIndex() {
        lock.lock()
        defer { lock.unlock() }
        guard let data = try? Data(contentsOf: indexURL),
              let decoded = try? JSONDecoder().decode(IndexFile.self, from: data) else { return }
        index = decoded
    }

    private func persistIndexLocked() {
        guard let data = try? JSONEncoder().encode(index) else { return }
        try? data.write(to: indexURL, options: .atomic)
    }

    private static func generateThumbnail(for url: URL, maximumSize: CGSize) async -> NSImage? {
        guard url.isFileURL, FileManager.default.fileExists(atPath: url.path) else { return nil }
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = maximumSize
        let time = CMTime(seconds: 1, preferredTimescale: 600)

        return await withCheckedContinuation { continuation in
            generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, result, _ in
                guard result == .succeeded, let cgImage else {
                    continuation.resume(returning: nil)
                    return
                }
                let image = NSImage(
                    cgImage: cgImage,
                    size: NSSize(width: cgImage.width, height: cgImage.height)
                )
                continuation.resume(returning: image)
            }
        }
    }

    private func jpegData(from image: NSImage) -> Data? {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.82])
    }
}
