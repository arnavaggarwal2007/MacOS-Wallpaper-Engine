import SwiftUI
import AppKit
import AVFoundation
import AVKit

/// A SwiftUI wrapper around `AVPlayerView` for video preview playback.
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

        // Start playback
        Task { await loadAndPlay(player: player, url: videoURL, shouldLoop: shouldLoop, coordinator: context.coordinator) }

        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        if context.coordinator.player?.isMuted != isMuted {
            context.coordinator.player?.isMuted = isMuted
        }

        if isPlaybackPaused {
            context.coordinator.player?.pause()
        } else if context.coordinator.player?.rate == 0, context.coordinator.currentURL != nil {
            context.coordinator.player?.play()
        }

        if context.coordinator.currentURL?.absoluteString != videoURL.absoluteString {
            context.coordinator.currentURL = videoURL
            Task { await loadAndPlay(player: context.coordinator.player ?? AVPlayer(), url: videoURL, shouldLoop: shouldLoop, coordinator: context.coordinator) }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    private func loadAndPlay(player: AVPlayer, url: URL, shouldLoop: Bool, coordinator: Coordinator) async {
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
            } else {
                if debug { print("VideoPreviewView: already accessing scope for \(url.path)") }
            }
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            if debug { print("VideoPreviewView: file missing at \(url.path)") }
            return
        }

        let asset = AVURLAsset(url: url)
        if debug { print("VideoPreviewView: asset created") }
        let item = AVPlayerItem(asset: asset)

        coordinator.playerItemObserver = item.observe(\AVPlayerItem.status, options: [.initial, .new]) { item, _ in
            guard debug else { return }
            print("VideoPreviewView: playerItem.status = \(item.status.rawValue)")
            if item.status == .readyToPlay {
                print("VideoPreviewView: playerItem readyToPlay")
            } else if item.status == .failed {
                print("VideoPreviewView: playerItem failed -> \(String(describing: item.error))")
            }
        }

        if shouldLoop {
            coordinator.loopObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { _ in
                if debug { print("VideoPreviewView: didPlayToEnd, looping") }
                player.seek(to: .zero)
                player.play()
            }
        }

        await MainActor.run {
            player.replaceCurrentItem(with: item)
            player.play()
            if debug { print("VideoPreviewView: player.play()") }
        }
    }

    class Coordinator {
        var player: AVPlayer?
        var playerView: AVPlayerView?
        var loopObserver: NSObjectProtocol?
        var playerItemObserver: NSKeyValueObservation?
        var accessedURL: URL?
        var currentURL: URL?

        deinit {
            if let observer = loopObserver, let item = player?.currentItem {
                NotificationCenter.default.removeObserver(observer, name: .AVPlayerItemDidPlayToEndTime, object: item)
            }
            playerItemObserver?.invalidate()
            if let accessed = accessedURL { accessed.stopAccessingSecurityScopedResource() }
            player?.pause()
        }
    }
}

#Preview {
    // For preview purposes, show a placeholder
    Text("Video Preview")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
}
