import AppKit
import SwiftUI

/// Tab-based main shell: Home, Collections, Setups, Settings.
struct TabbedMainView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @State private var selectedTab: MainTab = .home
    @State private var pauseWallpaperPreview = false
    @State private var pauseHeroPreviewForPolicy = false
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

    private var isOnHomeTab: Bool {
        selectedTab == .home
    }

    private var backgroundIntensity: AppWallpaperBackground.Intensity {
        isOnHomeTab ? .hero : .management
    }

    private func mainTab(from shellTab: ShellTab) -> MainTab {
        switch shellTab {
        case .home: return .home
        case .collections: return .collections
        case .setups: return .setups
        case .settings: return .settings
        }
    }

    private func recomputeHeroPreviewPausePolicy() -> Bool {
        if appModel.performanceProfile == .maxQuality {
            return appModel.shouldPauseHeroPreview(isOnHomeTab: isOnHomeTab)
        }
        guard isOnHomeTab else { return true }
        return appModel.shouldPauseHeroPreview(isOnHomeTab: true)
    }

    var body: some View {
        ZStack(alignment: .top) {
            AppWallpaperBackground(
                intensity: backgroundIntensity,
                isGlobalDesktopPaused: appModel.shouldShowPausedChrome,
                pausePlayback: pauseWallpaperPreview
                    || appModel.shouldShowPausedChrome
                    || pauseHeroPreviewForPolicy
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

            if let suggestion = appModel.performanceSuggestion {
                VStack {
                    Spacer()
                    PerformanceSuggestionBanner(
                        suggestion: suggestion,
                        onApply: { appModel.applySuggestedPerformanceProfile() },
                        onDismiss: { appModel.dismissPerformanceSuggestion() },
                        onDismissPermanently: { appModel.dismissPerformanceSuggestion(permanently: true) }
                    )
                    .padding(.bottom, 56)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.25), value: appModel.performanceSuggestion)
            }
        }
        .onWallpaperPreviewPauseChange { pauseWallpaperPreview = $0 }
        .onAppear {
            appModel.setMainShellOnHomeTab(isOnHomeTab)
            pauseHeroPreviewForPolicy = recomputeHeroPreviewPausePolicy()
            appModel.scheduleShellHeroLayoutRecovery()
        }
        .onChange(of: selectedTab) { _, newTab in
            appModel.setMainShellOnHomeTab(newTab == .home)
            pauseHeroPreviewForPolicy = recomputeHeroPreviewPausePolicy()
        }
        .onChange(of: appModel.heroPreviewVisibilityRevision) { _, _ in
            pauseHeroPreviewForPolicy = recomputeHeroPreviewPausePolicy()
        }
        .onChange(of: appModel.performanceProfile) { oldProfile, newProfile in
            pauseHeroPreviewForPolicy = recomputeHeroPreviewPausePolicy()
            if !isOnHomeTab, oldProfile == .maxQuality, newProfile != .maxQuality {
                appModel.prepareManagementStaticHeroBackground()
            }
        }
        .onChange(of: appModel.shellNavigationRequest) { _, request in
            guard let request, let tab = request.tab else { return }
            selectedTab = mainTab(from: tab)
            appModel.clearShellNavigationRequest()
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    TabbedMainView()
        .environmentObject(AppViewModel())
}
