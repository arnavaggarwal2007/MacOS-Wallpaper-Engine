import SwiftUI
import AppKit

struct HeroWallpaperView: View {
    let title: String
    let subtitle: String
    let image: NSImage?
    let badge: String
    let metadata: [String]
    let videoURL: URL?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            heroImage

            LinearGradient(
                colors: [
                    Color.black.opacity(0.12),
                    Color.black.opacity(0.40),
                    Color.black.opacity(0.68)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Text(badge)
                        .font(DesignTokens.Typography.subtitle)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.88))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.black.opacity(0.24))
                        .clipShape(Capsule(style: .continuous))

                    Spacer()
                }

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(.system(size: 34, weight: .semibold, design: .default))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)

                    Text(subtitle)
                        .font(DesignTokens.Typography.subtitle)
                        .foregroundColor(.white.opacity(0.82))
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        ForEach(metadata, id: \.self) { item in
                            Text(item)
                                .font(DesignTokens.Typography.subtitle)
                                .foregroundColor(.white.opacity(0.88))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.white.opacity(0.14))
                                .clipShape(Capsule(style: .continuous))
                        }
                    }
                }
            }
            .padding(28)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(16 / 9, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(DesignTokens.Colors.cardBorder.opacity(0.6), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(isHovered ? 0.16 : 0.10), radius: isHovered ? 28 : 20, x: 0, y: isHovered ? 14 : 10)
        .scaleEffect(isHovered && !reduceMotion ? 1.01 : 1)
        .animation(reduceMotion ? .linear(duration: 0) : .easeInOut(duration: DesignTokens.Motion.standardDuration), value: isHovered)
        .onHover { isHovered = $0 }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
    }

    private var heroImage: some View {
        Group {
            if let videoURL = videoURL, isVideoFile(videoURL) {
                VideoPreviewView(videoURL: videoURL, shouldLoop: true, isMuted: true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .id(videoURL.absoluteString)
                    .onAppear { print("HeroWallpaperView: Rendering video preview for \(videoURL.path)") }
            } else if let image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear { print("HeroWallpaperView: Rendering static image") }
            } else {
                ZStack {
                    LinearGradient(
                        colors: [
                            DesignTokens.Colors.primary.opacity(0.55),
                            DesignTokens.Colors.cardBackground,
                            Color.black.opacity(0.72)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Image(systemName: "display.2")
                        .font(.system(size: 52, weight: .light))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear { print("HeroWallpaperView: Rendering placeholder") }
            }
        }
    }
    
    private func isVideoFile(_ url: URL) -> Bool {
        let videoExtensions = ["mp4", "mov", "mkv", "avi", "m4v", "webm"]
        let fileExtension = url.pathExtension.lowercased()
        return videoExtensions.contains(fileExtension)
    }
}
