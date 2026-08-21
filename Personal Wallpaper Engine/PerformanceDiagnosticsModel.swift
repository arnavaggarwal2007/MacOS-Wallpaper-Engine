import Combine
import Foundation

/// Live CPU readings and engine diagnostics, kept off `AppViewModel` on purpose.
///
/// The CPU sampler ticks once a second. Publishing those ticks from `AppViewModel` invalidated every
/// view observing it — the whole shell — once a second, for numbers only the Diagnostics card in
/// Settings actually displays. Holding them here means the 1 Hz churn is scoped to the views that
/// observe this object.
///
/// CPU values are on `PerformanceMonitor`'s per-core scale (100% = one logical core). Use
/// `CPUMetricsFormatting` to present a system-wide share.
@MainActor
final class PerformanceDiagnosticsModel: ObservableObject {
    @Published private(set) var instantCPUPercent: Double = 0
    @Published private(set) var smoothedCPUPercent: Double = 0
    /// Rolling 60-second mean.
    @Published private(set) var averageCPUPercent: Double = 0
    @Published private(set) var isCPUMeasurementReady = false

    @Published private(set) var engineDiagnostics: WallpaperManager.EngineDiagnosticsSnapshot = .init(
        lifecycleState: .idle,
        isPlaybackActive: false,
        performanceProfile: .balanced,
        sharedSessionAttachments: 0,
        decodePathCount: 0,
        heroSharesDesktopDecode: false,
        coalesceTip: nil,
        displayRows: [],
        powerPolicyMessage: nil,
        anyDisplayVisible: false
    )

    func apply(_ metrics: PerformanceCPUMetrics) {
        isCPUMeasurementReady = metrics.isReady
        guard metrics.isReady else { return }
        instantCPUPercent = metrics.instantPercent
        smoothedCPUPercent = metrics.smoothedPercent
        averageCPUPercent = metrics.averagePercent
    }

    func apply(_ snapshot: WallpaperManager.EngineDiagnosticsSnapshot) {
        engineDiagnostics = snapshot
    }
}
