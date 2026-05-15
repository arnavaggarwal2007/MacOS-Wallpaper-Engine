import SwiftUI
import AppKit

struct PerDisplayPreviewTile: View {
    var displayName: String = "Display"
    var thumbnail: NSImage?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            if let ns = thumbnail {
                Image(nsImage: ns)
                    .resizable()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                Circle()
                    .fill(DesignTokens.Colors.primary.opacity(0.15))
                    .frame(width: 44, height: 44)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                // Subtitle or small detail could go here
            }

            Spacer()
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
        .shadow(color: Color.black.opacity(isHovered ? DesignTokens.Motion.hoverShadowOpacity : 0.05), radius: isHovered ? DesignTokens.Elevation.cardShadowRadius : 2, x: 0, y: isHovered ? DesignTokens.Elevation.cardShadowYOffset : 1)
        .scaleEffect(isHovered && !reduceMotion ? DesignTokens.Motion.hoverScale : 1)
        .animation(reduceMotion ? .linear(duration: 0) : .easeInOut(duration: DesignTokens.Motion.standardDuration), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

#Preview("Per Display Tile") {
    PerDisplayPreviewTile(displayName: "Built-in Retina")
        .padding()
}
