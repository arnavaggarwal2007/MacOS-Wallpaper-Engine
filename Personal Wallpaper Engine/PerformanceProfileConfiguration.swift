import AVFoundation
import CoreGraphics

/// Profile-specific AVPlayerItem tuning (Phase 7E). Avoids seek-timer FPS caps (ADR-005).
enum PerformanceProfileConfiguration {
    private static let balancedMaxDimension = CGSize(width: 1920, height: 1080)
    private static let batterySaverPeakBitRate: Double = 2_000_000

    static func apply(to item: AVPlayerItem, profile: PerformanceProfile) {
        switch profile {
        case .maxQuality:
            item.preferredMaximumResolution = .zero
            item.preferredPeakBitRate = 0
        case .balanced:
            item.preferredMaximumResolution = balancedMaxDimension
            item.preferredPeakBitRate = 0
        case .batterySaver:
            item.preferredMaximumResolution = balancedMaxDimension
            item.preferredPeakBitRate = batterySaverPeakBitRate
        }
    }
}
