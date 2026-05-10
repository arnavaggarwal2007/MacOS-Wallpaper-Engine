---
type: feature-contract
feature_id: "Phase-6A"
status: in-progress
related_kb: ../Wallpaper Engine KB/30 Features/Feature-Wallpaper-Collections-Phase-6A.md
created: 2026-05-06T15:58
---

# Feature Contract — Wallpaper Collections (Phase 6A)

## Purpose
This document tracks implementation status and code contract for Phase 6A: Wallpaper Collections. All modifications must align with the KB spec (`Feature-Wallpaper-Collections-Phase-6A.md`) and existing architectural patterns from prior phases.

---

## Implementation Status Matrix

| Category | KB Spec Item | Current State (Verified) | Implementation Chunk |
|----------|--------------|-------------------------|---------------------|
| **Data Model** | `WallpaperCollection: Codable, Identifiable` struct with id/name/createdAt/updatedAt/collectionType/sources | ✅ Implemented (`Personal Wallpaper Engine/WallpaperCollection.swift`) | Chunk 2 |
| | CollectionSource struct with id/url/displayLabel/displayIDFallback/scalingMode/order | ✅ Implemented in same file | Chunk 2 |
| | Validation helpers: `isValidCollectionName()`, `isValidSourceURL()` | ✅ Implemented in same file | Chunk 2 |
| **Persistence** | UserDefaults via SettingsStore with keys `savedCollections` and `lastUsedCollectionName` | ✅ Implemented (`Personal Wallpaper Engine/SettingsStore.swift`) | Chunk 3 |
| | JSON-encoded dictionaries with Codable structs | ✅ Implemented in same file | Chunk 3 |
| | CRUD helpers: `allCollectionNames()`, `saveCollection()`, `loadCollection()`, `updateCollection()`, `deleteCollection()` | ✅ Implemented in same file | Chunk 3 |
| **UI Components** | Collection picker with preview area | ❌ Not implemented yet | Chunk 6 (Editor), Chunk 7 (ContentView) |
| | CollectionEditorView modal | ❌ Not implemented yet | Chunk 6 |
| | CollectionSourceInput rows | ❌ Not implemented yet | Chunk 6 |
| **ViewModel Orchestration** | `@Published` collection state in AppViewModel | ❌ Missing | Chunk 4 |
| | Async methods for collection apply/management | ❌ Missing | Chunk 4, Chunk 5 |
| **Manager Logic** | Simple collection apply logic | ❌ Missing | Chunk 5 |
| | Display-bound collection apply logic | ❌ Missing | Chunk 5 |
| **Error Handling** | `WallpaperError.collectionNotFound()`, `invalidCollectionName()`, `invalidCollectionSource()`, `displayMismatchWarning()` | ✅ Extended in same file as data model | Chunk 2, Chunk 8 |

---

## Code Contract — Data Model (`WallpaperCollection.swift`)

### Required Properties
All structs must conform to `Codable` and `Identifiable`.

**WallpaperCollection:**
- ✅ `id: String` (UUID string for unique identification)
- ✅ `name: String` (User-provided; validated: non-empty, max 255 chars, no /, \, *)
- ✅ `description: String` (Optional description)
- ✅ `createdAt: Date`
- ✅ `updatedAt: Date`
- ✅ `collectionType: CollectionType` (.simple or .displayBound)
- ✅ `sources: [CollectionSource]`

**CollectionSource:**
- ✅ `id: String` (UUID string)
- ✅ `url: String` (File path or HTTP(S) URL)
- ✅ `displayLabel: String?` (Optional display label for display-bound)
- ✅ `displayIDFallback: Int?` (Optional numeric display ID fallback)
- ✅ `scalingMode: String?` (Optional; if nil, use global default)
- ✅ `order: Int`

### Validation Rules
- ✅ `isValidCollectionName(_:)`: Non-empty, ≤255 chars, no `/ \ *`
- ✅ `isValidSourceURL(_:)`: Empty strings rejected; accepts file:///, http://, https:// paths

### Init Methods
- ✅ Failable `init(name:description:collectionType:sources:)` throws for validation
- ✅ Explicit `init(id:name:description:createdAt:updatedAt:collectionType:sources:)` for decoding

### Mutable Helpers
- ✅ `updated(name:description:collectionType:sources:) throws` returns copy with updatedAt updated

---

## Code Contract — Persistence (`SettingsStore.swift`)

### UserDefaults Keys
- ✅ `savedCollections`: `[String: WallpaperCollection]` (keyed by collection name)
- ✅ `lastUsedCollectionName`: `String?` (for UI convenience)

### Encoding Pattern
All properties using `didSet` encode to UserDefaults on change:
```swift
var savedCollections: [String: WallpaperCollection] {
    didSet { /* encode JSON, set in UserDefaults */ }
}
```

### CRUD Helpers
- ✅ `allCollectionNames() -> [String]`: Returns sorted list of all saved collection names
- ✅ `saveCollection(name:description:collectionType:sources:) -> Result<WallpaperCollection, WallpaperError>`
  - Creates new collection via failable init
  - Adds to `savedCollections` dictionary keyed by name
  - Returns success with created collection or failure with error
- ✅ `loadCollection(name:) -> Result<WallpaperCollection, WallpaperError>`
  - Retrieves from `savedCollections[name]`
  - Returns `.failure(.collectionNotFound(name:))` if missing
- ✅ `updateCollection(name:newName:description:collectionType:sources:) -> Result<WallpaperCollection, WallpaperError>`
  - Validates collection exists before modifying
  - If name changed: remove old entry, add with new name; update `lastUsedCollectionName` accordingly
  - Returns updated collection on success
- ✅ `deleteCollection(name:) -> Result<Void, WallpaperError>`
  - Removes from `savedCollections`
  - Clears `lastUsedCollectionName` if it pointed to this collection

---

## Code Contract — ViewModel (`AppViewModel.swift`)

### Required @Published Properties for Phase 6A
- ❌ `@Published var savedCollections: [String: WallpaperCollection]` (loaded from SettingsStore)
- ❌ `@Published var lastUsedCollectionName: String?`
- ❌ `@Published var selectedCollectionName: String?`

### Required Async Methods for Phase 6A

**Collection Management:**
```swift
// Load saved collections from settings on init/start
func loadSavedCollections() async {
    if let data = settings.data(forKey: Keys.savedCollections) {
        self.savedCollections = try? JSONDecoder().decode([String: WallpaperCollection].self, from: data) ?? [:]
    }
    self.lastUsedCollectionName = settings.lastUsedCollectionName
}

// Select a collection (for preview or apply)
func selectCollection(name: String) {
    selectedCollectionName = name
}

// Create new collection (opens editor modal)
func createNewCollection() async {
    // Present CollectionEditorView, capture result from save action
}

// Load selected collection for preview
func loadSelectedCollection() async -> Result<WallpaperCollection, WallpaperError> {
    guard let name = selectedCollectionName else { return .failure(.collectionNotFound(name: "")) }
    return settings.loadCollection(name: name)
}

// Delete selected collection
func deleteCollection(name: String) async -> Result<Void, WallpaperError> {
    return settings.deleteCollection(name: name)
}
```

**Apply Collection:**
```swift
@MainActor
func applyCollection(
    name: String,
    useUnified: Bool = false  // If true, apply only first source to all displays
) async -> Result<Void, WallpaperError> {
    let collection = try? await loadSelectedCollection()
    guard case .success(let collection) = collection else { return .failure(.collectionNotFound(name: name)) }
    
    switch collection.collectionType {
    case .simple:
        // Apply sequentially: source 0 → display 0, source 1 → display 1...
        // If fewer sources than displays: leave extra unchanged (graceful)
        // If more sources than displays: warn user, apply only to available
        return await applySimpleCollection(collection, useUnified: useUnified)
    case .displayBound:
        // For each source: try ID match, then label fallback
        // Skip unmatched with warning
        return await applyDisplayBoundCollection(collection)
    }
}

@MainActor
private func applySimpleCollection(_ collection: WallpaperCollection, useUnified: Bool) async -> Result<Void, WallpaperError> {
    guard !usePerDisplay else {
        errorMessage = "Unified wallpaper apply is disabled while per-display mode is enabled."
        return .failure(.internalError(description: "Cannot apply simple collection in unified mode"))
    }
    
    var displayIndex = 0
    
    // If useUnified, apply only first source to all displays
    if useUnified {
        guard let firstSource = collection.sources.first else {
            return .success(())
        }
        
        for (displayID, controller) in WallpaperManager.displayControllers {
            do {
                try await wallpaperManager.setWallpaper(url: URL(string: firstSource.url)!)
            } catch {
                logger.error("Failed to apply unified wallpaper: \(error)")
            }
        }
        return .success(())
    }
    
    // Sequential apply
    for source in collection.sources {
        guard displayIndex < WallpaperManager.displayControllers.count else { break }
        
        let url = URL(string: source.url) ?? nil  // Should be validated already
        if let url = url {
            await wallpaperManager.setWallpaper(url: url)
        }
        
        displayIndex += 1
    }
    
    lastUsedCollectionName = name
    return .success(())
}

@MainActor
private func applyDisplayBoundCollection(_ collection: WallpaperCollection) async -> Result<Void, WallpaperError> {
    var unmatchedWarnings: [String] = []
    
    for source in collection.sources {
        // Resolve display via ID or label fallback
        let matchedDisplayID = resolveDisplayForSource(source: source)
        
        if let displayID = matchedDisplayID {
            let url = URL(string: source.url) ?? nil
            if let url = url {
                await wallpaperManager.setPerDisplayWallpaper(
                    displayID: displayID,
                    url: url,
                    rendererMode: .video,  // Collections default to video; can extend later
                    scalingMode: source.scalingMode.flatMap { VideoScalingMode(rawValue: $0) } ?? settings.scalingMode
                )
            }
        } else {
            let message = "Display \(source.displayLabel ?? source.displayIDFallback ?? "?") not found"
            unmatchedWarnings.append(message)
            logger.warning("Display-bound collection skip: \(message)")
        }
    }
    
    // If there were unmatched displays, show warnings via statusMessage or alert
    guard !unmatchedWarnings.isEmpty else { return .success(()) }
    
    let warningText = unmatchedWarnings.joined(separator: ", ")
    statusMessage = "Applied to matched displays. Warnings:\n\(warningText)"
    return .success(())
}

private func resolveDisplayForSource(source: CollectionSource) -> CGDirectDisplayID? {
    // First attempt: ID match
    if let displayIDFallback = source.displayIDFallback,
       let controller = WallpaperManager.displayControllers.values.first(where: { $0.displayID == displayIDFallback }) {
        return controller.displayID
    }
    
    // Fallback: label match (case-insensitive partial or exact)
    if let label = source.displayLabel {
        for controller in WallpaperManager.displayControllers.values {
            let screenName = controller.screen.displayName ?? ""
            // Exact match first
            if screenName == label {
                return controller.displayID
            }
            // Fuzzy match: label appears anywhere in screen name (e.g., "LG 4K" matches "LG 4K Display")
            if screenName.contains(label) || label.contains(screenName) {
                logger.debug("Display-bound label fallback: '\(label)' matched '\(screenName)'")
                return controller.displayID
            }
        }
    }
    
    return nil
}
```

---

## Code Contract — Manager (`WallpaperManager.swift`)

### Collection-Specific Methods (Chunks 5)

**Simple Apply:**
Already has: `setWallpaper(url:)` for unified, `setPerDisplayWallpaper(displayID:url:rendererMode:scalingMode:)` for per-display.

Chunk 5 adds collection orchestration on top of existing methods.

**Display-Bound Apply:**
Already has same underlying methods; Chunk 5 just orchestrates via label/ID matching logic in AppViewModel.

---

## Code Contract — UI Components (`UI/CollectionEditorView.swift`, `UI/CollectionSourceInput.swift`)

### CollectionEditorView Requirements (Chunk 6)

```swift
import SwiftUI

struct CollectionEditorView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var collectionName: String
    @Binding var collectionDescription: String
    @Binding var collectionType: WallpaperCollection.CollectionType
    @Binding var sources: [CollectionSourceRow]  // Row wraps CollectionSource for mutable access
    @FocusState private var focusedField: CollectionEditorField?
    
    enum CollectionEditorField {
        case name, description, typePicker
    }
    
    var canSave: Bool {
        !collectionName.trimmingCharacters(in: .whitespaces).isEmpty &&
        sources.count > 0
    }
    
    // ... preview section showing collection info
    // ... source rows with URL field, display picker (if display-bound), scaling picker (if display-bound), delete button
    // ... Save/Cancel buttons
}

struct CollectionSourceRow: View {
    let onDelete: () -> Void
    @Binding var url: String
    @Binding var displayLabel: String?
    @Binding var displayIDFallback: Int?
    @Binding var scalingMode: String?
    
    // ... UI for editing source properties
}
```

### CollectionSourceInput Requirements (Chunk 6)

Each source row contains:
- ✅ Text field for URL/path with placeholder
- ✅ Browse button: opens file picker, auto-fills field with selected path
- ✅ If display-bound: display picker (populated from `NSScreen.screens`)
- ✅ If display-bound: scaling mode picker
- ✅ Delete button (red) for removing source

---

## Code Contract — ContentView Integration (`ContentView.swift`, Chunk 7)

### "Saved Collections" Section Requirements

**Collection Picker:**
- Dropdown/picker showing all saved collections (sorted alphabetically)
- Empty state: "No collections saved yet. Create one to get started."

**Preview Area (when collection selected):**
- Collection name, type badge (Simple/Display-Bound)
- Source count and creation date
- Display-source mappings (e.g., "Source A → Display 1", "Source B → Display 2")
- Last-used timestamp (optional)

**Buttons:**
- ✅ "Create Collection" → opens CollectionEditorView modal
- ✅ "Load Collection" → loads selected collection, shows in preview (no apply yet)
- ✅ "Apply Collection" → applies selected collection to displays, shows result message
- ✅ "Delete Collection" → confirmation alert, then removes (does not affect current wallpaper)

---

## Error Handling Extensions (`Errors.swift`)

Already extended `WallpaperError` with:
- ✅ `.collectionNotFound(name:)`: Surface clear error: "Collection '\(name)' not found. It may have been deleted."
- ✅ `.invalidCollectionName(reason:)`: "Invalid collection name: \(reason)"
- ✅ `.invalidCollectionSource(url:reason:)`: "Invalid source URL '\(url)': \(reason)"
- ✅ `.displayMismatchWarning(message:)`: "Display mismatch: \(message)"

---

## Regression Requirements (Chunk 9)

All Phase 6A changes must preserve:
- ✅ Per-display wallpaper apply via `setPerDisplayWallpaper()` 
- ✅ Unified wallpaper apply via `setWallpaper()`
- ✅ Screen change handling in WallpaperManager
- ✅ Space/virtual desktop tracking
- ✅ Sleep/wake lifecycle coordination
- ✅ Menu bar controls (togglePlayback, toggleMute)
- ✅ Launch-on-login support

---

## Testing Checklist (Chunk 9)

**Codable Round-Trips:**
- [ ] Create collection → encode to JSON → decode from JSON → verify all fields match
- [ ] Verify UUID string format is valid

**Name Validation:**
- [ ] Empty name rejected with clear error
- [ ] Duplicate names allowed in storage (user choice)
- [ ] Special characters `/ \ *` rejected
- [ ] Name length >255 rejected

**Display Matching:**
- [ ] ID resolution works for matching sources to displays
- [ ] Label fallback works when display reconnected/reordered
- [ ] No-match produces warning, not crash

**Persistence:**
- [ ] Create collection → relaunch app → verify collection still exists
- [ ] `lastUsedCollectionName` updates on apply/delete

**Apply Workflows:**
- [ ] Simple sequential: source i → display i (graceful degradation on mismatch)
- [ ] Display-bound: correct mapping, warning for unmapped displays
- [ ] Unified mode with simple collection: applies only first source to all displays

**UI Validation:**
- [ ] Editor Save button disabled if name empty or no sources
- [ ] Name field validation on blur (reject invalid chars immediately)
- [ ] Preview shows correct info for loaded collection

**Regression Tests:**
- [ ] Existing per-display wallpapers still work after Phase 6A changes
- [ ] Existing unified wallpaper still works
- [ ] Menu bar controls function correctly
- [ ] Sleep/wake behavior unchanged
- [ ] Screen resize handling unchanged
- [ ] Build produces no new warnings or errors

---

## Architecture Impact Summary

**Modified Modules:**
- `SettingsStore.swift`: +collection persistence layer (already done)
- `AppViewModel.swift`: +collection coordination methods
- `WallpaperManager.swift`: Collection apply logic reuses existing methods (orchestration only)
- `ContentView.swift`: +Saved Collections section and buttons

**New Files:**
- `Models/WallpaperCollection.swift` (already exists at root level, should move to Models/)
- `UI/CollectionEditorView.swift`
- `UI/CollectionSourceInput.swift`

**Preserved:**
- No breaking changes to DisplayController or Renderer protocols
- No new rendering subsystems; collections apply through existing orchestration

---

## Timeline Tracking

| Chunk | Effort | Status | Completion Criteria |
|-------|--------|--------|---------------------|
| 1. KB Alignment & Feature Contract | 2 hrs | ✅ **DONE** (this document) | Feature contract created and reviewed |
| 2. Data Model & Validation | 3 hrs | ✅ DONE (`WallpaperCollection.swift`) | Codable structs + validation helpers implemented |
| 3. SettingsStore Persistence | 4 hrs | ✅ DONE (`SettingsStore.swift`) | JSON encoding, CRUD helpers implemented |
| 4. AppViewModel Coordination | 4 hrs | ⏳ PENDING | @Published state + async methods for collection management/apply |
| 5. WallpaperManager Apply Logic | 5 hrs | ⏳ PENDING | Simple + display-bound apply orchestration methods |
| 6. Collection Editor UI | 4 hrs | ⏳ PENDING | CollectionEditorView and CollectionSourceInput components |
| 7. ContentView Integration | 4 hrs | ⏳ PENDING | "Saved Collections" section with picker/preview/buttons |
| 8. Error Handling & Edge Cases | 3 hrs | ✅ DONE (WallpaperError extensions) | All error types implemented + clear messages |
| 9. Integration Testing & Verification | 5 hrs | ⏳ PENDING | Smoke tests, regression verification, build checks |

**Total Estimated:** ~36 hours (~5 days for focused part-time work)

---

## Switch me to ACT MODE to implement Chunk 1 updates or continue with next chunk.
