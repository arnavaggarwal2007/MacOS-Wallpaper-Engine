import AppKit
import AVFoundation
import SwiftUI

/// Hero preview that reuses the desktop AVPlayer when the same file is already decoding (Phase 7D).
struct UnifiedVideoPreviewView: NSViewRepresentable {
    let appModel: AppViewModel
    let videoURL: URL
    var isPlaybackPaused: Bool
    /// Global desktop pause: keep hero layer visible at the held desktop frame.
    var holdDesktopFrame: Bool = false
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
        context.coordinator.holdDesktopFrame = holdDesktopFrame
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
        var holdDesktopFrame = false
        var onAttachStateChanged: ((Bool) -> Void)?
        var isAttached = false
        var attachedURLKey: String?
        private var pendingDeferredAttach = false
        private var pendingLayoutWork = false
        private var pendingHoldFrameRetry = false

        func syncAttachState() {
            guard let appModel, let container = containerView, let url = videoURL else { return }

            if isPlaybackPaused, !holdDesktopFrame {
                if isAttached {
                    appModel.setHeroPreviewLayerHidden(true)
                }
                return
            }

            if holdDesktopFrame {
                if isAttached,
                   attachedURLKey == url.absoluteString,
                   containerView === container {
                    if !appModel.isHeroPreviewAttached(to: container) {
                        isAttached = false
                        attachedURLKey = nil
                        attemptAttach()
                        return
                    }
                    appModel.setHeroPreviewLayerHidden(false)
                    appModel.updateHeroPreviewLayerFrame(in: container)
                    return
                }
                if attachedURLKey != url.absoluteString {
                    isAttached = false
                    attachedURLKey = nil
                }
                attemptAttach()
                return
            }

            let urlKey = url.absoluteString
            if isAttached,
               attachedURLKey == urlKey,
               containerView === container {
                if !appModel.isHeroPreviewAttached(to: container) {
                    isAttached = false
                    attachedURLKey = nil
                    attemptAttach()
                    return
                }
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
            guard !isPlaybackPaused || holdDesktopFrame else { return }
            if isAttached, let container = containerView {
                if appModel?.isHeroPreviewAttached(to: container) != true {
                    isAttached = false
                    attachedURLKey = nil
                    attemptAttach()
                    return
                }
                appModel?.setHeroPreviewLayerHidden(false)
                appModel?.updateHeroPreviewLayerFrame(in: container)
                return
            }
            attemptAttach()
        }

        private func attemptAttach() {
            guard let appModel, let container = containerView, let url = videoURL else { return }
            guard !isPlaybackPaused || holdDesktopFrame else { return }

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
                if holdDesktopFrame, !pendingHoldFrameRetry {
                    scheduleHoldFrameRetry()
                } else {
                    reportAttachState(false)
                }
            }
        }

        private func scheduleHoldFrameRetry() {
            pendingHoldFrameRetry = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self else { return }
                self.pendingHoldFrameRetry = false
                self.attemptAttach()
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
