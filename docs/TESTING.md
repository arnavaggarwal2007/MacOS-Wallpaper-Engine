# Testing guide

**Purpose:** Canonical reference for automated and manual verification before release.

**Platform:** macOS 15.0+ · XCTest · scheme **Personal Wallpaper Engine**

---

## Testing pyramid

| Layer | What | Who runs |
|-------|------|----------|
| **Unit tests** | Pure logic, persistence, validation (`Personal Wallpaper EngineTests/`) | Owner in Xcode (`Cmd+U`) or CI |
| **Build + smoke** | Mach-O, bundle, unsigned Debug/Release build | `chunk7_regression.sh` (CI on `main`) |
| **Manual regression** | Hotplug, performance banner, bookmarks, UI flows | Owner on real hardware |

Automate deterministic logic; manual-test integration with the display server, GPU, and IOKit power APIs.

---

## Running unit tests (owner)

### Xcode (recommended)

1. Open `Personal Wallpaper Engine.xcodeproj`
2. Select scheme **Personal Wallpaper Engine**
3. **Product → Test** (`Cmd+U`), or use the Test navigator for a single class
4. Before Archive: run once with the **Release** configuration for extra confidence

### Terminal

```bash
CODE_SIGNING_ALLOWED=NO xcodebuild test \
  -scheme "Personal Wallpaper Engine" \
  -destination 'platform=macOS'
```

After a full build, `test-without-building` is faster — but requires a prior `build-for-testing` (plain `build` does not compile app-hosted test bundles):

```bash
CODE_SIGNING_ALLOWED=NO xcodebuild build-for-testing \
  -scheme "Personal Wallpaper Engine" \
  -destination 'platform=macOS,arch=$(uname -m)'

CODE_SIGNING_ALLOWED=NO xcodebuild test-without-building \
  -scheme "Personal Wallpaper Engine" \
  -destination 'platform=macOS,arch=$(uname -m)'
```

Or use `xcodebuild test`, which builds and runs in one step.

### CI

`scripts/chunk7_regression.sh` runs Debug + Release build, smoke checks, `build-for-testing` (Debug), then unit tests on every push to `main` (see `.github/workflows/chunk7_regression.yml`).

- **Builds** use `generic/platform=macOS` via [`scripts/xcodebuild_ci.sh`](../scripts/xcodebuild_ci.sh) (universal binary on headless runners).
- **XCTest** sets `XCODEBUILD_DESTINATION="platform=macOS,arch=$(uname -m)"` so tests run on a concrete destination (required by modern Xcode; `generic/platform=macOS` fails with “Any Mac”).

---

## AI agent policy

Agents **write** tests; the **owner runs** them. See [`AGENTS.md`](../AGENTS.md) § XCTest.

After an agent adds or changes tests, run `Cmd+U` in Xcode and report any failures.

---

## When to add a unit test

- New or changed **pure helper** (`DisplayBoundCollectionMapping`, `PerformanceSuggestionPolicy`, validators)
- **Bug fix** with a reproducible logic path (regression test required)
- **Persistence** or Codable round-trip (`SettingsStore`, collections, setups)
- **Validation rules** (collection names, source URLs)

## When not to unit-test (manual instead)

- Multi-display hotplug visuals — [`HOTPLUG_REGRESSION.md`](HOTPLUG_REGRESSION.md)
- CPU suggestion banner on real hardware — [`PRE_RELEASE_CHECKLIST.md`](PRE_RELEASE_CHECKLIST.md) § Performance
- Security-scoped bookmark survival across relaunch
- App Store sandbox end-to-end

---

## Test suite inventory

**Count:** **92** `test*` methods across 12 files in `Personal Wallpaper EngineTests/` (2026-08-29).

| File | Focus |
|------|--------|
| `DisplayBoundCollectionMappingTests` | Display-bound apply resolution, auto-detect round-robin |
| `DisplayConfigurationMigratorTests` | Per-display ID rekeying, `migrationMapping` |
| `DisplayMigrationOrchestrationTests` | Cold-start signature merge, hotplug augmentation, focused-display migration |
| `SettingsStorePersistenceTests` | UserDefaults quarantine, collection/setup CRUD, signature keys |
| `WallpaperCollectionTests` | Name/URL validation, Codable |
| `PerformanceSuggestionPolicyTests` | CPU suggestion thresholds |
| `WebWallpaperURLValidatorTests` | Web URL allowlist |
| `QuickModeTests` | Quick mode presets |
| `CPUMetricsFormattingTests` | Diagnostics formatting |
| `AppLinksTests` / `AppInfoTests` / `UpdateCheckerTests` | Metadata and links |

---

## Test hygiene

- One behavior per `test*` method; Arrange–Act–Assert
- No sleeps, network, or `NSScreen` in unit tests
- Restore `SettingsStore.shared` state in `defer` when mutating the singleton
- Use `withTemporaryKey` for isolated `UserDefaults` decode tests
- `@testable import Personal_Wallpaper_Engine` only in the test target

---

## Related

- [`PRE_RELEASE_CHECKLIST.md`](PRE_RELEASE_CHECKLIST.md) — release gate
- [`DISTRIBUTION.md`](DISTRIBUTION.md) §8 — CI commands
- [`HOTPLUG_REGRESSION.md`](HOTPLUG_REGRESSION.md) — display manual matrix
- [`AGENTS.md`](../AGENTS.md) — agent write-only XCTest policy
