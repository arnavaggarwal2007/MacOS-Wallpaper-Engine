import SwiftUI

/// Diagnostics readout and engine controls (Phase 7C).
struct EngineDiagnosticsSection: View {
    @EnvironmentObject private var appModel: AppViewModel
    @State private var isRestarting = false
    @State private var isResetting = false

    var body: some View {
        GlassCardView(title: "Diagnostics") {
            VStack(alignment: .leading, spacing: 14) {
                Text("Live engine status and recovery actions.")
                    .font(.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)

                // Separate view so the 1 Hz CPU updates redraw only this readout.
                DiagnosticsReadout(diagnostics: appModel.diagnostics)

                #if DEBUG
                // QA affordance only. `AppViewModel` also forces production thresholds in Release,
                // so a persisted Debug value cannot leak into a shipping build.
                Toggle(
                    isOn: Binding(
                        get: { appModel.useTestPerformanceSuggestionThresholds },
                        set: { appModel.useTestPerformanceSuggestionThresholds = $0 }
                    )
                ) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Use test suggestion thresholds")
                            .font(DesignTokens.Typography.subtitle)
                        Text("Lowers the suggestion gate to 2% of system CPU for verifying the banner.")
                            .font(.caption)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }
                }
                #endif

                Divider()

                HStack(spacing: 12) {
                    Button {
                        Task { await restartEngine() }
                    } label: {
                        Label("Restart Engine", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .disabled(isRestarting || isResetting)

                    Button(role: .destructive) {
                        Task { await resetToSafeDefault() }
                    } label: {
                        Label("Reset to Safe Default", systemImage: "pause.circle")
                    }
                    .buttonStyle(.bordered)
                    .disabled(isRestarting || isResetting)
                }

                if isRestarting || isResetting {
                    ProgressView()
                        .controlSize(.small)
                }
            }
        }
        .onAppear { appModel.setDiagnosticsPanelVisible(true) }
        .onDisappear { appModel.setDiagnosticsPanelVisible(false) }
    }

    private func restartEngine() async {
        isRestarting = true
        defer { isRestarting = false }
        await appModel.restartWallpaperEngine()
    }

    private func resetToSafeDefault() async {
        isResetting = true
        defer { isResetting = false }
        await appModel.resetToSafeDefault()
    }
}

/// Live CPU and engine rows. Observes `PerformanceDiagnosticsModel` directly rather than
/// `AppViewModel` so the per-second sampler does not invalidate the rest of Settings.
private struct DiagnosticsReadout: View {
    @ObservedObject var diagnostics: PerformanceDiagnosticsModel

    var body: some View {
        let diag = diagnostics.engineDiagnostics
        VStack(alignment: .leading, spacing: 8) {
            diagnosticRow("CPU (instant)", cpuPercentText(diagnostics.instantCPUPercent))
            diagnosticRow("CPU (smoothed)", cpuPercentText(diagnostics.smoothedCPUPercent))
            diagnosticRow("CPU (60s avg)", cpuPercentText(diagnostics.averageCPUPercent))
            diagnosticRow(
                "System CPU share",
                CPUMetricsFormatting.systemWideText(
                    fromPerCore: diagnostics.averageCPUPercent,
                    ready: diagnostics.isCPUMeasurementReady
                )
            )
            Text("Process CPU — 100% = one logical core (Activity Monitor scale). System share = per-core ÷ \(CPUMetricsFormatting.logicalProcessorCount) cores. Smoothed aligns with `ps`; Activity Monitor often reads 2–5pp lower due to heavier smoothing.")
                .font(.caption2)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
            diagnosticRow("Logical CPUs", "\(CPUMetricsFormatting.logicalProcessorCount)")
            diagnosticRow("Profile", diag.performanceProfile.displayName)
            diagnosticRow("Lifecycle", String(describing: diag.lifecycleState))
            diagnosticRow("Playback active", diag.isPlaybackActive ? "Yes" : "No")
            diagnosticRow("Displays", "\(diag.displayRows.count)")
            diagnosticRow("Decode paths", "\(diag.decodePathCount)")
            diagnosticRow("Hero shares desktop decode", diag.heroSharesDesktopDecode ? "Yes" : "No")
            diagnosticRow("Shared decode", diag.sharedSessionAttachments > 1
                ? "Yes (\(diag.sharedSessionAttachments) layers)"
                : diag.sharedSessionAttachments == 1 ? "1 layer" : "No")
            diagnosticRow("Desktop visible", diag.anyDisplayVisible ? "Yes" : "No")

            if let tip = diag.coalesceTip {
                Label(tip, systemImage: "square.stack.3d.up.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if !diag.displayRows.isEmpty {
                Text("Per display")
                    .font(.caption.weight(.semibold))
                    .padding(.top, 4)
                ForEach(diag.displayRows, id: \.displayID) { row in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.label)
                            .font(.caption.weight(.medium))
                        Text("\(row.sourceName) · \(row.usesSharedRenderer ? "shared" : "standalone") · rate \(String(format: "%.2f", row.playbackRate))\(row.visibilityPaused ? " · visibility paused" : "")")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let callout = heavyScenarioCallout(diag) {
                Label(callout, systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let power = diag.powerPolicyMessage, !power.isEmpty {
                Label(power, systemImage: "bolt.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func heavyScenarioCallout(_ diag: WallpaperManager.EngineDiagnosticsSnapshot) -> String? {
        guard diag.isPlaybackActive, !diag.displayRows.isEmpty else { return nil }

        var reasons: [String] = []
        if diag.decodePathCount > 1 {
            reasons.append("multiple decode paths")
        }
        if has4KSource(diag) {
            reasons.append("4K source")
        }
        if diag.performanceProfile == .maxQuality {
            reasons.append("Max Quality")
        }
        guard !reasons.isEmpty else { return nil }
        return "Elevated CPU is expected with \(reasons.joined(separator: ", ")). Canonical baseline: same 1080p on all displays, unfocused (~2.5% per-core Debug, ~0.2% system on 12 cores)."
    }

    private func has4KSource(_ diag: WallpaperManager.EngineDiagnosticsSnapshot) -> Bool {
        diag.displayRows.contains { row in
            let name = row.sourceName.lowercased()
            return name.contains("3840")
                || name.contains("2160")
                || name.contains("4k")
        }
    }

    private func cpuPercentText(_ value: Double) -> String {
        guard diagnostics.isCPUMeasurementReady else { return "Measuring…" }
        return String(format: "%.2f%%", value)
    }

    private func diagnosticRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(DesignTokens.Typography.subtitle)
        }
    }
}
