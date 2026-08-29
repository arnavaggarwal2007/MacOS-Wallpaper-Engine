import CoreGraphics
import Foundation

/// Pure helpers for composing display-signature snapshots before `DisplayConfigurationMigrator.migrationMapping`.
enum DisplayMigrationOrchestration {
    typealias DisplaySignature = DisplayConfigurationMigrator.DisplaySignature

    /// Cold-start: merges persisted signature keys with connected displays that have per-display settings.
    static func previousSignaturesForColdStart(
        perDisplaySignatureKeys: [String: String],
        persistedSettingsKeys: Set<String>,
        connectedSignatures: [CGDirectDisplayID: DisplaySignature]
    ) -> (
        previous: [CGDirectDisplayID: DisplaySignature],
        settingsKeyBySignature: [DisplaySignature: String],
        connectedDisplayIDsToPersist: [CGDirectDisplayID]
    ) {
        var previous: [CGDirectDisplayID: DisplaySignature] = [:]
        var settingsKeyBySignature: [DisplaySignature: String] = [:]
        var connectedDisplayIDsToPersist: [CGDirectDisplayID] = []

        for (persistenceKey, settingsKey) in perDisplaySignatureKeys {
            guard let signature = DisplaySignature(persistenceKey: persistenceKey),
                  let oldID = UInt32(settingsKey) else { continue }
            let displayID = CGDirectDisplayID(oldID)
            previous[displayID] = signature
            settingsKeyBySignature[signature] = settingsKey
        }

        for (displayID, signature) in connectedSignatures {
            let key = String(displayID)
            guard persistedSettingsKeys.contains(key) else { continue }
            previous[displayID] = signature
            settingsKeyBySignature[signature] = key
            connectedDisplayIDsToPersist.append(displayID)
        }

        return (previous, settingsKeyBySignature, connectedDisplayIDsToPersist)
    }

    /// Hotplug: includes disconnected displays so unplugged monitor settings can remap on replug.
    static func augmentedPreviousSignatures(
        lastDisplaySignatures: [CGDirectDisplayID: DisplaySignature],
        settingsKeyBySignature: [DisplaySignature: String],
        connectedDisplayIDs: Set<CGDirectDisplayID>
    ) -> [CGDirectDisplayID: DisplaySignature] {
        var augmented = lastDisplaySignatures

        for (signature, key) in settingsKeyBySignature {
            guard let oldID = UInt32(key) else { continue }
            let displayID = CGDirectDisplayID(oldID)
            if augmented[displayID] == nil {
                augmented[displayID] = signature
            }
        }

        for (displayID, signature) in lastDisplaySignatures where !connectedDisplayIDs.contains(displayID) {
            if augmented[displayID] == nil {
                augmented[displayID] = signature
            }
        }

        return augmented
    }

    enum FocusedDisplayMigrationResult: Equatable {
        case resolved(CGDirectDisplayID)
        case needsSync
    }

    /// Resolves focused display ID after a configuration migration mapping is applied.
    static func migrateFocusedDisplayID(
        currentFocusedID: CGDirectDisplayID?,
        mapping: [String: String],
        focusedSignatureBefore: DisplaySignature?,
        currentSignatures: [CGDirectDisplayID: DisplaySignature]
    ) -> FocusedDisplayMigrationResult {
        guard let focused = currentFocusedID else {
            return .needsSync
        }

        if let newKey = mapping[String(focused)], let newID = UInt32(newKey) {
            return .resolved(CGDirectDisplayID(newID))
        }

        if let previousSignature = focusedSignatureBefore {
            for (displayID, signature) in currentSignatures where signature == previousSignature {
                return .resolved(displayID)
            }
        }

        return .needsSync
    }
}
