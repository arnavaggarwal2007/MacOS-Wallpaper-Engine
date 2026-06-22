import AppKit

/// Background agent mode: hide dock icon when no windows are visible (Wallspace-style).
@MainActor
enum DockAgentPolicy {
    static func applyInitialPolicy() {
        updateDockVisibility(hasVisibleMainWindows: false)
    }

    static func updateDockVisibility(hasVisibleMainWindows: Bool) {
        let app = NSApplication.shared
        let target: NSApplication.ActivationPolicy = hasVisibleMainWindows ? .regular : .accessory
        guard app.activationPolicy() != target else { return }
        app.setActivationPolicy(target)
    }

    static func mainWindowsVisible() -> Bool {
        NSApplication.shared.windows.contains { window in
            window.isVisible && !window.isMiniaturized && window.canBecomeMain
        }
    }
}
