import AppKit
import AVFoundation
import Foundation

/// Generates and caches still frames for video wallpaper previews (hero / carousel).
enum VideoWallpaperThumbnail {
    private static let cache = NSCache<NSString, NSImage>()

    static func isVideoFile(_ url: URL) -> Bool {
        let videoExtensions = ["mp4", "mov", "mkv", "avi", "m4v", "webm"]
        return videoExtensions.contains(url.pathExtension.lowercased())
    }

    static func cacheKey(for url: URL) -> NSString {
        let path = url.isFileURL ? url.standardizedFileURL.path : url.absoluteString
        let values = try? url.resourceValues(forKeys: [.contentModificationDateKey])
        let mod = values?.contentModificationDate?.timeIntervalSince1970 ?? 0
        return "\(path)|\(mod)" as NSString
    }

    static func cachedImage(for url: URL) -> NSImage? {
        cache.object(forKey: cacheKey(for: url))
    }

    static func image(for url: URL) -> NSImage? {
        let key = cacheKey(for: url)
        if let cached = cache.object(forKey: key) {
            return cached
        }
        guard let generated = generateThumbnail(for: url) else { return nil }
        cache.setObject(generated, forKey: key)
        return generated
    }

    static func imageAsync(for url: URL) async -> NSImage? {
        if let cached = cachedImage(for: url) {
            return cached
        }
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let image = image(for: url)
                continuation.resume(returning: image)
            }
        }
    }

    private static func generateThumbnail(for url: URL) -> NSImage? {
        if !url.isFileURL {
            return nil
        }
        let fileExtension = url.pathExtension.lowercased()
        if ["png", "jpg", "jpeg", "gif", "tiff", "bmp", "heic", "webp"].contains(fileExtension),
           let image = NSImage(contentsOf: url), image.size != .zero {
            return image
        }

        guard FileManager.default.fileExists(atPath: url.path) else { return nil }

        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 1920, height: 1920)

        let requestedTime = NSValue(time: .zero)
        let semaphore = DispatchSemaphore(value: 0)
        var generatedImage: NSImage?

        generator.generateCGImagesAsynchronously(forTimes: [requestedTime]) { _, cgImage, _, result, _ in
            defer { semaphore.signal() }
            guard result == .succeeded, let cgImage else { return }
            let imageSize = NSSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
            generatedImage = NSImage(cgImage: cgImage, size: imageSize)
        }

        semaphore.wait()
        return generatedImage
    }
}
