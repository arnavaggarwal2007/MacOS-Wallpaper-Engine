import SwiftUI

struct TopUtilityBar: View {
    @EnvironmentObject private var appModel: AppViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 12) {
            // Play / Pause
            Button(action: {
                Task { await appModel.togglePlayback() }
            }) {
                Image(systemName: appModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .semibold))
            }
            .help(appModel.isPlaying ? "Pause wallpaper" : "Play wallpaper")
            .accessibilityLabel(appModel.isPlaying ? "Pause wallpaper" : "Play wallpaper")

            // Mute toggle
            Button(action: {
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
            Button(action: {
                Task { await appModel.applyWallpaperFromSelection() }
            }) {
                Label("Apply Now", systemImage: "bolt.fill")
            }
            .disabled(appModel.isApplyingWallpaper || appModel.usePerDisplay)
            .opacity((appModel.isApplyingWallpaper || appModel.usePerDisplay) ? 0.5 : 1.0)
            .help("Apply the current selection as wallpaper")

            Spacer()

            // Favorites (lightweight stub for now)
            Button(action: {
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
