import Foundation
import AVFoundation

final class SettingsStore {
    static let shared = SettingsStore()

    private enum Keys {
        static let videoPath = "videoPath"
        static let videoBookmark = "videoBookmark"
        static let rendererMode = "rendererMode"
        static let webURL = "webURL"
        static let perDisplaySources = "perDisplaySources"
        static let isMuted = "isMuted"
        static let scalingMode = "scalingMode"
        static let debugDiagnostics = "debugDiagnostics"  // Chunk 4E: Debug flag
        static let launchOnLogin = "launchOnLogin"  // Phase 5G: Launch-on-login flag
    }

    private init() {
        videoFilePath = UserDefaults.standard.string(forKey: Keys.videoPath) ?? ""
        videoBookmarkData = UserDefaults.standard.data(forKey: Keys.videoBookmark)
        rendererMode = WallpaperRendererMode(rawValue: UserDefaults.standard.string(forKey: Keys.rendererMode) ?? WallpaperRendererMode.video.rawValue) ?? .video
        webURLString = UserDefaults.standard.string(forKey: Keys.webURL) ?? ""
        // Load per-display sources (JSON encoded dictionary)
        if let data = UserDefaults.standard.data(forKey: Keys.perDisplaySources) {
            if let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
                perDisplaySources = decoded
            } else {
                perDisplaySources = [:]
            }
        } else {
            perDisplaySources = [:]
        }
        isMuted = UserDefaults.standard.bool(forKey: Keys.isMuted)
        scalingMode = VideoScalingMode(rawValue: UserDefaults.standard.string(forKey: Keys.scalingMode) ?? VideoScalingMode.resizeAspectFill.rawValue) ?? .resizeAspectFill
        debugDiagnosticsEnabled = UserDefaults.standard.bool(forKey: Keys.debugDiagnostics)  // Chunk 4E
        launchOnLoginEnabled = UserDefaults.standard.bool(forKey: Keys.launchOnLogin)  // Phase 5G
    }

    // Per-display mapping: displayID (as string) -> URL string
    var perDisplaySources: [String: String] {
        didSet {
            if let encoded = try? JSONEncoder().encode(perDisplaySources) {
                UserDefaults.standard.set(encoded, forKey: Keys.perDisplaySources)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.perDisplaySources)
            }
        }
    }

    var videoFilePath: String {
        didSet { UserDefaults.standard.set(videoFilePath, forKey: Keys.videoPath) }
    }

    var videoBookmarkData: Data? {
        didSet { UserDefaults.standard.set(videoBookmarkData, forKey: Keys.videoBookmark) }
    }

    var rendererMode: WallpaperRendererMode {
        didSet { UserDefaults.standard.set(rendererMode.rawValue, forKey: Keys.rendererMode) }
    }

    var webURLString: String {
        didSet { UserDefaults.standard.set(webURLString, forKey: Keys.webURL) }
    }

    var isMuted: Bool {
        didSet { UserDefaults.standard.set(isMuted, forKey: Keys.isMuted) }
    }

    var scalingMode: VideoScalingMode {
        didSet { UserDefaults.standard.set(scalingMode.rawValue, forKey: Keys.scalingMode) }
    }
    
    var debugDiagnosticsEnabled: Bool {  // Chunk 4E: Debug diagnostics flag
        didSet { UserDefaults.standard.set(debugDiagnosticsEnabled, forKey: Keys.debugDiagnostics) }
    }

    var launchOnLoginEnabled: Bool {  // Phase 5G: Launch-on-login preference
        didSet { UserDefaults.standard.set(launchOnLoginEnabled, forKey: Keys.launchOnLogin) }
    }
}

enum VideoScalingMode: String, CaseIterable {
    case resizeAspectFill = "resizeAspectFill"
    case resizeAspect = "resizeAspect"
    case resizeAspectHeight = "resizeAspectHeight"

    var displayName: String {
        switch self {
        case .resizeAspectFill:
            return "Fill"
        case .resizeAspect:
            return "Fit"
        case .resizeAspectHeight:
            return "Stretch"
        }
    }

    var avLayerVideoGravity: AVLayerVideoGravity {
        switch self {
        case .resizeAspectFill:
            return .resizeAspectFill
        case .resizeAspect:
            return .resizeAspect
        case .resizeAspectHeight:
            return .resize
        }
    }
}

enum WallpaperRendererMode: String, CaseIterable {
    case video
    case web

    var displayName: String {
        switch self {
        case .video:
            return "Video"
        case .web:
            return "Web"
        }
    }
}
