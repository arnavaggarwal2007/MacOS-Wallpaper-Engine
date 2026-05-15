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
            }

            // Mute toggle
            Button(action: {
                Task { await appModel.toggleMute() }
            }) {
                Image(systemName: appModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
            }

            // Scaling menu
            Menu {
                ForEach(VideoScalingMode.allCases, id: \.self) { mode in
                    Button(action: { appModel.updateScalingMode(mode) }) {
                        Label(mode.displayName, systemImage: appModel.scalingMode == mode ? "checkmark" : "")
                    }
                }
            } label: {
                Label("Scaling", systemImage: "aspectratio")
            }

            // Quick apply
            Button(action: {
                Task { await appModel.applyWallpaperFromSelection() }
            }) {
                Label("Apply Now", systemImage: "bolt.fill")
            }
            .disabled(appModel.isApplyingWallpaper || appModel.usePerDisplay)

            Spacer()

            // Favorites (lightweight stub for now)
            Button(action: {
                appModel.statusMessage = "Added to favorites"
            }) {
                Image(systemName: "star")
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(DesignTokens.Colors.cardBackground.opacity(0.95))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
        .animation(reduceMotion ? .none : .easeInOut(duration: DesignTokens.Motion.standardDuration), value: appModel.isPlaying)
    }
}

#Preview("Top Utility Bar") {
    TopUtilityBar()
        .environmentObject(AppViewModel())
        .padding()
}
