import SwiftUI
import AppKit

struct PerDisplayCard: View {
    var displayName: String
    var displayIndex: Int
    var thumbnail: NSImage?
    var scalingName: String
    var warningText: String?
    var onApply: (() -> Void)?
    var onPreview: (() -> Void)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                if let ns = thumbnail {
                    Image(nsImage: ns)
                        .resizable()
                        .frame(width: 72, height: 72)
                        .cornerRadius(8)
                } else {
                    Rectangle()
                        .fill(DesignTokens.Colors.primary.opacity(0.12))
                        .frame(width: 72, height: 72)
                        .cornerRadius(8)
                        .overlay(
                            Text(String(displayName.prefix(1)))
                                .font(DesignTokens.Typography.title)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName)
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    Text("Display \(displayIndex)")
                        .font(DesignTokens.Typography.subtitle)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    Text(scalingName)
                        .font(DesignTokens.Typography.subtitle)
                        .foregroundColor(DesignTokens.Colors.primary)
                }

                Spacer()

                VStack(spacing: 8) {
                    Button(action: { onApply?() }) {
                        Label("Apply", systemImage: "arrow.down.doc")
                    }
                    .buttonStyle(.borderedProminent)

                    Button(action: { onPreview?() }) {
                        Label("Preview", systemImage: "play.circle")
                    }
                    .buttonStyle(.bordered)
                    .disabled(onPreview == nil)
                }
            }

            if let warning = warningText {
                Text(warning)
                    .font(DesignTokens.Typography.subtitle)
                    .foregroundColor(.yellow)
            }
        }
        .padding(DesignTokens.Spacing.medium)
        .background(DesignTokens.Colors.cardBackground)
        .cornerRadius(DesignTokens.Corner.radius)
        .shadow(color: DesignTokens.Colors.primary.opacity(isHovered ? DesignTokens.Motion.hoverShadowOpacity : 0.06), radius: isHovered ? 8 : 6, x: 0, y: isHovered ? 3 : 2)
        .scaleEffect(isHovered && !reduceMotion ? DesignTokens.Motion.hoverScale : 1)
        .animation(reduceMotion ? .linear(duration: 0) : .easeInOut(duration: DesignTokens.Motion.standardDuration), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

#Preview("PerDisplayCard") {
    PerDisplayCard(displayName: "Built-in Retina", displayIndex: 1, thumbnail: nil, scalingName: "Fill", warningText: nil)
        .padding()
}
