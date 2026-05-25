import SwiftUI
import AppKit
import AVFoundation
import AVKit

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

        Task {
            await loadAndPlay(
                player: player,
                url: videoURL,
                shouldLoop: shouldLoop,
                coordinator: context.coordinator
            )
        }

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
            Task {
                await loadAndPlay(
                    player: context.coordinator.player ?? AVPlayer(),
                    url: videoURL,
                    shouldLoop: shouldLoop,
                    coordinator: context.coordinator
                )
            }
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

    private func loadAndPlay(
        player: AVPlayer,
        url: URL,
        shouldLoop: Bool,
        coordinator: Coordinator
    ) async {
        let debug = SettingsStore.shared.debugDiagnosticsEnabled
        if debug { print("VideoPreviewView: loadAndPlay -> \(url.path)") }

        // Manage security-scoped access for file URLs
        if url.isFileURL {
            if let prev = coordinator.accessedURL, prev.path != url.path {
                prev.stopAccessingSecurityScopedResource()
                coordinator.accessedURL = nil
                if debug { print("VideoPreviewView: stopped scope for \(prev.path)") }
            }
            if coordinator.accessedURL?.path != url.path {
                let didStart = url.startAccessingSecurityScopedResource()
                if debug { print("VideoPreviewView: startAccessingScope -> \(didStart) for \(url.path)") }
                if didStart { coordinator.accessedURL = url }
            }
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            if debug { print("VideoPreviewView: file missing at \(url.path)") }
            return
        }

        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        PerformanceProfileConfiguration.apply(to: item, profile: SettingsStore.shared.performanceProfile)

        coordinator.playerItemObserver = item.observe(\AVPlayerItem.status, options: [.initial, .new]) { item, _ in
            guard debug else { return }
            print("VideoPreviewView: playerItem.status = \(item.status.rawValue)")
        }

        if shouldLoop {
            if let observer = coordinator.loopObserver, let oldItem = coordinator.loopItem {
                NotificationCenter.default.removeObserver(observer, name: .AVPlayerItemDidPlayToEndTime, object: oldItem)
            }
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

        let shouldStartPlayback = !coordinator.isPlaybackPaused
        await MainActor.run {
            player.replaceCurrentItem(with: item)
            if shouldStartPlayback {
                player.play()
                if debug { print("VideoPreviewView: player.play()") }
            } else {
                player.pause()
                if debug { print("VideoPreviewView: player.pause() after load (scroll pause)") }
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

        deinit {
            if let observer = loopObserver, let item = loopItem {
                NotificationCenter.default.removeObserver(observer, name: .AVPlayerItemDidPlayToEndTime, object: item)
            }
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
