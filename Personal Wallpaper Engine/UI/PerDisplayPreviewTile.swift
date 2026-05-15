import SwiftUI
import AppKit

struct PerDisplayPreviewTile: View {
    var displayName: String = "Display"
    var thumbnail: NSImage?

    var body: some View {
        HStack(spacing: 10) {
            if let ns = thumbnail {
                Image(nsImage: ns)
                    .resizable()
                    .frame(width: 44, height: 44)
                    .cornerRadius(6)
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
        .padding(DesignTokens.Spacing.small)
        .background(DesignTokens.Colors.cardBackground)
        .cornerRadius(DesignTokens.Corner.radius)
    }
}

#Preview("Per Display Tile") {
    PerDisplayPreviewTile(displayName: "Built-in Retina")
        .padding()
}
