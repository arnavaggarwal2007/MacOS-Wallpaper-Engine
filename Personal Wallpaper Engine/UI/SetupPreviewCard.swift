import SwiftUI

/// Card displaying a saved setup's metadata in a summary format
struct SetupPreviewCard: View {
    let setup: SavedSetup
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    var isSelected: Bool {
        viewModel.selectedSetupName == setup.name
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: Title and badge
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(setup.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    if !setup.description.isEmpty {
                        Text(setup.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                
                Spacer()
                
                // Selected indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.body)
                }
            }
            
            // Info badges (configuration summary)
            HStack(spacing: 6) {
                infoBadge(
                    label: setup.rendererMode == "web" ? "🌐 Web" : "🎬 Video",
                    value: setup.rendererMode == "web" ? "Web" : "Video"
                )
                
                infoBadge(
                    label: "🖥 Displays",
                    value: "\(setup.perDisplaySources.count) assigned"
                )

                infoBadge(
                    label: setup.isMuted ? "🔇 Muted" : "🔊 Sound",
                    value: setup.isMuted ? "Muted" : "Sound On"
                )
            }
            
            // Metadata
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Created")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(setup.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                Divider()
                    .frame(height: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Updated")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(setup.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
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
        .onHover { isHovered = $0 }
    }
    
    /// Small inline badge for configuration info
    private func infoBadge(label: String, value: String) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Text(label)
                .font(.caption2)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
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
