import Foundation

/// Shared screen-saver settings and the copy into the App Group container.
///
/// The desktop engine does not load in the `.saver` process. Both targets compile this file.
/// The saver only reads `Snapshot`. The app publishes a video by copying it into the group
/// container, because app-scoped bookmarks do not open in the screen-saver host.
nonisolated enum ScreensaverConfig: Sendable {
    static let appGroupIdentifier = "group.Personal.Personal-Wallpaper-Engine"
    static let mediaDirectoryName = "Screensaver"
    static let placeholderMessage = "Open Deskface and choose a video"

    enum Key {
        static let videoPath = "saver.videoPath"
        static let scalingMode = "saver.scalingMode"
        static let syncWithDesktop = "saver.syncWithDesktop"
        static let muted = "saver.muted"
        static let lastUpdated = "saver.lastUpdated"
        static let sourceIdentity = "saver.sourceIdentity"
    }

    enum Scaling {
        static let fill = "resizeAspectFill"
        static let fit = "resizeAspect"
        static let stretch = "resizeAspectHeight"
        static let all = [fill, fit, stretch]
    }

    private static let videoExtensions: Set<String> = ["mp4", "mov", "m4v"]

    struct Snapshot: Equatable, Sendable {
        var videoPath: String?
        var scalingMode: String
        var syncWithDesktop: Bool
        var muted: Bool
        var lastUpdated: Date?
        var sourceIdentity: String?

        static let empty = Snapshot(
            videoPath: nil,
            scalingMode: Scaling.fill,
            syncWithDesktop: false,
            muted: true,
            lastUpdated: nil,
            sourceIdentity: nil
        )

        static func read(from defaults: UserDefaults) -> Snapshot {
            let scaling = defaults.string(forKey: Key.scalingMode) ?? Scaling.fill
            let updated = defaults.object(forKey: Key.lastUpdated) as? Date
            return Snapshot(
                videoPath: defaults.string(forKey: Key.videoPath),
                scalingMode: normalizedScaling(scaling),
                syncWithDesktop: defaults.bool(forKey: Key.syncWithDesktop),
                muted: defaults.object(forKey: Key.muted) as? Bool ?? true,
                lastUpdated: updated,
                sourceIdentity: defaults.string(forKey: Key.sourceIdentity)
            )
        }

        func write(to defaults: UserDefaults) {
            if let videoPath {
                defaults.set(videoPath, forKey: Key.videoPath)
            } else {
                defaults.removeObject(forKey: Key.videoPath)
            }
            defaults.set(scalingMode, forKey: Key.scalingMode)
            defaults.set(syncWithDesktop, forKey: Key.syncWithDesktop)
            defaults.set(muted, forKey: Key.muted)
            if let lastUpdated {
                defaults.set(lastUpdated, forKey: Key.lastUpdated)
            } else {
                defaults.removeObject(forKey: Key.lastUpdated)
            }
            if let sourceIdentity {
                defaults.set(sourceIdentity, forKey: Key.sourceIdentity)
            } else {
                defaults.removeObject(forKey: Key.sourceIdentity)
            }
        }
    }

    enum PublishError: Error, Equatable, Sendable {
        case notAVideo
        case unreadableSource
        case copyFailed
    }

    static func isVideoFile(_ url: URL) -> Bool {
        guard url.isFileURL else { return false }
        return videoExtensions.contains(url.pathExtension.lowercased())
    }

    static func normalizedScaling(_ raw: String) -> String {
        Scaling.all.contains(raw) ? raw : Scaling.fill
    }

    static func relativeMediaPath(for source: URL) -> String {
        let name = source.lastPathComponent
        let safe = name.isEmpty ? "current.mp4" : name
        return "\(mediaDirectoryName)/\(safe)"
    }

    static func resolvedMediaURL(relativePath: String?, container: URL) -> URL? {
        guard let relativePath, !relativePath.isEmpty else { return nil }
        return container.appendingPathComponent(relativePath)
    }

    static func makeSourceIdentity(for url: URL, fileManager: FileManager = .default) -> String? {
        guard url.isFileURL else { return nil }
        let path = url.standardizedFileURL.path
        guard fileManager.fileExists(atPath: path) else { return path }
        let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
        let size = values?.fileSize ?? -1
        let modified = values?.contentModificationDate?.timeIntervalSince1970 ?? 0
        return "\(path)|\(size)|\(modified)"
    }

    /// Copies `source` into `container` and writes the suite keys.
    /// A matching identity leaves the existing file in place and only refreshes settings.
    /// A failed copy does not change the stored video path.
    static func publish(
        source: URL,
        scalingRaw: String,
        syncWithDesktop: Bool,
        sourceIdentity: String,
        container: URL,
        defaults: UserDefaults,
        fileManager: FileManager = .default,
        now: Date = Date()
    ) throws -> Snapshot {
        guard isVideoFile(source) else { throw PublishError.notAVideo }
        guard fileManager.isReadableFile(atPath: source.path) else { throw PublishError.unreadableSource }

        let relativePath = relativeMediaPath(for: source)
        let destination = container.appendingPathComponent(relativePath)
        let previous = Snapshot.read(from: defaults)
        let scaling = normalizedScaling(scalingRaw)

        if previous.sourceIdentity == sourceIdentity,
           fileManager.fileExists(atPath: destination.path) {
            var refreshed = previous
            refreshed.videoPath = relativePath
            refreshed.scalingMode = scaling
            refreshed.syncWithDesktop = syncWithDesktop
            refreshed.muted = true
            refreshed.lastUpdated = now
            refreshed.sourceIdentity = sourceIdentity
            refreshed.write(to: defaults)
            return refreshed
        }

        let directory = destination.deletingLastPathComponent()
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            let incoming = destination.appendingPathExtension("incoming")
            if fileManager.fileExists(atPath: incoming.path) {
                try fileManager.removeItem(at: incoming)
            }
            try fileManager.copyItem(at: source, to: incoming)
            if fileManager.fileExists(atPath: destination.path) {
                _ = try fileManager.replaceItemAt(destination, withItemAt: incoming)
            } else {
                try fileManager.moveItem(at: incoming, to: destination)
            }
            try removeSiblingMedia(beside: destination, fileManager: fileManager)
        } catch {
            throw PublishError.copyFailed
        }

        let snapshot = Snapshot(
            videoPath: relativePath,
            scalingMode: scaling,
            syncWithDesktop: syncWithDesktop,
            muted: true,
            lastUpdated: now,
            sourceIdentity: sourceIdentity
        )
        snapshot.write(to: defaults)
        return snapshot
    }

    static func mediaExists(relativePath: String?, container: URL?, fileManager: FileManager = .default) -> Bool {
        guard let container, let url = resolvedMediaURL(relativePath: relativePath, container: container) else {
            return false
        }
        return fileManager.fileExists(atPath: url.path)
    }

    static func statusMessage(
        fileName: String?,
        mediaExists: Bool,
        lastUpdated: Date?,
        syncWithDesktop: Bool,
        desktopVideoAvailable: Bool
    ) -> String {
        if syncWithDesktop, !desktopVideoAvailable {
            if mediaExists {
                return "Screen Saver needs a video file. The main display is not using a video, so the current screen saver video was left unchanged."
            }
            return "Screen Saver needs a video file. Choose one, or switch the main display to a video wallpaper."
        }
        guard mediaExists, let fileName, !fileName.isEmpty else {
            return "No screen saver video yet. Choose a video, or use the desktop wallpaper."
        }
        if let lastUpdated {
            let formatted = lastUpdated.formatted(date: .abbreviated, time: .shortened)
            return "Using \(fileName). Updated \(formatted)."
        }
        return "Using \(fileName)."
    }

    private static func removeSiblingMedia(beside destination: URL, fileManager: FileManager) throws {
        let directory = destination.deletingLastPathComponent()
        let keep = destination.lastPathComponent
        let names = try fileManager.contentsOfDirectory(atPath: directory.path)
        for name in names where name != keep && !name.hasSuffix(".incoming") {
            try fileManager.removeItem(at: directory.appendingPathComponent(name))
        }
    }
}
