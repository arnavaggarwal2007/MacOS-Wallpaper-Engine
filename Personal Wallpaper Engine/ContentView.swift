//
//  ContentView.swift
//  Personal Wallpaper Engine
//
//  Created by Arnav Aggarwal on 4/30/26.
//

import SwiftUI
import AppKit
import AVFoundation
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @State private var isFileImporterPresented = false
    @State private var selectedDisplayForPicker: CGDirectDisplayID?
    @State private var perDisplayDraftSources: [String: String] = [:]
    @State private var isCollectionEditorPresented = false
    @State private var isDeleteCollectionAlertPresented = false
    @State private var editingCollectionName: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Wallpaper Configuration")
                        .font(.system(.title2, design: .default))
                        .fontWeight(.bold)
                    Text("Configure wallpaper sources and display settings")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // MARK: - Preview Section
                // Mode selector: Unified vs Per-Display
                HStack {
                    Text("Mode")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Toggle(isOn: Binding(get: { appModel.usePerDisplay }, set: { appModel.toggleUsePerDisplay($0) })) {
                        Text("Use Per-Display Wallpapers")
                            .font(.subheadline)
                    }
                    .toggleStyle(.switch)
                    Spacer()
                }

                previewSection

                // MARK: - Global Settings Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Global Settings")
                        .font(.headline)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: 10) {
                        // Renderer Mode
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Renderer Mode", systemImage: "waveform.circle")
                                .font(.subheadline)
                                .fontWeight(.medium)

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

                        Divider()

                        // Scaling Mode
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Scaling Mode", systemImage: "aspectratio")
                                .font(.subheadline)
                                .fontWeight(.medium)

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

                        Divider()

                        // Audio Controls
                        Toggle(
                            isOn: Binding(
                                get: { appModel.isMuted },
                                set: { appModel.updateMuted($0) }
                            )
                        ) {
                            Label("Mute Audio", systemImage: appModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(12)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)
                }

                // MARK: - Video Source Section (Unified Mode Only)
                if !appModel.usePerDisplay {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Main Wallpaper Source")
                            .font(.headline)
                            .fontWeight(.semibold)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(appModel.selectedVideoPath.isEmpty ? "No video selected" : appModel.selectedVideoPath)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        .padding(12)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(8)

                        if appModel.rendererMode == .web {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Web Source URL", systemImage: "globe")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                HStack {
                                    TextField("https://example.com/animated-background", text: Binding(
                                        get: { appModel.webURLString },
                                        set: { appModel.updateWebURL($0) }
                                    ))
                                    .textFieldStyle(.roundedBorder)

                                    Button(action: {
                                        Task { await appModel.applyWallpaperFromSelection() }
                                    }) {
                                        Label("Apply", systemImage: "checkmark.circle.fill")
                                            .labelStyle(.titleAndIcon)
                                    }
                                    .disabled(appModel.webURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || appModel.isApplyingWallpaper)
                                }
                                Text("Enter a public HTTP(S) URL to render as animated wallpaper.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(8)
                        } else {
                            HStack(spacing: 12) {
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

                // MARK: - Per-Display Settings
                if appModel.usePerDisplay {
                    if NSScreen.screens.count > 1 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Per-Display Settings")
                                .font(.headline)
                                .fontWeight(.semibold)

                            ForEach(Array(NSScreen.screens.enumerated()), id: \.element.displayID) { index, screen in
                                let displayIndex = index + 1
                                let id = screen.displayID
                                let displayName = screen.localizedName

                                VStack(alignment: .leading, spacing: 10) {
                                    Label("Display \(displayIndex): \(displayName)", systemImage: "display")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.blue)

                                    // URL/Source Input
                                    HStack {
                                        let displayKey = String(id)
                                        TextField("http://... or file:///...", text: Binding(
                                            get: { perDisplayDraftSources[displayKey] ?? appModel.perDisplaySource(for: id) },
                                            set: { perDisplayDraftSources[displayKey] = $0 }
                                        ))
                                        .textFieldStyle(.roundedBorder)

                                        Button(action: {
                                            selectedDisplayForPicker = id
                                            isFileImporterPresented = true
                                        }) {
                                            Label("Browse", systemImage: "folder")
                                                .labelStyle(.titleAndIcon)
                                        }

                                        Button(action: {
                                            Task {
                                                await appModel.applyPerDisplayWallpaper(
                                                    displayID: id,
                                                    sourceString: perDisplayDraftSources[displayKey] ?? appModel.perDisplaySource(for: id)
                                                )
                                            }
                                        }) {
                                            Label("Apply Wallpaper", systemImage: "checkmark.circle.fill")
                                                .labelStyle(.titleAndIcon)
                                        }
                                    }

                                    // Per-Display Scaling Mode
                                    VStack(alignment: .leading, spacing: 6) {
                                        Label("Scaling", systemImage: "aspectratio.fill")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.secondary)

                                        Picker(
                                            "Scaling",
                                            selection: Binding(
                                                get: { appModel.perDisplayScalingMode(for: id) },
                                                set: { appModel.updatePerDisplayScalingMode(id, $0) }
                                            )
                                        ) {
                                            ForEach(VideoScalingMode.allCases, id: \.self) { mode in
                                                Text(mode.displayName).tag(mode)
                                            }
                                        }
                                        .pickerStyle(.segmented)
                                        .font(.caption)
                                    }
                                }
                                .padding(12)
                                .background(Color(.controlBackgroundColor))
                                .cornerRadius(8)
                            }
                        }
                    } else {
                        Text("Per-display mode requires multiple displays connected.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                // MARK: - Saved Collections Section (Phase 6A)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Saved Collections")
                        .font(.headline)
                        .fontWeight(.semibold)

                    let collectionNames = appModel.savedCollections.keys.sorted()

                    if collectionNames.isEmpty {
                        Text("No collections saved yet. Create one to get started.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(12)
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(8)
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

                        if let selectedName = appModel.selectedCollectionName,
                           let selectedCollection = appModel.savedCollections[selectedName] {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(selectedCollection.name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)

                                    Text(selectedCollection.collectionType == .simple ? "Simple" : "Display-Bound")
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.15))
                                        .cornerRadius(4)

                                    Spacer()

                                    Text("\(selectedCollection.sources.count) source(s)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                ForEach(Array(selectedCollection.sources.enumerated()), id: \.offset) { index, source in
                                    Text(collectionMappingDescription(index: index, source: source, type: selectedCollection.collectionType))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .padding(12)
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(8)
                        }
                    }

                    HStack(spacing: 10) {
                        Button(action: { isCollectionEditorPresented = true }) {
                            Label("Create Collection", systemImage: "plus.circle")
                                .labelStyle(.titleAndIcon)
                        }

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
                        .disabled(appModel.selectedCollectionName == nil || appModel.isApplyingWallpaper)

                        Button(role: .destructive, action: {
                            isDeleteCollectionAlertPresented = true
                        }) {
                            Label("Delete Collection", systemImage: "trash")
                                .labelStyle(.titleAndIcon)
                        }
                        .disabled(appModel.selectedCollectionName == nil)
                    }
                }

                // MARK: - System Settings Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("System Settings")
                        .font(.headline)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(
                            isOn: Binding(
                                get: { appModel.isLaunchOnLoginEnabled },
                                set: { _ in
                                    Task { await appModel.toggleLaunchOnLogin() }
                                }
                            )
                        ) {
                            Label("Launch on Login", systemImage: "power")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }

                        Text("Automatically start the wallpaper engine when you log in (requires macOS 13.2+)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)
                }

                // MARK: - Status Messages
                if appModel.isApplyingWallpaper {
                    HStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.8, anchor: .center)
                        Text("Applying wallpaper...")
                            .font(.footnote)
                    }
                    .padding(12)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }

                if let message = appModel.statusMessage {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(message)
                            .font(.footnote)
                    }
                    .padding(12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }

                if let error = appModel.errorMessage {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.footnote)
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }

                if let message = appModel.launchOnLoginStatusMessage {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(message)
                            .font(.footnote)
                    }
                    .padding(12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }

                if let error = appModel.launchOnLoginErrorMessage {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.footnote)
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(20)
        }
        .frame(minWidth: 580, minHeight: 380)
        .task {
            await appModel.loadSavedCollections()
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.movie, .mpeg4Movie, .quickTimeMovie],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let firstURL = urls.first else { return }

                // If a display was selected for per-display picker, use that
                if let displayID = selectedDisplayForPicker {
                    perDisplayDraftSources[String(displayID)] = firstURL.absoluteString
                    selectedDisplayForPicker = nil
                } else {
                    // Otherwise, use the main video picker only when unified mode is enabled.
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
            }
        }
        .sheet(isPresented: $isCollectionEditorPresented) {
            let selectedName = editingCollectionName.flatMap { appModel.savedCollections[$0] }
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

    // MARK: - Preview Section
    @ViewBuilder
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Wallpaper Preview")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                if !appModel.usePerDisplay {
                    // Main wallpaper info with icon (unified mode)
                    HStack(spacing: 12) {
                    let iconImage = previewIcon(forURL: URL(fileURLWithPath: appModel.selectedVideoPath), fallbackIsWeb: appModel.rendererMode == .web)

                    Image(nsImage: iconImage)
                        .resizable()
                        .renderingMode(.original)
                        .frame(width: 36, height: 36)
                        .cornerRadius(6)

                    VStack(alignment: .leading, spacing: 4) {
                        Label("Main Display", systemImage: "display")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        if appModel.rendererMode == .web {
                            Text(appModel.webURLString.isEmpty ? "No URL set" : appModel.webURLString)
                                .font(.callout)
                                .lineLimit(1)
                        } else {
                            Text(appModel.selectedVideoPath.isEmpty ? "No video selected" : URL(fileURLWithPath: appModel.selectedVideoPath).lastPathComponent)
                                .font(.callout)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Label(appModel.scalingMode.displayName, systemImage: "aspectratio.fill")
                            .font(.caption)
                            .fontWeight(.medium)
                        Label(appModel.isMuted ? "Muted" : "Audio On", systemImage: appModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.caption)
                    }
                    .foregroundStyle(.blue)
                    }
                    .padding(12)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)
                } else {
                    // Indicate that unified main wallpaper is disabled when using per-display
                    HStack {
                        Image(systemName: "rectangle.on.rectangle")
                            .foregroundStyle(.secondary)
                        Text("Per-display mode enabled — main unified wallpaper is disabled")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(10)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)
                }

                // Per-display preview if multi-display and per-display mode enabled
                if appModel.usePerDisplay && NSScreen.screens.count > 1 {
                    ForEach(Array(NSScreen.screens.enumerated()), id: \.element.displayID) { index, screen in
                        let displayIndex = index + 1
                        let id = screen.displayID
                        let source = appModel.perDisplaySource(for: id)
                        let scaling = appModel.perDisplayScalingMode(for: id)

                        if !source.isEmpty {
                            HStack(spacing: 12) {
                                // Per-display icon
                                let perIcon = previewIcon(forURL: appModel.perDisplayResolvedURL(for: id) ?? URL(fileURLWithPath: source), fallbackIsWeb: true)

                                Image(nsImage: perIcon)
                                    .resizable()
                                    .frame(width: 28, height: 28)
                                    .cornerRadius(6)

                                VStack(alignment: .leading, spacing: 4) {
                                    Label("Display \(displayIndex)", systemImage: "display.2")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.secondary)

                                    Text((appModel.perDisplayResolvedURL(for: id)?.lastPathComponent).flatMap { $0.isEmpty ? nil : $0 } ?? URL(fileURLWithPath: source).lastPathComponent)
                                        .font(.callout)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Label(scaling.displayName, systemImage: "aspectratio.fill")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.blue)
                            }
                            .padding(10)
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.windowBackgroundColor).opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }

    private func previewIcon(forURL url: URL, fallbackIsWeb: Bool) -> NSImage {
        if url.isFileURL {
            if let thumbnail = thumbnailForLocalFile(at: url) {
                return thumbnail
            }
            if let image = NSImage(contentsOf: url), image.size != .zero {
                return image
            }
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
        generator.maximumSize = CGSize(width: 96, height: 96)

        do {
            let cgImage = try generator.copyCGImage(at: .zero, actualTime: nil)
            return NSImage(cgImage: cgImage, size: .zero)
        } catch {
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
                return "\(sourceName) -> All displays"
            }
            return "\(sourceName) -> Screen slot \(index + 1)"
        }

        let target = source.displayLabel ?? source.displayIDFallback.map { "Display ID \($0)" } ?? "Auto-detect"
        return "\(sourceName) -> \(target)"
    }
}

#Preview {
    ContentView()
        .environmentObject(AppViewModel())
}
