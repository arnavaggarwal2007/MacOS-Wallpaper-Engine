import AppKit
import Combine
import os.log

final class MenuBarController: NSObject, ObservableObject {
    private let logger = Logger(subsystem: "MenuBarController", category: "menu")
    private weak var viewModel: AppViewModel?
    private var statusItem: NSStatusItem?
    private var cancellables = Set<AnyCancellable>()

    func setup(with viewModel: AppViewModel) {
        self.viewModel = viewModel
        
        // Create status bar item with fixed width
        let statusBar = NSStatusBar.system
        statusItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        
        guard let button = statusItem?.button else {
            logger.error("Failed to get status item button")
            return
        }
        
        // Set initial icon and color
        updateIcon(isPlaying: true, isMuted: true)
        
        // Create and assign menu
        let menu = createMenu()
        statusItem?.menu = menu
        
        // Subscribe to ViewModel changes to update menu state
        viewModel.objectWillChange
            .sink { [weak self] in
                self?.updateMenuState()
            }
            .store(in: &cancellables)
        
        logger.debug("Menu bar initialized successfully")
    }
    
    private func createMenu() -> NSMenu {
        let menu = NSMenu()
        
        // Play/Pause toggle
        let playPauseItem = NSMenuItem(
            title: "Pause",
            action: #selector(handlePlayPauseAction),
            keyEquivalent: "p"
        )
        playPauseItem.target = self
        menu.addItem(playPauseItem)
        
        // Mute/Unmute toggle
        let muteItem = NSMenuItem(
            title: "Mute",
            action: #selector(handleMuteAction),
            keyEquivalent: "m"
        )
        muteItem.target = self
        menu.addItem(muteItem)
        
        // Separator
        menu.addItem(NSMenuItem.separator())
        
        // Preferences
        let prefsItem = NSMenuItem(
            title: "Preferences...",
            action: #selector(handlePreferencesAction),
            keyEquivalent: ","
        )
        prefsItem.target = self
        menu.addItem(prefsItem)
        
        // Separator
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(handleQuitAction),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        return menu
    }
    
    // MARK: - Menu Actions
    
    @objc private func handlePlayPauseAction() {
        guard let viewModel = viewModel else { return }
        Task { @MainActor in
            await viewModel.togglePlayback()
        }
        logger.debug("Play/Pause toggled from menu")
    }
    
    @objc private func handleMuteAction() {
        guard let viewModel = viewModel else { return }
        Task { @MainActor in
            await viewModel.toggleMute()
        }
        logger.debug("Mute toggled from menu")
    }
    
    @objc private func handlePreferencesAction() {
        guard let viewModel = viewModel else { return }
        Task { @MainActor in
            await viewModel.openPreferences()
        }
        logger.debug("Preferences opened from menu")
    }
    
    @objc private func handleQuitAction() {
        NSApplication.shared.terminate(self)
    }
    
    // MARK: - State Management
    
    private func updateMenuState() {
        guard let menu = statusItem?.menu else { return }
        
        let isMuted = viewModel?.isMuted ?? true
        let isPlaying = viewModel?.isPlaying ?? false
        
        // Update Play/Pause item
        if let playPauseItem = menu.items.first {
            playPauseItem.title = isPlaying ? "Pause" : "Play"
        }
        
        // Update Mute item
        if menu.items.count > 1, let muteItem = menu.items[1] as NSMenuItem? {
            muteItem.title = isMuted ? "Unmute" : "Mute"
        }
        
        // Update icon
        updateIcon(isPlaying: isPlaying, isMuted: isMuted)
    }
    
    private func updateIcon(isPlaying: Bool, isMuted: Bool) {
        guard let button = statusItem?.button else { return }
        
        // Use system symbols or text indicators
        let iconText = isMuted ? "🔇" : (isPlaying ? "▶" : "⏸")
        button.title = iconText
    }
}
