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
        migrationMapping(
            previousSignatures: previousSignatures,
            currentSignatures: signatures(for: currentScreens)
        )
    }

    /// Same as `migrationMapping(previousSignatures:currentScreens:)` but accepts pre-built signatures (unit tests).
    static func migrationMapping(
        previousSignatures: [CGDirectDisplayID: DisplaySignature],
        currentSignatures: [CGDirectDisplayID: DisplaySignature]
    ) -> [String: String] {

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

    /// Moves per-display values onto their new display IDs.
    ///
    /// Built in a single pass over the original dictionary rather than by mutating a copy while
    /// iterating `mapping`. Mutating in place made the outcome depend on `Dictionary`'s arbitrary
    /// iteration order: for a chained mapping such as `1 → 2, 2 → 3`, visiting `1 → 2` first found
    /// the destination still occupied and silently discarded display 1's wallpaper, while the other
    /// order preserved both. `computeDisplayIDMapping` reserves each destination ID, so the mapping
    /// is injective and remapped entries cannot collide with one another.
    static func rekeyDictionary<Value>(
        _ dictionary: [String: Value],
        mapping: [String: String]
    ) -> [String: Value] {
        var result: [String: Value] = [:]
        var remapped: [String: Value] = [:]
        result.reserveCapacity(dictionary.count)

        for (key, value) in dictionary {
            if let newKey = mapping[key], newKey != key {
                remapped[newKey] = value
            } else {
                result[key] = value
            }
        }

        // A remapped entry wins over whatever sat on its destination key: that ID has just been
        // reassigned to a different physical screen, so the resident entry is the stale one.
        for (key, value) in remapped {
            result[key] = value
        }

        return result
    }
}
