import Darwin
import Foundation
import os.log

/// CPU metrics from one sampler tick (Phase 7C.2.3).
struct PerformanceCPUMetrics: Sendable {
    let instantPercent: Double
    let smoothedPercent: Double
    let averagePercent: Double
    let isReady: Bool
}

/// Samples process CPU usage on a fixed interval (Phase 7C / 7C.2.3).
/// Runs off the main thread; reports Activity Monitor / top-style % (100% = one logical core).
final class PerformanceMonitor: @unchecked Sendable {
    static let sampleIntervalSeconds: TimeInterval = 1
    static let rollingWindowSeconds: TimeInterval = 60
    /// Slow EMA (~8s half-life at 1s interval) to approximate `ps` / Activity Monitor decay.
    private static let smoothedEmaAlpha = 0.08

    private let logger = Logger(subsystem: "com.local.wallpaper", category: "PerformanceMonitor")
    private let logicalProcessorCount: Int
    private let machTimebase: mach_timebase_info_data_t
    private let sampleQueue = DispatchQueue(label: "com.local.wallpaper.performance-monitor", qos: .utility)
    private var sampleTimer: DispatchSourceTimer?

    private var instantCPUPercent: Double = 0
    private var smoothedCPUPercent: Double = 0
    private var averageCPUPercent: Double = 0
    private var hasValidMeasurement = false
    private var samples: [(date: Date, value: Double)] = []
    private var lastProcTicks: UInt64?
    private var lastClockCPUNanoseconds: UInt64?
    private var lastMonotonicNanoseconds: UInt64?
    private var smoothedEMA: Double?
    private var validSampleCount = 0

    var onSample: (@MainActor @Sendable (PerformanceCPUMetrics) -> Void)?

    init() {
        logicalProcessorCount = max(1, ProcessInfo.processInfo.activeProcessorCount)
        machTimebase = Self.effectiveMachTimebase()
    }

    func start() {
        sampleQueue.async { [weak self] in
            guard let self else { return }
            guard self.sampleTimer == nil else { return }
            self.resetState()
            self.seedBaseline()

            let timer = DispatchSource.makeTimerSource(queue: self.sampleQueue)
            timer.schedule(
                deadline: .now() + Self.sampleIntervalSeconds,
                repeating: Self.sampleIntervalSeconds
            )
            timer.setEventHandler { [weak self] in
                self?.takeSample()
            }
            timer.resume()
            self.sampleTimer = timer
        }
    }

    func stop() {
        sampleQueue.async { [weak self] in
            self?.sampleTimer?.cancel()
            self?.sampleTimer = nil
        }
    }

    private func resetState() {
        lastProcTicks = nil
        lastClockCPUNanoseconds = nil
        lastMonotonicNanoseconds = nil
        samples.removeAll()
        instantCPUPercent = 0
        smoothedCPUPercent = 0
        averageCPUPercent = 0
        smoothedEMA = nil
        validSampleCount = 0
        hasValidMeasurement = false
    }

    /// Establishes baselines so the first timer tick yields a real delta.
    private func seedBaseline() {
        _ = Self.readCPUSample(
            sinceProcTicks: &lastProcTicks,
            sinceClockCPUNanoseconds: &lastClockCPUNanoseconds,
            sinceMonotonicNanoseconds: &lastMonotonicNanoseconds,
            machTimebase: machTimebase
        )
    }

    private func takeSample() {
        guard let sample = Self.readCPUSample(
            sinceProcTicks: &lastProcTicks,
            sinceClockCPUNanoseconds: &lastClockCPUNanoseconds,
            sinceMonotonicNanoseconds: &lastMonotonicNanoseconds,
            machTimebase: machTimebase
        ) else {
            publishSample()
            return
        }

        let instant = sample.percent
        if let previousEMA = smoothedEMA {
            smoothedEMA = Self.smoothedEmaAlpha * instant + (1 - Self.smoothedEmaAlpha) * previousEMA
        } else {
            smoothedEMA = instant
        }

        validSampleCount += 1
        hasValidMeasurement = validSampleCount >= 1

        instantCPUPercent = instant
        if let smoothedEMA {
            smoothedCPUPercent = smoothedEMA
        }

        let now = Date()
        samples.append((now, instant))
        let cutoff = now.addingTimeInterval(-Self.rollingWindowSeconds)
        samples.removeAll { $0.date < cutoff }

        if samples.isEmpty {
            averageCPUPercent = smoothedCPUPercent
        } else {
            averageCPUPercent = samples.map(\.value).reduce(0, +) / Double(samples.count)
        }

        logger.debug(
            """
            CPU sample instant=\(instant, format: .fixed(precision: 2))% \
            smoothed=\(self.smoothedCPUPercent, format: .fixed(precision: 2))% \
            avg60s=\(self.averageCPUPercent, format: .fixed(precision: 2))% \
            clockGettime=\(sample.clockGettimePercent.map { String(format: "%.2f", $0) } ?? "n/a")% \
            procPidinfo=\(sample.procPidinfoPercent.map { String(format: "%.2f", $0) } ?? "n/a")% \
            wallMs=\(sample.wallMs, format: .fixed(precision: 0)) \
            logicalCPUs=\(self.logicalProcessorCount) \
            source=\(sample.source.rawValue)
            """
        )

        publishSample()
    }

    private func publishSample() {
        let metrics = PerformanceCPUMetrics(
            instantPercent: instantCPUPercent,
            smoothedPercent: smoothedCPUPercent,
            averagePercent: averageCPUPercent,
            isReady: hasValidMeasurement
        )
        guard let onSample else { return }
        Task { @MainActor in
            onSample(metrics)
        }
    }

    private enum CPUSampleSource: String {
        case clockGettime
        case procPidinfo
    }

    private struct CPUSample {
        let percent: Double
        let clockGettimePercent: Double?
        let procPidinfoPercent: Double?
        let cpuTicksDelta: UInt64?
        let cpuNsDelta: UInt64?
        let wallMs: Double
        let source: CPUSampleSource
    }

    /// Returns Activity Monitor–style CPU % since the previous sample (100% = one logical core).
    private static func readCPUSample(
        sinceProcTicks lastProcTicks: inout UInt64?,
        sinceClockCPUNanoseconds lastClockCPUNanoseconds: inout UInt64?,
        sinceMonotonicNanoseconds lastMonotonicNanoseconds: inout UInt64?,
        machTimebase: mach_timebase_info_data_t
    ) -> CPUSample? {
        let monotonicNow = clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)
        let clockCPUNow = clock_gettime_nsec_np(CLOCK_PROCESS_CPUTIME_ID)

        var info = proc_taskinfo()
        let size = Int32(MemoryLayout<proc_taskinfo>.size)
        let procInfoOK = proc_pidinfo(getpid(), PROC_PIDTASKINFO, 0, &info, size) == size
        let procTicksNow = procInfoOK ? info.pti_total_user + info.pti_total_system : nil

        defer {
            if let procTicksNow {
                lastProcTicks = procTicksNow
            }
            lastClockCPUNanoseconds = clockCPUNow
            lastMonotonicNanoseconds = monotonicNow
        }

        guard let previousMonotonic = lastMonotonicNanoseconds else {
            return nil
        }

        let wallNanoseconds = monotonicNow &- previousMonotonic
        guard wallNanoseconds > 25_000_000 else { return nil }

        let wallMs = Double(wallNanoseconds) / 1_000_000

        var clockGettimePercent: Double?
        if let previousClockCPU = lastClockCPUNanoseconds {
            let cpuNsDelta = clockCPUNow &- previousClockCPU
            clockGettimePercent = percentFromNanoseconds(
                cpuNanoseconds: Double(cpuNsDelta),
                wallNanoseconds: Double(wallNanoseconds)
            )
        }

        var procPidinfoPercent: Double?
        var cpuTicksDelta: UInt64?
        if procInfoOK, let previousProcTicks = lastProcTicks, let procTicksNow {
            cpuTicksDelta = procTicksNow &- previousProcTicks
            let cpuNsFromTicks = machTicksToNanoseconds(ticks: cpuTicksDelta!, timebase: machTimebase)
            procPidinfoPercent = percentFromNanoseconds(
                cpuNanoseconds: cpuNsFromTicks,
                wallNanoseconds: Double(wallNanoseconds)
            )
        }

        let (percent, source): (Double, CPUSampleSource)
        if let clockGettimePercent {
            percent = clockGettimePercent
            source = .clockGettime
        } else if let procPidinfoPercent {
            percent = procPidinfoPercent
            source = .procPidinfo
        } else {
            return nil
        }

        let cpuNsDelta: UInt64?
        if let previousClockCPU = lastClockCPUNanoseconds {
            cpuNsDelta = clockCPUNow &- previousClockCPU
        } else if let cpuTicksDelta {
            cpuNsDelta = UInt64(machTicksToNanoseconds(ticks: cpuTicksDelta, timebase: machTimebase))
        } else {
            cpuNsDelta = nil
        }

        return CPUSample(
            percent: max(0, percent),
            clockGettimePercent: clockGettimePercent.map { max(0, $0) },
            procPidinfoPercent: procPidinfoPercent.map { max(0, $0) },
            cpuTicksDelta: cpuTicksDelta,
            cpuNsDelta: cpuNsDelta,
            wallMs: wallMs,
            source: source
        )
    }

    private static func percentFromNanoseconds(cpuNanoseconds: Double, wallNanoseconds: Double) -> Double {
        guard wallNanoseconds > 0 else { return 0 }
        return (cpuNanoseconds / wallNanoseconds) * 100
    }

    private static func machTicksToNanoseconds(ticks: UInt64, timebase: mach_timebase_info_data_t) -> Double {
        Double(ticks) * Double(timebase.numer) / Double(timebase.denom)
    }

    /// Mach timebase for proc_pidinfo ticks; Rosetta may report 1:1 while ticks remain arm64-native.
    private static func effectiveMachTimebase() -> mach_timebase_info_data_t {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)

        var translated = 0
        var size = MemoryLayout.size(ofValue: translated)
        if sysctlbyname("sysctl.proc_translated", &translated, &size, nil, 0) == 0,
           translated != 0,
           info.numer == 1, info.denom == 1 {
            info.numer = 125
            info.denom = 3
        }
        return info
    }
}
