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

                diagnosticsGrid

                Toggle(
                    isOn: Binding(
                        get: { appModel.useTestPerformanceSuggestionThresholds },
                        set: { appModel.useTestPerformanceSuggestionThresholds = $0 }
                    )
                ) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Use test suggestion thresholds")
                            .font(DesignTokens.Typography.subtitle)
                        Text("Lower Max→Balanced gate (4%) for verifying the suggestion banner.")
                            .font(.caption)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }
                }

                if let callout = heavyScenarioCallout {
                    Label(callout, systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let power = appModel.engineDiagnostics.powerPolicyMessage, !power.isEmpty {
                    Label(power, systemImage: "bolt.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

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

    private var diagnosticsGrid: some View {
        let diag = appModel.engineDiagnostics
        return VStack(alignment: .leading, spacing: 8) {
            diagnosticRow("CPU (instant)", cpuPercentText(appModel.instantCPUPercent))
            diagnosticRow("CPU (smoothed)", cpuPercentText(appModel.currentCPUPercent))
            diagnosticRow("CPU (60s avg)", cpuPercentText(appModel.estimatedCPUPercent))
            Text("Process CPU — 100% = one logical core. Smoothed aligns with `ps`; Activity Monitor often reads 2–5pp lower due to heavier smoothing. Instant is the last 1s window. Suggestions use smoothed CPU.")
                .font(.caption2)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
            diagnosticRow("Logical CPUs", "\(ProcessInfo.processInfo.activeProcessorCount)")
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
        }
    }

    private var heavyScenarioCallout: String? {
        let diag = appModel.engineDiagnostics
        guard diag.isPlaybackActive, diag.displayRows.count >= 1 else { return nil }

        var reasons: [String] = []
        if hasMultipleDecodePaths(diag) {
            reasons.append("multiple decode paths")
        }
        if has4KSource(diag) {
            reasons.append("4K source")
        }
        if diag.performanceProfile == .maxQuality {
            reasons.append("Max Quality")
        }
        guard !reasons.isEmpty else { return nil }
        return "Elevated CPU is expected with \(reasons.joined(separator: ", ")). Canonical baseline: same 1080p on all displays, unfocused (~2.5–3% Debug)."
    }

    private func hasMultipleDecodePaths(_ diag: WallpaperManager.EngineDiagnosticsSnapshot) -> Bool {
        diag.decodePathCount > 1
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
        guard appModel.isCPUMeasurementReady else { return "Measuring…" }
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
