import AppKit
import Foundation

/// App-side access to the screen-saver App Group. Not compiled into the `.saver`.
nonisolated enum ScreensaverCoordinator {
    static let systemSettingsURL = URL(string: "x-apple.systempreferences:com.apple.ScreenSaver-Settings.extension")!

    static let bundledSaverRelativePath = "Contents/Library/Screen Savers/Deskface.saver"
    static let userLibrarySaverRelativePath = "Library/Screen Savers/Deskface.saver"

    enum PublishFailure: Error, Equatable, Sendable {
        case containerUnavailable
        case publish(ScreensaverConfig.PublishError)
    }

    static func suiteDefaults() -> UserDefaults {
        UserDefaults(suiteName: ScreensaverConfig.appGroupIdentifier) ?? .standard
    }

    static func containerURL(fileManager: FileManager = .default) -> URL? {
        fileManager.containerURL(forSecurityApplicationGroupIdentifier: ScreensaverConfig.appGroupIdentifier)
    }

    static func snapshot() -> ScreensaverConfig.Snapshot {
        ScreensaverConfig.Snapshot.read(from: suiteDefaults())
    }

    static func setSyncWithDesktop(_ enabled: Bool) {
        var snapshot = snapshot()
        snapshot.syncWithDesktop = enabled
        snapshot.write(to: suiteDefaults())
    }

    static func mediaExists() -> Bool {
        let snapshot = snapshot()
        return ScreensaverConfig.mediaExists(
            relativePath: snapshot.videoPath,
            container: containerURL()
        )
    }

    static func resolvedVideoURL() -> URL? {
        guard let container = containerURL() else { return nil }
        return ScreensaverConfig.resolvedMediaURL(relativePath: snapshot().videoPath, container: container)
    }

    static func publish(
        source: URL,
        scalingRaw: String,
        syncWithDesktop: Bool,
        sourceIdentity: String,
        now: Date = Date()
    ) -> Result<ScreensaverConfig.Snapshot, PublishFailure> {
        guard let container = containerURL() else {
            return .failure(.containerUnavailable)
        }
        do {
            let snapshot = try ScreensaverConfig.publish(
                source: source,
                scalingRaw: scalingRaw,
                syncWithDesktop: syncWithDesktop,
                sourceIdentity: sourceIdentity,
                container: container,
                defaults: suiteDefaults(),
                now: now
            )
            return .success(snapshot)
        } catch let error as ScreensaverConfig.PublishError {
            return .failure(.publish(error))
        } catch {
            return .failure(.publish(.copyFailed))
        }
    }

    static func openSystemSettings() {
        NSWorkspace.shared.open(systemSettingsURL)
    }

    /// Direct builds also copy the embedded saver into `~/Library/Screen Savers/`.
    /// App Store builds only embed it. A sandbox denial leaves the embedded copy in place.
    static func installUserLibrarySaverIfNeeded(bundle: Bundle = .main, fileManager: FileManager = .default) -> String? {
        #if DIRECT_BUILD
        let bundled = bundle.bundleURL.appendingPathComponent(bundledSaverRelativePath, isDirectory: true)
        guard fileManager.fileExists(atPath: bundled.path) else {
            return "Deskface couldn’t find the screen saver inside the app."
        }
        let destination = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(userLibrarySaverRelativePath, isDirectory: true)
        let temporary = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("saver")
        do {
            try fileManager.createDirectory(
                at: destination.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            if fileManager.fileExists(atPath: temporary.path) {
                try fileManager.removeItem(at: temporary)
            }
            try fileManager.copyItem(at: bundled, to: temporary)
            if fileManager.fileExists(atPath: destination.path) {
                _ = try fileManager.replaceItemAt(destination, withItemAt: temporary)
            } else {
                try fileManager.moveItem(at: temporary, to: destination)
            }
            return nil
        } catch {
            return "Deskface couldn’t copy the screen saver to \(destination.path). Choose Deskface in System Settings if it already appears there."
        }
        #else
        _ = bundle
        _ = fileManager
        return nil
        #endif
    }

    static func message(for failure: PublishFailure) -> String {
        switch failure {
        case .containerUnavailable:
            return "Screen saver storage isn’t available yet. Enable the App Group \(ScreensaverConfig.appGroupIdentifier) for this app in the Apple Developer account."
        case .publish(.notAVideo):
            return "Screen Saver needs a video file (MP4 or MOV)."
        case .publish(.unreadableSource):
            return "Deskface couldn’t read that video."
        case .publish(.copyFailed):
            return "Deskface couldn’t copy the video for the screen saver. The previous screen saver video was left unchanged."
        }
    }
}
