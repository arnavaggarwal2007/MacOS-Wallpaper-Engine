import SwiftUI
import AppKit
import AVFoundation
import UniformTypeIdentifiers

struct ModernHomeView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFileImporterPresented = false
    @State private var selectedDisplayForPicker: CGDirectDisplayID?
    @State private var selectedDisplayID: CGDirectDisplayID?
    @State private var transientPerDisplayPreviewURL: URL?
    @State private var isSaveSetupModalPresented = false
    @State private var isSidebarVisible = true
    @State private var isDisplaySelectionModalPresented = false
    @State private var pendingVideoURL: URL?
    @State private var showDisplaysScrollHint = true
    @State private var isDisplaysPanelVisible = false
    @State private var pauseWallpaperPreview = false
    @State private var cachedDisplayCards: [DisplayCard] = []
    @State private var thumbnailLoadsInFlight: Set<String> = []

    var body: some View {
        ScrollViewReader { scrollProxy in
        GeometryReader { proxy in
            let sidebarWidth = min(max(320, proxy.size.width * 0.33), 420)
            ZStack(alignment: .topLeading) {
                // Layer 1: Scroll to reveal display carousel (background owned by TabbedMainView)
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Color.clear
                            .frame(height: scrollRevealSpacerHeight(in: proxy.size))
                            .accessibilityHidden(true)

                        Group {
                            if isDisplaysPanelVisible {
                                scrollContentSection
                            } else {
                                Color.clear
                                    .frame(height: displaysPanelPlaceholderHeight)
                                    .accessibilityHidden(true)
                            }
                        }
                        .id(Self.displaysPanelScrollID)
                        .padding(.horizontal, DesignTokens.Spacing.large)
                        .padding(.bottom, DesignTokens.Spacing.large)
                    }
                }
                .scrollIndicators(.hidden)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y
                } action: { _, offsetY in
                    updateScrollRevealState(offsetY: offsetY)
                }
                .zIndex(1)

                // Layer 1: Floating glass utility bar (fixed at top)
                TopUtilityBar(
                    isSidebarVisible: $isSidebarVisible,
                    onChooseWallpaper: { isFileImporterPresented = true }
                )
                .padding(.horizontal, 24)
                .padding(.top, DesignTokens.Surfaces.mainTabBarReservedHeight + 8)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .zIndex(2)

                if showDisplaysScrollHint && !isDisplaysPanelVisible {
                    displaysScrollHint(scrollProxy: scrollProxy)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, DesignTokens.Spacing.large)
                        .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .bottom)))
                        .zIndex(2)
                }

                // Layer 2: Toggleable sidebar overlay
                if isSidebarVisible {
                    HStack(alignment: .top, spacing: 0) {
                        Spacer()
                            .allowsHitTesting(false)
                        sidebarPanel(width: sidebarWidth)
                            .frame(width: sidebarWidth)
                    }
                    .padding(.top, DesignTokens.Surfaces.mainTabBarReservedHeight + 8)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .zIndex(3)
                }
            }
        }
        }
        .wallpaperPreviewPause(pauseWallpaperPreview)
        .frame(minWidth: 800, minHeight: 600)
        .task {
            appModel.loadSavedCollections()
            await appModel.loadSavedSetups()
            appModel.ensurePerDisplayMode()
            syncSelectedDisplayIfNeeded()
        }
        .task(id: NSScreen.screens.map(\.displayID)) {
            migrateSelectedDisplayAfterScreenChange()
            syncSelectedDisplayIfNeeded()
            scheduleRebuildDisplayCardsCache()
        }
        .onChange(of: selectedDisplayID) { _, newValue in
            Task { @MainActor in
                appModel.focusedDisplayID = newValue
                rebuildDisplayCardsCache()
            }
        }
        .onChange(of: appModel.focusedDisplayID) { _, newValue in
            Task { @MainActor in
                if selectedDisplayID != newValue {
                    selectedDisplayID = newValue
                }
            }
        }
        .onChange(of: appModel.displaySourcesVersion) { _, _ in
            Task { @MainActor in
                transientPerDisplayPreviewURL = nil
                rebuildDisplayCardsCache()
            }
        }
        .onAppear {
            scheduleRebuildDisplayCardsCache()
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.movie, .mpeg4Movie, .quickTimeMovie],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let firstURL = urls.first else { return }
                
                // Store URL and show display selection modal
                pendingVideoURL = firstURL
                isDisplaySelectionModalPresented = true
                
            case .failure(let error):
                appModel.errorMessage = "File selection failed: \(error.localizedDescription)"
                appModel.statusMessage = nil
                selectedDisplayForPicker = nil
            }
        }
        .sheet(isPresented: $isDisplaySelectionModalPresented) {
            if let videoURL = pendingVideoURL {
                DisplaySelectionModal(videoURL: videoURL, appModel: appModel)
            }
        }
        .sheet(isPresented: $isSaveSetupModalPresented) {
            SaveSetupModal(viewModel: appModel)
                .frame(minWidth: 400, minHeight: 520)
        }
    }

    private func sidebarPanel(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
            HStack {
                Text("Status")
                    .font(.headline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)

                Spacer()

                Button(action: { withAnimation { isSidebarVisible = false } }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Hide sidebar")
            }
            .padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
                    statusCard(
                        title: "Display",
                        icon: "display",
                        value: sidebarDisplayStatus
                    )

                    CardView(title: "Wallpaper", style: .elevated) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(sidebarWallpaperName)
                                .font(DesignTokens.Typography.subtitle)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .lineLimit(3)

                            Button(action: { isFileImporterPresented = true }) {
                                Label("Choose Wallpaper", systemImage: "folder.badge.plus")
                                    .labelStyle(.titleAndIcon)
                            }
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)
                        }
                    }

                    collectionStatusCard

                    setupStatusCard

                    VStack(alignment: .leading, spacing: 12) {
                        if appModel.isApplyingWallpaper {
                            statusBanner(title: "Applying wallpaper...", systemImage: "arrow.triangle.2.circlepath", tint: .blue)
                        }
                        if let message = appModel.statusMessage {
                            statusBanner(title: message, systemImage: "checkmark.circle.fill", tint: .green)
                        }
                        if let error = appModel.errorMessage {
                            statusBanner(title: error, systemImage: "exclamationmark.circle.fill", tint: .red)
                        }
                    }
                }
            }
        }
        .padding(DesignTokens.Spacing.large)
        .frame(maxWidth: width)
        .glassChrome(.panel)
        .padding(DesignTokens.Spacing.large)
    }

    private static let displaysPanelScrollID = "home-displays-panel"

    /// Reserves scroll space below the fold without rendering the carousel (avoids HUD/drawingGroup glitches).
    private var displaysPanelPlaceholderHeight: CGFloat {
        DesignTokens.Surfaces.homeDisplaysPanelHeight + DesignTokens.Spacing.large
    }

    private func updateScrollRevealState(offsetY: CGFloat) {
        let shouldPause = offsetY > 8
        if shouldPause != pauseWallpaperPreview {
            pauseWallpaperPreview = shouldPause
        }

        if offsetY > DesignTokens.Surfaces.homeDisplaysRevealThreshold {
            if !isDisplaysPanelVisible {
                withAnimation(DesignTokens.Motion.selectionAnimation(reduceMotion: reduceMotion)) {
                    isDisplaysPanelVisible = true
                }
            }
            if showDisplaysScrollHint {
                showDisplaysScrollHint = false
            }
        } else if offsetY < DesignTokens.Surfaces.homeDisplaysHideThreshold {
            if isDisplaysPanelVisible {
                withAnimation(DesignTokens.Motion.selectionAnimation(reduceMotion: reduceMotion)) {
                    isDisplaysPanelVisible = false
                }
            }
            if !showDisplaysScrollHint {
                showDisplaysScrollHint = true
            }
        }
        uiDebugLog("displays scroll offset=\(offsetY) visible=\(isDisplaysPanelVisible)")
    }

    /// Spacer keeps the carousel below the fold while total content height still exceeds the viewport.
    private func scrollRevealSpacerHeight(in size: CGSize) -> CGFloat {
        let reserved = DesignTokens.Surfaces.homeUtilityBarReservedHeight
            + DesignTokens.Surfaces.homeScrollPeekHeight
        return max(size.height - reserved, 280)
    }

    private func scheduleRebuildDisplayCardsCache() {
        Task { @MainActor in
            rebuildDisplayCardsCache()
        }
    }

    private func rebuildDisplayCardsCache() {
        cachedDisplayCards = buildDisplayCards()
        prefetchMissingThumbnails()
    }

    private func prefetchMissingThumbnails() {
        for screen in NSScreen.screens {
            guard let url = perDisplayPreviewURL(for: screen.displayID), url.isFileURL else { continue }
            scheduleThumbnailLoad(for: url)
        }
    }

    private func scheduleThumbnailLoad(for url: URL) {
        if VideoWallpaperThumbnail.cachedImage(for: url) != nil { return }
        let key = url.standardizedFileURL.path
        guard !thumbnailLoadsInFlight.contains(key) else { return }
        thumbnailLoadsInFlight.insert(key)

        Task {
            let image = await VideoWallpaperThumbnail.imageAsync(for: url)
            await MainActor.run {
                thumbnailLoadsInFlight.remove(key)
                guard image != nil else { return }
                cachedDisplayCards = buildDisplayCards()
            }
        }
    }

    private func displaysScrollHint(scrollProxy: ScrollViewProxy) -> some View {
        Button {
            revealDisplaysPanel(using: scrollProxy)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                Text("Scroll for Displays")
                    .font(DesignTokens.Typography.subtitle)
                    .fontWeight(.medium)
            }
            .foregroundStyle(DesignTokens.Colors.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .glassChrome(.bar)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Show display picker")
        .accessibilityHint("Scrolls to the display carousel")
    }

    private func revealDisplaysPanel(using scrollProxy: ScrollViewProxy) {
        withAnimation(DesignTokens.Motion.selectionAnimation(reduceMotion: reduceMotion)) {
            scrollProxy.scrollTo(Self.displaysPanelScrollID, anchor: .bottom)
            isDisplaysPanelVisible = true
        }
        showDisplaysScrollHint = false
    }

    private var sidebarDisplayStatus: String {
        if let display = selectedDisplay {
            return "\(display.title) · \(display.resolution)"
        }
        return "\(NSScreen.screens.count) display\(NSScreen.screens.count == 1 ? "" : "s")"
    }

    private var sidebarWallpaperName: String {
        if let display = selectedDisplay {
            return display.subtitle
        }
        return "No display selected"
    }

    @ViewBuilder
    private var collectionStatusCard: some View {
        CardView(title: "Collection", style: .elevated) {
            VStack(alignment: .leading, spacing: 10) {
                Text(appModel.selectedCollectionName ?? appModel.lastUsedCollectionName ?? "None applied")
                    .font(DesignTokens.Typography.subtitle)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .lineLimit(2)

                if let name = appModel.selectedCollectionName ?? appModel.lastUsedCollectionName {
                    Button(action: {
                        Task { _ = await appModel.applyCollection(name: name) }
                    }) {
                        Label("Apply Collection", systemImage: "checkmark.circle")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    .disabled(appModel.isApplyingWallpaper)
                } else {
                    Text("Manage collections in the Collections tab.")
                        .font(.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private var setupStatusCard: some View {
        CardView(title: "Setup", style: .elevated) {
            VStack(alignment: .leading, spacing: 10) {
                Text(appModel.selectedSetupName ?? "None active")
                    .font(DesignTokens.Typography.subtitle)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .lineLimit(2)

                Button(action: { isSaveSetupModalPresented = true }) {
                    Label("Save Current Setup", systemImage: "square.and.arrow.down")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)

                Text("Restore and delete setups in the Setups tab.")
                    .font(.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
        }
    }

    private func statusCard(title: String, icon: String, value: String) -> some View {
        CardView(title: title, style: .elevated) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(DesignTokens.Typography.subtitle)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .lineLimit(3)
                Spacer(minLength: 0)
            }
        }
    }

    private func uiDebugLog(_ message: String) {
        guard SettingsStore.shared.debugDiagnosticsEnabled else { return }
        print("ModernHomeView: \(message)")
    }

    private var selectedDisplay: DisplayCard? {
        guard let selectedDisplayID else {
            return displayCards.first
        }

        return displayCards.first(where: { $0.displayID == selectedDisplayID }) ?? displayCards.first
    }

    private var selectedPerDisplayID: CGDirectDisplayID? {
        selectedDisplayID ?? NSScreen.screens.first?.displayID
    }

    private var selectedPerDisplaySource: String {
        guard let displayID = selectedPerDisplayID else {
            return ""
        }

        return appModel.perDisplaySource(for: displayID)
    }

    private var selectedPerDisplayPreviewURL: URL? {
        guard let displayID = selectedPerDisplayID else {
            return nil
        }

        if let transient = transientPerDisplayPreviewURL, displayID == selectedPerDisplayID {
            return transient
        }

        return appModel.previewURL(forDisplayID: displayID)
    }

    private var selectedPerDisplayScaling: VideoScalingMode {
        guard let displayID = selectedPerDisplayID else {
            return appModel.scalingMode
        }

        return appModel.perDisplayScalingMode(for: displayID)
    }

    private var displayCards: [DisplayCard] {
        cachedDisplayCards.isEmpty ? buildDisplayCards() : cachedDisplayCards
    }

    private func buildDisplayCards() -> [DisplayCard] {
        _ = appModel.displaySourcesVersion
        return NSScreen.screens.enumerated().map { index, screen in
            let displayID = screen.displayID
            let source = perDisplaySource(for: displayID)
            let resolvedURL = perDisplayPreviewURL(for: displayID)
            let scaling = appModel.perDisplayScalingMode(for: displayID)
            let previewImage = displayPreviewImage(for: displayID, source: source, resolvedURL: resolvedURL)
            let activeID = selectedDisplayID ?? NSScreen.screens.first?.displayID
            let isActive = displayID == activeID

            return DisplayCard(
                displayID: displayID,
                title: "Display \(index + 1)",
                subtitle: source.isEmpty ? "No source selected yet." : (resolvedURL?.lastPathComponent ?? source),
                badge: screen.localizedName,
                resolution: String(format: "%.0fx%.0f", screen.frame.width, screen.frame.height),
                scaling: scaling.displayName,
                previewImage: previewImage,
                isActive: isActive
            )
        }
    }

    private func perDisplaySource(for displayID: CGDirectDisplayID) -> String {
        appModel.perDisplaySource(for: displayID)
    }

    private func perDisplayPreviewURL(for displayID: CGDirectDisplayID) -> URL? {
        appModel.previewURL(forDisplayID: displayID)
    }

    private func displayPreviewImage(for displayID: CGDirectDisplayID, source: String, resolvedURL: URL?) -> NSImage? {
        if let resolvedURL {
            if resolvedURL.isFileURL {
                let didStartScope = resolvedURL.startAccessingSecurityScopedResource()
                defer {
                    if didStartScope {
                        resolvedURL.stopAccessingSecurityScopedResource()
                    }
                }

                if let thumbnail = thumbnailForLocalFile(at: resolvedURL) {
                    return thumbnail
                }

                if let image = NSImage(contentsOf: resolvedURL), image.size != .zero {
                    return image
                }

                return NSWorkspace.shared.icon(forFile: resolvedURL.path)
            }

            return previewIcon(forURL: resolvedURL, fallbackIsWeb: true)
        }

        if !source.isEmpty, let fallbackURL = URL(string: source) {
            return previewIcon(forURL: fallbackURL, fallbackIsWeb: true)
        }

        return nil
    }

    private func migrateSelectedDisplayAfterScreenChange() {
        // AppViewModel remaps focusedDisplayID by screen signature; mirror that in local UI state.
        if let focused = appModel.focusedDisplayID {
            selectedDisplayID = focused
        }
    }

    private func syncSelectedDisplayIfNeeded() {
        appModel.syncFocusedDisplayIfNeeded()
        guard !NSScreen.screens.isEmpty else {
            selectedDisplayID = nil
            return
        }

        if let selectedDisplayID,
           NSScreen.screens.contains(where: { $0.displayID == selectedDisplayID }) {
            appModel.focusedDisplayID = selectedDisplayID
            return
        }

        if let focused = appModel.focusedDisplayID,
           NSScreen.screens.contains(where: { $0.displayID == focused }) {
            selectedDisplayID = focused
            return
        }

        selectedDisplayID = NSScreen.screens.first?.displayID
        appModel.focusedDisplayID = selectedDisplayID
    }

    @ViewBuilder
    private func statusBanner(title: String, systemImage: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundColor(tint)
                .font(.subheadline)

            Text(title)
                .font(DesignTokens.Typography.subtitle)
                .foregroundColor(DesignTokens.Colors.textPrimary)

            Spacer()
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.Corner.radius, style: .continuous)
                .fill(tint.opacity(0.10))
                .overlay {
                    RoundedRectangle(cornerRadius: DesignTokens.Corner.radius, style: .continuous)
                        .stroke(tint.opacity(0.18), lineWidth: 1)
                }
        }
    }

    @ViewBuilder
    private var scrollContentSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
            if !NSScreen.screens.isEmpty {
                DisplaySwitcherView(
                    selectedDisplayID: Binding(
                        get: { selectedDisplayID ?? NSScreen.screens.first?.displayID },
                        set: { newValue in
                            selectedDisplayID = newValue
                            appModel.focusedDisplayID = newValue
                        }
                    ),
                    displays: displayCards,
                    isGloballyPaused: appModel.shouldShowPausedChrome,
                    onSelect: { displayID in
                        selectedDisplayID = displayID
                        appModel.focusedDisplayID = displayID
                    }
                )
            } else {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "rectangle.on.rectangle")
                        .foregroundStyle(.secondary)
                        .font(.title3)

                    Text("No displays detected. Connect a display to assign wallpapers.")
                        .font(DesignTokens.Typography.subtitle)
                        .foregroundColor(DesignTokens.Colors.textSecondary)

                    Spacer(minLength: 0)
                }
                .padding(14)
                .background {
                    RoundedRectangle(cornerRadius: DesignTokens.Corner.radius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: DesignTokens.Corner.radius, style: .continuous)
                                .stroke(DesignTokens.Colors.cardBorder, lineWidth: 1)
                        }
                }
            }
        }
    }

    private func previewIcon(forURL url: URL, fallbackIsWeb: Bool) -> NSImage {
        if url.isFileURL {
            let didStartScope = url.startAccessingSecurityScopedResource()
            defer {
                if didStartScope {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            if let thumbnail = thumbnailForLocalFile(at: url) {
                uiDebugLog("previewIcon: thumbnail size \(thumbnail.size)")
                return thumbnail
            }
            uiDebugLog("previewIcon: thumbnail failed, trying direct load")
            if let image = NSImage(contentsOf: url), image.size != .zero {
                uiDebugLog("previewIcon: direct load size \(image.size)")
                return image
            }
            uiDebugLog("previewIcon: direct load failed, using file icon")
            return NSWorkspace.shared.icon(forFile: url.path)
        }

        return fallbackIsWeb
            ? NSWorkspace.shared.icon(for: UTType.internetLocation)
            : NSWorkspace.shared.icon(for: .movie)
    }

    private func thumbnailForLocalFile(at url: URL) -> NSImage? {
        let fileExtension = url.pathExtension.lowercased()
        if ["png", "jpg", "jpeg", "gif", "tiff", "bmp", "heic", "webp"].contains(fileExtension), let image = NSImage(contentsOf: url), image.size != .zero {
            return image
        }

        if let cached = VideoWallpaperThumbnail.cachedImage(for: url) {
            return cached
        }

        scheduleThumbnailLoad(for: url)
        return NSWorkspace.shared.icon(for: .movie)
    }
}

#Preview {
    ModernHomeView()
        .environmentObject(AppViewModel())
}
