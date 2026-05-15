import SwiftUI

struct CardView<Content: View>: View {
    enum Style {
        case standard
        case elevated
        case hero

        var cornerRadius: CGFloat {
            switch self {
            case .standard:
                return DesignTokens.Corner.radius
            case .elevated:
                return DesignTokens.Elevation.cardRadius
            case .hero:
                return DesignTokens.Corner.heroRadius
            }
        }

        var shadowRadius: CGFloat {
            switch self {
            case .standard:
                return 8
            case .elevated:
                return DesignTokens.Elevation.cardShadowRadius
            case .hero:
                return DesignTokens.Elevation.heroShadowRadius
            }
        }

        var shadowYOffset: CGFloat {
            switch self {
            case .standard:
                return 2
            case .elevated:
                return DesignTokens.Elevation.cardShadowYOffset
            case .hero:
                return DesignTokens.Elevation.heroShadowYOffset
            }
        }
    }

    let title: String?
    let style: Style
    let content: Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    init(title: String? = nil, style: Style = .standard, @ViewBuilder content: () -> Content) {
        self.title = title
        self.style = style
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            if let title = title {
                Text(title)
                    .font(style == .hero ? DesignTokens.Typography.heroTitle : DesignTokens.Typography.title)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
            }
            content
        }
        .padding(style == .hero ? DesignTokens.Spacing.large : DesignTokens.Spacing.medium)
        .background {
            RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                .fill(DesignTokens.Colors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                        .fill(.linearGradient(colors: [DesignTokens.Colors.cardHighlight, Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .blendMode(.screen)
                        .opacity(style == .hero ? 1 : DesignTokens.Effects.cardBackdropOpacity)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                        .stroke(DesignTokens.Colors.cardBorder, lineWidth: 1)
                }
        }
        .shadow(color: Color.black.opacity(isHovered ? DesignTokens.Motion.hoverShadowOpacity : 0.05), radius: isHovered ? style.shadowRadius : 1, x: 0, y: isHovered ? style.shadowYOffset : 1)
        .scaleEffect(isHovered && !reduceMotion ? DesignTokens.Motion.hoverScale : 1)
        .animation(reduceMotion ? .linear(duration: 0) : .easeInOut(duration: DesignTokens.Motion.standardDuration), value: isHovered)
        .onHover { isHovered = $0 }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title ?? "Card")
    }
}

#Preview("Card") {
    CardView(title: "Placeholder Card") {
        Text("This is a placeholder card body.")
            .font(DesignTokens.Typography.body)
            .foregroundColor(DesignTokens.Colors.textSecondary)
    }
    .padding()
}
