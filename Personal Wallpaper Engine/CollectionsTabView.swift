import SwiftUI

/// Phase 7: Dedicated Collections Tab for full collection management
/// Provides a focused experience for creating, editing, and applying collections
struct CollectionsTabView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @State private var isCollectionEditorPresented = false
    @State private var isDeleteCollectionAlertPresented = false
    @State private var editingCollectionName: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
                TabHeaderView(
                    title: "Collections",
                    subtitle: "Create, preview, and apply wallpaper sets for your displays.",
                    systemImage: "square.stack.3d.up.fill"
                )

                let collectionNames = appModel.savedCollections.keys.sorted()
                let selectedCollection = appModel.selectedCollectionName.flatMap { appModel.savedCollections[$0] }
                let lastUsedCollection = appModel.lastUsedCollectionName.flatMap { appModel.savedCollections[$0] }

                collectionsActionBar(collectionNames: collectionNames)

                GlassCardView(title: "Library") {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "square.stack.3d.up")
                                            .foregroundStyle(.secondary)

                                        Text("\(collectionNames.count) collection\(collectionNames.count == 1 ? "" : "s")")
                                            .font(DesignTokens.Typography.subtitle)
                                            .fontWeight(.semibold)
                                    }

                                    Text(collectionNames.isEmpty ? "Create a collection to save a wallpaper set." : "Select a collection to preview, apply, or manage.")
                                        .font(DesignTokens.Typography.subtitle)
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                }

                                Spacer()

                                if let lastUsedCollection {
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("Last Used")
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
                                        Text("No Collections Yet")
                                            .font(DesignTokens.Typography.subtitle)
                                            .fontWeight(.semibold)
                                        Text("Create your first collection to get started.")
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

                                Button(action: { isCollectionEditorPresented = true }) {
                                    Label("Create First Collection", systemImage: "plus.circle.fill")
                                        .labelStyle(.titleAndIcon)
                                }
                                .buttonStyle(.borderedProminent)
                                .frame(maxWidth: .infinity, alignment: .center)
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
                                .frame(maxWidth: .infinity, alignment: .leading)

                                CollectionThumbnailStrip(
                                    collectionNames: collectionNames,
                                    collections: appModel.savedCollections,
                                    selectedName: Binding(
                                        get: { appModel.selectedCollectionName },
                                        set: { newValue in
                                            if let newValue {
                                                appModel.selectCollection(name: newValue)
                                            } else {
                                                appModel.selectedCollectionName = nil
                                            }
                                        }
                                    )
                                )

                                if collectionNames.count > 1 {
                                    collectionGrid(
                                        collectionNames: collectionNames,
                                        lastUsedName: lastUsedCollection?.name
                                    )
                                }

                                if let selectedCollection {
                                    CollectionSummaryCard(
                                        collection: selectedCollection,
                                        isSelected: true,
                                        isLastUsed: lastUsedCollection?.name == selectedCollection.name,
                                        mappingDescriptions: selectedCollection.sources.enumerated().map { index, source in
                                            collectionMappingDescription(index: index, source: source, type: selectedCollection.collectionType)
                                        },
                                        previewSourceURL: selectedCollection.sources.first?.url,
                                        collectionName: selectedCollection.name
                                    )
                                }

                            }
                        }
                    }
            }
            .padding(DesignTokens.Spacing.large)
            .padding(.top, DesignTokens.Surfaces.mainTabBarReservedHeight + 8)
        }
        .frame(minWidth: 800, minHeight: 600)
        .task {
            appModel.loadSavedCollections()
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
            Text("Are you sure you want to delete the selected collection? This cannot be undone.")
        }
    }

    @ViewBuilder
    private func collectionsActionBar(collectionNames: [String]) -> some View {
        GlassCardView {
            HStack(spacing: 10) {
                Button(action: {
                    editingCollectionName = nil
                    isCollectionEditorPresented = true
                }) {
                    Label("New", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)

                Button(action: {
                    Task {
                        guard let selectedName = appModel.selectedCollectionName else { return }
                        _ = await appModel.applyCollection(name: selectedName)
                    }
                }) {
                    Label("Apply", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(appModel.selectedCollectionName == nil || appModel.isApplyingWallpaper)

                Button(action: {
                    guard let selectedName = appModel.selectedCollectionName else { return }
                    editingCollectionName = selectedName
                    isCollectionEditorPresented = true
                }) {
                    Label("Edit", systemImage: "pencil")
                }
                .buttonStyle(.bordered)
                .disabled(appModel.selectedCollectionName == nil)

                Button(role: .destructive, action: { isDeleteCollectionAlertPresented = true }) {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .disabled(appModel.selectedCollectionName == nil)

                Spacer(minLength: 0)

                Text("\(collectionNames.count) saved")
                    .font(.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func collectionGrid(collectionNames: [String], lastUsedName: String?) -> some View {
        let columns = [
            GridItem(.flexible(), spacing: 14),
            GridItem(.flexible(), spacing: 14)
        ]

        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(collectionNames, id: \.self) { name in
                if let collection = appModel.savedCollections[name] {
                    CollectionSummaryCard(
                        collection: collection,
                        isSelected: appModel.selectedCollectionName == name,
                        isLastUsed: lastUsedName == name,
                        mappingDescriptions: collection.sources.enumerated().map { index, source in
                            collectionMappingDescription(index: index, source: source, type: collection.collectionType)
                        },
                        previewSourceURL: collection.sources.first?.url,
                        collectionName: collection.name
                    )
                    .onTapGesture {
                        appModel.selectCollection(name: name)
                    }
                }
            }
        }
    }

    private func collectionMappingDescription(index: Int, source: CollectionSource, type: WallpaperCollection.CollectionType) -> String {
        let displayInfo = type == .displayBound
            ? (source.displayLabel ?? "Display \(index + 1)")
            : "Display \(index + 1)"
        let fileInfo = URL(fileURLWithPath: source.url).lastPathComponent
        return "\(fileInfo) → \(displayInfo)"
    }
}

#Preview {
    CollectionsTabView()
        .environmentObject(AppViewModel())
}
