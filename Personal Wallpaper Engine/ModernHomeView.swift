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
    @State private var isCollectionEditorPresented = false
    @State private var isDeleteCollectionAlertPresented = false
    @State private var editingCollectionName: String?
    @State private var isSidebarVisible = true

    var body: some View {
        GeometryReader { proxy in
            let horizontalPadding = DesignTokens.Spacing.large * 2
            let availableWidth = max(proxy.size.width - horizontalPadding, 0)
            let sidebarWidth = min(max(320, availableWidth * 0.33), 420)

            ZStack(alignment: .topTrailing) {
                // Main content area - hero gets full width
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
                        headerSection

                        TopUtilityBar(isSidebarVisible: $isSidebarVisible)
                            .padding(.horizontal, 4)

                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
                            HeroWallpaperView(
                                title: heroTitle,
                                subtitle: heroSubtitle,
                                image: heroPreviewImage,
                                badge: heroBadge,
                                metadata: heroMetadata,
                                videoURL: heroVideoURL
                            )

                            if appModel.usePerDisplay && NSScreen.screens.count > 1 {
                                DisplaySwitcherView(
                                    selectedDisplayID: Binding(
                                        get: { selectedDisplayID ?? NSScreen.screens.first?.displayID },
                                        set: { selectedDisplayID = $0 }
                                    ),
                                    displays: displayCards,
                                    onSelect: { selectedDisplayID = $0 }
                                )
                            }

                            previewSection
                        }
                        .frame(maxWidth: availableWidth, alignment: .leading)
                    }
                    .padding(DesignTokens.Spacing.large)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background {
                    LinearGradient(
                        colors: [
                            DesignTokens.Colors.background,
                            DesignTokens.Colors.cardBackground.opacity(0.92),
                            DesignTokens.Colors.background.opacity(0.96)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                }

                // Overlay sidebar - transparent, positioned at top-right
                if isSidebarVisible {
                    sidebarPanel(width: sidebarWidth)
                        .frame(width: sidebarWidth)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .task {
            await appModel.loadSavedCollections()
            syncSelectedDisplayIfNeeded()
        }
        .task(id: appModel.usePerDisplay) {
            syncSelectedDisplayIfNeeded()
        }
        .task(id: NSScreen.screens.count) {
            syncSelectedDisplayIfNeeded()
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.movie, .mpeg4Movie, .quickTimeMovie],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let firstURL = urls.first else { return }

                if let displayID = selectedDisplayForPicker {
                    // Keep a transient URL so the preview can load immediately
                    transientPerDisplayPreviewURL = firstURL
                    appModel.selectPerDisplaySource(displayID, at: firstURL)
                    selectedDisplayID = displayID
                    selectedDisplayForPicker = nil
                } else {
                    if !appModel.usePerDisplay {
                        appModel.selectVideo(at: firstURL)
                    } else {
                        appModel.errorMessage = "Main wallpaper selection is disabled while per-display mode is enabled."
                        appModel.statusMessage = nil
                    }
                }
            case .failure(let error):
                appModel.errorMessage = "File selection failed: \(error.localizedDescription)"
                appModel.statusMessage = nil
                selectedDisplayForPicker = nil
            }
        }
        .sheet(isPresented: $isCollectionEditorPresented) {
            let selectedName = editingCollectionName.flatMap { appModel.savedCollections[$0] }
            CardView(title: editingCollectionName == nil ? "Create Collection" : "Edit Collection", style: .elevated) {
                CollectionEditorView(
                    initialName: selectedName?.name ?? "",
                    initialDescription: selectedName?.description ?? "",
                    initialType: selectedName?.collectionType ?? .simple,
                    initialSources: selectedName?.sources ?? [],
                    initialBookmarks: editingCollectionName.map { appModel.bookmarksForCollection(name: $0) } ?? [:],
                    originalCollectionName: editingCollectionName,
                    existingCollectionNames: Set(appModel.savedCollections.keys),
                    onCancel: { isCollectionEditorPresented = false },
                    onSave: { collection, bookmarks in
                        Task {
                            if let editingCollectionName {
                                _ = await appModel.updateCollection(
                                    existingName: editingCollectionName,
                                    newName: collection.name,
                                    description: collection.description,
                                    collectionType: collection.collectionType,
                                    sources: collection.sources,
                                    bookmarks: bookmarks
                                )
                            } else {
                                _ = await appModel.createCollection(
                                    name: collection.name,
                                    description: collection.description,
                                    collectionType: collection.collectionType,
                                    sources: collection.sources,
                                    bookmarks: bookmarks
                                )
                            }
                            self.editingCollectionName = nil
                            isCollectionEditorPresented = false
                        }
                    }
                )
            }
            .frame(minWidth: 640, minHeight: 520)
        }
        .alert("Delete Collection", isPresented: $isDeleteCollectionAlertPresented) {
            Button("Delete", role: .destructive) {
                Task {
                    guard let selectedName = appModel.selectedCollectionName else { return }
                    _ = await appModel.deleteCollection(name: selectedName)
                    editingCollectionName = nil
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete the selected collection?")
        }
    }

    private func sidebarPanel(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
            HStack {
                Text("Settings")
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
                    CardView(title: "Workspace", style: .elevated) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Use Per-Display Wallpapers")
                                        .font(DesignTokens.Typography.subtitle)
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                    Text(appModel.usePerDisplay ? "Every display keeps its own source." : "One wallpaper drives the entire desktop.")
                                        .font(DesignTokens.Typography.subtitle)
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                }

                                Spacer()

                                Toggle("", isOn: Binding(get: { appModel.usePerDisplay }, set: { appModel.toggleUsePerDisplay($0) }))
                                    .labelsHidden()
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Label("Renderer Mode", systemImage: "display")
                                    .font(DesignTokens.Typography.subtitle)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)

                                Picker(
                                    "Renderer Mode",
                                    selection: Binding(
                                        get: { appModel.rendererMode },
                                        set: { appModel.updateRendererMode($0) }
                                    )
                                ) {
                                    ForEach(WallpaperRendererMode.allCases, id: \.self) { mode in
                                        Text(mode.displayName).tag(mode)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Label("Scaling Mode", systemImage: "aspectratio")
                                    .font(DesignTokens.Typography.subtitle)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)

                                Picker(
                                    "Scaling Mode",
                                    selection: Binding(
                                        get: { appModel.scalingMode },
                                        set: { appModel.updateScalingMode($0) }
                                    )
                                ) {
                                    ForEach(VideoScalingMode.allCases, id: \.self) { mode in
                                        Text(mode.displayName).tag(mode)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }

                            Toggle(
                                isOn: Binding(
                                    get: { appModel.isMuted },
                                    set: { appModel.updateMuted($0) }
                                )
                            ) {
                                Label("Mute Audio", systemImage: appModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                    .font(DesignTokens.Typography.subtitle)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                            }
                        }
                    }

                    if appModel.usePerDisplay, let selectedDisplay {
                        CardView(title: "Current Display", style: .elevated) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(selectedPerDisplaySource.isEmpty ? "No source selected" : selectedPerDisplaySource)
                                    .font(DesignTokens.Typography.subtitle)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                                    .lineLimit(2)

                                HStack(spacing: 10) {
                                    Button(action: {
                                        selectedDisplayForPicker = selectedDisplay.displayID
                                        selectedDisplayID = selectedDisplay.displayID
                                        isFileImporterPresented = true
                                    }) {
                                        Label("Choose Video", systemImage: "folder.badge.plus")
                                    }

                                    Button(action: {
                                        Task { @MainActor in
                                            await appModel.applyPerDisplayWallpaper(displayID: selectedDisplay.displayID, sourceString: selectedPerDisplaySource)
                                        }
                                    }) {
                                        Label("Apply", systemImage: "checkmark.circle.fill")
                                    }
                                    .disabled(selectedPerDisplaySource.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || appModel.isApplyingWallpaper)
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Label("Scaling", systemImage: "aspectratio")
                                        .font(DesignTokens.Typography.subtitle)
                                        .foregroundColor(DesignTokens.Colors.textPrimary)

                                    Picker(
                                        "Scaling",
                                        selection: Binding(
                                            get: { appModel.perDisplayScalingMode(for: selectedDisplay.displayID) },
                                            set: { appModel.updatePerDisplayScalingMode(selectedDisplay.displayID, $0) }
                                        )
                                    ) {
                                        ForEach(VideoScalingMode.allCases, id: \.self) { mode in
                                            Text(mode.displayName).tag(mode)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                }
                            }
                        }
                    } else {
                        CardView(title: "Main Source", style: .elevated) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(appModel.selectedVideoPath.isEmpty ? "No video selected" : appModel.selectedVideoPath)
                                    .font(DesignTokens.Typography.subtitle)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                                    .lineLimit(2)

                                if appModel.rendererMode == .web {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Label("Web Source URL", systemImage: "globe")
                                            .font(DesignTokens.Typography.subtitle)
                                            .foregroundColor(DesignTokens.Colors.textPrimary)

                                        TextField("https://example.com/animated-background", text: Binding(
                                            get: { appModel.webURLString },
                                            set: { appModel.updateWebURL($0) }
                                        ))
                                        .textFieldStyle(.roundedBorder)

                                        HStack(spacing: 10) {
                                            Button(action: { isFileImporterPresented = true }) {
                                                Label("Choose File", systemImage: "folder.badge.plus")
                                            }

                                            Button(action: { Task { await appModel.applyWallpaperFromSelection() } }) {
                                                Label("Apply", systemImage: "checkmark.circle.fill")
                                            }
                                            .disabled(appModel.webURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || appModel.isApplyingWallpaper)
                                        }

                                        Text("Enter a public HTTP(S) URL to render as the wallpaper source.")
                                            .font(DesignTokens.Typography.subtitle)
                                            .foregroundColor(DesignTokens.Colors.textSecondary)
                                    }
                                } else {
                                    HStack(spacing: 10) {
                                        Button(action: { isFileImporterPresented = true }) {
                                            Label("Choose Video", systemImage: "folder.badge.plus")
                                        }

                                        Button(action: { Task { await appModel.applyWallpaperFromSelection() } }) {
                                            Label("Apply", systemImage: "checkmark.circle.fill")
                                        }
                                        .disabled(appModel.selectedVideoPath.isEmpty || appModel.isApplyingWallpaper)
                                    }
                                }
                            }
                        }
                    }

                    CardView(title: "Saved Collections", style: .elevated) {
                        let collectionNames = appModel.savedCollections.keys.sorted()
                        let selectedCollection = appModel.selectedCollectionName.flatMap { appModel.savedCollections[$0] }
                        let lastUsedCollection = appModel.lastUsedCollectionName.flatMap { appModel.savedCollections[$0] }

                        VStack(alignment: .leading, spacing: 14) {
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "square.stack.3d.up")
                                            .foregroundStyle(.secondary)

                                        Text("\(collectionNames.count) saved collection\(collectionNames.count == 1 ? "" : "s")")
                                            .font(DesignTokens.Typography.subtitle)
                                            .fontWeight(.semibold)
                                    }

                                    Text(collectionNames.isEmpty ? "Create a collection to capture a wallpaper set." : "Pick a collection to review its summary and actions.")
                                        .font(DesignTokens.Typography.subtitle)
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                }

                                Spacer()

                                if let lastUsedCollection {
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("Last used")
                                            .font(.caption)
                                            .foregroundColor(DesignTokens.Colors.textSecondary)
                                        Text(lastUsedCollection.name)
                                            .font(DesignTokens.Typography.subtitle)
                                            .fontWeight(.medium)
                                    }
                                }
                            }

                            if collectionNames.isEmpty {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "tray")
                                        .foregroundStyle(.secondary)
                                        .font(.title3)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("No collections saved yet")
                                            .font(DesignTokens.Typography.subtitle)
                                            .fontWeight(.semibold)
                                        Text("Create one to save a wallpaper set for later.")
                                            .font(DesignTokens.Typography.subtitle)
                                            .foregroundColor(DesignTokens.Colors.textSecondary)
                                    }

                                    Spacer()
                                }
                                .padding(14)
                                .background {
                                    RoundedRectangle(cornerRadius: DesignTokens.Corner.radius, style: .continuous)
                                        .fill(DesignTokens.Colors.cardBackground)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: DesignTokens.Corner.radius, style: .continuous)
                                                .fill(.linearGradient(colors: [DesignTokens.Colors.cardHighlight, Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing))
                                                .opacity(DesignTokens.Effects.cardBackdropOpacity)
                                        }
                                        .overlay {
                                            RoundedRectangle(cornerRadius: DesignTokens.Corner.radius, style: .continuous)
                                                .stroke(DesignTokens.Colors.cardBorder, lineWidth: 1)
                                        }
                                }
                            } else {
                                Picker(
                                    "Collection",
                                    selection: Binding(
                                        get: { appModel.selectedCollectionName ?? "" },
                                        set: { newValue in
                                            if newValue.isEmpty {
                                                appModel.selectedCollectionName = nil
                                            } else {
                                                appModel.selectCollection(name: newValue)
                                            }
                                        }
                                    )
                                ) {
                                    Text("Select Collection").tag("")
                                    ForEach(collectionNames, id: \.self) { name in
                                        Text(name).tag(name)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: 320, alignment: .leading)

                                if let selectedCollection {
                                    CollectionSummaryCard(
                                        collection: selectedCollection,
                                        isSelected: true,
                                        isLastUsed: lastUsedCollection?.name == selectedCollection.name,
                                        mappingDescriptions: selectedCollection.sources.enumerated().map { index, source in
                                            collectionMappingDescription(index: index, source: source, type: selectedCollection.collectionType)
                                        }
                                    )
                                }

                                CardSection(header: "Actions") {
                                    HStack(spacing: 10) {
                                        Button(action: { isCollectionEditorPresented = true }) {
                                            Label("Create Collection", systemImage: "plus.circle")
                                                .labelStyle(.titleAndIcon)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .contentShape(Rectangle())

                                        Button(action: {
                                            guard let selectedName = appModel.selectedCollectionName,
                                                  let selectedCollection = appModel.savedCollections[selectedName] else { return }
                                            editingCollectionName = selectedName
                                            isCollectionEditorPresented = true
                                            appModel.selectCollection(name: selectedCollection.name)
                                        }) {
                                            Label("Edit Collection", systemImage: "pencil")
                                                .labelStyle(.titleAndIcon)
                                        }
                                        .buttonStyle(.bordered)
                                        .contentShape(Rectangle())
                                        .disabled(appModel.selectedCollectionName == nil)

                                        Button(action: {
                                            Task {
                                                guard let selectedName = appModel.selectedCollectionName else { return }
                                                let loaded = await appModel.loadSelectedCollection()
                                                switch loaded {
                                                case .success:
                                                    appModel.statusMessage = "Loaded collection '\(selectedName)'."
                                                    appModel.errorMessage = nil
                                                case .failure(let error):
                                                    appModel.errorMessage = error.errorDescription
                                                    appModel.statusMessage = nil
                                                }
                                            }
                                        }) {
                                            Label("Load Collection", systemImage: "folder")
                                                .labelStyle(.titleAndIcon)
                                        }
                                        .buttonStyle(.bordered)
                                        .contentShape(Rectangle())
                                        .disabled(appModel.selectedCollectionName == nil)

                                        Button(action: {
                                            Task {
                                                guard let selectedName = appModel.selectedCollectionName else { return }
                                                _ = await appModel.applyCollection(name: selectedName)
                                            }
                                        }) {
                                            Label("Apply Collection", systemImage: "checkmark.circle.fill")
                                                .labelStyle(.titleAndIcon)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .contentShape(Rectangle())
                                        .disabled(appModel.selectedCollectionName == nil || appModel.isApplyingWallpaper)

                                        Button(role: .destructive, action: {
                                            isDeleteCollectionAlertPresented = true
                                        }) {
                                            Label("Delete Collection", systemImage: "trash")
                                                .labelStyle(.titleAndIcon)
                                        }
                                        .buttonStyle(.bordered)
                                        .contentShape(Rectangle())
                                        .disabled(appModel.selectedCollectionName == nil)
                                    }
                                }
                            }
                        }
                    }

                    CardView(title: "System", style: .elevated) {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(
                                isOn: Binding(
                                    get: { appModel.isLaunchOnLoginEnabled },
                                    set: { _ in Task { await appModel.toggleLaunchOnLogin() } }
                                )
                            ) {
                                Label("Launch on Login", systemImage: "power")
                                    .font(DesignTokens.Typography.subtitle)
                                    .fontWeight(.medium)
                            }

                            Text("Automatically start the wallpaper engine when you log in (requires macOS 13.2+)")
                                .font(DesignTokens.Typography.subtitle)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                    }

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

                        if let message = appModel.launchOnLoginStatusMessage {
                            statusBanner(title: message, systemImage: "checkmark.circle.fill", tint: .green)
                        }

                        if let error = appModel.launchOnLoginErrorMessage {
                            statusBanner(title: error, systemImage: "exclamationmark.circle.fill", tint: .red)
                        }
                    }
                }
            }
        }
        .padding(DesignTokens.Spacing.large)
        .frame(maxWidth: width)
        .background(.ultraThinMaterial)
        .cornerRadius(DesignTokens.Corner.radius)
        .padding(DesignTokens.Spacing.large)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Wallpaper Configuration")
                .font(.system(size: 28, weight: .semibold, design: .default))
                .foregroundColor(DesignTokens.Colors.textPrimary)

            Text("A modern workspace for live wallpaper previews, collections, and display-specific control.")
                .font(DesignTokens.Typography.subtitle)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
    }

    private var heroTitle: String {
        if appModel.usePerDisplay, let selectedDisplay {
            return selectedDisplay.title
        }

        return appModel.usePerDisplay ? "Multi-Display Workspace" : "Current Wallpaper Preview"
    }

    private var heroSubtitle: String {
        if appModel.usePerDisplay {
            if let selectedDisplay {
                return selectedDisplay.subtitle
            }

            return NSScreen.screens.count > 1
                ? "Each display keeps its own source and scaling. Switch among screens without leaving the workspace."
                : "Per-display mode is enabled, but only one display is connected."
        }

        if appModel.rendererMode == .web {
            return appModel.webURLString.isEmpty ? "No web source configured yet." : appModel.webURLString
        }

        return appModel.selectedVideoPath.isEmpty ? "No video selected yet." : URL(fileURLWithPath: appModel.selectedVideoPath).lastPathComponent
    }

    private var heroBadge: String {
        if appModel.usePerDisplay {
            return selectedDisplay?.badge ?? "Per-Display"
        }
        return appModel.rendererMode == .web ? "Web" : "Video"
    }

    private var heroMetadata: [String] {
        var values: [String] = [appModel.isMuted ? "Muted" : "Audio On"]
        values.append(appModel.usePerDisplay ? "\(NSScreen.screens.count) displays" : "Unified mode")
        values.append(appModel.usePerDisplay ? selectedPerDisplayScaling.displayName : appModel.scalingMode.displayName)
        if let selectedDisplay {
            values.append(selectedDisplay.resolution)
        }
        return values
    }

    private var heroPreviewImage: NSImage? {
        if appModel.usePerDisplay, let selectedDisplay {
            print("ModernHomeView: heroPreviewImage - Per-display mode, using display preview")
            return selectedDisplay.previewImage
        }

        if appModel.rendererMode == .web {
            print("ModernHomeView: heroPreviewImage - Web mode, returning web icon")
            return NSWorkspace.shared.icon(forFileType: "webloc")
        }

        let path = appModel.selectedVideoPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !path.isEmpty else {
            print("ModernHomeView: heroPreviewImage - No path selected, returning movie icon")
            return NSWorkspace.shared.icon(forFileType: "public.movie")
        }

        print("ModernHomeView: heroPreviewImage - Loading preview for: \(path)")
        let image = previewIcon(forURL: URL(fileURLWithPath: path), fallbackIsWeb: false)
        print("ModernHomeView: heroPreviewImage - Got image with size: \(image.size)")
        return image
    }

    private var heroVideoURL: URL? {
        if appModel.usePerDisplay, let selectedDisplay {
            // For per-display mode, return the selected display's preview URL as video
            let url = selectedPerDisplayPreviewURL
            print("ModernHomeView.heroVideoURL: per-display -> \(url?.absoluteString ?? "nil")")
            return url
        }

        // For unified mode, return the selected video path
        if appModel.rendererMode == .web {
            print("ModernHomeView.heroVideoURL: rendererMode=web -> nil")
            return nil  // Don't play web URLs in preview
        }

        let path = appModel.selectedVideoPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !path.isEmpty else {
            print("ModernHomeView.heroVideoURL: selectedVideoPath empty -> nil")
            return nil
        }

        let fileURL = URL(fileURLWithPath: path)
        print("ModernHomeView.heroVideoURL: unified -> \(fileURL.absoluteString), exists=\(FileManager.default.fileExists(atPath: fileURL.path))")
        return fileURL
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

        let source = selectedPerDisplaySource.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty else {
            return nil
        }

        // If we've just selected a file for this display, prefer the transient URL
        if let transient = transientPerDisplayPreviewURL, displayID == selectedPerDisplayID {
            return transient
        }

        return appModel.perDisplayResolvedURL(for: displayID) ?? URL(string: source) ?? URL(fileURLWithPath: source)
    }

    private var selectedPerDisplayScaling: VideoScalingMode {
        guard let displayID = selectedPerDisplayID else {
            return appModel.scalingMode
        }

        return appModel.perDisplayScalingMode(for: displayID)
    }

    private var displayCards: [DisplayCard] {
        NSScreen.screens.enumerated().map { index, screen in
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
        let source = perDisplaySource(for: displayID)
        guard !source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        return appModel.perDisplayResolvedURL(for: displayID) ?? URL(string: source) ?? URL(fileURLWithPath: source)
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

    private func syncSelectedDisplayIfNeeded() {
        guard appModel.usePerDisplay, !NSScreen.screens.isEmpty else {
            selectedDisplayID = nil
            return
        }

        if let selectedDisplayID,
           NSScreen.screens.contains(where: { $0.displayID == selectedDisplayID }) {
            return
        }

        selectedDisplayID = NSScreen.screens.first?.displayID
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
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Per-Display Workspace")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                if appModel.usePerDisplay && NSScreen.screens.count > 1 {
                    if let selectedDisplay {
                        let sourceSummary = selectedPerDisplaySource.isEmpty ? "No source selected" : (selectedPerDisplayPreviewURL?.lastPathComponent ?? selectedPerDisplaySource)

                        CardView(title: "Current Display Preview", style: .elevated) {
                            VStack(alignment: .leading, spacing: 14) {
                                WallpaperPreviewCard(
                                    title: selectedDisplay.title,
                                    subtitle: selectedDisplay.subtitle,
                                    thumbnail: selectedDisplay.previewImage,
                                    trailingInfo: selectedPerDisplayScaling.displayName,
                                    isHero: false
                                )

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(sourceSummary)
                                        .font(DesignTokens.Typography.subtitle)
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                } else {
                    HStack {
                        Image(systemName: "rectangle.on.rectangle")
                            .foregroundStyle(.secondary)
                        Text("Unified wallpaper mode is active. Enable per-display mode to manage individual displays here.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(10)
                    .background {
                        RoundedRectangle(cornerRadius: DesignTokens.Corner.radius, style: .continuous)
                            .fill(DesignTokens.Colors.cardBackground)
                            .overlay {
                                RoundedRectangle(cornerRadius: DesignTokens.Corner.radius, style: .continuous)
                                    .fill(.linearGradient(colors: [DesignTokens.Colors.cardHighlight, Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .opacity(DesignTokens.Effects.cardBackdropOpacity)
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: DesignTokens.Corner.radius, style: .continuous)
                                    .stroke(DesignTokens.Colors.cardBorder, lineWidth: 1)
                            }
                    }
                }
            }
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(DesignTokens.Colors.background.opacity(0.72))
                .background(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(DesignTokens.Colors.cardBorder, lineWidth: 1)
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
                print("ModernHomeView.previewIcon: Successfully generated thumbnail with size \(thumbnail.size)")
                return thumbnail
            }
            print("ModernHomeView.previewIcon: Thumbnail generation failed, trying direct load")
            if let image = NSImage(contentsOf: url), image.size != .zero {
                print("ModernHomeView.previewIcon: Loaded image directly with size \(image.size)")
                return image
            }
            print("ModernHomeView.previewIcon: Direct load failed, using file icon")
            return NSWorkspace.shared.icon(forFile: url.path)
        }

        return fallbackIsWeb ? NSWorkspace.shared.icon(forFileType: "webloc") : NSWorkspace.shared.icon(forFileType: "public.movie")
    }

    private func thumbnailForLocalFile(at url: URL) -> NSImage? {
        let fileExtension = url.pathExtension.lowercased()
        if ["png", "jpg", "jpeg", "gif", "tiff", "bmp", "heic", "webp"].contains(fileExtension), let image = NSImage(contentsOf: url), image.size != .zero {
            return image
        }

        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 1920, height: 1920)

        do {
            let cgImage = try generator.copyCGImage(at: .zero, actualTime: nil)
            // Calculate proper size from CGImage dimensions
            let imageSize = NSSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
            return NSImage(cgImage: cgImage, size: imageSize)
        } catch {
            print("ModernHomeView: Failed to generate thumbnail - \(error.localizedDescription)")
            return nil
        }
    }

    private func collectionMappingDescription(
        index: Int,
        source: CollectionSource,
        type: WallpaperCollection.CollectionType
    ) -> String {
        let sourceName = URL(string: source.url)?.lastPathComponent ?? source.url

        if type == .simple {
            if appModel.savedCollections[appModel.selectedCollectionName ?? ""]?.sources.count == 1 {
                return "\(sourceName) → all displays"
            }
            return "\(sourceName) → screen slot \(index + 1) in order"
        }

        let target = source.displayLabel ?? source.displayIDFallback.map { "Display ID \($0)" } ?? "Auto-detect"
        return "\(sourceName) → bound to \(target)"
    }
}

#Preview {
    ModernHomeView()
        .environmentObject(AppViewModel())
}
