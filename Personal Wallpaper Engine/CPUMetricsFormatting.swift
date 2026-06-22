import Foundation

/// Shared CPU display helpers (Activity Monitor per-core scale).
enum CPUMetricsFormatting {
    static var logicalProcessorCount: Int {
        max(1, ProcessInfo.processInfo.activeProcessorCount)
    }

    /// Per-core percent → share of total system CPU capacity (0–100%).
    static func systemWidePercent(fromPerCore perCore: Double) -> Double {
        perCore / Double(logicalProcessorCount)
    }

    static func perCoreText(_ value: Double, ready: Bool, precision: Int = 2) -> String {
        guard ready else { return "Measuring…" }
        return String(format: "%.\(precision)f%%", value)
    }

    static func systemWideText(fromPerCore perCore: Double, ready: Bool, precision: Int = 2) -> String {
        guard ready else { return "Measuring…" }
        let system = systemWidePercent(fromPerCore: perCore)
        return String(format: "~%.\(precision)f%% of system", system)
    }

    static func menuBarCPUText(perCoreAverage: Double, ready: Bool) -> String {
        guard ready else { return "CPU —" }
        return String(format: "CPU %.1f%%", perCoreAverage)
    }
}
