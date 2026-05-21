import SwiftUI

/// Compact glass section header for management tabs.
struct TabHeaderView: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.primary)
                .symbolRenderingMode(.hierarchical)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DesignTokens.Typography.heroTitle)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text(subtitle)
                    .font(DesignTokens.Typography.subtitle)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassChrome(.bar)
    }
}
