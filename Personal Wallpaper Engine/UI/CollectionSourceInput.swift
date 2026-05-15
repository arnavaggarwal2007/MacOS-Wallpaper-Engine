import SwiftUI
import AppKit

/// Reusable component for editing a single collection source.
/// Used both in the editor panel and preview sections.
struct CollectionSourceInput: View {
    private static let autoDisplayToken = "__AUTO_DISPLAY__"

    let isDisplayBound: Bool
    let onDelete: () -> Void
    let onBrowse: () -> Void
    @Binding var url: String
    @Binding var displayLabel: String?
    @Binding var displayIDFallback: Int?
    @Binding var scalingMode: String?
    @Binding var bookmark: Data?
    @Binding var captureError: String?

    private var displayOptions: [String] {
        let names = NSScreen.screens.map { $0.localizedName }
        return Array(Set(names)).sorted()
    }

    private var selectedDisplay: Binding<String> {
        Binding(
            get: { displayLabel ?? Self.autoDisplayToken },
            set: { newValue in
                if newValue == Self.autoDisplayToken {
                    displayLabel = nil
                    displayIDFallback = nil
                    return
                }

                displayLabel = newValue
                let matchedScreen = NSScreen.screens.first { $0.localizedName == newValue }
                displayIDFallback = matchedScreen.map { Int($0.displayID) }
            }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Button(action: { onDelete() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .frame(width: 32, height: 32)
                        .background(
                            Capsule()
                                .stroke(Color.red.opacity(0.2), lineWidth: 1)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.red.opacity(0.2), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                TextField("Source URL", text: $url)
                    .textFieldStyle(.roundedBorder)

                Button(action: onBrowse) {
                    Label("Browse", systemImage: "folder")
                        .labelStyle(.titleAndIcon)
                }
            }
            
            // Bookmark status hint
            if !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if let captureError = captureError {
                    Text("Bookmark error: \(captureError)")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else if bookmark == nil {
                    Text("No bookmark captured — file access may not persist across restarts.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Bookmark captured — persistent access available.")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            if isDisplayBound {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Display Mapping")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 2)

                    HStack(spacing: 16) {
                        Picker("Display", selection: selectedDisplay) {
                            Text("Auto-detect").tag(Self.autoDisplayToken)
                            ForEach(displayOptions, id: \.self) { name in
                                Text(name).tag(name)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("Scaling", selection: $scalingMode) {
                            Text("Global Default").tag(nil as String?)
                            ForEach(VideoScalingMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(Optional(mode.rawValue))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            } else {
                HStack(spacing: 8) {
                    Text("Simple Source")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                }
            }

            if url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Enter a file path or URL")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview("Display-Bound Source") {
    CollectionSourceInput(
        isDisplayBound: true,
        onDelete: { print("Delete called") },
        onBrowse: { print("Browse called") },
        url: .constant("file:///Users/arnav/Videos/sample.mp4"),
        displayLabel: .constant("LG 4K"),
        displayIDFallback: .constant(nil),
        scalingMode: .constant("resizeAspectFill"),
        bookmark: .constant(nil),
        captureError: .constant(nil)
    )
    .frame(minHeight: 120)
}

#Preview("Simple Source") {
    CollectionSourceInput(
        isDisplayBound: false,
        onDelete: { print("Delete called") },
        onBrowse: { print("Browse called") },
        url: .constant("/path/to/video.mp4"),
        displayLabel: .constant(nil),
        displayIDFallback: .constant(nil),
        scalingMode: .constant(nil),
        bookmark: .constant(nil),
        captureError: .constant(nil)
    )
    .frame(minHeight: 70)
}
