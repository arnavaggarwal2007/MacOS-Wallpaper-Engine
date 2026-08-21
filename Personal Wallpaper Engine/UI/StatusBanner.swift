import SwiftUI

/// Inline status, success, and error banner.
///
/// Replaces three near-identical private `statusBanner` helpers in `ModernHomeView`,
/// `SettingsTabView`, and `CollectionEditorView`. The two styles exist because the surfaces differ:
/// banners over the live wallpaper need their own tinted plate, while Settings sits on glass chrome
/// already.
struct StatusBanner: View {
    enum Style {
        /// Tinted rounded plate. For banners sitting directly on content.
        case tinted
        /// Inherits the surrounding glass chrome.
        case glass
    }

    let title: String
    var message: String?
    let systemImage: String
    var tint: Color = DesignTokens.Colors.primary
    var style: Style = .tinted

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundColor(tint)
                .font(.subheadline)

            if let message {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignTokens.Typography.subtitle)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    Text(message)
                        .font(DesignTokens.Typography.subtitle)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            } else {
                Text(title)
                    .font(DesignTokens.Typography.subtitle)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
            }

            Spacer()
        }
        .padding(12)
        .modifier(BannerBackground(style: style, tint: tint))
        // Read as one announcement rather than an icon and two stray strings.
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message.map { "\(title): \($0)" } ?? title)
    }

    private struct BannerBackground: ViewModifier {
        let style: Style
        let tint: Color

        func body(content: Content) -> some View {
            switch style {
            case .glass:
                content.glassChrome(.bar)
            case .tinted:
                content.background {
                    RoundedRectangle(cornerRadius: DesignTokens.Corner.radius, style: .continuous)
                        .fill(tint.opacity(0.10))
                        .overlay {
                            RoundedRectangle(cornerRadius: DesignTokens.Corner.radius, style: .continuous)
                                .stroke(tint.opacity(0.18), lineWidth: 1)
                        }
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        StatusBanner(title: "Applying wallpaper…", systemImage: "arrow.triangle.2.circlepath", tint: .blue)
        StatusBanner(title: "Wallpaper applied", systemImage: "checkmark.circle.fill", tint: .green)
        StatusBanner(
            title: "Name",
            message: "A collection with that name already exists.",
            systemImage: "exclamationmark.triangle.fill",
            tint: .red
        )
        StatusBanner(
            title: "Paused on battery",
            systemImage: "bolt.slash.fill",
            tint: .orange,
            style: .glass
        )
    }
    .padding()
    .frame(width: 420)
}
