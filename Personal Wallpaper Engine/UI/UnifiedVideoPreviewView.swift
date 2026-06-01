import AppKit
import AVFoundation
import SwiftUI

/// Hero preview that reuses the desktop AVPlayer when the same file is already decoding (Phase 7D).
struct UnifiedVideoPreviewView: NSViewRepresentable {
    let appModel: AppViewModel
    let videoURL: URL
    var isPlaybackPaused: Bool
    var onAttachStateChanged: ((Bool) -> Void)?

    func makeNSView(context: Context) -> PreviewContainerView {
        let view = PreviewContainerView()
        view.wantsLayer = true
        context.coordinator.containerView = view
        view.onLayout = { [weak coordinator = context.coordinator] in
            coordinator?.scheduleLayoutWork()
        }
        return view
    }

    func updateNSView(_ nsView: PreviewContainerView, context: Context) {
        context.coordinator.appModel = appModel
        context.coordinator.containerView = nsView
        context.coordinator.videoURL = videoURL
        context.coordinator.isPlaybackPaused = isPlaybackPaused
        context.coordinator.onAttachStateChanged = onAttachStateChanged
        context.coordinator.syncAttachState()
    }

    static func dismantleNSView(_ nsView: PreviewContainerView, coordinator: Coordinator) {
        MainActor.assumeIsolated {
            coordinator.appModel?.detachHeroPreviewLayer()
            coordinator.containerView = nil
            coordinator.isAttached = false
            coordinator.attachedURLKey = nil
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    @MainActor
    final class Coordinator {
        weak var appModel: AppViewModel?
        weak var containerView: PreviewContainerView?
        var videoURL: URL?
        var isPlaybackPaused = false
        var onAttachStateChanged: ((Bool) -> Void)?
        var isAttached = false
        var attachedURLKey: String?
        private var pendingDeferredAttach = false
        private var pendingLayoutWork = false

        func syncAttachState() {
            guard let appModel, let container = containerView, let url = videoURL else { return }

            if isPlaybackPaused {
                if isAttached {
                    appModel.setHeroPreviewLayerHidden(true)
                }
                return
            }

            let urlKey = url.absoluteString
            if isAttached,
               attachedURLKey == urlKey,
               containerView === container {
                appModel.setHeroPreviewLayerHidden(false)
                appModel.updateHeroPreviewLayerFrame(in: container)
                return
            }

            if attachedURLKey != urlKey {
                isAttached = false
                attachedURLKey = nil
            }

            attemptAttach()
        }

        func scheduleLayoutWork() {
            guard !pendingLayoutWork else { return }
            pendingLayoutWork = true
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.pendingLayoutWork = false
                self.handleLayoutDeferred()
            }
        }

        private func handleLayoutDeferred() {
            guard !isPlaybackPaused else { return }
            if isAttached, let container = containerView {
                appModel?.setHeroPreviewLayerHidden(false)
                appModel?.updateHeroPreviewLayerFrame(in: container)
                return
            }
            attemptAttach()
        }

        private func attemptAttach() {
            guard let appModel, let container = containerView, let url = videoURL else { return }
            guard !isPlaybackPaused else { return }

            if container.bounds.isEmpty {
                scheduleDeferredAttach()
                return
            }

            let attached = appModel.attachHeroPreviewLayer(in: container, url: url)
            isAttached = attached
            if attached {
                attachedURLKey = url.absoluteString
                appModel.setHeroPreviewLayerHidden(false)
                reportAttachState(true)
            } else {
                attachedURLKey = nil
                reportAttachState(false)
            }
        }

        private func scheduleDeferredAttach() {
            guard !pendingDeferredAttach else { return }
            pendingDeferredAttach = true
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.pendingDeferredAttach = false
                self.attemptAttach()
            }
        }

        private func reportAttachState(_ attached: Bool) {
            guard let callback = onAttachStateChanged else { return }
            if attached {
                callback(true)
            } else {
                DispatchQueue.main.async {
                    callback(false)
                }
            }
        }
    }

    /// Host view whose layer subtree receives the shared preview layer.
    final class PreviewContainerView: NSView {
        var onLayout: (() -> Void)?

        override func layout() {
            super.layout()
            onLayout?()
        }
    }
}
