import SwiftUI
import AppKit

struct HeroWallpaperView: View {
    @EnvironmentObject private var appModel: AppViewModel
    let title: String
    let subtitle: String
    let image: NSImage?
    let badge: String
    let metadata: [String]
    let videoURL: URL?
    var usesUnifiedDesktopDecode: Bool = false
    let isFullWindowBackground: Bool
    let dynamicAspectRatio: CGFloat?
    var isPlaybackPaused: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false
    @State private var unifiedAttachFailed = false

    var body: some View {
        ZStack(alignment: isFullWindowBackground ? .topLeading : .bottomLeading) {
            heroImage

            // Only show gradient overlay if NOT full-window background
            if !isFullWindowBackground {
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.12),
                        Color.black.opacity(0.40),
                        Color.black.opacity(0.68)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                // For full-window, lighter gradient at bottom for text readability
                LinearGradient(
                    colors: [
                        Color.black.opacity(0),
                        Color.black.opacity(0.15),
                        Color.black.opacity(0.35)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }

            // Only show UI overlay if NOT full-window background
            if !isFullWindowBackground {
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(
            dynamicAspectRatio ?? (16 / 9),
            contentMode: isFullWindowBackground ? .fill : .fit
        )
        .clipped()
        .conditionalModifier(!isFullWindowBackground) {
            $0
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(DesignTokens.Colors.cardBorder.opacity(0.6), lineWidth: 1)
                }
        }
        .conditionalModifier(!isFullWindowBackground) {
            $0
                .shadow(color: Color.black.opacity(isHovered ? 0.16 : 0.10), radius: isHovered ? 28 : 20, x: 0, y: isHovered ? 14 : 10)
                .scaleEffect(isHovered && !reduceMotion ? 1.01 : 1)
                .onHover { isHovered = $0 }
        }
        .animation(reduceMotion ? .linear(duration: 0) : .easeInOut(duration: DesignTokens.Motion.standardDuration), value: isHovered)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
        .onChange(of: videoURL?.absoluteString) { _, _ in
            unifiedAttachFailed = false
        }
    }

    @ViewBuilder
    private func unifiedHeroFallback(videoURL: URL) -> some View {
        if let image {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VideoPreviewView(
                videoURL: videoURL,
                shouldLoop: true,
                isMuted: true,
                isPlaybackPaused: false
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .id("fallback-\(videoURL.absoluteString)")
            .onAppear {
                if SettingsStore.shared.debugDiagnosticsEnabled {
                    print("HeroWallpaperView: unified attach failed — independent decode fallback \(videoURL.path)")
                }
            }
        }
    }

    private var heroImage: some View {
        Group {
            if let videoURL = videoURL, isVideoFile(videoURL) {
                if usesUnifiedDesktopDecode, !isPlaybackPaused {
                    if unifiedAttachFailed {
                        unifiedHeroFallback(videoURL: videoURL)
                    } else {
                        UnifiedVideoPreviewView(
                            appModel: appModel,
                            videoURL: videoURL,
                            isPlaybackPaused: false,
                            onAttachStateChanged: { attached in
                                if !attached {
                                    unifiedAttachFailed = true
                                }
                            }
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .id("unified-\(videoURL.absoluteString)")
                    }
                } else if usesUnifiedDesktopDecode, isPlaybackPaused, let image {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .antialiased(true)
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !isPlaybackPaused {
                    VideoPreviewView(
                        videoURL: videoURL,
                        shouldLoop: true,
                        isMuted: true,
                        isPlaybackPaused: isPlaybackPaused
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .id(videoURL.absoluteString)
                    .onAppear {
                        if SettingsStore.shared.debugDiagnosticsEnabled {
                            print("HeroWallpaperView: video preview \(videoURL.path)")
                        }
                    }
                } else if let image {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .antialiased(true)
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    heroPlaceholder
                }
            } else if let image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        if SettingsStore.shared.debugDiagnosticsEnabled {
                            print("HeroWallpaperView: static image")
                        }
                    }
            } else {
                heroPlaceholder
            }
        }
    }

    private var heroPlaceholder: some View {
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
        .onAppear {
            if SettingsStore.shared.debugDiagnosticsEnabled {
                print("HeroWallpaperView: placeholder")
            }
        }
    }
    
    private func isVideoFile(_ url: URL) -> Bool {
        let videoExtensions = ["mp4", "mov", "mkv", "avi", "m4v", "webm"]
        let fileExtension = url.pathExtension.lowercased()
        return videoExtensions.contains(fileExtension)
    }
}

// MARK: - View Modifier Helper

extension View {
    @ViewBuilder
    func conditionalModifier<Content: View>(
        _ condition: Bool,
        @ViewBuilder transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    HeroWallpaperView(
        title: "Spider-Man Black",
        subtitle: "High contrast wallpaper",
        image: nil,
        badge: "System",
        metadata: ["4K", "Dark", "Portrait"],
        videoURL: nil,
        isFullWindowBackground: false,
        dynamicAspectRatio: nil
    )
    .frame(maxWidth: 600, maxHeight: 340)
}
