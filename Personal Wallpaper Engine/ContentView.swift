//
//  ContentView.swift
//  Personal Wallpaper Engine
//
//  Created by Arnav Aggarwal on 4/30/26.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @State private var isFileImporterPresented = false
    @State private var selectedDisplayForPicker: CGDirectDisplayID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Wallpaper Configuration")
                        .font(.system(.title2, design: .default))
                        .fontWeight(.bold)
                    Text("Configure wallpaper sources and display settings")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // MARK: - Preview Section
                previewSection

                // MARK: - Global Settings Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Global Settings")
                        .font(.headline)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: 10) {
                        // Renderer Mode
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Renderer Mode", systemImage: "waveform.circle")
                                .font(.subheadline)
                                .fontWeight(.medium)

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

                        Divider()

                        // Scaling Mode
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Scaling Mode", systemImage: "aspectratio")
                                .font(.subheadline)
                                .fontWeight(.medium)

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

                        Divider()

                        // Audio Controls
                        Toggle(
                            isOn: Binding(
                                get: { appModel.isMuted },
                                set: { appModel.updateMuted($0) }
                            )
                        ) {
                            Label("Mute Audio", systemImage: appModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(12)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)
                }

                // MARK: - Video Source Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Main Wallpaper Source")
                        .font(.headline)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(appModel.selectedVideoPath.isEmpty ? "No video selected" : appModel.selectedVideoPath)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .padding(12)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)

                    if appModel.rendererMode == .web {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Web Source URL", systemImage: "globe")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            HStack {
                                TextField("https://example.com/animated-background", text: Binding(
                                    get: { appModel.webURLString },
                                    set: { appModel.updateWebURL($0) }
                                ))
                                .textFieldStyle(.roundedBorder)

                                Button(action: {
                                    Task { await appModel.applyWallpaperFromSelection() }
                                }) {
                                    Label("Apply", systemImage: "checkmark.circle.fill")
                                        .labelStyle(.titleAndIcon)
                                }
                                .disabled(appModel.webURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || appModel.isApplyingWallpaper)
                            }
                            Text("Enter a public HTTP(S) URL to render as animated wallpaper.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(8)
                    } else {
                        HStack(spacing: 12) {
                            Button(action: { isFileImporterPresented = true }) {
                                Label("Choose Video", systemImage: "folder.badge.plus")
                            }

                            Button(action: { Task { await appModel.applyWallpaperFromSelection() } }) {
                                Label("Apply", systemImage: "checkmark.circle.fill")
                            }
                            .disabled(appModel.selectedVideoPath.isEmpty || appModel.isApplyingWallpaper)
                        }
                    }
                }

                // MARK: - Per-Display Settings
                if NSScreen.screens.count > 1 {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Per-Display Settings")
                            .font(.headline)
                            .fontWeight(.semibold)

                        ForEach(Array(NSScreen.screens.enumerated()), id: \.element.displayID) { index, screen in
                            let displayIndex = index + 1
                            let id = screen.displayID
                            let displayName = screen.localizedName

                            VStack(alignment: .leading, spacing: 10) {
                                Label("Display \(displayIndex): \(displayName)", systemImage: "display")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.blue)

                                // URL/Source Input
                                HStack {
                                    TextField("http://... or file:///...", text: Binding(
                                        get: { appModel.perDisplaySource(for: id) },
                                        set: { appModel.updatePerDisplaySource(id, $0) }
                                    ))
                                    .textFieldStyle(.roundedBorder)

                                    Button(action: {
                                        selectedDisplayForPicker = id
                                        isFileImporterPresented = true
                                    }) {
                                        Label("Browse", systemImage: "folder")
                                            .labelStyle(.titleAndIcon)
                                    }
                                }

                                // Per-Display Scaling Mode
                                VStack(alignment: .leading, spacing: 6) {
                                    Label("Scaling", systemImage: "aspectratio.fill")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.secondary)

                                    Picker(
                                        "Scaling",
                                        selection: Binding(
                                            get: { appModel.perDisplayScalingMode(for: id) },
                                            set: { appModel.updatePerDisplayScalingMode(id, $0) }
                                        )
                                    ) {
                                        ForEach(VideoScalingMode.allCases, id: \.self) { mode in
                                            Text(mode.displayName).tag(mode)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    .font(.caption)
                                }
                            }
                            .padding(12)
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(8)
                        }
                    }
                }

                // MARK: - System Settings Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("System Settings")
                        .font(.headline)
                        .fontWeight(.semibold)

                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(
                            isOn: Binding(
                                get: { appModel.isLaunchOnLoginEnabled },
                                set: { _ in
                                    Task { await appModel.toggleLaunchOnLogin() }
                                }
                            )
                        ) {
                            Label("Launch on Login", systemImage: "power")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }

                        Text("Automatically start the wallpaper engine when you log in (requires macOS 13.2+)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)
                }

                // MARK: - Status Messages
                if appModel.isApplyingWallpaper {
                    HStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.8, anchor: .center)
                        Text("Applying wallpaper...")
                            .font(.footnote)
                    }
                    .padding(12)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }

                if let message = appModel.statusMessage {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(message)
                            .font(.footnote)
                    }
                    .padding(12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }

                if let error = appModel.errorMessage {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.footnote)
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }

                if let message = appModel.launchOnLoginStatusMessage {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(message)
                            .font(.footnote)
                    }
                    .padding(12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }

                if let error = appModel.launchOnLoginErrorMessage {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.footnote)
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(20)
        }
        .frame(minWidth: 580, minHeight: 380)
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.movie, .mpeg4Movie, .quickTimeMovie],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let firstURL = urls.first else { return }

                // If a display was selected for per-display picker, use that
                if let displayID = selectedDisplayForPicker {
                    appModel.updatePerDisplaySource(displayID, firstURL.absoluteString)
                    selectedDisplayForPicker = nil
                } else {
                    // Otherwise, use the main video picker
                    appModel.selectVideo(at: firstURL)
                }
            case .failure(let error):
                appModel.errorMessage = "File selection failed: \(error.localizedDescription)"
                appModel.statusMessage = nil
            }
        }
    }

    // MARK: - Preview Section
    @ViewBuilder
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Wallpaper Preview")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                // Main wallpaper info
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Main Display", systemImage: "display")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        if appModel.rendererMode == .web {
                            Text(appModel.webURLString.isEmpty ? "No URL set" : appModel.webURLString)
                                .font(.callout)
                                .lineLimit(1)
                        } else {
                            Text(appModel.selectedVideoPath.isEmpty ? "No video selected" : URL(fileURLWithPath: appModel.selectedVideoPath).lastPathComponent)
                                .font(.callout)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Label(appModel.scalingMode.displayName, systemImage: "aspectratio.fill")
                            .font(.caption)
                            .fontWeight(.medium)
                        Label(appModel.isMuted ? "Muted" : "Audio On", systemImage: appModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.caption)
                    }
                    .foregroundStyle(.blue)
                }
                .padding(12)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)

                // Per-display preview if multi-display
                if NSScreen.screens.count > 1 {
                    ForEach(Array(NSScreen.screens.enumerated()), id: \.element.displayID) { index, screen in
                        let displayIndex = index + 1
                        let id = screen.displayID
                        let source = appModel.perDisplaySource(for: id)
                        let scaling = appModel.perDisplayScalingMode(for: id)

                        if !source.isEmpty {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Label("Display \(displayIndex)", systemImage: "display.2")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.secondary)

                                    Text(URL(string: source)?.lastPathComponent ?? source)
                                        .font(.callout)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Label(scaling.displayName, systemImage: "aspectratio.fill")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.blue)
                            }
                            .padding(10)
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.windowBackgroundColor).opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(AppViewModel())
}
