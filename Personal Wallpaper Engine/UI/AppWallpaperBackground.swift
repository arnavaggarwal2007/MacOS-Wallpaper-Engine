import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Shared live wallpaper layer behind all tabs (shell-level).
struct AppWallpaperBackground: View {
    enum Intensity {
        case hero
        case management
    }

    @EnvironmentObject private var appModel: AppViewModel
    let intensity: Intensity
    var pausePlayback: Bool = false

    var body: some View {
        GeometryReader { proxy in
            let aspect = proxy.size.width / max(proxy.size.height, 1)
            ZStack {
                HeroWallpaperView(
                    title: "",
                    subtitle: "",
                    image: previewImage,
                    badge: "",
                    metadata: [],
                    videoURL: previewVideoURL,
                    isFullWindowBackground: true,
                    dynamicAspectRatio: aspect,
                    isPlaybackPaused: pausePlayback
                )

                if intensity == .management {
                    VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                        .opacity(DesignTokens.Surfaces.managementBlurOpacity)
                    Color.black.opacity(DesignTokens.Surfaces.managementScrimOpacity)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var focusedDisplayID: CGDirectDisplayID? {
        appModel.focusedDisplayID ?? NSScreen.screens.first?.displayID
    }

    private var previewURL: URL? {
        appModel.heroPreviewURL(forDisplayID: focusedDisplayID)
    }

    private var previewVideoURL: URL? {
        guard let url = previewURL else { return nil }
        guard appModel.rendererMode != .web else { return nil }
        guard url.isFileURL else { return nil }
        let videoExtensions = ["mp4", "mov", "mkv", "avi", "m4v", "webm"]
        guard videoExtensions.contains(url.pathExtension.lowercased()) else { return nil }
        return url
    }

    private var previewImage: NSImage? {
        guard previewVideoURL == nil, let url = previewURL else { return nil }
        if url.isFileURL, let image = NSImage(contentsOf: url), image.size != .zero {
            return image
        }
        if appModel.rendererMode == .web {
            return NSWorkspace.shared.icon(for: UTType.internetLocation)
        }
        return NSWorkspace.shared.icon(for: .movie)
    }
}

private struct WallpaperPreviewPauseKey: PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}

extension View {
    func wallpaperPreviewPause(_ paused: Bool) -> some View {
        preference(key: WallpaperPreviewPauseKey.self, value: paused)
    }

    func onWallpaperPreviewPauseChange(_ action: @escaping (Bool) -> Void) -> some View {
        onPreferenceChange(WallpaperPreviewPauseKey.self, perform: action)
    }
}
