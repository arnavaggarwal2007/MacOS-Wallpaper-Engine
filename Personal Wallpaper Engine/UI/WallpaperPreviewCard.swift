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
        HStack(alignment: .center, spacing: isHero ? 18 : 14) {
            thumbnailView

            VStack(alignment: .leading, spacing: isHero ? 8 : 4) {
                Text(title)
                    .font(isHero ? DesignTokens.Typography.heroTitle : DesignTokens.Typography.title)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                if let s = subtitle {
                    Text(s)
                        .font(isHero ? DesignTokens.Typography.heroSubtitle : DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .lineLimit(isHero ? 2 : 1)
                }

                if let trailing = trailingInfo, isHero {
                    Text(trailing)
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.primary)
                }
            }

            Spacer(minLength: isHero ? 12 : 8)

            if let trailing = trailingInfo, !isHero {
                Text(trailing)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
        }
        .padding(isHero ? DesignTokens.Spacing.large : DesignTokens.Spacing.medium)
        .background {
            RoundedRectangle(cornerRadius: isHero ? DesignTokens.Corner.heroRadius : DesignTokens.Corner.radius, style: .continuous)
                .fill(DesignTokens.Colors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: isHero ? DesignTokens.Corner.heroRadius : DesignTokens.Corner.radius, style: .continuous)
                        .fill(.linearGradient(colors: [DesignTokens.Colors.cardHighlight, Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .opacity(isHero ? 1 : DesignTokens.Effects.cardBackdropOpacity)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: isHero ? DesignTokens.Corner.heroRadius : DesignTokens.Corner.radius, style: .continuous)
                        .stroke(DesignTokens.Colors.cardBorder, lineWidth: 1)
                }
        }
        .shadow(color: Color.black.opacity(isHero ? 0.08 : 0.05), radius: isHero ? DesignTokens.Elevation.heroShadowRadius : DesignTokens.Elevation.cardShadowRadius * 0.5, x: 0, y: isHero ? DesignTokens.Elevation.heroShadowYOffset : DesignTokens.Elevation.cardShadowYOffset * 0.5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint(isHero ? "Large preview of current wallpaper with quick controls" : "Preview")
    }

    private var thumbnailView: some View {
        Group {
            if let ns = thumbnail {
                Image(nsImage: ns)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(DesignTokens.Colors.primary.opacity(isHero ? 0.12 : 0.08))
                    .overlay {
                        Image(systemName: isHero ? "photo.on.rectangle.angled" : "photo")
                            .font(.system(size: isHero ? 26 : 18, weight: .semibold))
                            .foregroundColor(DesignTokens.Colors.primary)
                    }
            }
        }
        .frame(width: isHero ? 220 : 64, height: isHero ? 120 : 64)
        .clipShape(RoundedRectangle(cornerRadius: isHero ? DesignTokens.Corner.heroRadius : 8, style: .continuous))
    }
}

#Preview("Wallpaper Preview Card") {
    WallpaperPreviewCard(title: "Main Display", subtitle: "No video selected", thumbnail: nil, trailingInfo: "Muted")
        .padding()
}
