import AppKit
import Combine
import os.log

// MARK: - Preview Header

@MainActor
private final class MenuBarPreviewHeaderView: NSView {
    static let preferredWidth: CGFloat = 248
    static let preferredHeight: CGFloat = 160

    private let imageView = NSImageView()
    private let captionField = NSTextField(labelWithString: "")
    private let statusField = NSTextField(labelWithString: "")
    private let horizontalInset: CGFloat = 12
    private let bottomInset: CGFloat = 6
    private let bannerHeight: CGFloat = 112

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        translatesAutoresizingMaskIntoConstraints = true

        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.wantsLayer = true
        imageView.layer?.cornerRadius = 8
        imageView.layer?.masksToBounds = true

        captionField.font = .systemFont(ofSize: 11, weight: .medium)
        captionField.textColor = .labelColor
        captionField.lineBreakMode = .byTruncatingMiddle
        captionField.isEditable = false
        captionField.isBordered = false
        captionField.drawsBackground = false

        statusField.font = .systemFont(ofSize: 10)
        statusField.textColor = .secondaryLabelColor
        statusField.lineBreakMode = .byTruncatingTail
        statusField.isEditable = false
        statusField.isBordered = false
        statusField.drawsBackground = false

        addSubview(imageView)
        addSubview(captionField)
        addSubview(statusField)
    }

    override func layout() {
        super.layout()
        let width = bounds.width
        let textWidth = max(0, width - horizontalInset * 2)
        let captionHeight: CGFloat = 14
        let statusHeight: CGFloat = 12
        let captionStatusGap: CGFloat = 2
        let imageCaptionGap: CGFloat = 6

        statusField.frame = NSRect(
            x: horizontalInset,
            y: bottomInset,
            width: textWidth,
            height: statusHeight
        )
        captionField.frame = NSRect(
            x: horizontalInset,
            y: bottomInset + statusHeight + captionStatusGap,
            width: textWidth,
            height: captionHeight
        )

        let captionTop = bottomInset + statusHeight + captionStatusGap + captionHeight
        imageView.frame = NSRect(
            x: horizontalInset,
            y: captionTop + imageCaptionGap,
            width: textWidth,
            height: bannerHeight
        )
    }

    func update(image: NSImage?, caption: String, statusLine: String) {
        imageView.image = image
        imageView.contentTintColor = nil
        if image == nil {
            imageView.image = NSImage(systemSymbolName: "photo", accessibilityDescription: nil)
            imageView.contentTintColor = .tertiaryLabelColor
        }
        captionField.stringValue = caption
        statusField.stringValue = statusLine
        needsLayout = true
    }
}

// MARK: - Menu Bar Controller

@MainActor
final class MenuBarController: NSObject, ObservableObject, NSMenuDelegate {
    private let logger = Logger(subsystem: "MenuBarController", category: "menu")
    private weak var viewModel: AppViewModel?
    private var statusItem: NSStatusItem?
    private var cancellables = Set<AnyCancellable>()
    private var menu: NSMenu?
    private var previewHeaderView: MenuBarPreviewHeaderView?
    private var previewHeaderItem: NSMenuItem?
    private var quickModeMenuItem: NSMenuItem?
    private var applySavedMenuItem: NSMenuItem?
    private var recentsMenuItem: NSMenuItem?
    private var diagnosticsItem: NSMenuItem?
    private var launchAtLoginItem: NSMenuItem?
    private var isMenuOpen = false
    private var lastIconState: IconState?
    private var thumbnailTask: Task<Void, Never>?

    func setup(with viewModel: AppViewModel) {
        self.viewModel = viewModel

        let statusBar = NSStatusBar.system
        statusItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)

        guard statusItem?.button != nil else {
            logger.error("Failed to get status item button")
            return
        }

        updateIcon(isPlaying: true, isMuted: true)

        let menu = createMenu()
        menu.delegate = self
        self.menu = menu
        statusItem?.menu = menu

        // `objectWillChange` fires for every view-model change, most of which the menu bar does not
        // reflect. While the menu is closed only the status icon is visible, and `menuWillOpen`
        // refreshes the full menu anyway, so titles are rebuilt at the point they can be seen.
        viewModel.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                if self.isMenuOpen {
                    self.updateMenuState()
                } else {
                    self.updateIconFromViewModel()
                }
            }
            .store(in: &cancellables)

        logger.debug("Menu bar initialized successfully")
    }

    // MARK: - NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        guard let viewModel else { return }
        isMenuOpen = true
        viewModel.menuBarContextDisplayID = detectMenuBarDisplayID()
        rebuildDynamicSubmenus()
        refreshPreviewHeader()
        updateMenuState()
    }

    func menuDidClose(_ menu: NSMenu) {
        isMenuOpen = false
        thumbnailTask?.cancel()
        viewModel?.menuBarContextDisplayID = nil
    }

    // MARK: - Menu Construction

    private func createMenu() -> NSMenu {
        let menu = NSMenu()

        let headerView = makePreviewHeaderView()
        previewHeaderView = headerView
        let headerItem = NSMenuItem()
        assignPreviewHeader(headerView, to: headerItem)
        previewHeaderItem = headerItem
        menu.addItem(headerItem)

        menu.addItem(NSMenuItem.separator())

        addActionItem(to: menu, title: "Pause", action: #selector(handlePlayPauseAction), key: "")
        addActionItem(to: menu, title: "Mute", action: #selector(handleMuteAction), key: "m")

        menu.addItem(NSMenuItem.separator())

        let quickModeItem = NSMenuItem(title: "Quick Mode", action: nil, keyEquivalent: "")
        quickModeItem.submenu = NSMenu()
        quickModeMenuItem = quickModeItem
        menu.addItem(quickModeItem)

        addActionItem(to: menu, title: "Pause Until Plugged In", action: #selector(handlePauseUntilPluggedInAction), key: "")
        addActionItem(to: menu, title: "Use Battery Saver Profile", action: #selector(handleBatterySaverAction), key: "")

        menu.addItem(NSMenuItem.separator())

        let applySavedItem = NSMenuItem(title: "Apply Saved…", action: nil, keyEquivalent: "")
        applySavedItem.submenu = NSMenu()
        applySavedMenuItem = applySavedItem
        menu.addItem(applySavedItem)

        let recentsItem = NSMenuItem(title: "Library Recents", action: nil, keyEquivalent: "")
        recentsItem.submenu = NSMenu()
        recentsMenuItem = recentsItem
        menu.addItem(recentsItem)

        menu.addItem(NSMenuItem.separator())

        addActionItem(to: menu, title: "Show Main Window", action: #selector(handleShowMainWindowAction), key: "")
        addActionItem(to: menu, title: "Preferences…", action: #selector(handlePreferencesAction), key: ",")

        menu.addItem(NSMenuItem.separator())

        let diagnostics = NSMenuItem(title: "CPU — · — MB", action: nil, keyEquivalent: "")
        diagnostics.isEnabled = false
        diagnosticsItem = diagnostics
        menu.addItem(diagnostics)

        addActionItem(to: menu, title: "Clear Thumbnail Cache", action: #selector(handleClearCacheAction), key: "")

        let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(handleLaunchAtLoginAction), keyEquivalent: "")
        loginItem.target = self
        launchAtLoginItem = loginItem
        menu.addItem(loginItem)

        menu.addItem(NSMenuItem.separator())

        addActionItem(to: menu, title: "Quit", action: #selector(handleQuitAction), key: "q")

        return menu
    }

    private func makePreviewHeaderView() -> MenuBarPreviewHeaderView {
        let size = NSSize(
            width: MenuBarPreviewHeaderView.preferredWidth,
            height: MenuBarPreviewHeaderView.preferredHeight
        )
        return MenuBarPreviewHeaderView(frame: NSRect(origin: .zero, size: size))
    }

    private func assignPreviewHeader(_ headerView: MenuBarPreviewHeaderView, to headerItem: NSMenuItem) {
        headerView.frame = NSRect(
            x: 0,
            y: 0,
            width: MenuBarPreviewHeaderView.preferredWidth,
            height: MenuBarPreviewHeaderView.preferredHeight
        )
        headerItem.view = headerView
    }

    private func addActionItem(to menu: NSMenu, title: String, action: Selector, key: String) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        menu.addItem(item)
    }

    private func rebuildDynamicSubmenus() {
        rebuildQuickModeSubmenu()
        rebuildApplySavedSubmenu()
        rebuildRecentsSubmenu()
    }

    private func rebuildQuickModeSubmenu() {
        guard let submenu = quickModeMenuItem?.submenu, let viewModel else { return }
        submenu.removeAllItems()

        for mode in QuickMode.selectableCases {
            if mode == .pinnedSetup {
                if let pinnedName = viewModel.pinnedSetupName {
                    let item = NSMenuItem(
                        title: "Pinned: \(pinnedName)",
                        action: #selector(handlePinnedSetupAction(_:)),
                        keyEquivalent: ""
                    )
                    item.target = self
                    item.representedObject = pinnedName
                    if viewModel.quickMode == .pinnedSetup {
                        item.state = .on
                    }
                    submenu.addItem(item)
                } else {
                    let item = NSMenuItem(
                        title: "Pin a setup in Setups…",
                        action: #selector(handleOpenSetupsAction),
                        keyEquivalent: ""
                    )
                    item.target = self
                    submenu.addItem(item)
                }
            } else {
                let item = NSMenuItem(title: mode.displayName, action: #selector(handleQuickModeAction(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = mode.rawValue
                if viewModel.quickMode == mode {
                    item.state = .on
                }
                submenu.addItem(item)
            }
        }

        if viewModel.quickMode == .custom {
            submenu.addItem(NSMenuItem.separator())
            let item = NSMenuItem(title: "Return to Last Mode", action: #selector(handleReturnToLastModeAction), keyEquivalent: "")
            item.target = self
            submenu.addItem(item)
        }
    }

    private func rebuildApplySavedSubmenu() {
        guard let submenu = applySavedMenuItem?.submenu, let viewModel else { return }
        submenu.removeAllItems()

        let collectionsMenu = NSMenu()
        let collectionNames = viewModel.savedCollections.keys.sorted()
        if collectionNames.isEmpty {
            collectionsMenu.addItem(disabledItem("No collections"))
        } else {
            for name in collectionNames {
                let item = NSMenuItem(title: name, action: #selector(handleApplyCollectionAction(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = name
                collectionsMenu.addItem(item)
            }
        }
        let collectionsParent = NSMenuItem(title: "Collections", action: nil, keyEquivalent: "")
        collectionsParent.submenu = collectionsMenu
        submenu.addItem(collectionsParent)

        let setupsMenu = NSMenu()
        let setupNames = viewModel.allSetupNames()
        if setupNames.isEmpty {
            setupsMenu.addItem(disabledItem("No setups"))
        } else {
            for name in setupNames {
                let item = NSMenuItem(title: name, action: #selector(handleRestoreSetupAction(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = name
                setupsMenu.addItem(item)
            }
        }
        let setupsParent = NSMenuItem(title: "Desktop Setups", action: nil, keyEquivalent: "")
        setupsParent.submenu = setupsMenu
        submenu.addItem(setupsParent)
    }

    private func rebuildRecentsSubmenu() {
        guard let submenu = recentsMenuItem?.submenu, let viewModel else { return }
        submenu.removeAllItems()

        let recents = viewModel.recentLibraryItems()
        if recents.isEmpty {
            submenu.addItem(disabledItem("No recent library items"))
            return
        }

        for item in recents {
            let menuItem = NSMenuItem(title: item.displayName, action: #selector(handleRecentLibraryItemAction(_:)), keyEquivalent: "")
            menuItem.target = self
            menuItem.representedObject = item.id
            submenu.addItem(menuItem)
        }
    }

    private func disabledItem(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    // MARK: - Preview

    private func refreshPreviewHeader() {
        guard let viewModel, let previewHeaderView, let previewHeaderItem else { return }
        assignPreviewHeader(previewHeaderView, to: previewHeaderItem)
        previewHeaderView.update(
            image: nil,
            caption: viewModel.menuBarPreviewCaption(),
            statusLine: viewModel.menuBarStatusLine()
        )

        thumbnailTask?.cancel()
        guard let url = viewModel.menuBarPreviewURL() else { return }

        thumbnailTask = Task { @MainActor in
            let image = await viewModel.menuBarThumbnailImage(for: url)
            guard !Task.isCancelled else { return }
            previewHeaderView.update(
                image: image,
                caption: viewModel.menuBarPreviewCaption(),
                statusLine: viewModel.menuBarStatusLine()
            )
        }
    }

    private func detectMenuBarDisplayID() -> CGDirectDisplayID? {
        if let screen = statusItem?.button?.window?.screen {
            return screen.displayID
        }
        let point = NSEvent.mouseLocation
        for screen in NSScreen.screens where screen.frame.contains(point) {
            return screen.displayID
        }
        return NSScreen.screens.first?.displayID
    }

    // MARK: - Actions

    @objc private func handlePlayPauseAction() {
        viewModel?.handlePlayPauseButtonPressed(source: .menuBar)
    }

    @objc private func handleMuteAction() {
        guard let viewModel else { return }
        Task { await viewModel.toggleMute() }
    }

    @objc private func handleQuickModeAction(_ sender: NSMenuItem) {
        guard let viewModel, let raw = sender.representedObject as? String, let mode = QuickMode(rawValue: raw) else { return }
        runAfterMenuDismiss { await viewModel.applyQuickMode(mode, activateApp: true) }
    }

    @objc private func handlePinnedSetupAction(_ sender: NSMenuItem) {
        guard let viewModel else { return }
        runAfterMenuDismiss { await viewModel.applyQuickMode(.pinnedSetup, activateApp: true) }
    }

    @objc private func handleReturnToLastModeAction() {
        guard let viewModel else { return }
        runAfterMenuDismiss { await viewModel.returnToLastCommittedQuickMode(activateApp: true) }
    }

    private func runAfterMenuDismiss(_ operation: @escaping () async -> Void) {
        DispatchQueue.main.async {
            Task { await operation() }
        }
    }

    @objc private func handlePauseUntilPluggedInAction() {
        viewModel?.enablePauseUntilPluggedIn()
    }

    @objc private func handleBatterySaverAction() {
        viewModel?.applyBatterySaverProfile()
    }

    @objc private func handleApplyCollectionAction(_ sender: NSMenuItem) {
        guard let viewModel, let name = sender.representedObject as? String else { return }
        Task { _ = await viewModel.applyCollection(name: name) }
    }

    @objc private func handleRestoreSetupAction(_ sender: NSMenuItem) {
        guard let viewModel, let name = sender.representedObject as? String else { return }
        Task { _ = await viewModel.restoreSetup(name: name) }
    }

    @objc private func handleRecentLibraryItemAction(_ sender: NSMenuItem) {
        guard let viewModel,
              let itemID = sender.representedObject as? String,
              let item = viewModel.libraryItems.first(where: { $0.id == itemID }) else { return }
        Task { await viewModel.applyRecentLibraryItem(item) }
    }

    @objc private func handleShowMainWindowAction() {
        viewModel?.bringAppToFront()
    }

    @objc private func handleOpenSetupsAction() {
        viewModel?.bringAppToFront(selecting: .setups)
    }

    @objc private func handlePreferencesAction() {
        viewModel?.bringAppToFront(selecting: .settings)
    }

    @objc private func handleClearCacheAction() {
        viewModel?.clearLibraryThumbnailCache()
    }

    @objc private func handleLaunchAtLoginAction() {
        guard let viewModel else { return }
        Task { await viewModel.toggleLaunchOnLogin() }
    }

    @objc private func handleQuitAction() {
        NSApplication.shared.terminate(self)
    }

    // MARK: - State

    /// Status-icon-only refresh for changes that arrive while the menu is closed.
    private func updateIconFromViewModel() {
        guard let viewModel else { return }
        updateIcon(isPlaying: viewModel.isPlaying, isMuted: viewModel.isMuted)
    }

    private func updateMenuState() {
        guard let menu, let viewModel else { return }

        let isMuted = viewModel.isMuted
        let isPlaying = viewModel.isPlaying

        if let playPauseItem = menu.items.first(where: { $0.action == #selector(handlePlayPauseAction) }) {
            playPauseItem.title = isPlaying ? "Pause" : "Play"
        }

        if let muteItem = menu.items.first(where: { $0.action == #selector(handleMuteAction) }) {
            muteItem.title = isMuted ? "Unmute" : "Mute"
        }

        diagnosticsItem?.title = viewModel.formattedDiagnosticsLine()

        if let launchAtLoginItem {
            launchAtLoginItem.state = viewModel.isLaunchOnLoginEnabled ? .on : .off
        }

        updateIcon(isPlaying: isPlaying, isMuted: isMuted)
    }

    private func updateIcon(isPlaying: Bool, isMuted: Bool) {
        guard let button = statusItem?.button else { return }
        // Called on every view-model change, so skip the image allocation when nothing moved.
        guard lastIconState != IconState(isPlaying: isPlaying, isMuted: isMuted) else { return }
        lastIconState = IconState(isPlaying: isPlaying, isMuted: isMuted)

        let name = AppInfo.displayName
        let description = isMuted
            ? "\(name), muted"
            : (isPlaying ? "\(name), playing" : "\(name), paused")

        if #available(macOS 11.0, *) {
            let symbol = isMuted ? "speaker.slash.fill" : (isPlaying ? "play.fill" : "pause.fill")
            button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: description)
            button.title = ""
        } else {
            button.title = isMuted ? "🔇" : (isPlaying ? "▶" : "⏸")
        }
        button.setAccessibilityLabel(description)
    }

    private struct IconState: Equatable {
        let isPlaying: Bool
        let isMuted: Bool
    }
}
