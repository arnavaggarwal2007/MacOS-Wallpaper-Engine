import SwiftUI

struct TopUtilityBar: View {
    @EnvironmentObject private var appModel: AppViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var buttonHovers: [String: Bool] = [:]
    @Binding var isSidebarVisible: Bool
    var onChooseWallpaper: () -> Void
    var onBrowseLibrary: (() -> Void)? = nil

    private func button(key: String, action: @escaping () -> Void, label: @escaping () -> some View) -> some View {
        Button(action: action) {
            label()
        }
        .scaleEffect(buttonHovers[key] ?? false && !reduceMotion ? 1.05 : 1.0)
        .opacity((buttonHovers[key] ?? false) ? 1.0 : 0.8)
        .animation(reduceMotion ? .none : .easeInOut(duration: DesignTokens.Motion.gentleDuration), value: buttonHovers[key] ?? false)
        .onHover { isHovered in buttonHovers[key] = isHovered }
    }

    private var pausedBannerText: String {
        if let policyMessage = appModel.powerPolicyStatusMessage, appModel.shouldShowPausedChrome {
            return policyMessage
        }
        return "Wallpapers paused on all displays — in-app preview may still animate."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                QuickModeSelector()

                button(key: "choose", action: onChooseWallpaper) {
                    Label("Choose Wallpaper", systemImage: "folder.badge.plus")
                        .font(.system(size: 13, weight: .semibold))
                }
                .help("Pick a video for the selected display (or multiple displays)")

                if let onBrowseLibrary {
                    button(key: "library", action: onBrowseLibrary) {
                        Label("Browse Library", systemImage: "square.grid.2x2")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .help("Open full library browser")
                }

                button(key: "play", action: {
                    appModel.handlePlayPauseButtonPressed(source: .toolbar)
                }) {
                    Image(systemName: appModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .animation(reduceMotion ? .none : .easeInOut(duration: DesignTokens.Motion.standardDuration), value: appModel.isPlaying)
                }
                .buttonStyle(.plain)
                .disabled(appModel.isPlaybackCommandInFlight)
                .help(appModel.isPlaying ? "Pause wallpapers on all displays" : "Play wallpapers on all displays")
                .accessibilityLabel(appModel.isPlaying ? "Pause wallpapers on all displays" : "Play wallpapers on all displays")

                button(key: "mute", action: {
                    Task { await appModel.toggleMute() }
                }) {
                    Image(systemName: appModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 14, weight: .regular))
                }
                .help(appModel.isMuted ? "Unmute audio" : "Mute audio")
                .accessibilityLabel(appModel.isMuted ? "Unmute audio" : "Mute audio")

                Menu {
                    ForEach(VideoScalingMode.allCases, id: \.self) { mode in
                        Button(action: { appModel.updateScalingMode(mode) }) {
                            Label(mode.displayName, systemImage: appModel.scalingMode == mode ? "checkmark" : "")
                        }
                    }
                } label: {
                    Label("Scaling", systemImage: "aspectratio")
                        .help("Set global scaling mode")
                }

                button(key: "apply", action: {
                    Task {
                        if appModel.selectedLibraryItemID != nil {
                            await appModel.applySelectedLibraryItemToFocusedDisplay()
                        } else {
                            await appModel.applyWallpaperToFocusedDisplay()
                        }
                    }
                }) {
                    Label("Apply Now", systemImage: "bolt.fill")
                }
                .disabled(appModel.isApplyingWallpaper)
                .opacity(appModel.isApplyingWallpaper ? 0.5 : 1.0)
                .help(
                    appModel.selectedLibraryItemID != nil
                        ? "Apply the selected library video to the focused display."
                        : "Apply the wallpaper assigned to the selected display"
                )

                button(key: "sidebar", action: {
                    withAnimation(DesignTokens.Motion.selectionAnimation(reduceMotion: reduceMotion)) {
                        isSidebarVisible.toggle()
                    }
                }) {
                    Image(systemName: isSidebarVisible ? "sidebar.trailing" : "sidebar.trailing")
                        .font(.system(size: 14, weight: .semibold))
                }
                .help(isSidebarVisible ? "Hide sidebar" : "Show sidebar")
                .accessibilityLabel(isSidebarVisible ? "Hide sidebar" : "Show sidebar")
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .fixedSize(horizontal: true, vertical: false)
            .glassChrome(.bar)

            if appModel.shouldShowPausedChrome {
                HStack(spacing: 8) {
                    Image(systemName: "pause.circle.fill")
                        .foregroundStyle(DesignTokens.Colors.primary)
                    Text(pausedBannerText)
                        .font(DesignTokens.Typography.subtitle)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: 420, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: DesignTokens.Corner.radius, style: .continuous)
                        .fill(DesignTokens.Colors.primary.opacity(0.08))
                        .overlay {
                            RoundedRectangle(cornerRadius: DesignTokens.Corner.radius, style: .continuous)
                                .stroke(DesignTokens.Colors.primary.opacity(0.2), lineWidth: 1)
                        }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Wallpapers paused. \(pausedBannerText)")
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(DesignTokens.Motion.selectionAnimation(reduceMotion: reduceMotion), value: appModel.shouldShowPausedChrome)
    }
}

#Preview("Top Utility Bar") {
    TopUtilityBar(isSidebarVisible: .constant(true), onChooseWallpaper: {})
        .environmentObject(AppViewModel())
        .padding()
}
