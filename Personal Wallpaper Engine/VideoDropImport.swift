import Foundation
import UniformTypeIdentifiers

/// Resolves dropped video files for Home and Library import surfaces.
enum VideoDropImport {
    static let supportedContentTypes: [UTType] = [.movie, .mpeg4Movie, .quickTimeMovie, .video, .mpeg2Video]

    static func firstVideoURL(from providers: [NSItemProvider]) async -> URL? {
        for provider in providers {
            if let url = await loadFileURL(from: provider) {
                if isVideoFile(url) { return url }
            }
        }
        return nil
    }

    private static func loadFileURL(from provider: NSItemProvider) async -> URL? {
        let typeIdentifiers = [UTType.fileURL.identifier, UTType.movie.identifier, UTType.video.identifier]
        for identifier in typeIdentifiers where provider.hasItemConformingToTypeIdentifier(identifier) {
            if let url = await loadURL(provider: provider, typeIdentifier: identifier) {
                return url
            }
        }
        return nil
    }

    private static func loadURL(provider: NSItemProvider, typeIdentifier: String) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, _ in
                if let url = item as? URL {
                    continuation.resume(returning: url)
                    return
                }
                if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                    continuation.resume(returning: url)
                    return
                }
                if let string = item as? String, let url = URL(string: string) {
                    continuation.resume(returning: url)
                    return
                }
                continuation.resume(returning: nil)
            }
        }
    }

    static func isVideoFile(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ["mp4", "mov", "m4v", "mkv", "avi", "webm"].contains(ext)
    }
}
