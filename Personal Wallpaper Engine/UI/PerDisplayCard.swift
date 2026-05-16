import SwiftUI
import AppKit

struct PerDisplayCard: View {
    var displayName: String
    var displayIndex: Int
    var thumbnail: NSImage?
    var sourceSummary: String? = nil
    var scalingName: String
    var warningText: String?
    var canApply: Bool = true
    var onBrowse: (() -> Void)? = nil
    var onApply: (() -> Void)?
    var onPreview: (() -> Void)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            HStack(spacing: DesignTokens.Spacing.medium) {
                if let ns = thumbnail {
                    Image(nsImage: ns)
                        .resizable()
                        .interpolation(.high)
                        .antialiased(true)
                        .scaledToFit()
                        .frame(width: 96, height: 60)
                        .padding(4)
                        .background(DesignTokens.Colors.background.opacity(0.42))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    Rectangle()
                        .fill(DesignTokens.Colors.primary.opacity(0.12))
                        .frame(width: 96, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                    if let sourceSummary {
                        Text(sourceSummary)
                            .font(.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .lineLimit(1)
                    }
                    Text(scalingName)
                        .font(DesignTokens.Typography.subtitle)
                        .foregroundColor(DesignTokens.Colors.primary)
                }

                Spacer()

                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Button(action: { onBrowse?() }) {
                            Label("Browse", systemImage: "folder.badge.plus")
                        }
                        .buttonStyle(.bordered)

                        Button(action: { onPreview?() }) {
                            Label("Open", systemImage: "eye")
                        }
                        .buttonStyle(.bordered)
                        .disabled(onPreview == nil)
                    }

                    Button(action: { onApply?() }) {
                        Label("Apply", systemImage: "arrow.down.doc")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canApply || onApply == nil)
                }
            }

            if let warning = warningText {
                Text(warning)
                    .font(DesignTokens.Typography.subtitle)
                    .foregroundColor(.yellow)
            }
        }
        .padding(DesignTokens.Spacing.large)
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
        .shadow(color: Color.black.opacity(isHovered ? DesignTokens.Motion.hoverShadowOpacity : 0.05), radius: isHovered ? DesignTokens.Elevation.cardShadowRadius : 4, x: 0, y: isHovered ? DesignTokens.Elevation.cardShadowYOffset : 2)
        .scaleEffect(isHovered && !reduceMotion ? DesignTokens.Motion.hoverScale : 1)
        .animation(reduceMotion ? .linear(duration: 0) : .easeInOut(duration: DesignTokens.Motion.standardDuration), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

#Preview("PerDisplayCard") {
    PerDisplayCard(displayName: "Built-in Retina", displayIndex: 1, thumbnail: nil, scalingName: "Fill", warningText: nil)
        .padding()
}
