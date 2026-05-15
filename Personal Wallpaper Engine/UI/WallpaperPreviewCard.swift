import SwiftUI
import AppKit

struct WallpaperPreviewCard: View {
    let title: String
    let subtitle: String?
    let thumbnail: NSImage?
    let trailingInfo: String?

    init(title: String, subtitle: String? = nil, thumbnail: NSImage? = nil, trailingInfo: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.thumbnail = thumbnail
        self.trailingInfo = trailingInfo
    }

    var body: some View {
        HStack(spacing: 12) {
            if let ns = thumbnail {
                Image(nsImage: ns)
                    .resizable()
                    .frame(width: 64, height: 64)
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(DesignTokens.Colors.primary.opacity(0.08))
                    .frame(width: 64, height: 64)
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DesignTokens.Typography.subtitle)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                if let s = subtitle {
                    Text(s)
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let trailing = trailingInfo {
                Text(trailing)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
        }
        .padding(DesignTokens.Spacing.small)
        .background(DesignTokens.Colors.cardBackground)
        .cornerRadius(DesignTokens.Corner.radius)
    }
}

#Preview("Wallpaper Preview Card") {
    WallpaperPreviewCard(title: "Main Display", subtitle: "No video selected", thumbnail: nil, trailingInfo: "Muted")
        .padding()
}
