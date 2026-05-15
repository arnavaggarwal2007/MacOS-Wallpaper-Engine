import SwiftUI
import AppKit

struct WallpaperPreviewCard: View {
    let title: String
    let subtitle: String?
    let thumbnail: NSImage?
    let trailingInfo: String?
    let isHero: Bool

    init(title: String, subtitle: String? = nil, thumbnail: NSImage? = nil, trailingInfo: String? = nil, isHero: Bool = false) {
        self.title = title
        self.subtitle = subtitle
        self.thumbnail = thumbnail
        self.trailingInfo = trailingInfo
        self.isHero = isHero
    }

    var body: some View {
        HStack(spacing: isHero ? 16 : 12) {
            if let ns = thumbnail {
                Image(nsImage: ns)
                    .resizable()
                    .scaledToFill()
                    .frame(width: isHero ? 220 : 64, height: isHero ? 120 : 64)
                    .clipped()
                    .cornerRadius(isHero ? DesignTokens.Corner.heroRadius : 8)
            } else {
                Rectangle()
                    .fill(DesignTokens.Colors.primary.opacity(isHero ? 0.06 : 0.08))
                    .frame(width: isHero ? 220 : 64, height: isHero ? 120 : 64)
                    .cornerRadius(isHero ? DesignTokens.Corner.heroRadius : 8)
            }

            VStack(alignment: .leading, spacing: isHero ? 8 : 4) {
                Text(title)
                    .font(isHero ? DesignTokens.Typography.heroTitle : DesignTokens.Typography.subtitle)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                if let s = subtitle {
                    Text(s)
                        .font(isHero ? DesignTokens.Typography.heroSubtitle : DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .lineLimit(isHero ? 2 : 1)
                }
            }

            Spacer()

            if let trailing = trailingInfo {
                Text(trailing)
                    .font(isHero ? DesignTokens.Typography.body : DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
        }
        .padding(isHero ? DesignTokens.Spacing.medium : DesignTokens.Spacing.small)
        .background(DesignTokens.Colors.cardBackground)
        .cornerRadius(isHero ? DesignTokens.Corner.heroRadius : DesignTokens.Corner.radius)
        .overlay(
            RoundedRectangle(cornerRadius: isHero ? DesignTokens.Corner.heroRadius : DesignTokens.Corner.radius)
                .stroke(Color.gray.opacity(isHero ? 0.12 : 0.2), lineWidth: isHero ? 1 : 1)
        )
    }
}

#Preview("Wallpaper Preview Card") {
    WallpaperPreviewCard(title: "Main Display", subtitle: "No video selected", thumbnail: nil, trailingInfo: "Muted")
        .padding()
}
