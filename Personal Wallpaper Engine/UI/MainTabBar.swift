import SwiftUI

/// Labeled top tab bar (icon + text) with translucent glass styling on pills only.
struct MainTabBar: View {
    @Binding var selectedTab: TabbedMainView.MainTab
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.small) {
            ForEach(TabbedMainView.MainTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .glassChrome(.tabBarGroup)
    }

    @ViewBuilder
    private func tabButton(for tab: TabbedMainView.MainTab) -> some View {
        let isSelected = selectedTab == tab

        Button {
            selectedTab = tab
        } label: {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.subheadline.weight(.semibold))
                    .symbolVariant(isSelected ? .fill : .none)

                Text(tab.label)
                    .font(DesignTokens.Typography.subtitle)
                    .fontWeight(isSelected ? .semibold : .medium)
            }
            .foregroundStyle(isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .glassChrome(.pill(isSelected: isSelected))
            .contentShape(RoundedRectangle(cornerRadius: DesignTokens.Corner.tab, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .animation(DesignTokens.Motion.selectionAnimation(reduceMotion: reduceMotion), value: selectedTab)
    }
}

extension TabbedMainView.MainTab: CaseIterable {
    static var allCases: [TabbedMainView.MainTab] {
        [.home, .collections, .setups, .settings]
    }
}

#Preview {
    MainTabBarPreview()
        .frame(width: 900, height: 120)
}

private struct MainTabBarPreview: View {
    @State private var selectedTab: TabbedMainView.MainTab = .home

    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue, .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            MainTabBar(selectedTab: $selectedTab)
        }
    }
}
