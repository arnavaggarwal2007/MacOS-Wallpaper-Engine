import SwiftUI

/// Card displaying a saved setup's metadata in a summary format
struct SetupPreviewCard: View {
    let setup: SavedSetup
    @ObservedObject var viewModel: AppViewModel
    var isPinned: Bool = false
    var onSelect: (() -> Void)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    var isSelected: Bool {
        viewModel.selectedSetupName == setup.name
    }

    private var connectedDisplayCount: Int {
        viewModel.connectedDisplayCount(in: setup.perDisplaySources)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(setup.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .truncationMode(.tail)

                        if isPinned {
                            Label("Pinned", systemImage: "pin.fill")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(DesignTokens.Colors.primary)
                                .labelStyle(.titleAndIcon)
                        }
                    }

                    if !setup.description.isEmpty {
                        Text(setup.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .truncationMode(.tail)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.body)
                }
            }

            HStack(spacing: 6) {
                infoBadge(
                    icon: setup.rendererMode == "web" ? "globe" : "film",
                    value: setup.rendererMode == "web" ? "Web" : "Video"
                )

                infoBadge(
                    icon: "display",
                    value: "\(connectedDisplayCount) display\(connectedDisplayCount == 1 ? "" : "s")"
                )

                infoBadge(
                    icon: setup.isMuted ? "speaker.slash" : "speaker.wave.2",
                    value: setup.isMuted ? "Muted" : "Sound"
                )
            }

            HStack(spacing: 12) {
                metadataColumn(title: "Created", value: setup.createdAt.formatted(date: .abbreviated, time: .shortened))
                Divider().frame(height: 20)
                metadataColumn(title: "Updated", value: setup.updatedAt.formatted(date: .abbreviated, time: .shortened))
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(6)
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
                        .stroke(
                            isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.cardBorder,
                            lineWidth: isSelected ? 2 : 1
                        )
                }
        }
        .shadow(color: .black.opacity(isHovered ? DesignTokens.Motion.hoverShadowOpacity : 0.04), radius: isHovered ? 8 : 2, y: isHovered ? 4 : 1)
        .scaleEffect(isHovered && !reduceMotion ? DesignTokens.Motion.hoverScale : 1)
        .animation(DesignTokens.Motion.hoverAnimation(reduceMotion: reduceMotion), value: isHovered)
        .contentShape(RoundedRectangle(cornerRadius: DesignTokens.Corner.radius, style: .continuous))
        .onTapGesture { onSelect?() }
        .onHover { isHovered = $0 }
    }

    private func metadataColumn(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }

    private func infoBadge(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(value)
                .font(.caption2)
                .fontWeight(.semibold)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(4)
    }
}

#Preview {
    let sampleSetup = SavedSetup(
        name: "Work Setup",
        description: "4K video wallpaper with per-display config",
        rendererMode: "video",
        isMuted: false,
        scalingMode: "resizeAspectFill",
        usePerDisplay: true,
        unifiedSource: "/path/to/video.mp4",
        perDisplaySources: [:],
        perDisplayScalingModes: [:],
        unifiedBookmarkBase64: nil,
        perDisplayBookmarksBase64: [:]
    )

    SetupPreviewCard(setup: sampleSetup, viewModel: AppViewModel())
}
