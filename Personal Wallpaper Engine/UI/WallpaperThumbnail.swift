import SwiftUI
import AppKit
import AVFoundation
import UniformTypeIdentifiers

enum WallpaperThumbnailLoader {
    static func resolveURL(from urlString: String, collectionName: String? = nil) -> URL? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let collectionName,
           let bookmarks = SettingsStore.shared.collectionBookmarks[collectionName],
           let bookmarkData = bookmarks[trimmed] {
            var isStale = false
            if let resolved = try? URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ) {
                return resolved
            }
        }

        if trimmed.hasPrefix("/") {
            return URL(fileURLWithPath: trimmed)
        }

        if let url = URL(string: trimmed) {
            if url.scheme == nil, url.path.hasPrefix("/") {
                return URL(fileURLWithPath: url.path)
            }
            return url
        }

        return nil
    }

    static func image(for urlString: String, collectionName: String? = nil, maxPixelSize: CGFloat = 320) -> NSImage? {
        guard let url = resolveURL(from: urlString, collectionName: collectionName) else { return nil }

        if url.isFileURL {
            let didStartScope = url.startAccessingSecurityScopedResource()
            defer {
                if didStartScope {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            if let thumbnail = thumbnailForLocalFile(at: url, maxPixelSize: maxPixelSize) {
                return thumbnail
            }
            if let image = NSImage(contentsOf: url), image.size != .zero {
                return image
            }
            return NSWorkspace.shared.icon(forFile: url.path)
        }

        let isWeb = url.scheme?.hasPrefix("http") == true
        return isWeb
            ? NSWorkspace.shared.icon(for: UTType.internetLocation)
            : NSWorkspace.shared.icon(for: .movie)
    }

    private static func thumbnailForLocalFile(at url: URL, maxPixelSize: CGFloat) -> NSImage? {
        let fileExtension = url.pathExtension.lowercased()
        if ["png", "jpg", "jpeg", "gif", "tiff", "bmp", "heic", "webp"].contains(fileExtension),
           let image = NSImage(contentsOf: url),
           image.size != .zero {
            return image
        }

        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: maxPixelSize, height: maxPixelSize * 9 / 16)

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

struct WallpaperThumbnailView: View {
    let urlString: String?
    var collectionName: String? = nil
    var width: CGFloat = DesignTokens.Surfaces.thumbnailLandscapeWidth
    var cornerRadius: CGFloat = DesignTokens.Corner.thumbnail

    @State private var image: NSImage?

    private var height: CGFloat {
        width * DesignTokens.Surfaces.thumbnailLandscapeAspectHeight / DesignTokens.Surfaces.thumbnailLandscapeAspectWidth
    }

    var body: some View {
        Group {
            if let image, image.size != .zero {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(
                        DesignTokens.Surfaces.thumbnailLandscapeAspectWidth / DesignTokens.Surfaces.thumbnailLandscapeAspectHeight,
                        contentMode: .fill
                    )
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(DesignTokens.Colors.cardBackground)
                    Image(systemName: "photo")
                        .font(.title3)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(DesignTokens.Colors.cardBorder, lineWidth: 1)
        }
        .shadow(color: .black.opacity(DesignTokens.Surfaces.thumbnailShadowOpacity), radius: 4, y: 2)
        .task(id: "\(urlString ?? "")-\(collectionName ?? "")") {
            guard let urlString, !urlString.isEmpty else {
                image = nil
                return
            }
            let maxPixelSize = max(width, height) * 2
            let collection = collectionName
            image = await Task.detached(priority: .utility) {
                WallpaperThumbnailLoader.image(
                    for: urlString,
                    collectionName: collection,
                    maxPixelSize: maxPixelSize
                )
            }.value
        }
    }
}
