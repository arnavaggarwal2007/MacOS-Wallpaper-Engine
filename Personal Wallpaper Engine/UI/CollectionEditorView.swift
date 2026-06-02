import SwiftUI
import UniformTypeIdentifiers
import os.log

/// Main SwiftUI view for creating/editing wallpaper collections.
struct CollectionEditorView: View {

    @EnvironmentObject private var appModel: AppViewModel
    @State private var collectionName: String
    @State private var collectionDescription: String
    @State private var collectionType: WallpaperCollection.CollectionType
    @State private var sourceDrafts: [CollectionSourceDraft]
    @State private var validationMessage: String?
    @State private var nameValidationMessage: String?
    @State private var browseIndex: Int?
    @State private var libraryBrowseIndex: Int?
    @State private var isFileImporterPresented = false
    @State private var isLibraryPickerPresented = false

    let originalCollectionName: String?
    let existingCollectionNames: Set<String>
    let onCancel: () -> Void
    let onSave: (WallpaperCollection, [String: Data]) -> Void

    @FocusState private var focusedField: CollectionEditorField?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private let logger = Logger(subsystem: "com.local.wallpaper", category: "CollectionEditor")
    
    enum CollectionEditorField {
        case name, description, typePicker
    }

    init(
        initialName: String = "",
        initialDescription: String = "",
        initialType: WallpaperCollection.CollectionType = .simple,
        initialSources: [CollectionSource] = [],
        initialBookmarks: [String: Data] = [:],
        originalCollectionName: String? = nil,
        existingCollectionNames: Set<String> = [],
        onCancel: @escaping () -> Void,
        onSave: @escaping (WallpaperCollection, [String: Data]) -> Void
    ) {
        _collectionName = State(initialValue: initialName)
        _collectionDescription = State(initialValue: initialDescription)
        _collectionType = State(initialValue: initialType)
        _sourceDrafts = State(
            initialValue: initialSources.isEmpty
                ? [CollectionSourceDraft(order: 0)]
                : initialSources.enumerated().map { index, source in
                    CollectionSourceDraft(
                        url: source.url,
                        displayLabel: source.displayLabel,
                        displayIDFallback: source.displayIDFallback,
                        scalingMode: source.scalingMode,
                        order: index,
                        bookmark: initialBookmarks[source.url],
                        captureError: nil
                    )
                }
        )
        self.originalCollectionName = originalCollectionName
        self.existingCollectionNames = existingCollectionNames
        self.onCancel = onCancel
        self.onSave = onSave
    }

    var canSave: Bool {
        let hasName = !collectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasSource = sourceDrafts.contains { !$0.url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return hasName && hasSource
    }

    private var canAddNew: Bool { sourceDrafts.count < 8 }

    var body: some View {
        CardView(title: originalCollectionName == nil ? "Create Collection" : "Edit Collection", style: .elevated) {
            VStack(alignment: .leading, spacing: 16) {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Group wallpaper sources into a reusable collection. Collection behavior is unchanged; this view only improves how the inputs are presented and validated.")
                            .font(DesignTokens.Typography.subtitle)
                            .foregroundColor(DesignTokens.Colors.textSecondary)

                        CardSection(header: "Basics") {
                            VStack(alignment: .leading, spacing: 12) {
                                VStack(alignment: .leading, spacing: 8) {
                                    TextField("Collection Name", text: $collectionName)
                                        .textFieldStyle(.roundedBorder)
                                        .focused($focusedField, equals: .name)
                                        .onSubmit { _ = validateCollectionName() }

                                    TextField("Description (optional)", text: $collectionDescription)
                                        .textFieldStyle(.roundedBorder)
                                        .focused($focusedField, equals: .description)
                                }

                                HStack(alignment: .center, spacing: 12) {
                                    Picker("Type", selection: $collectionType) {
                                        Text("Simple").tag(WallpaperCollection.CollectionType.simple)
                                        Text("Display-Bound").tag(WallpaperCollection.CollectionType.displayBound)
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(maxWidth: 260)

                                    Spacer()
                                }
                            }

                            if let nameValidationMessage {
                                statusBanner(title: "Name", message: nameValidationMessage, color: .red)
                            }
                        }

                        CardSection(header: "Sources") {
                            VStack(alignment: .leading, spacing: 12) {
                                if !sourceDrafts.isEmpty {
                                    ForEach(sourceDrafts.indices, id: \.self) { index in
                                        CollectionSourceInput(
                                            isDisplayBound: collectionType == .displayBound,
                                            onDelete: { removeSource(at: index) },
                                            onBrowse: {
                                                browseIndex = index
                                                isFileImporterPresented = true
                                            },
                                            onLibraryBrowse: {
                                                libraryBrowseIndex = index
                                                isLibraryPickerPresented = true
                                            },
                                            url: Binding(
                                                get: { sourceDrafts[index].url },
                                                set: { sourceDrafts[index].url = $0 }
                                            ),
                                            displayLabel: Binding(
                                                get: { sourceDrafts[index].displayLabel },
                                                set: { sourceDrafts[index].displayLabel = $0 }
                                            ),
                                            displayIDFallback: Binding(
                                                get: { sourceDrafts[index].displayIDFallback },
                                                set: { sourceDrafts[index].displayIDFallback = $0 }
                                            ),
                                            scalingMode: Binding(
                                                get: { sourceDrafts[index].scalingMode },
                                                set: { sourceDrafts[index].scalingMode = $0 }
                                            ),
                                            bookmark: Binding(
                                                get: { sourceDrafts[index].bookmark },
                                                set: { sourceDrafts[index].bookmark = $0 }
                                            ),
                                            captureError: Binding(
                                                get: { sourceDrafts[index].captureError },
                                                set: { sourceDrafts[index].captureError = $0 }
                                            )
                                        )
                                    }
                                } else {
                                    HStack(spacing: 10) {
                                        Image(systemName: "tray.and.arrow.down")
                                            .foregroundColor(DesignTokens.Colors.textSecondary)
                                        Text("Add a source to get started.")
                                            .font(DesignTokens.Typography.subtitle)
                                            .foregroundColor(DesignTokens.Colors.textSecondary)
                                        Spacer()
                                    }
                                    .padding(12)
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

                                HStack {
                                    Button(action: { addSource() }) {
                                        Label("Add Source", systemImage: "plus")
                                            .labelStyle(.titleAndIcon)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(!canAddNew)

                                    Spacer()

                                    Text("\(sourceDrafts.filter { !$0.url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count) active source\(sourceDrafts.filter { !$0.url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count == 1 ? "" : "s")")
                                        .font(DesignTokens.Typography.subtitle)
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                }
                            }
                        }

                        CardSection(header: "Preview") {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Sources: \(sourceDrafts.filter { !$0.url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count)")
                                    .font(DesignTokens.Typography.subtitle)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)

                                if !collectionDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Text(collectionDescription)
                                        .font(DesignTokens.Typography.body)
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                } else {
                                    Text("The preview reflects the collection metadata and source count only.")
                                        .font(DesignTokens.Typography.subtitle)
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                }
                            }
                            .padding(DesignTokens.Spacing.medium)
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

                        if let validationMessage {
                            statusBanner(title: "Save", message: validationMessage, color: .orange)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .scrollClipDisabled(true)
                .frame(maxHeight: .infinity, alignment: .topLeading)

                HStack {
                    Spacer()

                    Button("Cancel", action: onCancel)
                        .buttonStyle(.bordered)
                        .keyboardShortcut(.cancelAction)

                    Button("Save") {
                        saveCollection()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canSave)
                }
            }
        }
        .padding()
        .onAppear {
            focusedField = .name
        }
        .animation(reduceMotion ? .linear(duration: 0) : .easeInOut(duration: DesignTokens.Motion.standardDuration), value: sourceDrafts.count)
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.movie, .mpeg4Movie, .quickTimeMovie],
            allowsMultipleSelection: false
        ) { result in
            guard let index = browseIndex else { return }
            browseIndex = nil

            guard sourceDrafts.indices.contains(index) else { return }

            switch result {
            case .success(let urls):
                if let firstURL = urls.first {
                    sourceDrafts[index].url = firstURL.absoluteString
                    logger.debug("File selected: \(firstURL.path), URL string: \(firstURL.absoluteString)")

                    let didStartAccess = firstURL.startAccessingSecurityScopedResource()
                    defer {
                        if didStartAccess {
                            firstURL.stopAccessingSecurityScopedResource()
                        }
                    }
                    
                    // Capture security-scoped bookmark for file access persistence
                    do {
                        let bookmark = try firstURL.bookmarkData(
                            options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                            includingResourceValuesForKeys: nil,
                            relativeTo: nil
                        )
                        sourceDrafts[index].bookmark = bookmark
                        sourceDrafts[index].captureError = nil
                        logger.debug("Successfully captured bookmark for \(firstURL.path)")
                    } catch {
                        sourceDrafts[index].captureError = error.localizedDescription
                        logger.error("Failed to capture bookmark for \(firstURL.path): \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                logger.error("File picker error: \(error.localizedDescription)")
            }
        }
        .sheet(isPresented: $isLibraryPickerPresented) {
            LibraryPickerSheet { item, url in
                guard let index = libraryBrowseIndex,
                      sourceDrafts.indices.contains(index) else { return }
                libraryBrowseIndex = nil
                sourceDrafts[index].url = url.absoluteString
                let didStartAccess = url.startAccessingSecurityScopedResource()
                defer {
                    if didStartAccess { url.stopAccessingSecurityScopedResource() }
                }
                if let bookmark = try? url.bookmarkData(
                    options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                ) {
                    sourceDrafts[index].bookmark = bookmark
                    sourceDrafts[index].captureError = nil
                } else {
                    sourceDrafts[index].captureError = "Could not capture bookmark for \(item.displayName)"
                }
            }
            .environmentObject(appModel)
        }
        .onChange(of: collectionType) { _, newType in
            guard newType == .simple else { return }
            for index in sourceDrafts.indices {
                sourceDrafts[index].displayLabel = nil
                sourceDrafts[index].displayIDFallback = nil
                sourceDrafts[index].scalingMode = nil
            }
        }
        .onChange(of: focusedField) { _, newField in
            if newField != .name {
                _ = validateCollectionName()
            }
        }
        .onChange(of: collectionName) { _, _ in
            if focusedField != .name {
                _ = validateCollectionName()
            }
        }
    }
    
    private func addSource() {
        sourceDrafts.append(CollectionSourceDraft(order: sourceDrafts.count))
    }
    
    private func removeSource(at index: Int) {
        guard sourceDrafts.indices.contains(index) else { return }
        sourceDrafts.remove(at: index)

        if sourceDrafts.isEmpty {
            sourceDrafts = [CollectionSourceDraft(order: 0)]
        }
    }

    private func saveCollection() {
        validationMessage = nil

        guard validateCollectionName() else { return }

        do {
            let sources = try buildSources()
            let collection = try WallpaperCollection(
                name: collectionName,
                description: collectionDescription,
                collectionType: collectionType,
                sources: sources
            )
            
            // Extract bookmarks from source drafts: URL -> bookmark data
            var bookmarks: [String: Data] = [:]
            var nonEmptyCount = 0
            for draft in sourceDrafts {
                if !draft.url.isEmpty {
                    nonEmptyCount += 1
                    if let bookmarkData = draft.bookmark {
                        bookmarks[draft.url] = bookmarkData
                        logger.debug("Including bookmark for: \(draft.url)")
                    } else {
                        logger.warning("Source has no bookmark: \(draft.url)")
                    }
                }
            }
            logger.debug("Collected \(bookmarks.count) bookmarks for collection")

            if bookmarks.count < nonEmptyCount {
                validationMessage = "Saved, but some sources are missing bookmarks and may not persist across restarts."
            } else {
                validationMessage = nil
            }

            onSave(collection, bookmarks)
        } catch let error as WallpaperError {
            validationMessage = error.errorDescription
        } catch {
            validationMessage = error.localizedDescription
        }
    }

    private func validateCollectionName() -> Bool {
        let trimmedName = collectionName.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedName.isEmpty {
            nameValidationMessage = "Collection name cannot be empty."
            return false
        }

        if !isValidCollectionName(trimmedName) {
            nameValidationMessage = "Use 1-255 characters and avoid /, \\ , or *."
            return false
        }

        let isOriginalName = originalCollectionName == trimmedName
        let isDuplicate = existingCollectionNames.contains(trimmedName) && !isOriginalName
        if isDuplicate {
            nameValidationMessage = "A collection named '\(trimmedName)' already exists."
            return false
        }

        nameValidationMessage = nil
        return true
    }

    private func buildSources() throws -> [CollectionSource] {
        var builtSources: [CollectionSource] = []

        let nonEmptyDrafts = sourceDrafts.filter { !$0.url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !nonEmptyDrafts.isEmpty else {
            throw WallpaperError.invalidCollectionSource(url: "", reason: "At least one source is required.")
        }

        for (index, draft) in nonEmptyDrafts.enumerated() {
            let source = try CollectionSource(
                url: draft.url.trimmingCharacters(in: .whitespacesAndNewlines),
                displayLabel: collectionType == .displayBound ? draft.displayLabel : nil,
                displayIDFallback: collectionType == .displayBound ? draft.displayIDFallback : nil,
                scalingMode: collectionType == .displayBound ? draft.scalingMode : nil,
                order: index
            )
            builtSources.append(source)
        }

        return builtSources
    }

    private func statusBanner(title: String, message: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignTokens.Typography.subtitle)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                Text(message)
                    .font(DesignTokens.Typography.subtitle)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }

            Spacer()
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color.opacity(0.12))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(color.opacity(0.22), lineWidth: 1)
                }
        }
    }
}

struct CollectionSourceDraft: Identifiable {
    let id = UUID()
    var url: String = ""
    var displayLabel: String?
    var displayIDFallback: Int?
    var scalingMode: String?
    var order: Int
    var bookmark: Data?  // Phase 6A: Security-scoped bookmark for file access
    var captureError: String?
}

#Preview("Collection Editor") {
    CollectionEditorView(
        onCancel: {},
        onSave: { _, _ in }
    )
    .environmentObject(AppViewModel())
    .frame(width: 650, height: 580)
}
