import Foundation
import AVFoundation

final class SettingsStore {
    static let shared = SettingsStore()

    private enum Keys {
        static let videoPath = "videoPath"
        static let videoBookmark = "videoBookmark"
        static let isMuted = "isMuted"
        static let scalingMode = "scalingMode"
        static let debugDiagnostics = "debugDiagnostics"  // Chunk 4E: Debug flag
    }

    private init() {
        videoFilePath = UserDefaults.standard.string(forKey: Keys.videoPath) ?? ""
        videoBookmarkData = UserDefaults.standard.data(forKey: Keys.videoBookmark)
        isMuted = UserDefaults.standard.bool(forKey: Keys.isMuted)
        scalingMode = VideoScalingMode(rawValue: UserDefaults.standard.string(forKey: Keys.scalingMode) ?? VideoScalingMode.resizeAspectFill.rawValue) ?? .resizeAspectFill
        debugDiagnosticsEnabled = UserDefaults.standard.bool(forKey: Keys.debugDiagnostics)  // Chunk 4E
    }

    var videoFilePath: String {
        didSet { UserDefaults.standard.set(videoFilePath, forKey: Keys.videoPath) }
    }

    var videoBookmarkData: Data? {
        didSet { UserDefaults.standard.set(videoBookmarkData, forKey: Keys.videoBookmark) }
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
