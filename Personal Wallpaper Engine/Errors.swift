import Foundation
import CoreGraphics

enum WallpaperError: LocalizedError, Equatable {
    case videoFileNotFound(path: String)
    case videoFileNotReadable(path: String)
    case videoDecodingFailed(url: URL, reason: String)
    case windowCreationFailed(reason: String)
    case rendererInitializationFailed(reason: String)
    case screenNotFound(id: CGDirectDisplayID)
    case internalError(description: String)

    var errorDescription: String? {
        switch self {
        case .videoFileNotFound(let path): return "Video file not found: \(path)"
        case .videoFileNotReadable(let path): return "Video file is not readable: \(path)"
        case .videoDecodingFailed(let url, let reason): return "Video decoding failed for \(url.lastPathComponent): \(reason)"
        case .windowCreationFailed(let reason): return "Window creation failed: \(reason)"
        case .rendererInitializationFailed(let reason): return "Renderer initialization failed: \(reason)"
        case .screenNotFound(let id): return "Screen not found: \(id)"
        case .internalError(let description): return "Internal error: \(description)"
        }
    }
}
