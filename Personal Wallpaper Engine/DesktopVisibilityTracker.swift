import AppKit
import CoreGraphics
import os.log

/// Tracks whether desktop wallpaper windows are visible to the user (Phase 7B P3).
@MainActor
final class DesktopVisibilityTracker {
    private let logger = Logger(subsystem: "com.local.wallpaper", category: "DesktopVisibility")

    private(set) var displayVisible: [CGDirectDisplayID: Bool] = [:]

    var onChange: (@MainActor () -> Void)?

    private var windowObservers: [CGDirectDisplayID: NSObjectProtocol] = [:]
    private var trackedWindows: [CGDirectDisplayID: NSWindow] = [:]

    var anyDisplayVisible: Bool {
        !displayVisible.isEmpty && displayVisible.values.contains(true)
    }

    func syncWindows(_ windows: [CGDirectDisplayID: NSWindow]) {
        let incomingIDs = Set(windows.keys)

        for removedID in Set(trackedWindows.keys).subtracting(incomingIDs) {
            unregister(displayID: removedID)
        }

        for (displayID, window) in windows {
            if trackedWindows[displayID] === window {
                refreshVisibility(displayID: displayID, window: window)
                continue
            }
            register(window: window, displayID: displayID)
        }
    }

    func evaluateAll() {
        for (displayID, window) in trackedWindows {
            refreshVisibility(displayID: displayID, window: window)
        }
    }

    func stop() {
        for displayID in Array(trackedWindows.keys) {
            unregister(displayID: displayID)
        }
    }

    private func register(window: NSWindow, displayID: CGDirectDisplayID) {
        unregister(displayID: displayID)
        trackedWindows[displayID] = window
        refreshVisibility(displayID: displayID, window: window)

        windowObservers[displayID] = NotificationCenter.default.addObserver(
            forName: NSWindow.didChangeOcclusionStateNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let tracked = self.trackedWindows[displayID] else { return }
                self.refreshVisibility(displayID: displayID, window: tracked)
            }
        }
    }

    private func unregister(displayID: CGDirectDisplayID) {
        if let observer = windowObservers.removeValue(forKey: displayID) {
            NotificationCenter.default.removeObserver(observer)
        }
        trackedWindows.removeValue(forKey: displayID)
        displayVisible.removeValue(forKey: displayID)
    }

    private func refreshVisibility(displayID: CGDirectDisplayID, window: NSWindow) {
        let visible = isDesktopWindowVisible(window: window, displayID: displayID)
        let previous = displayVisible[displayID]
        displayVisible[displayID] = visible

        if previous != visible {
            logger.info(
                "Desktop visibility display=\(DisplayController.logLabel(for: displayID), privacy: .public) visible=\(visible)"
            )
            onChange?()
        }
    }

    private func isDesktopWindowVisible(window: NSWindow, displayID: CGDirectDisplayID) -> Bool {
        if CGDisplayIsAsleep(displayID) != 0 {
            return false
        }
        return window.occlusionState.contains(.visible)
    }
}
