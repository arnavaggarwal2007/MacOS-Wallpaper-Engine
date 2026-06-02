import AppKit
import AVFoundation
import Foundation
import os.log

/// Generates and caches still frames for video wallpaper previews (hero / carousel).
enum VideoWallpaperThumbnail {
    private static let logger = Logger(subsystem: "com.local.wallpaper", category: "VideoWallpaperThumbnail")
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

    /// Cache key for pause / mid-timeline snapshots (0.1s buckets; separate from t=0 poster cache).
    static func pauseCacheKey(for url: URL, at time: CMTime) -> NSString {
        let base = cacheKey(for: url) as String
        let seconds = max(0, CMTimeGetSeconds(time))
        let bucket = (seconds * 10).rounded() / 10
        return "\(base)|pause|\(bucket)" as NSString
    }

    static func cachedImage(for url: URL) -> NSImage? {
        cache.object(forKey: cacheKey(for: url))
    }

    static func image(for url: URL) -> NSImage? {
        image(for: url, at: .zero)
    }

    static func image(for url: URL, at time: CMTime) -> NSImage? {
        if CMTimeCompare(time, .zero) == 0 {
            let key = cacheKey(for: url)
            if let cached = cache.object(forKey: key) {
                return cached
            }
            guard let generated = generateThumbnail(for: url, at: .zero) else { return nil }
            cache.setObject(generated, forKey: key)
            return generated
        }

        let key = pauseCacheKey(for: url, at: time)
        if let cached = cache.object(forKey: key) {
            return cached
        }
        guard let generated = generateThumbnail(for: url, at: time) else { return nil }
        cache.setObject(generated, forKey: key)
        return generated
    }

    static func imageAsync(for url: URL) async -> NSImage? {
        await imageAsync(for: url, at: .zero)
    }

    static func imageAsync(for url: URL, at time: CMTime) async -> NSImage? {
        if CMTimeCompare(time, .zero) == 0, let cached = cachedImage(for: url) {
            return cached
        }
        if CMTimeCompare(time, .zero) != 0 {
            let key = pauseCacheKey(for: url, at: time)
            if let cached = cache.object(forKey: key) {
                return cached
            }
        }
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let image = image(for: url, at: time)
                continuation.resume(returning: image)
            }
        }
    }

    private static func generateThumbnail(for url: URL) -> NSImage? {
        generateThumbnail(for: url, at: .zero)
    }

    private static func generateThumbnail(for url: URL, at time: CMTime) -> NSImage? {
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
        let tolerance = CMTime(seconds: 0.1, preferredTimescale: 600)
        generator.requestedTimeToleranceBefore = tolerance
        generator.requestedTimeToleranceAfter = tolerance

        if let image = generateStill(from: generator, at: time) {
            return image
        }

        if CMTimeCompare(time, .zero) != 0 {
            logger.debug("Pause snapshot failed at t=\(CMTimeGetSeconds(time), privacy: .public)s; falling back to t=0 file=\(url.lastPathComponent, privacy: .public)")
            return generateStill(from: generator, at: .zero)
        }
        return nil
    }

    private static func generateStill(from generator: AVAssetImageGenerator, at time: CMTime) -> NSImage? {
        let requestedTime = NSValue(time: time)
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
