import AppKit

/// Matches persisted per-display settings to screens when `CGDirectDisplayID` values change after hotplug.
struct DisplayConfigurationMigrator {
    struct DisplaySignature: Equatable, Hashable {
        let localizedName: String
        let widthPoints: Int
        let heightPoints: Int

        init(screen: NSScreen) {
            localizedName = screen.localizedName
            widthPoints = Int(screen.frame.width.rounded())
            heightPoints = Int(screen.frame.height.rounded())
        }
    }

    /// Builds a map from old display ID string keys to new ID string keys using screen name + resolution.
    ///
    /// Handles hotplug cases where:
    /// - a display ID disappears and reappears on a different physical screen;
    /// - the same ID is reused (e.g. built-in was the only screen at ID 1, then an external becomes ID 1).
    static func migrationMapping(
        previousSignatures: [CGDirectDisplayID: DisplaySignature],
        currentScreens: [NSScreen]
    ) -> [String: String] {
        let currentSignatures = signatures(for: currentScreens)

        var currentBySignature: [DisplaySignature: [CGDirectDisplayID]] = [:]
        for (displayID, signature) in currentSignatures {
            currentBySignature[signature, default: []].append(displayID)
        }

        var usedNewIDs = Set<CGDirectDisplayID>()
        var mapping: [String: String] = [:]

        for oldID in previousSignatures.keys.sorted() {
            guard let oldSignature = previousSignatures[oldID] else { continue }

            // ID unchanged and still refers to the same physical display — keep key as-is.
            if let currentSignature = currentSignatures[oldID], currentSignature == oldSignature {
                usedNewIDs.insert(oldID)
                continue
            }

            guard let candidates = currentBySignature[oldSignature] else { continue }
            guard let newID = candidates.first(where: { !usedNewIDs.contains($0) }) else { continue }

            if oldID != newID {
                mapping[String(oldID)] = String(newID)
            }
            usedNewIDs.insert(newID)
        }

        return mapping
    }

    static func signatures(for screens: [NSScreen]) -> [CGDirectDisplayID: DisplaySignature] {
        Dictionary(uniqueKeysWithValues: screens.map { ($0.displayID, DisplaySignature(screen: $0)) })
    }

    static func rekeyPerDisplaySettings(in settings: SettingsStore, mapping: [String: String]) {
        guard !mapping.isEmpty else { return }

        settings.perDisplaySources = rekeyDictionary(settings.perDisplaySources, mapping: mapping)
        settings.perDisplayBookmarks = rekeyDictionary(settings.perDisplayBookmarks, mapping: mapping)
        settings.perDisplayScalingModes = rekeyDictionary(settings.perDisplayScalingModes, mapping: mapping)
        settings.perDisplayRendererModes = rekeyDictionary(settings.perDisplayRendererModes, mapping: mapping)
    }

    private static func rekeyDictionary<Value>(
        _ dictionary: [String: Value],
        mapping: [String: String]
    ) -> [String: Value] {
        var result = dictionary
        for (oldKey, newKey) in mapping {
            guard oldKey != newKey, let value = result.removeValue(forKey: oldKey) else { continue }
            if result[newKey] == nil {
                result[newKey] = value
            }
        }
        return result
    }
}
