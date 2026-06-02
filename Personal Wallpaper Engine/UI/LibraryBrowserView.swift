import SwiftUI
import AppKit

/// Limits concurrent library thumbnail generation to avoid main-thread priority inversions.
private actor LibraryThumbnailLoader {
    static let shared = LibraryThumbnailLoader()
    private let maxConcurrent = 4
    private var inFlight = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func acquire() async {
        if inFlight < maxConcurrent {
            inFlight += 1
            return
        }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
        inFlight += 1
    }

    func release() {
        inFlight = max(0, inFlight - 1)
        if !waiters.isEmpty, inFlight < maxConcurrent {
            let next = waiters.removeFirst()
            next.resume()
        }
    }
}

/// Grid or horizontal-strip browser for indexed local library items (Phase 8C).
struct LibraryBrowserView: View {
    enum Layout {
        case grid
        case strip
    }

    enum Mode {
        case browse
        case picker(onSelect: (LibraryItem) -> Void)
    }

    @EnvironmentObject private var appModel: AppViewModel

    let mode: Mode
    var layout: Layout = .grid
    var showsApplyButton: Bool = true
    var compact: Bool = false

    @State private var thumbnailCache: [String: NSImage] = [:]
    @State private var loadingIDs: Set<String> = []

    private let gridColumns = [
        GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 14)
    ]

    private var titleLineLimit: Int {
        layout == .strip ? 1 : (compact ? 1 : 2)
    }

    private var showsApplyOnTile: Bool {
        showsApplyButton && layout == .grid
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if layout == .grid {
                filterBar
            }

            if appModel.libraryRoots.isEmpty {
                emptyRootsState
            } else if appModel.filteredLibraryItems.isEmpty {
                emptyItemsState
            } else {
                switch layout {
                case .grid:
                    libraryGrid
                case .strip:
                    libraryStrip
                }
            }
        }
    }

    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                TextField("Search library…", text: $appModel.librarySearchText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: DesignTokens.Corner.radius, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(title: "All", isSelected: appModel.libraryRootFilterID == nil && !appModel.libraryFavoritesOnly) {
                        appModel.libraryRootFilterID = nil
                        appModel.libraryFavoritesOnly = false
                    }
                    filterChip(title: "Favorites", systemImage: "heart.fill", isSelected: appModel.libraryFavoritesOnly) {
                        appModel.libraryFavoritesOnly.toggle()
                    }
                    ForEach(appModel.libraryRoots) { root in
                        filterChip(title: root.displayName, isSelected: appModel.libraryRootFilterID == root.id) {
                            appModel.libraryRootFilterID = appModel.libraryRootFilterID == root.id ? nil : root.id
                        }
                    }
                }
            }

            if appModel.isLibraryScanning {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Scanning library…")
                        .font(DesignTokens.Typography.subtitle)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            }
        }
    }

    private func filterChip(
        title: String,
        systemImage: String? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.caption2)
                }
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background {
                Capsule(style: .continuous)
                    .fill(isSelected ? DesignTokens.Colors.primary.opacity(0.22) : Color.white.opacity(0.08))
            }
            .overlay {
                Capsule(style: .continuous)
                    .stroke(isSelected ? DesignTokens.Colors.primary.opacity(0.45) : Color.white.opacity(0.12), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var libraryGrid: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 22) {
                ForEach(appModel.filteredLibraryItems) { item in
                    tile(for: item, stripWidth: nil)
                        .task(id: item.id) {
                            await loadThumbnail(for: item)
                        }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 2)
        }
        .frame(maxHeight: compact ? 360 : 520)
    }

    private var libraryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(appModel.filteredLibraryItems) { item in
                    tile(for: item, stripWidth: 168)
                        .task(id: item.id) {
                            await loadThumbnail(for: item)
                        }
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 2)
        }
        .frame(height: 220)
    }

    @ViewBuilder
    private func tile(for item: LibraryItem, stripWidth: CGFloat?) -> some View {
        LibraryItemTile(
            item: item,
            image: thumbnailCache[item.id],
            isSelected: appModel.selectedLibraryItemID == item.id,
            titleLineLimit: titleLineLimit,
            showsApplyButton: showsApplyOnTile,
            fixedWidth: stripWidth,
            onFavorite: { appModel.toggleLibraryFavorite(itemID: item.id) },
            onSelect: { handleSelect(item) },
            onDoubleTapApply: layout == .strip && !item.isMissing
                ? { Task { await handleApply(item) } }
                : nil,
            onApply: showsApplyOnTile ? { Task { await handleApply(item) } } : nil
        )
    }

    private var emptyRootsState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No library folders yet")
                .font(DesignTokens.Typography.subtitle.weight(.semibold))
            Text("Add a folder in Settings → Local Library to index your wallpaper videos.")
                .font(.caption)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
        .padding(.vertical, 12)
    }

    private var emptyItemsState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No videos match your filters")
                .font(DesignTokens.Typography.subtitle.weight(.semibold))
            Text("Try another search, rescan your library in Settings, or add MP4/MOV files to an indexed folder.")
                .font(.caption)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
        .padding(.vertical, 12)
    }

    private func handleSelect(_ item: LibraryItem) {
        switch mode {
        case .browse:
            appModel.previewLibraryItem(item)
        case .picker(let onSelect):
            onSelect(item)
        }
    }

    private func handleApply(_ item: LibraryItem) async {
        guard let displayID = appModel.focusedDisplayID ?? NSScreen.screens.first?.displayID else {
            await MainActor.run {
                appModel.errorMessage = "No display available."
            }
            return
        }
        _ = await appModel.applyLibraryItem(item, displayIDs: [displayID])
    }

    private func loadThumbnail(for item: LibraryItem) async {
        if thumbnailCache[item.id] != nil || loadingIDs.contains(item.id) {
            return
        }
        loadingIDs.insert(item.id)
        defer {
            Task { @MainActor in
                loadingIDs.remove(item.id)
            }
        }

        await LibraryThumbnailLoader.shared.acquire()
        defer { Task { await LibraryThumbnailLoader.shared.release() } }

        guard let image = await appModel.libraryThumbnail(for: item) else { return }
        await MainActor.run {
            thumbnailCache[item.id] = image
        }
    }
}

struct LibraryItemTile: View {
    let item: LibraryItem
    let image: NSImage?
    let isSelected: Bool
    var titleLineLimit: Int = 2
    var showsApplyButton: Bool = true
    var fixedWidth: CGFloat?
    let onFavorite: () -> Void
    let onSelect: () -> Void
    var onDoubleTapApply: (() -> Void)? = nil
    let onApply: (() -> Void)?

    private var metadataBlockHeight: CGFloat {
        showsApplyButton ? 80 : 52
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            thumbnailBlock

            VStack(alignment: .leading, spacing: 6) {
                Text(item.displayName)
                    .font(.caption.weight(.semibold))
                    .lineLimit(titleLineLimit)
                    .truncationMode(.middle)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 32, maxHeight: 32, alignment: .topLeading)

                HStack(spacing: 6) {
                    if let resolution = item.resolutionLabel {
                        badge(resolution)
                    }
                    if let duration = item.durationLabel {
                        badge(duration)
                    }
                    Spacer(minLength: 0)
                }
                .frame(height: 20, alignment: .leading)

                if showsApplyButton, let onApply, !item.isMissing {
                    Spacer(minLength: 0)
                    Button(action: onApply) {
                        Label("Apply", systemImage: "bolt.fill")
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .frame(height: metadataBlockHeight, alignment: .top)
        }
        .frame(width: fixedWidth)
    }

    private var thumbnailBlock: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onSelect) {
                ZStack {
                    if let image {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(16 / 9, contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                        Image(systemName: "film")
                            .font(.title2)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }
                    if item.isMissing {
                        Color.black.opacity(0.55)
                        Text("Missing")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(16 / 9, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Corner.radius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: DesignTokens.Corner.radius, style: .continuous)
                        .stroke(isSelected ? DesignTokens.Colors.primary : Color.white.opacity(0.15), lineWidth: isSelected ? 2 : 1)
                }
            }
            .buttonStyle(.plain)
            .disabled(item.isMissing)
            .simultaneousGesture(
                TapGesture(count: 2).onEnded {
                    onDoubleTapApply?()
                }
            )
            .accessibilityHint(onDoubleTapApply != nil ? "Double-click to apply." : "")

            Button(action: onFavorite) {
                Image(systemName: item.favorited ? "heart.fill" : "heart")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(item.favorited ? .pink : .white.opacity(0.85))
                    .padding(6)
                    .background(Circle().fill(Color.black.opacity(0.45)))
            }
            .buttonStyle(.plain)
            .padding(6)
        }
    }

    private func badge(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.white.opacity(0.1)))
            .foregroundStyle(DesignTokens.Colors.textSecondary)
    }
}

/// Full library browser presented as a sheet from Home.
struct LibraryBrowserSheet: View {
    @EnvironmentObject private var appModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Browse Library")
                    .font(.title3.weight(.semibold))
                Spacer()
                Button("Done") { dismiss() }
            }

            LibraryBrowserView(mode: .browse, layout: .grid)
        }
        .padding(24)
        .frame(minWidth: 760, minHeight: 560)
        .presentationSizing(.fitted)
    }
}

/// Sheet wrapper for picking a library item in collection editor flows.
struct LibraryPickerSheet: View {
    @EnvironmentObject private var appModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    let onPick: (LibraryItem, URL) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Pick from Library")
                    .font(.title3.weight(.semibold))
                Spacer()
                Button("Cancel") { dismiss() }
            }
            LibraryBrowserView(
                mode: .picker { item in
                    guard let url = LocalLibraryManager.shared.resolveURL(for: item) else { return }
                    onPick(item, url)
                    dismiss()
                },
                layout: .grid,
                showsApplyButton: false,
                compact: true
            )
        }
        .padding(24)
        .frame(minWidth: 720, minHeight: 520)
        .presentationSizing(.fitted)
    }
}
