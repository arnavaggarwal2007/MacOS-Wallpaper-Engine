import CoreGraphics
import Foundation

/// Resolves display-bound collection sources to connected displays.
///
/// Explicit bindings (monitor name or saved ID) are resolved first; auto-detect rows fill
/// remaining displays in screen order, matching simple multi-source collections.
enum DisplayBoundCollectionMapping {
    struct ConnectedDisplay: Equatable {
        let id: CGDirectDisplayID
        let name: String
    }

    static func isAutoDetect(_ source: CollectionSource) -> Bool {
        source.displayLabel == nil && source.displayIDFallback == nil
    }

    /// Resolves a source with an explicit display label and/or saved ID fallback.
    ///
    /// When a label is set, only that label is used — a stale `displayIDFallback` from a
    /// different monitor session is ignored so a swapped panel does not steal the wrong slot.
    static func resolveExplicitBinding(
        source: CollectionSource,
        connected: [ConnectedDisplay],
        claimed: inout Set<CGDirectDisplayID>
    ) -> CGDirectDisplayID? {
        guard !isAutoDetect(source) else { return nil }

        if let label = source.displayLabel {
            if let match = matchLabel(label, in: connected, claimed: claimed) {
                claimed.insert(match)
                return match
            }
            return nil
        }

        if let fallback = source.displayIDFallback {
            let id = CGDirectDisplayID(fallback)
            guard connected.contains(where: { $0.id == id }), !claimed.contains(id) else { return nil }
            claimed.insert(id)
            return id
        }

        return nil
    }

    /// Assigns auto-detect sources to unused displays in `orderedDisplayIDs` order.
    static func autoDetectDisplayIDs(
        count: Int,
        orderedDisplayIDs: [CGDirectDisplayID],
        claimed: Set<CGDirectDisplayID>
    ) -> [CGDirectDisplayID] {
        guard count > 0 else { return [] }
        let available = orderedDisplayIDs.filter { !claimed.contains($0) }
        return Array(available.prefix(count))
    }

    private static func matchLabel(
        _ label: String,
        in connected: [ConnectedDisplay],
        claimed: Set<CGDirectDisplayID>
    ) -> CGDirectDisplayID? {
        let candidates = connected.filter { !claimed.contains($0.id) }

        if let exact = candidates.first(where: { $0.name == label }) {
            return exact.id
        }

        if let fuzzy = candidates.first(where: { $0.name.contains(label) || label.contains($0.name) }) {
            return fuzzy.id
        }

        return nil
    }
}

extension DisplayConfigurationMigrator.DisplaySignature {
    /// Stable string key for persisting signature → settings-key associations.
    var persistenceKey: String {
        "\(localizedName)|\(widthPoints)|\(heightPoints)"
    }

    init?(persistenceKey: String) {
        let parts = persistenceKey.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 3,
              let width = Int(parts[1]),
              let height = Int(parts[2]) else { return nil }
        localizedName = parts[0]
        widthPoints = width
        heightPoints = height
    }
}
