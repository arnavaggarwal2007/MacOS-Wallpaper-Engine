//
//  ContentView.swift
//  Personal Wallpaper Engine
//
//  Created by Arnav Aggarwal on 4/30/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @State private var isFileImporterPresented = false

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

            HStack(spacing: 12) {
                Button("Choose Video") {
                    isFileImporterPresented = true
                }

                Button("Apply Wallpaper") {
                    Task {
                        await appModel.applyWallpaperFromSelection()
                    }
                }
                .disabled(appModel.selectedVideoPath.isEmpty || appModel.isApplyingWallpaper)
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
                appModel.selectVideo(at: firstURL)
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
