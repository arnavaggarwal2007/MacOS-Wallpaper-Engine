import SwiftUI

/// Horizontal, thumbnail-forward collection picker.
struct CollectionThumbnailStrip: View {
    let collectionNames: [String]
    let collections: [String: WallpaperCollection]
    @Binding var selectedName: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.small) {
                ForEach(collectionNames, id: \.self) { name in
                    collectionChip(name: name)
                }
            }
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    private func collectionChip(name: String) -> some View {
        let isSelected = selectedName == name
        let previewURL = collections[name]?.sources.first?.url

        Button {
            selectedName = name
        } label: {
            VStack(spacing: 6) {
                WallpaperThumbnailView(
                    urlString: previewURL,
                    collectionName: name,
                    width: DesignTokens.Surfaces.thumbnailLandscapeWidth,
                    cornerRadius: DesignTokens.Corner.thumbnail
                )
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: DesignTokens.Corner.thumbnail, style: .continuous)
                            .stroke(DesignTokens.Colors.primary, lineWidth: 2)
                    }
                }

                Text(name)
                    .font(.caption.weight(isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.textSecondary)
                    .lineLimit(1)
                    .frame(width: DesignTokens.Surfaces.thumbnailLandscapeWidth)
            }
            .padding(8)
            .background {
                RoundedRectangle(cornerRadius: DesignTokens.Corner.radius, style: .continuous)
                    .fill(isSelected ? DesignTokens.Colors.primary.opacity(DesignTokens.Surfaces.selectedTabFillOpacity) : DesignTokens.Colors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: DesignTokens.Corner.radius, style: .continuous)
                            .stroke(
                                isSelected ? DesignTokens.Colors.primary.opacity(DesignTokens.Surfaces.selectedTabStrokeOpacity) : DesignTokens.Colors.cardBorder,
                                lineWidth: 1
                            )
                    }
            }
        }
        .buttonStyle(.plain)
        .animation(DesignTokens.Motion.selectionAnimation(reduceMotion: reduceMotion), value: selectedName)
    }
}
