import SwiftUI
import AppKit
import AVFoundation

/// A SwiftUI wrapper around AVPlayer for video preview playback
struct VideoPreviewView: NSViewRepresentable {
    let videoURL: URL
    let shouldLoop: Bool
    var isMuted: Bool = true
    
    func makeNSView(context: Context) -> NSView {
        let containerView = NSView()
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.black.cgColor
        containerView.postsFrameChangedNotifications = true
        
        let player = AVPlayer()
        player.isMuted = isMuted
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.backgroundColor = NSColor.clear.cgColor
        playerLayer.frame = containerView.bounds
        
        if let contentLayer = containerView.layer {
            contentLayer.addSublayer(playerLayer)
        }
        
        // Store player and layer for updates
        context.coordinator.player = player
        context.coordinator.playerLayer = playerLayer
        context.coordinator.containerView = containerView
        context.coordinator.currentURL = videoURL

        // Observe frame changes to keep playerLayer sized correctly
        context.coordinator.frameObserver = NotificationCenter.default.addObserver(
            forName: NSView.frameDidChangeNotification,
            object: containerView,
            queue: .main
        ) { _ in
            playerLayer.frame = containerView.bounds
            print("VideoPreviewView: frame updated to \(playerLayer.frame)")
        }

        // Load and play video
        Task {
            await loadAndPlayVideo(player: player, url: videoURL, shouldLoop: shouldLoop, coordinator: context.coordinator)
        }
        
        return containerView
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Update layout when size changes
        if let playerLayer = context.coordinator.playerLayer {
            playerLayer.frame = nsView.bounds
        }
        
        // Update mute state if changed
        if context.coordinator.player?.isMuted != isMuted {
            context.coordinator.player?.isMuted = isMuted
        }
        
        // If the incoming videoURL changed, reload the player with new URL
        if context.coordinator.currentURL?.absoluteString != videoURL.absoluteString {
            context.coordinator.currentURL = videoURL
            Task {
                await loadAndPlayVideo(player: context.coordinator.player ?? AVPlayer(), url: videoURL, shouldLoop: shouldLoop, coordinator: context.coordinator)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    private func loadAndPlayVideo(player: AVPlayer, url: URL, shouldLoop: Bool, coordinator: Coordinator) async {
        print("VideoPreviewView: Starting video load for \(url.path)")

        // Stop any existing loop observer
        if let observer = coordinator.loopObserver, let existingItem = player.currentItem {
            NotificationCenter.default.removeObserver(observer, name: .AVPlayerItemDidPlayToEndTime, object: existingItem)
            coordinator.loopObserver = nil
        }

        // Ensure the coordinator holds a security-scoped access handle while playback is active.
        if url.isFileURL {
            // If we were accessing a previous URL, stop it first
            if let prev = coordinator.accessedURL, prev.path != url.path {
                prev.stopAccessingSecurityScopedResource()
                print("VideoPreviewView: stopped previous security scope for \(prev.path)")
                coordinator.accessedURL = nil
            }

            if coordinator.accessedURL?.path != url.path {
                let didStartAccessing = url.startAccessingSecurityScopedResource()
                print("VideoPreviewView: startAccessingSecurityScopedResource -> \(didStartAccessing) for \(url.path)")
                if didStartAccessing {
                    coordinator.accessedURL = url
                } else {
                    print("VideoPreviewView: WARNING - failed to start security scope for \(url.path)")
                }
            } else {
                print("VideoPreviewView: already accessing security scope for \(url.path)")
            }
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            print("VideoPreviewView: File does not exist at \(url.path)")
            return
        }

        print("VideoPreviewView: File exists, creating asset")
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)

        // Observe player item status for debugging (ready/failure)
        coordinator.playerItemStatusObserver = playerItem.observe(\AVPlayerItem.status, options: [.initial, .new]) { item, _ in
            print("VideoPreviewView: playerItem.status = \(item.status.rawValue)")
            if item.status == .readyToPlay {
                print("VideoPreviewView: playerItem is readyToPlay")
            }
        }

        print("VideoPreviewView: Asset created, setting up playback")

        // Set up loop observer if needed
        if shouldLoop {
            coordinator.loopObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: playerItem,
                queue: .main
            ) { _ in
                print("VideoPreviewView: Video ended, looping")
                player.seek(to: .zero)
                player.play()
            }
        }

        await MainActor.run {
            player.replaceCurrentItem(with: playerItem)
            player.play()
            print("VideoPreviewView: Video playback started")
            if player.currentItem?.status == .failed {
                print("VideoPreviewView: player.currentItem failed with error: \(String(describing: player.currentItem?.error))")
            }
        }

        // Also log asset resource loader errors if any
        if let itemError = playerItem.error {
            print("VideoPreviewView: playerItem.error after setup -> \(itemError.localizedDescription)")
        }
    }
    
    class Coordinator {
        var player: AVPlayer?
        var playerLayer: AVPlayerLayer?
        weak var containerView: NSView?
        var loopObserver: NSObjectProtocol?
        var currentURL: URL?
        var frameObserver: NSObjectProtocol?
        var playerItemStatusObserver: NSKeyValueObservation?
        var accessedURL: URL?

        deinit {
            if let observer = loopObserver, let item = player?.currentItem {
                NotificationCenter.default.removeObserver(observer, name: .AVPlayerItemDidPlayToEndTime, object: item)
            }
            if let frameObs = frameObserver {
                NotificationCenter.default.removeObserver(frameObs)
            }
            playerItemStatusObserver?.invalidate()
            if let accessed = accessedURL {
                accessed.stopAccessingSecurityScopedResource()
                print("VideoPreviewView: deinit - stopped security scope for \(accessed.path)")
            }
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
