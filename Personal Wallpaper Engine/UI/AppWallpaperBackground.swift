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
    /// User-initiated global desktop pause (toolbar) — hero holds visible AVPlayerLayer frame.
    var isGlobalDesktopPaused: Bool = false
    var pausePlayback: Bool = false
    @State private var managementThumbnail: NSImage?

    var body: some View {
        GeometryReader { proxy in
            let aspect = proxy.size.width / max(proxy.size.height, 1)
            ZStack {
                HeroWallpaperView(
                    title: "",
                    subtitle: "",
                    image: heroFallbackImage,
                    badge: "",
                    metadata: [],
                    videoURL: heroVideoURL,
                    usesUnifiedDesktopDecode: usesUnifiedDesktopDecode,
                    isFullWindowBackground: true,
                    dynamicAspectRatio: aspect,
                    isPlaybackPaused: pausePlayback,
                    isGlobalDesktopPaused: isGlobalDesktopPaused
                )

                if appModel.shouldShowPausedChrome {
                    ZStack {
                        Color.black.opacity(0.38)
                        VStack(spacing: 10) {
                            Image(systemName: "pause.circle.fill")
                                .font(.system(size: 36, weight: .semibold))
                            Text("Wallpapers paused on all displays")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundStyle(.white.opacity(0.92))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    }
                    .allowsHitTesting(false)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Wallpapers paused on all displays")
                }

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
        .task(id: managementThumbnailTaskKey) {
            await loadManagementThumbnailIfNeeded()
        }
    }

    private var managementThumbnailTaskKey: String {
        guard let url = previewURL, needsManagementThumbnail else { return "none" }
        if intensity == .hero, usesPolicyUnifiedPauseSnapshot {
            return "policy-pause|\(url.absoluteString)"
        }
        return url.absoluteString
    }

    /// Policy/unfocus/scroll pause with unified decode — async snapshot, not global desktop hold.
    private var usesPolicyUnifiedPauseSnapshot: Bool {
        intensity == .hero
            && pausePlayback
            && !isGlobalDesktopPaused
            && usesUnifiedDesktopDecode
    }

    private var needsManagementThumbnail: Bool {
        if intensity == .management {
            return true
        }
        if usesPolicyUnifiedPauseSnapshot {
            return true
        }
        return false
    }

    private var focusedDisplayID: CGDirectDisplayID? {
        appModel.focusedDisplayID ?? NSScreen.screens.first?.displayID
    }

    /// Applied wallpaper on focused display (ignores library transient preview).
    private var previewURL: URL? {
        appModel.shellHeroPreviewURL(forDisplayID: focusedDisplayID)
    }

    /// Live video on Home; Max Quality keeps live hero on all tabs (7E). Balanced uses static thumbnail on management tabs.
    private var heroVideoURL: URL? {
        guard usesLiveHeroVideo else { return nil }
        guard let url = previewURL else { return nil }
        guard appModel.rendererMode != .web else { return nil }
        guard url.isFileURL else { return nil }
        guard VideoWallpaperThumbnail.isVideoFile(url) else { return nil }
        return url
    }

    /// Live video on Home for all profiles; Max Quality also live on management tabs (7E.1).
    private var usesLiveHeroVideo: Bool {
        if intensity == .hero { return true }
        return intensity == .management && appModel.performanceProfile == .maxQuality
    }

    private var usesUnifiedDesktopDecode: Bool {
        guard let url = previewURL else { return false }
        return appModel.heroPreviewCanShareDesktopDecode(for: url)
    }

    /// Static fallback for policy unified pause or non-video sources (not used for global desktop hold).
    private var heroFallbackImage: NSImage? {
        if intensity == .management {
            return managementThumbnail ?? staticPreviewImage
        }
        if usesPolicyUnifiedPauseSnapshot {
            return managementThumbnail
        }
        return staticPreviewImage
    }

    private var staticPreviewImage: NSImage? {
        guard heroVideoURL == nil, let url = previewURL else {
            if let url = previewURL, VideoWallpaperThumbnail.isVideoFile(url) {
                return NSWorkspace.shared.icon(for: .movie)
            }
            return nil
        }
        if url.isFileURL, let image = NSImage(contentsOf: url), image.size != .zero {
            return image
        }
        if appModel.rendererMode == .web {
            return NSWorkspace.shared.icon(for: UTType.internetLocation)
        }
        return NSWorkspace.shared.icon(for: .movie)
    }

    @MainActor
    private func loadManagementThumbnailIfNeeded() async {
        managementThumbnail = nil

        guard let url = previewURL else {
            return
        }
        guard needsManagementThumbnail else {
            return
        }
        guard VideoWallpaperThumbnail.isVideoFile(url) else {
            return
        }

        if usesPolicyUnifiedPauseSnapshot {
            managementThumbnail = await appModel.captureHeroPauseSnapshot(for: url)
        } else {
            managementThumbnail = await VideoWallpaperThumbnail.imageAsync(for: url)
        }
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
