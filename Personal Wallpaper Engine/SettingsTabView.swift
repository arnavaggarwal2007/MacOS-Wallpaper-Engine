import SwiftUI
import UniformTypeIdentifiers

/// Workspace, source, and system preferences (moved from Home sidebar).
struct SettingsTabView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @State private var isFileImporterPresented = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
                TabHeaderView(
                    title: "Settings",
                    subtitle: "Renderer, scaling, audio, and startup preferences.",
                    systemImage: "gearshape.fill"
                )

                GlassCardView(title: "Workspace") {
                    VStack(alignment: .leading, spacing: 16) {
                        settingRow(
                            title: "Renderer Mode",
                            caption: "Video uses local files; Web loads a URL in the desktop layer.",
                            icon: "display"
                        ) {
                            Picker(
                                "Renderer Mode",
                                selection: Binding(
                                    get: { appModel.rendererMode },
                                    set: { appModel.updateRendererMode($0) }
                                )
                            ) {
                                ForEach(WallpaperRendererMode.allCases, id: \.self) { mode in
                                    Text(mode.displayName).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        settingRow(
                            title: "Scaling Mode",
                            caption: "Default scaling for new assignments; per-display overrides apply on Home.",
                            icon: "aspectratio"
                        ) {
                            Picker(
                                "Scaling Mode",
                                selection: Binding(
                                    get: { appModel.scalingMode },
                                    set: { appModel.updateScalingMode($0) }
                                )
                            ) {
                                ForEach(VideoScalingMode.allCases, id: \.self) { mode in
                                    Text(mode.displayName).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        Toggle(
                            isOn: Binding(
                                get: { appModel.isMuted },
                                set: { appModel.updateMuted($0) }
                            )
                        ) {
                            VStack(alignment: .leading, spacing: 2) {
                                Label("Mute Audio", systemImage: appModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                    .font(DesignTokens.Typography.subtitle)
                                Text("Silences wallpaper playback in the app preview and engine.")
                                    .font(.caption)
                                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                            }
                        }
                    }
                }

                GlassCardView(title: "Wallpaper Source") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(appModel.selectedVideoPath.isEmpty ? "No video selected" : appModel.selectedVideoPath)
                            .font(DesignTokens.Typography.subtitle)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .lineLimit(3)

                        if appModel.rendererMode == .web {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Web Source URL", systemImage: "globe")
                                    .font(DesignTokens.Typography.subtitle)

                                TextField("https://example.com/animated-background", text: Binding(
                                    get: { appModel.webURLString },
                                    set: { appModel.updateWebURL($0) }
                                ))
                                .textFieldStyle(.roundedBorder)

                                HStack(spacing: 10) {
                                    Button(action: { isFileImporterPresented = true }) {
                                        Label("Choose File", systemImage: "folder.badge.plus")
                                    }

                                    Button(action: { Task { await appModel.applyWallpaperFromSelection() } }) {
                                        Label("Apply", systemImage: "checkmark.circle.fill")
                                    }
                                    .disabled(appModel.webURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || appModel.isApplyingWallpaper)
                                }
                            }
                        } else {
                            HStack(spacing: 10) {
                                Button(action: { isFileImporterPresented = true }) {
                                    Label("Choose Video", systemImage: "folder.badge.plus")
                                }

                                Button(action: { Task { await appModel.applyWallpaperFromSelection() } }) {
                                    Label("Apply to All Displays", systemImage: "checkmark.circle.fill")
                                }
                                .disabled(appModel.selectedVideoPath.isEmpty || appModel.isApplyingWallpaper)
                            }

                            Text("Assign per display on the Home tab, or apply this source to every connected display here.")
                                .font(.caption)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                    }
                }

                GlassCardView(title: "System") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(
                            isOn: Binding(
                                get: { appModel.isLaunchOnLoginEnabled },
                                set: { _ in Task { await appModel.toggleLaunchOnLogin() } }
                            )
                        ) {
                            VStack(alignment: .leading, spacing: 2) {
                                Label("Launch on Login", systemImage: "power")
                                    .font(DesignTokens.Typography.subtitle)
                                    .fontWeight(.medium)
                                Text("Automatically start when you log in (macOS 13.2+).")
                                    .font(.caption)
                                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                            }
                        }
                    }
                }

                statusBannersSection
            }
            .padding(DesignTokens.Spacing.large)
            .padding(.top, DesignTokens.Surfaces.mainTabBarReservedHeight + 8)
        }
        .frame(minWidth: 800, minHeight: 600)
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.movie, .mpeg4Movie, .quickTimeMovie],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                appModel.selectVideo(at: url)
                Task { await appModel.applyWallpaperFromSelection() }
            case .failure(let error):
                appModel.errorMessage = "File selection failed: \(error.localizedDescription)"
            }
        }
    }

    @ViewBuilder
    private func settingRow<Content: View>(
        title: String,
        caption: String,
        icon: String,
        @ViewBuilder control: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(DesignTokens.Typography.subtitle)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            Text(caption)
                .font(.caption)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
            control()
        }
    }

    @ViewBuilder
    private var statusBannersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if appModel.isApplyingWallpaper {
                statusBanner(title: "Applying wallpaper...", systemImage: "arrow.triangle.2.circlepath", tint: .blue)
            }
            if let message = appModel.statusMessage {
                statusBanner(title: message, systemImage: "checkmark.circle.fill", tint: .green)
            }
            if let error = appModel.errorMessage {
                statusBanner(title: error, systemImage: "exclamationmark.circle.fill", tint: .red)
            }
            if let message = appModel.launchOnLoginStatusMessage {
                statusBanner(title: message, systemImage: "checkmark.circle.fill", tint: .green)
            }
            if let error = appModel.launchOnLoginErrorMessage {
                statusBanner(title: error, systemImage: "exclamationmark.circle.fill", tint: .red)
            }
        }
    }

    private func statusBanner(title: String, systemImage: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundColor(tint)
            Text(title)
                .font(DesignTokens.Typography.subtitle)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            Spacer()
        }
        .padding(12)
        .glassChrome(.bar)
    }
}

#Preview {
    SettingsTabView()
        .environmentObject(AppViewModel())
}
