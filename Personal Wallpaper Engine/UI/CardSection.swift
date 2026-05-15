import SwiftUI

struct CardSection<Content: View>: View {
    let header: String?
    let content: Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(header: String? = nil, @ViewBuilder content: () -> Content) {
        self.header = header
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            if let header = header {
                Text(header)
                    .font(DesignTokens.Typography.title)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
            }
            content
        }
        .padding(.vertical, DesignTokens.Spacing.medium)
        .animation(reduceMotion ? .linear(duration: 0) : .easeInOut(duration: DesignTokens.Motion.gentleDuration), value: header)
        .accessibilityElement(children: .contain)
    }
}

#Preview("Card Section") {
    CardSection(header: "Section Header") {
        Text("Section content")
    }
    .padding()
}
