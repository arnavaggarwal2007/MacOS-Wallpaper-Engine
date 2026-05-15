import SwiftUI

struct CollectionSummaryCard: View {
    let collection: WallpaperCollection
    let isSelected: Bool
    let isLastUsed: Bool
    let mappingDescriptions: [String]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    private var collectionTypeLabel: String {
        collection.collectionType == .simple ? "Simple" : "Display-Bound"
    }

    private var sourceCountLabel: String {
        "\(collection.sources.count) source\(collection.sources.count == 1 ? "" : "s")"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.medium) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(collection.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        if isSelected {
                            pill("Selected")
                        }
                    }

                    if !collection.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(collection.description)
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    pill(collectionTypeLabel)

                    if isLastUsed {
                        pill("Last used")
                    }
                }
            }

            HStack(spacing: 8) {
                infoBadge(label: "Sources", value: sourceCountLabel)
                infoBadge(label: "Updated", value: collection.updatedAt.formatted(date: .abbreviated, time: .omitted))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Mapping")
                    .font(DesignTokens.Typography.subtitle)
                    .foregroundColor(DesignTokens.Colors.textPrimary)

                if mappingDescriptions.isEmpty {
                    Text("No source mappings available.")
                        .font(DesignTokens.Typography.subtitle)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                } else {
                    ForEach(Array(mappingDescriptions.prefix(4).enumerated()), id: \.offset) { _, mapping in
                        Text(mapping)
                            .font(DesignTokens.Typography.subtitle)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .lineLimit(1)
                    }

                    if mappingDescriptions.count > 4 {
                        Text("And \(mappingDescriptions.count - 4) more source\(mappingDescriptions.count - 4 == 1 ? "" : "s")")
                            .font(DesignTokens.Typography.subtitle)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
            }
        }
        .padding(DesignTokens.Spacing.large)
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
        .shadow(color: Color.black.opacity(isHovered ? DesignTokens.Motion.hoverShadowOpacity : 0.05), radius: isHovered ? DesignTokens.Elevation.cardShadowRadius : 2, x: 0, y: isHovered ? DesignTokens.Elevation.cardShadowYOffset : 1)
        .scaleEffect(isHovered && !reduceMotion ? DesignTokens.Motion.hoverScale : 1)
        .animation(reduceMotion ? .linear(duration: 0) : .easeInOut(duration: DesignTokens.Motion.standardDuration), value: isHovered)
        .onHover { isHovered = $0 }
    }

    private func pill(_ text: String) -> some View {
        Text(text)
            .font(DesignTokens.Typography.subtitle)
            .foregroundColor(DesignTokens.Colors.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(DesignTokens.Colors.primary.opacity(0.10))
            .cornerRadius(999)
    }

    private func infoBadge(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(DesignTokens.Typography.subtitle)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            Text(value)
                .font(DesignTokens.Typography.subtitle)
                .foregroundColor(DesignTokens.Colors.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(DesignTokens.Colors.background)
        )
        .cornerRadius(8)
    }
}
