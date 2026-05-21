import SwiftUI

struct TopUtilityBar: View {
    @EnvironmentObject private var appModel: AppViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var buttonHovers: [String: Bool] = [:]
    @Binding var isSidebarVisible: Bool
    var onChooseWallpaper: () -> Void

    private func button(key: String, action: @escaping () -> Void, label: @escaping () -> some View) -> some View {
        Button(action: action) {
            label()
        }
        .scaleEffect(buttonHovers[key] ?? false && !reduceMotion ? 1.05 : 1.0)
        .opacity((buttonHovers[key] ?? false) ? 1.0 : 0.8)
        .animation(reduceMotion ? .none : .easeInOut(duration: DesignTokens.Motion.gentleDuration), value: buttonHovers[key] ?? false)
        .onHover { isHovered in buttonHovers[key] = isHovered }
    }

    var body: some View {
        HStack(spacing: 12) {
            button(key: "choose", action: onChooseWallpaper) {
                Label("Choose Wallpaper", systemImage: "folder.badge.plus")
                    .font(.system(size: 13, weight: .semibold))
            }
            .help("Pick a video for the selected display (or multiple displays)")

            button(key: "play", action: {
                Task { await appModel.togglePlayback() }
            }) {
                Image(systemName: appModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .semibold))
            }
            .help(appModel.isPlaying ? "Pause wallpaper" : "Play wallpaper")
            .accessibilityLabel(appModel.isPlaying ? "Pause wallpaper" : "Play wallpaper")

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
                Task { await appModel.applyWallpaperToFocusedDisplay() }
            }) {
                Label("Apply Now", systemImage: "bolt.fill")
            }
            .disabled(appModel.isApplyingWallpaper)
            .opacity(appModel.isApplyingWallpaper ? 0.5 : 1.0)
            .help("Apply the wallpaper assigned to the selected display")

            button(key: "sidebar", action: {
                withAnimation(DesignTokens.Motion.selectionAnimation(reduceMotion: reduceMotion)) {
                    isSidebarVisible.toggle()
                }
            }) {
                Image(systemName: isSidebarVisible ? "sidebar.trailing" : "sidebar.trailing.badge.up")
                    .font(.system(size: 14, weight: .semibold))
            }
            .help(isSidebarVisible ? "Hide sidebar" : "Show sidebar")
            .accessibilityLabel(isSidebarVisible ? "Hide sidebar" : "Show sidebar")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .fixedSize(horizontal: true, vertical: false)
        .glassChrome(.bar)
        .animation(reduceMotion ? .none : .easeInOut(duration: DesignTokens.Motion.standardDuration), value: appModel.isPlaying)
    }
}

#Preview("Top Utility Bar") {
    TopUtilityBar(isSidebarVisible: .constant(true), onChooseWallpaper: {})
        .environmentObject(AppViewModel())
        .padding()
}
