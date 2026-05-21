import SwiftUI

/// Tab-based main shell: Home, Collections, Setups, Settings.
struct TabbedMainView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @State private var selectedTab: MainTab = .home
    @State private var pauseWallpaperPreview = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum MainTab: Hashable {
        case home
        case collections
        case setups
        case settings

        var label: String {
            switch self {
            case .home: return "Home"
            case .collections: return "Collections"
            case .setups: return "Setups"
            case .settings: return "Settings"
            }
        }

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .collections: return "square.stack.3d.up.fill"
            case .setups: return "square.and.arrow.down.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    private var backgroundIntensity: AppWallpaperBackground.Intensity {
        selectedTab == .home ? .hero : .management
    }

    var body: some View {
        ZStack(alignment: .top) {
            AppWallpaperBackground(
                intensity: backgroundIntensity,
                pausePlayback: pauseWallpaperPreview
            )

            Group {
                switch selectedTab {
                case .home:
                    ModernHomeView()
                case .collections:
                    CollectionsTabView()
                case .setups:
                    SetupsTabView()
                case .settings:
                    SettingsTabView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(DesignTokens.Motion.selectionAnimation(reduceMotion: reduceMotion), value: selectedTab)

            MainTabBar(selectedTab: $selectedTab)
                .padding(.top, 10)
                .padding(.horizontal, DesignTokens.Spacing.medium)
        }
        .onWallpaperPreviewPauseChange { pauseWallpaperPreview = $0 }
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    TabbedMainView()
        .environmentObject(AppViewModel())
}
