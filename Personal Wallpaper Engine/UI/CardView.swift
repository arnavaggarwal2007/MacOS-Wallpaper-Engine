import SwiftUI

struct CardView<Content: View>: View {
    let title: String?
    let content: Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            if let title = title {
                Text(title)
                    .font(DesignTokens.Typography.title)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
            }
            content
        }
        .padding(DesignTokens.Spacing.medium)
        .background(DesignTokens.Colors.cardBackground)
        .cornerRadius(DesignTokens.Corner.radius)
        .shadow(color: DesignTokens.Colors.primary.opacity(isHovered ? DesignTokens.Motion.hoverShadowOpacity : 0.04), radius: isHovered ? 6 : 1, x: 0, y: isHovered ? 3 : 1)
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
