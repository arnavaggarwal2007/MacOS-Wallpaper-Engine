import Foundation
import IOKit.ps
import os.log

/// Observes AC/battery and Low Power Mode; exposes `AsyncStream<PowerEvent>` for WallpaperManager (Phase 7A).
@MainActor
final class PowerPolicyManager {
    private let logger = Logger(subsystem: "com.local.wallpaper", category: "PowerPolicy")
    private var eventContinuation: AsyncStream<PowerEvent>.Continuation?
    private var runLoopSource: CFRunLoopSource?
    private var lowPowerObserver: NSObjectProtocol?
    private var debounceTask: Task<Void, Never>?
    private let debounceIntervalNs: UInt64 = 400_000_000

    private(set) var currentSnapshot: PowerStateSnapshot

    init() {
        currentSnapshot = PowerStateSnapshot(
            isOnACPower: true,
            batteryLevelPercent: nil,
            isLowPowerModeEnabled: ProcessInfo.processInfo.isLowPowerModeEnabled
        )
        refreshSnapshot(emitEvents: false)
    }

    func makeEventStream() -> AsyncStream<PowerEvent> {
        AsyncStream { continuation in
            Task { @MainActor [weak self] in
                self?.eventContinuation = continuation
            }
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.stopObserving()
                }
            }
        }
    }

    func startObserving() {
        guard runLoopSource == nil else { return }

        let context = Unmanaged.passUnretained(self).toOpaque()
        runLoopSource = IOPSNotificationCreateRunLoopSource({ context in
            guard let context else { return }
            let manager = Unmanaged<PowerPolicyManager>.fromOpaque(context).takeUnretainedValue()
            Task { @MainActor in
                manager.refreshSnapshot(emitEvents: true)
            }
        }, context).takeRetainedValue()

        if let runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
        }

        lowPowerObserver = NotificationCenter.default.addObserver(
            forName: .NSProcessInfoPowerStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleLowPowerModeChange()
            }
        }

        refreshSnapshot(emitEvents: false)
        logger.debug("Power policy observation started")
    }

    func stopObserving() {
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
            self.runLoopSource = nil
        }
        if let lowPowerObserver {
            NotificationCenter.default.removeObserver(lowPowerObserver)
            self.lowPowerObserver = nil
        }
        debounceTask?.cancel()
        debounceTask = nil
        eventContinuation?.finish()
        eventContinuation = nil
    }

    private func handleLowPowerModeChange() {
        let enabled = ProcessInfo.processInfo.isLowPowerModeEnabled
        guard enabled != currentSnapshot.isLowPowerModeEnabled else { return }
        let previous = currentSnapshot
        currentSnapshot.isLowPowerModeEnabled = enabled
        scheduleDebouncedPowerEvents(previous: previous)
    }

    private func refreshSnapshot(emitEvents: Bool) {
        let previous = currentSnapshot
        let read = Self.readPowerSourceState()
        currentSnapshot = PowerStateSnapshot(
            isOnACPower: read.isOnACPower,
            batteryLevelPercent: read.batteryLevelPercent,
            isLowPowerModeEnabled: ProcessInfo.processInfo.isLowPowerModeEnabled
        )

        guard emitEvents else { return }
        scheduleDebouncedPowerEvents(previous: previous)
    }

    private func scheduleDebouncedPowerEvents(previous: PowerStateSnapshot) {
        debounceTask?.cancel()
        let intervalNs = debounceIntervalNs
        debounceTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: intervalNs)
            } catch {
                return
            }
            guard let self, !Task.isCancelled else { return }
            self.emitPowerEventsIfChanged(since: previous)
        }
    }

    private func emitPowerEventsIfChanged(since previous: PowerStateSnapshot) {
        guard let eventContinuation else { return }

        if currentSnapshot.isOnACPower != previous.isOnACPower {
            logger.info("Power source changed: AC=\(self.currentSnapshot.isOnACPower)")
            eventContinuation.yield(.powerSourceChanged(isOnACPower: currentSnapshot.isOnACPower))
        }

        if currentSnapshot.batteryLevelPercent != previous.batteryLevelPercent,
           let level = currentSnapshot.batteryLevelPercent {
            logger.info("Battery level changed: \(level)%")
            eventContinuation.yield(.batteryLevelChanged(percentage: level))
        }

        if currentSnapshot.isLowPowerModeEnabled != previous.isLowPowerModeEnabled {
            logger.info("Low Power Mode changed: \(self.currentSnapshot.isLowPowerModeEnabled)")
            eventContinuation.yield(.lowPowerModeChanged(enabled: currentSnapshot.isLowPowerModeEnabled))
        }
    }

    private static func readPowerSourceState() -> PowerStateSnapshot {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFString] else {
            return PowerStateSnapshot(isOnACPower: true, batteryLevelPercent: nil, isLowPowerModeEnabled: ProcessInfo.processInfo.isLowPowerModeEnabled)
        }

        var foundBattery = false
        var isOnAC = true
        var levelPercent: Int?

        for source in sources {
            guard let descRef = IOPSGetPowerSourceDescription(info, source) else { continue }
            let description = descRef.takeUnretainedValue() as NSDictionary

            guard isInternalBatterySource(description) else { continue }

            foundBattery = true
            if let powerSource = powerString(description, kIOPSPowerSourceStateKey as CFString) {
                isOnAC = powerSource == (kIOPSACPowerValue as String)
            }
            if let current = powerInt(description, kIOPSCurrentCapacityKey as CFString),
               let maxCapacity = powerInt(description, kIOPSMaxCapacityKey as CFString), maxCapacity > 0 {
                levelPercent = min(100, Swift.max(0, (current * 100) / maxCapacity))
            }
            break
        }

        if !foundBattery {
            return PowerStateSnapshot(
                isOnACPower: true,
                batteryLevelPercent: nil,
                isLowPowerModeEnabled: ProcessInfo.processInfo.isLowPowerModeEnabled
            )
        }

        return PowerStateSnapshot(
            isOnACPower: isOnAC,
            batteryLevelPercent: levelPercent,
            isLowPowerModeEnabled: ProcessInfo.processInfo.isLowPowerModeEnabled
        )
    }

    private static func isInternalBatterySource(_ description: NSDictionary) -> Bool {
        if let transport = powerString(description, kIOPSTransportTypeKey as CFString),
           transport == (kIOPSInternalBatteryType as String) {
            return true
        }
        if let type = powerString(description, kIOPSTypeKey as CFString),
           type == (kIOPSInternalBatteryType as String) {
            return true
        }
        // Fallback: present power source with capacity fields (MacBook internal pack).
        let isPresent = powerBool(description, kIOPSIsPresentKey as CFString) ?? true
        return isPresent && powerInt(description, kIOPSCurrentCapacityKey as CFString) != nil
    }

    private static func powerString(_ description: NSDictionary, _ key: CFString) -> String? {
        let stringKey = key as String
        if let value = description[stringKey] as? String { return value }
        if let value = description[key] as? String { return value }
        return nil
    }

    private static func powerInt(_ description: NSDictionary, _ key: CFString) -> Int? {
        let stringKey = key as String
        if let value = description[stringKey] as? Int { return value }
        if let value = description[key] as? Int { return value }
        if let value = description[stringKey] as? Double { return Int(value) }
        if let value = description[key] as? Double { return Int(value) }
        return nil
    }

    private static func powerBool(_ description: NSDictionary, _ key: CFString) -> Bool? {
        let stringKey = key as String
        if let value = description[stringKey] as? Bool { return value }
        if let value = description[key] as? Bool { return value }
        return nil
    }
}
