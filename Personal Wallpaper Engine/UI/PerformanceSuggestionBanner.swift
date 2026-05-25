import SwiftUI

struct PerformanceSuggestion: Equatable {
    let message: String
    let suggestedProfile: PerformanceProfile
}

/// Non-modal banner when sustained CPU exceeds profile thresholds (Phase 7C).
struct PerformanceSuggestionBanner: View {
    let suggestion: PerformanceSuggestion
    let onApply: () -> Void
    let onDismiss: () -> Void
    let onDismissPermanently: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "gauge.with.dots.needle.67percent")
                .font(.title3)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("High CPU usage")
                    .font(DesignTokens.Typography.subtitle.weight(.semibold))
                Text(suggestion.message)
                    .font(.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            Spacer(minLength: 8)

            Button("Switch to \(suggestion.suggestedProfile.displayName)", action: onApply)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
            .help("Remind me later")

            Button(action: onDismissPermanently) {
                Text("Don't show again")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Never show performance suggestions")
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.Corner.radius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: DesignTokens.Corner.radius, style: .continuous)
                        .stroke(Color.orange.opacity(0.35), lineWidth: 1)
                }
        }
        .padding(.horizontal, DesignTokens.Spacing.medium)
        .padding(.bottom, 8)
    }
}
