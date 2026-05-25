import AppKit
import os.log

/// Tracks whether the in-app hero preview should keep decoding (Phase 7B P1b).
@MainActor
final class AppPreviewVisibilityMonitor {
    private let logger = Logger(subsystem: "com.local.wallpaper", category: "AppPreviewVisibility")
    private static let debounceIntervalNs: UInt64 = 300_000_000

    private(set) var isAppActive: Bool = NSApplication.shared.isActive
    private(set) var isAppHidden: Bool = NSApplication.shared.isHidden
    private(set) var isMainWindowOccluded: Bool = false

    var onChange: (@MainActor () -> Void)?

    private var appObservers: [NSObjectProtocol] = []
    private var windowObserver: NSObjectProtocol?
    private weak var observedWindow: NSWindow?
    private var debounceTask: Task<Void, Never>?
    private var lastNotifiedSnapshot: Snapshot?

    private struct Snapshot: Equatable {
        let isAppActive: Bool
        let isAppHidden: Bool
        let isMainWindowOccluded: Bool
    }

    func start() {
        guard appObservers.isEmpty else { return }

        refreshAppState()
        attachMainWindowIfNeeded()
        lastNotifiedSnapshot = currentSnapshot()

        let center = NotificationCenter.default
        appObservers = [
            center.addObserver(forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in self?.setAppActive(true) }
            },
            center.addObserver(forName: NSApplication.didResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in self?.setAppActive(false) }
            },
            center.addObserver(forName: NSApplication.didHideNotification, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in self?.setAppHidden(true) }
            },
            center.addObserver(forName: NSApplication.didUnhideNotification, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in self?.setAppHidden(false) }
            },
            center.addObserver(forName: NSApplication.didFinishLaunchingNotification, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in self?.attachMainWindowIfNeeded() }
            },
            center.addObserver(forName: NSWindow.didBecomeKeyNotification, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in self?.attachMainWindowIfNeeded() }
            },
        ]
    }

    func stop() {
        debounceTask?.cancel()
        debounceTask = nil
        for observer in appObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        appObservers.removeAll()
        detachWindowObserver()
    }

    private func setAppActive(_ active: Bool) {
        guard isAppActive != active else { return }
        isAppActive = active
        scheduleDebouncedNotify(reason: "App active=\(active)")
    }

    private func setAppHidden(_ hidden: Bool) {
        guard isAppHidden != hidden else { return }
        isAppHidden = hidden
        scheduleDebouncedNotify(reason: "App hidden=\(hidden)")
    }

    private func setMainWindowOccluded(_ occluded: Bool) {
        guard isMainWindowOccluded != occluded else { return }
        isMainWindowOccluded = occluded
        scheduleDebouncedNotify(reason: "Main window occluded=\(occluded)")
    }

    private func scheduleDebouncedNotify(reason: String) {
        debounceTask?.cancel()
        debounceTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: Self.debounceIntervalNs)
            } catch {
                return
            }
            guard let self, !Task.isCancelled else { return }
            self.publishIfChanged(reason: reason)
        }
    }

    private func publishIfChanged(reason: String) {
        let snapshot = currentSnapshot()
        guard snapshot != lastNotifiedSnapshot else { return }
        lastNotifiedSnapshot = snapshot
        logger.info("\(reason, privacy: .public) — hero preview visibility updated")
        onChange?()
    }

    private func currentSnapshot() -> Snapshot {
        Snapshot(
            isAppActive: isAppActive,
            isAppHidden: isAppHidden,
            isMainWindowOccluded: isMainWindowOccluded
        )
    }

    private func attachMainWindowIfNeeded() {
        let window = NSApplication.shared.mainWindow
            ?? NSApplication.shared.keyWindow
            ?? NSApplication.shared.windows.first(where: { $0.canBecomeKey && $0.isVisible })

        guard let window else { return }

        if observedWindow === window {
            updateOcclusion(for: window)
            return
        }

        detachWindowObserver()
        observedWindow = window
        updateOcclusion(for: window)

        windowObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didChangeOcclusionStateNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let window = self.observedWindow else { return }
                self.updateOcclusion(for: window)
            }
        }
    }

    private func detachWindowObserver() {
        if let windowObserver {
            NotificationCenter.default.removeObserver(windowObserver)
            self.windowObserver = nil
        }
        observedWindow = nil
        isMainWindowOccluded = false
    }

    private func refreshAppState() {
        isAppActive = NSApplication.shared.isActive
        isAppHidden = NSApplication.shared.isHidden
    }

    private func updateOcclusion(for window: NSWindow) {
        let occluded = !window.occlusionState.contains(.visible)
        setMainWindowOccluded(occluded)
    }
}
