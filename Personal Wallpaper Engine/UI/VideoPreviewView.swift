import SwiftUI
import AppKit
import AVFoundation
import AVKit
import os.log

private let videoPreviewLogger = Logger(subsystem: "com.local.wallpaper", category: "VideoPreviewView")

/// A SwiftUI wrapper around `AVPlayerView` for in-app video preview playback.
/// `isPlaybackPaused` is for scroll-reveal pause only — not tied to desktop global pause.
struct VideoPreviewView: NSViewRepresentable {
    typealias NSViewType = AVPlayerView
    let videoURL: URL
    let shouldLoop: Bool
    var isMuted: Bool = true
    var isPlaybackPaused: Bool = false

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.controlsStyle = .none
        view.videoGravity = .resizeAspectFill
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor

        // Critical: Disable auto-resizing masks to allow SwiftUI to control the frame
        view.translatesAutoresizingMaskIntoConstraints = false

        let player = AVPlayer()
        player.isMuted = isMuted
        view.player = player

        context.coordinator.player = player
        context.coordinator.playerView = view
        context.coordinator.currentURL = videoURL
        context.coordinator.isPlaybackPaused = isPlaybackPaused

        startLoad(
            player: player,
            url: videoURL,
            shouldLoop: shouldLoop,
            coordinator: context.coordinator
        )

        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        context.coordinator.isPlaybackPaused = isPlaybackPaused

        if context.coordinator.player?.isMuted != isMuted {
            context.coordinator.player?.isMuted = isMuted
        }

        if context.coordinator.currentURL?.absoluteString != videoURL.absoluteString {
            context.coordinator.currentURL = videoURL
            context.coordinator.lastAppliedPauseState = nil
            startLoad(
                player: context.coordinator.player ?? AVPlayer(),
                url: videoURL,
                shouldLoop: shouldLoop,
                coordinator: context.coordinator
            )
            return
        }

        guard context.coordinator.lastAppliedPauseState != isPlaybackPaused else { return }
        context.coordinator.lastAppliedPauseState = isPlaybackPaused

        if isPlaybackPaused {
            context.coordinator.player?.pause()
        } else {
            context.coordinator.player?.play()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    /// Starts a load, superseding any in-flight one so a slow earlier load cannot win the race and
    /// leave the preview showing the wrong video.
    private func startLoad(
        player: AVPlayer,
        url: URL,
        shouldLoop: Bool,
        coordinator: Coordinator
    ) {
        coordinator.loadTask?.cancel()
        coordinator.loadTask = Task {
            await loadAndPlay(
                player: player,
                url: url,
                shouldLoop: shouldLoop,
                coordinator: coordinator
            )
        }
    }

    private func loadAndPlay(
        player: AVPlayer,
        url: URL,
        shouldLoop: Bool,
        coordinator: Coordinator
    ) async {
        let debug = SettingsStore.shared.debugDiagnosticsEnabled
        if debug { videoPreviewLogger.debug("loadAndPlay -> \(url.path, privacy: .public)") }

        // Manage security-scoped access for file URLs
        if url.isFileURL {
            if let prev = coordinator.accessedURL, prev.path != url.path {
                prev.stopAccessingSecurityScopedResource()
                coordinator.accessedURL = nil
                if debug { videoPreviewLogger.debug("stopped scope for \(prev.path, privacy: .public)") }
            }
            if coordinator.accessedURL?.path != url.path {
                let didStart = url.startAccessingSecurityScopedResource()
                if debug { videoPreviewLogger.debug("startAccessingScope -> \(didStart) for \(url.path, privacy: .public)") }
                if didStart { coordinator.accessedURL = url }
            }
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            if debug { videoPreviewLogger.debug("file missing at \(url.path, privacy: .public)") }
            return
        }

        guard !Task.isCancelled else { return }

        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        PerformanceProfileConfiguration.apply(to: item, profile: SettingsStore.shared.performanceProfile)

        // Status KVO exists purely for debug logging, so don't register it otherwise.
        coordinator.playerItemObserver?.invalidate()
        coordinator.playerItemObserver = nil
        if debug {
            coordinator.playerItemObserver = item.observe(\AVPlayerItem.status, options: [.initial, .new]) { item, _ in
                videoPreviewLogger.debug("playerItem.status = \(item.status.rawValue)")
            }
        }

        // Unconditional: turning looping off must also drop the previous item's observer.
        coordinator.removeLoopObserver()

        if shouldLoop {
            coordinator.loopItem = item
            coordinator.loopObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak coordinator] _ in
                guard let coordinator, !coordinator.isPlaybackPaused else { return }
                coordinator.player?.seek(to: .zero)
                coordinator.player?.play()
            }
        }

        guard !Task.isCancelled else { return }

        let shouldStartPlayback = !coordinator.isPlaybackPaused
        await MainActor.run {
            player.replaceCurrentItem(with: item)
            if shouldStartPlayback {
                player.play()
                if debug { videoPreviewLogger.debug("player.play()") }
            } else {
                player.pause()
                if debug { videoPreviewLogger.debug("player.pause() after load (scroll pause)") }
            }
        }
    }

    class Coordinator {
        var player: AVPlayer?
        var playerView: AVPlayerView?
        var loopObserver: NSObjectProtocol?
        var loopItem: AVPlayerItem?
        var playerItemObserver: NSKeyValueObservation?
        var accessedURL: URL?
        var currentURL: URL?
        var isPlaybackPaused = false
        var lastAppliedPauseState: Bool?
        var loadTask: Task<Void, Never>?

        func removeLoopObserver() {
            if let observer = loopObserver, let item = loopItem {
                NotificationCenter.default.removeObserver(observer, name: .AVPlayerItemDidPlayToEndTime, object: item)
            }
            loopObserver = nil
            loopItem = nil
        }

        deinit {
            loadTask?.cancel()
            removeLoopObserver()
            playerItemObserver?.invalidate()
            if let accessed = accessedURL { accessed.stopAccessingSecurityScopedResource() }
            player?.pause()
        }
    }
}

#Preview {
    Text("Video Preview")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
}
