import SwiftUI

struct TopUtilityBar: View {
    @EnvironmentObject private var appModel: AppViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var buttonHovers: [String: Bool] = [:]

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
            // Play / Pause
            button(key: "play", action: {
                Task { await appModel.togglePlayback() }
            }) {
                Image(systemName: appModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .semibold))
            }
            .help(appModel.isPlaying ? "Pause wallpaper" : "Play wallpaper")
            .accessibilityLabel(appModel.isPlaying ? "Pause wallpaper" : "Play wallpaper")

            // Mute toggle
            button(key: "mute", action: {
                Task { await appModel.toggleMute() }
            }) {
                Image(systemName: appModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 14, weight: .regular))
            }
            .help(appModel.isMuted ? "Unmute audio" : "Mute audio")
            .accessibilityLabel(appModel.isMuted ? "Unmute audio" : "Mute audio")

            // Scaling menu
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

            // Quick apply
            button(key: "apply", action: {
                Task { await appModel.applyWallpaperFromSelection() }
            }) {
                Label("Apply Now", systemImage: "bolt.fill")
            }
            .disabled(appModel.isApplyingWallpaper || appModel.usePerDisplay)
            .opacity((appModel.isApplyingWallpaper || appModel.usePerDisplay) ? 0.5 : 1.0)
            .help("Apply the current selection as wallpaper")

            Spacer()

            // Favorites (lightweight stub for now)
            button(key: "favorites", action: {
                appModel.statusMessage = "Added to favorites"
            }) {
                Image(systemName: "star")
            }
            .help("Add wallpaper to favorites")
            .accessibilityLabel("Add to favorites")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.Corner.radius, style: .continuous)
                .fill(DesignTokens.Colors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: DesignTokens.Corner.radius, style: .continuous)
                        .fill(.linearGradient(colors: [DesignTokens.Colors.cardHighlight, Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .opacity(DesignTokens.Effects.cardBackdropOpacity)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: DesignTokens.Corner.radius, style: .continuous)
                        .stroke(DesignTokens.Colors.cardBorder, lineWidth: 1)
                }
        }
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
        .animation(reduceMotion ? .none : .easeInOut(duration: DesignTokens.Motion.standardDuration), value: appModel.isPlaying)
    }
}

#Preview("Top Utility Bar") {
    TopUtilityBar()
        .environmentObject(AppViewModel())
        .padding()
}
