# Agent instructions

Guidance for AI coding agents working in this repository.

## Knowledge base

For non-trivial changes, consult the sibling folder `Wallpaper Engine KB/` (`10 Project Home.md`, `KB-Guide.md`, linked feature and architecture notes) before proposing changes. Update KB files only when the user explicitly asks.

## Build and CI

- **Build / smoke / regression:** Agents may run `xcodebuild build`, `chunk7_smoke.sh`, and `chunk7_regression.sh` when validating compile or bundle checks.
- **Coding standards:** [`DESIGN.md`](DESIGN.md) and [`docs/`](docs/).

## XCTest policy

| Agents MAY | Agents MUST NOT |
|------------|-----------------|
| Add or edit files under `Personal Wallpaper EngineTests/` | Run `xcodebuild test` or `xcodebuild test-without-building` |
| Extract small testable pure helpers (same pattern as `DisplayBoundCollectionMapping`) | Execute XCTest from the terminal or claim tests pass without owner confirmation |
| Document new tests in [`docs/TESTING.md`](docs/TESTING.md) when adding a new test file or suite area | |

After adding or changing tests, **tell the owner to run Product → Test (`Cmd+U`) in Xcode** and report any failures.

Canonical testing workflow: [`docs/TESTING.md`](docs/TESTING.md).

## Commits and PRs

Only create commits or pull requests when the user explicitly asks.
