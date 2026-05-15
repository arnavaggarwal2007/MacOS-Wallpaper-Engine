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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

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
            HStack(alignment: .top, spacing: 10) {
                Button(action: { onDelete() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.red.opacity(0.08)))
                        .overlay(Circle().stroke(Color.red.opacity(0.18), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .accessibilityLabel("Remove source")

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        TextField("Source URL", text: $url)
                            .textFieldStyle(.roundedBorder)

                        Button(action: onBrowse) {
                            Label("Browse", systemImage: "folder")
                                .labelStyle(.titleAndIcon)
                        }
                        .buttonStyle(.bordered)
                        .contentShape(Rectangle())
                        .accessibilityLabel("Browse for source")
                    }

                    if url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Enter a file path or URL, or use Browse to capture a bookmark automatically.")
                            .font(DesignTokens.Typography.subtitle)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
            }
            
            // Bookmark status hint
            if !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if let captureError = captureError {
                    recoveryStatus(title: "Bookmark error", message: captureError, color: .orange)
                } else if bookmark == nil {
                    recoveryStatus(title: "Bookmark missing", message: "File access may not persist across restarts. Re-browse the file to refresh the bookmark.", color: .secondary)
                } else {
                    recoveryStatus(title: "Bookmark captured", message: "Persistent access is available for this source.", color: .green)
                }
            }
            if isDisplayBound {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Display Mapping")
                        .font(DesignTokens.Typography.subtitle)
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

                    Text("Leave display mapping on Auto-detect unless you need a specific monitor; scaling falls back to the collection default when unset.")
                        .font(DesignTokens.Typography.subtitle)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            } else {
                HStack(spacing: 8) {
                    Text("Simple Source")
                        .font(DesignTokens.Typography.subtitle)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                }
            }
        }
        .padding(DesignTokens.Spacing.medium)
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
        .shadow(color: DesignTokens.Colors.primary.opacity(isHovered ? DesignTokens.Motion.hoverShadowOpacity : 0.0), radius: isHovered ? 4 : 0, x: 0, y: isHovered ? 2 : 0)
        .animation(reduceMotion ? .linear(duration: 0) : .easeInOut(duration: DesignTokens.Motion.gentleDuration), value: isHovered)
        .onHover { isHovered = $0 }
    }

    private func recoveryStatus(title: String, message: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(color)
                .font(.caption)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignTokens.Typography.subtitle)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                Text(message)
                    .font(DesignTokens.Typography.subtitle)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }

            Spacer()
        }
        .padding(10)
        .background(color.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
