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
        VStack(alignment: .leading, spacing: 16) {
            Text("Wallpaper Configuration")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                Text("Selected Video")
                    .font(.headline)

                Text(appModel.selectedVideoPath.isEmpty ? "None" : appModel.selectedVideoPath)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Renderer Mode")
                    .font(.headline)

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

                if appModel.rendererMode == .web {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Web Source URL")
                            .font(.subheadline)

                        HStack {
                            TextField("https://example.com/animated-background", text: Binding(
                                get: { appModel.webURLString },
                                set: { appModel.updateWebURL($0) }
                            ))
                            .textFieldStyle(.roundedBorder)

                            Button("Apply Web") {
                                Task { await appModel.applyWallpaperFromSelection() }
                            }
                            .disabled(appModel.webURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || appModel.isApplyingWallpaper)
                        }
                        Text("Enter a public HTTP(S) URL or a local file URL to render as wallpaper.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack(spacing: 12) {
                Button("Choose Video") {
                    isFileImporterPresented = true
                }

                Button("Apply Wallpaper") {
                    Task {
                        await appModel.applyWallpaperFromSelection()
                    }
                }
                .disabled(appModel.selectedVideoPath.isEmpty || appModel.isApplyingWallpaper || appModel.rendererMode == .web)
            }

            Divider()

            Toggle(
                "Mute Audio",
                isOn: Binding(
                    get: { appModel.isMuted },
                    set: { appModel.updateMuted($0) }
                )
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Scaling Mode")
                    .font(.headline)

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

            VStack(alignment: .leading, spacing: 8) {
                Text("Per-Display Sources")
                    .font(.headline)

                ForEach(Array(NSScreen.screens.enumerated()), id: \.element.displayID) { index, screen in
                    let displayIndex = index + 1
                    let id = screen.displayID
                    let displayName = screen.localizedName
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Display \(displayIndex): \(displayName)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            TextField("http://... or file:///...", text: Binding(
                                get: { appModel.perDisplaySource(for: id) },
                                set: { appModel.updatePerDisplaySource(id, $0) }
                            ))
                            .textFieldStyle(.roundedBorder)

                            Button("Browse") {
                                selectedDisplayForPicker = id
                                isFileImporterPresented = true
                            }
                        }
                    }
                    .padding(.bottom, 4)
                }
            }

            if appModel.isApplyingWallpaper {
                ProgressView("Applying wallpaper...")
            }

            if let message = appModel.statusMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.green)
            }

            if let error = appModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Spacer()
        }
        .padding(20)
        .frame(minWidth: 520, minHeight: 280)
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
}

#Preview {
    ContentView()
        .environmentObject(AppViewModel())
}
