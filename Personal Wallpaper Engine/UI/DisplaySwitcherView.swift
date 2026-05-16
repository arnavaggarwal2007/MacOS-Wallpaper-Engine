import SwiftUI
import AppKit

struct DisplaySwitcherView: View {
    let selectedDisplayID: Binding<CGDirectDisplayID?>
    let displays: [DisplayCard]
    let onSelect: (CGDirectDisplayID) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Displays")
                        .font(DesignTokens.Typography.title)
                        .foregroundColor(DesignTokens.Colors.textPrimary)

                    Text("Switch the hero preview to any connected screen.")
                        .font(DesignTokens.Typography.subtitle)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }

                Spacer()

                Text("\(displays.count)")
                    .font(DesignTokens.Typography.subtitle)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(DesignTokens.Colors.primary.opacity(0.10))
                    .clipShape(Capsule(style: .continuous))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(displays) { display in
                        button(for: display)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
            .frame(height: 174)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(DesignTokens.Colors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.linearGradient(colors: [DesignTokens.Colors.cardHighlight, Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .opacity(DesignTokens.Effects.cardBackdropOpacity)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(DesignTokens.Colors.cardBorder, lineWidth: 1)
                }
        }
    }

    private func button(for display: DisplayCard) -> some View {
        Button(action: {
            selectedDisplayID.wrappedValue = display.displayID
            onSelect(display.displayID)
        }) {
            VStack(alignment: .leading, spacing: 10) {
                preview(for: display)

                VStack(alignment: .leading, spacing: 4) {
                    Text(display.title)
                        .font(DesignTokens.Typography.subtitle)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignTokens.Colors.textPrimary)

                    Text(display.badge)
                        .font(.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)

                    Text(display.scaling)
                        .font(.caption)
                        .foregroundColor(DesignTokens.Colors.primary)
                }
            }
            .padding(12)
            .frame(width: 238, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(display.isActive ? DesignTokens.Colors.background.opacity(0.92) : DesignTokens.Colors.background.opacity(0.72))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(display.isActive ? DesignTokens.Colors.primary.opacity(0.55) : DesignTokens.Colors.cardBorder, lineWidth: display.isActive ? 2 : 1)
            }
            .shadow(color: Color.black.opacity(display.isActive ? 0.14 : 0.06), radius: display.isActive ? 18 : 10, x: 0, y: 8)
            .scaleEffect(display.isActive && !reduceMotion ? 1.01 : 1)
            .animation(reduceMotion ? .linear(duration: 0) : .easeInOut(duration: DesignTokens.Motion.standardDuration), value: display.isActive)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(display.title)
        .accessibilityHint("Switch hero preview to \(display.badge)")
    }

    @ViewBuilder
    private func preview(for display: DisplayCard) -> some View {
        ZStack {
            if let image = display.previewImage {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFit()
                    .padding(6)
                    .background(DesignTokens.Colors.background.opacity(0.34))
            } else {
                LinearGradient(
                    colors: [
                        DesignTokens.Colors.primary.opacity(0.50),
                        DesignTokens.Colors.cardBackground,
                        Color.black.opacity(0.60)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Image(systemName: "display.2")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.white.opacity(0.78))
            }

            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.26)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack {
                HStack {
                    Spacer()
                    Text(display.resolution)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.86))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.25))
                        .clipShape(Capsule(style: .continuous))
                }
                Spacer()
            }
            .padding(10)
        }
        .frame(height: 104)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(display.isActive ? 0.30 : 0.12), lineWidth: 1)
        }
    }
}