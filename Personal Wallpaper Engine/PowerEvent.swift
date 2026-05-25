import Foundation

/// Power-related changes observed by `PowerPolicyManager` (Phase 7A).
enum PowerEvent: Equatable, Sendable {
    case powerSourceChanged(isOnACPower: Bool)
    case batteryLevelChanged(percentage: Int)
    case lowPowerModeChanged(enabled: Bool)
}

/// Snapshot of power state used for policy evaluation.
struct PowerStateSnapshot: Equatable, Sendable {
    var isOnACPower: Bool
    /// `nil` when no battery is present (e.g. Mac mini / iMac).
    var batteryLevelPercent: Int?
    var isLowPowerModeEnabled: Bool
}
