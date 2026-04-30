# VSCode-based Development Roadmap for macOS Wallpaper Engine Core

**Last Updated:** April 30, 2026 | **Status:** Production Ready | **macOS Version Support:** 12.0+ | **Swift Version:** 5.10+

## Table of Contents

1. [Overview](#overview)
2. [Project Goals & Constraints](#project-goals--constraints)
3. [Architecture & Technical Design](#architecture--technical-design)
4. [Environment Setup](#environment-setup)
5. [Project Structure & Build Strategy](#project-structure--build-strategy)
6. [Git & GitHub Integration](#git--github-integration)
7. [Step-by-Step Implementation](#step-by-step-implementation)
8. [Code Examples & Patterns](#code-examples--patterns)
9. [Production Testing Checklist](#production-testing-checklist)
10. [Troubleshooting & Performance](#troubleshooting--performance)
11. [References](#references)

---

## Overview

This document provides a comprehensive, production-ready roadmap for developing a macOS wallpaper engine core with VSCode as the primary editor while leveraging Xcode's toolchains and SDKs under the hood. This hybrid approach provides the speed and flexibility of VSCode with the power and integration of Xcode's compilation and debugging infrastructure.

**Development Approach:** 
- Primary editing in VSCode Insiders with Swift extension (sourcekit-lsp backed)
- Build and run via Xcode command-line tools (`xcodebuild`)
- Project structure managed in Xcode (single creation), then edited entirely in VSCode
- Version control via Git and GitHub from VSCode's integrated tools

**Why This Approach:**
- VSCode is lightweight and responsive for daily editing
- Xcode's toolchains provide production-grade compilation, linking, and code signing
- Hybrid model avoids Xcode's UI overhead while maintaining full iOS/macOS toolchain capabilities
- Increasingly used pattern in Swift development community (2025-2026)

---

## Project Goals & Constraints

### Primary Goals

1. **Functional Wallpaper Engine:** Play MP4/MOV video files as the macOS desktop wallpaper
2. **Multi-Display Support:** Proper rendering across single, dual, and multi-monitor setups
3. **Virtual Desktop Awareness:** Function correctly with macOS Spaces/virtual desktops
4. **Low Resource Consumption:** Target <10% CPU and <2% GPU at idle (measured via Activity Monitor)
5. **Production Quality Code:** Proper error handling, resource management, and user feedback
6. **Extensibility:** Modular architecture enabling future video effects, web rendering, and advanced features

### Phase 1 Constraints (Local-Only)

- **No Network Access:** Video files local to system only
- **No Distribution:** App runs locally; no App Store, signing, or notarization initially
- **No Background Modes:** App must be running; no launch-on-login support yet
- **Permissions:** No sandboxing, special entitlements, or permissions needed

### Phase 1.5 Extensions (Optional for First Release)

- **Web/YouTube Support:** Render web content and YouTube videos via WKWebView
- **Configuration UI:** Menu-bar app or preferences window for settings
- **Scaling Modes:** Multiple video gravity options (fill, fit, stretch)

### Future Phases (Not in Scope)

- Login item and launch-on-login support
- App Store distribution with code signing and notarization
- Cloud sync for wallpaper settings
- AI-powered content recommendations
- Network streaming support

---

## Architecture & Technical Design

### System Architecture Overview

```
┌──────────────────────────────────────────────────────┐
│              SwiftUI/AppKit UI Layer                 │
│         (Configuration, Menu Bar, Preferences)       │
└────────────────────┬─────────────────────────────────┘
                     │
┌────────────────────▼─────────────────────────────────┐
│         WallpaperManager (Actor/Orchestrator)        │
│                                                       │
│  • Lifecycle: startup, shutdown, cleanup             │
│  • Screen monitoring: add, remove, resize            │
│  • Space/virtual desktop tracking                    │
│  • Display registry: NSScreen -> DisplayController   │
│  • Error handling and recovery                       │
│  • Resource lifecycle coordination                   │
└────────────────────┬─────────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
┌───────▼──┐  ┌──────▼──┐  ┌─────▼─────┐
│Display   │  │Display  │  │Display    │
│Controller│  │Controller│ │Controller │
│(Screen 1)│  │(Screen 2)│ │(Screen N) │
└────┬─────┘  └────┬─────┘  └────┬──────┘
     │             │             │
     ├─────────────┼─────────────┤
     │             │             │
┌────▼────────────────────────────▼───┐
│        Renderer Protocol Impl        │
│  (VideoRenderer || WebRenderer)      │
└────┬─────────────────────────────────┘
     │
┌────▼──────────────────────────────────┐
│   Media Playback (AVPlayer/WKWebView) │
│  + CALayer + NSView Integration       │
└────┬──────────────────────────────────┘
     │
┌────▼──────────────────────────────────┐
│  SettingsStore (UserDefaults wrapper) │
│     (Preferences Persistence)         │
└───────────────────────────────────────┘
```

### Module Responsibilities & Async Patterns

#### **WallpaperManager (Actor)**

**Purpose:** Orchestrates all wallpaper operations and coordinates across displays

**Responsibilities:**
- Initialize on app launch, providing single entry point
- Monitor screen additions/removals via `NSScreen.screensDidChangeNotification`
- Track virtual desktop changes via `NSWorkspace.activeSpaceDidChangeNotification`
- Maintain dictionary of `DisplayController` instances (key: display ID)
- Handle app termination with graceful resource cleanup
- Coordinate pause/resume across all displays (e.g., on screen lock)
- Handle errors from DisplayControllers and surface to UI

**Key Properties:**
```swift
actor WallpaperManager: ObservableObject {
    @Published var currentWallpaperURL: URL?
    @Published var scalingMode: VideoScalingMode = .resizeAspectFill
    @Published var isMuted: Bool = true
    
    private var displayControllers: [CGDirectDisplayID: DisplayController] = [:]
    private var screenChangeTask: Task<Void, Never>?
    private var spaceChangeTask: Task<Void, Never>?
    private var logger: Logger
}
```

**Concurrency Pattern:**
- Uses Swift actor model for thread-safe state mutations
- All state changes serialize through actor's isolation domain
- Async/await for all I/O operations (file access, display enumeration)
- Task groups for parallel display controller creation

#### **DisplayController (Class)**

**Purpose:** Manages one NSWindow and its associated renderer for a single display

**Responsibilities:**
- Create borderless NSWindow at desktop level with proper window level
- Prevent mouse/keyboard interaction (ignoresMouseEvents, canBecomeKey -> false)
- Manage window lifecycle (creation, resizing, repositioning, destruction)
- Hold and manage a Renderer instance (VideoRenderer or WebRenderer)
- Handle screen resolution/frame changes and call renderer.resize()
- Manage Space visibility using NSWindow.CollectionBehavior
- Graceful cleanup on display disconnect

**Key Properties:**
```swift
class DisplayController {
    private var window: NSWindow?
    private var contentView: NSView?
    private var renderer: Renderer?
    private var displayID: CGDirectDisplayID
    private var resizeObserver: NSObjectProtocol?
    private weak var manager: WallpaperManager?
}
```

#### **Renderer (Protocol)**

**Purpose:** Abstraction layer enabling multiple rendering backends

**Interface:**
```swift
protocol Renderer: AnyObject {
    /// Begin rendering content in the provided view
    func start(in containerView: NSView) async -> Result<Void, WallpaperError>
    
    /// Stop rendering and pause playback
    func stop() async
    
    /// Pause playback (may not apply to all renderers)
    func pause() async
    
    /// Resume playback (may not apply to all renderers)
    func resume() async
    
    /// Handle container view size changes
    func resize(to newSize: CGSize) async
    
    /// Full cleanup: remove observers, release resources, deallocate
    func dispose() async
}
```

#### **VideoRenderer (Renderer Implementation)**

**Technology Stack:** AVFoundation (AVPlayer + AVPlayerLayer)

**Features:**
- Load local MP4/MOV video files via file URL
- Render via CALayer composition in NSView
- Support multiple scaling modes (resizeAspectFill, resizeAspect, resizeAspectHeight)
- Looping via AVPlayerItemDidPlayToEndTime observation
- Muting control via AVPlayer.isMuted
- Proper resource cleanup (pause, remove observers, release layers)

**Lifecycle:**
```
videoURL provided -> start() -> create AVPlayer -> create AVPlayerLayer
   -> add to view -> observe notifications -> play()
   -> (on end) -> seek to zero -> play again (loop)
   -> stop() called -> pause() -> remove observer -> release resources
```

#### **WebRenderer (Optional, Renderer Implementation)**

**Technology Stack:** WebKit (WKWebView)

**Features:**
- Load user-provided URLs or local HTML files
- Support YouTube embedding with autoplay
- JavaScript execution for dynamic content
- Same Renderer protocol for seamless swapping

**Use Cases:**
- YouTube playlist wallpapers (with autoplay enabled)
- Animated website backgrounds
- Custom HTML5 canvas animations

#### **SettingsStore (UserDefaults Wrapper)**

**Purpose:** Persistent storage for user preferences and app state

**Persisted Properties:**
- Selected video file path
- Scaling mode preference
- Audio mute preference
- Renderer type (video vs. web)
- Selected web URL (if using WebRenderer)

**Implementation Pattern:**
```swift
@Observable
final class SettingsStore {
    @ObservationTracked var videoFilePath: String = "" {
        didSet { UserDefaults.standard.set(videoFilePath, forKey: "videoPath") }
    }
    
    @ObservationTracked var scalingMode: VideoScalingMode = .resizeAspectFill {
        didSet { UserDefaults.standard.set(scalingMode.rawValue, forKey: "scalingMode") }
    }
    
    // ... other properties
}
```

Uses Swift 5.10+ `@Observable` macro for reactive UI updates without manual KVO.

### Error Handling Strategy (Production-Grade)

#### **WallpaperError Enumeration**

All operations use explicit, recoverable error types:

```swift
enum WallpaperError: LocalizedError, Equatable {
    // File/Media errors
    case videoFileNotFound(path: String)
    case videoFileNotReadable(path: String)
    case videoDecodingFailed(url: URL, reason: String)
    case videoFormatNotSupported(format: String)
    
    // Window/Rendering errors
    case windowCreationFailed(reason: String)
    case rendererInitializationFailed(renderer: String, reason: String)
    case screenNotFound(id: CGDirectDisplayID)
    case layerCompositionFailed(reason: String)
    
    // System errors
    case permissionDenied(resource: String)
    case systemResourcesUnavailable(reason: String)
    case internalError(description: String)
    
    var errorDescription: String? {
        switch self {
        case .videoFileNotFound(let path):
            return "Video file not found at: \(path)"
        case .videoFileNotReadable(let path):
            return "Cannot read video file: \(path). Check file permissions."
        case .videoDecodingFailed(let url, let reason):
            return "Failed to decode video '\(url.lastPathComponent)': \(reason)"
        case .videoFormatNotSupported(let format):
            return "Video format not supported: \(format). Use MP4 or MOV."
        case .windowCreationFailed(let reason):
            return "Failed to create desktop window: \(reason)"
        case .rendererInitializationFailed(let renderer, let reason):
            return "\(renderer) renderer failed to initialize: \(reason)"
        case .screenNotFound(let id):
            return "Display with ID \(id) not found. May have been disconnected."
        case .layerCompositionFailed(let reason):
            return "Video composition error: \(reason)"
        case .permissionDenied(let resource):
            return "Permission denied: \(resource)"
        case .systemResourcesUnavailable(let reason):
            return "Insufficient system resources: \(reason)"
        case .internalError(let description):
            return "Internal error: \(description)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .videoFileNotFound, .videoFileNotReadable:
            return "Verify the file path and permissions, then select a different video."
        case .videoDecodingFailed:
            return "The video may be corrupted. Try a different video file."
        case .videoFormatNotSupported:
            return "Convert your video to MP4 or MOV format using ffmpeg or QuickTime."
        case .windowCreationFailed:
            return "Restart the application. If the problem persists, restart your Mac."
        case .rendererInitializationFailed:
            return "Check system resources (Activity Monitor) and close other apps."
        case .screenNotFound:
            return "Reconnect the display or restart the application."
        case .layerCompositionFailed:
            return "Try a different video file or reduce display resolution."
        case .permissionDenied:
            return "Grant necessary permissions in System Preferences > Security & Privacy."
        case .systemResourcesUnavailable:
            return "Close other applications to free system resources."
        case .internalError:
            return "Please contact support and include the logs."
        }
    }
}
```

#### **Error Propagation Pattern**

```swift
// Module-level async operations use Result types
actor WallpaperManager {
    func startWallpaper(videoURL: URL) async -> Result<Void, WallpaperError> {
        // 1. Validate input
        guard FileManager.default.fileExists(atPath: videoURL.path) else {
            return .failure(.videoFileNotFound(path: videoURL.path))
        }
        
        // 2. Attempt to create renderer
        let rendererResult = await createVideoRenderer(for: videoURL)
        guard case .success(let renderer) = rendererResult else {
            return rendererResult
        }
        
        // 3. Update display controllers
        for displayController in displayControllers.values {
            let updateResult = await displayController.updateRenderer(renderer)
            if case .failure(let error) = updateResult {
                logger.error("Failed to update display: \(error)")
                // Continue with other displays rather than failing completely
            }
        }
        
        return .success(())
    }
}

// UI layer handles errors with user feedback
func handleStartWallpaperError(_ error: WallpaperError) {
    DispatchQueue.main.async {
        showErrorAlert(
            title: "Wallpaper Error",
            message: error.errorDescription ?? "An unknown error occurred",
            recoveryOptions: error.recoverySuggestion != nil ? [error.recoverySuggestion!] : []
        )
    }
    
    // Log for debugging
    logger.error("Wallpaper error: \(error)")
}
```

### Concurrency Model (Structured Concurrency Best Practices)

#### **Actor-Based Synchronization**

WallpaperManager is an actor ensuring thread-safe mutations:

```swift
actor WallpaperManager {
    // All mutations happen serially on actor's isolation domain
    nonisolated func observeScreenChanges() {
        Task {
            // Observe screen changes using AsyncSequence
            let notifications = NSScreen.screensDidChangeNotifications()
            for await _ in notifications {
                await handleScreenChange()
            }
        }
    }
    
    func handleScreenChange() async {
        // This runs isolated (thread-safe)
        let currentScreens = NSScreen.screens
        await syncDisplayControllers(to: currentScreens)
    }
}
```

#### **AsyncSequence for Notifications**

Replace old notification callbacks with modern AsyncSequence:

```swift
// Extension on Notification.Name to provide AsyncSequence
extension NSScreen {
    nonisolated static func screensDidChangeNotifications() -> AsyncStream<Void> {
        AsyncStream { continuation in
            let observer = NotificationCenter.default.addObserver(
                forName: NSScreen.screensDidChangeNotification,
                object: nil,
                queue: .main
            ) { _ in
                continuation.yield()
            }
            
            continuation.onTermination = { _ in
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}
```

#### **Task Groups for Parallel Operations**

When setting up multiple DisplayControllers in parallel:

```swift
func setupDisplays(_ screens: [NSScreen]) async {
    await withTaskGroup(
        of: (CGDirectDisplayID, Result<DisplayController, WallpaperError>).self
    ) { group in
        // Create tasks for each screen in parallel
        for screen in screens {
            group.addTask {
                let result = await self.createDisplayController(for: screen)
                return (screen.displayID, result)
            }
        }
        
        // Collect results as they complete
        for await (displayID, result) in group {
            switch result {
            case .success(let controller):
                self.displayControllers[displayID] = controller
                logger.debug("Display \(displayID) initialized")
            case .failure(let error):
                logger.error("Failed to setup display \(displayID): \(error)")
            }
        }
    }
}
```

#### **Avoiding Common Concurrency Pitfalls**

```swift
// GOOD: Use nonisolated for static/class methods that don't access actor state
nonisolated static func createTempDirectory() throws -> URL {
    // Can be called from any thread
}

// BAD: Don't use DispatchQueue for serialization (use actor instead)
// GOOD: Use actor for serial access to mutable state
actor SettingsStore { /* ... */ }

// GOOD: Task cancellation for long-running operations
class DisplayController {
    private var resizeTask: Task<Void, Never>?
    
    func handleScreenResize() {
        resizeTask?.cancel()
        resizeTask = Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s debounce
            if !Task.isCancelled {
                await applyResize()
            }
        }
    }
    
    deinit {
        resizeTask?.cancel()
    }
}
```

### Memory Management & Resource Lifecycle

#### **Resource Cleanup Strategy**

Every resource must have an explicit cleanup path:

| Resource | Created By | Cleanup Method | Timing |
|----------|-----------|-----------------|--------|
| NSWindow | DisplayController | `orderOut(nil)` then release reference | Display disconnect or app exit |
| AVPlayer | VideoRenderer | `pause()` + remove observers | Renderer.dispose() |
| AVPlayerLayer | VideoRenderer | `removeFromSuperlayer()` | Renderer.dispose() |
| NotificationCenter observers | Any component | `removeObserver()` | Component deinit or Task cancellation |
| CALayer sublayers | DisplayController | Remove before superlayer deallocation | deinit |
| Task instances | Any async code | `Task.cancel()` | Component deinit |

#### **Renderer Cleanup Pattern**

```swift
class VideoRenderer: Renderer {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var endObserver: NSObjectProtocol?
    private var containerView: NSView?
    
    func start(in containerView: NSView) async -> Result<Void, WallpaperError> {
        self.containerView = containerView
        
        let player = AVPlayer()
        self.player = player
        
        // Create and add layer
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        containerView.layer?.addSublayer(layer)
        self.playerLayer = layer
        
        // Add end-of-playback observer for looping
        self.endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
        
        player.play()
        return .success(())
    }
    
    func dispose() async {
        // 1. Stop playback
        player?.pause()
        
        // 2. Remove observer
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
            endObserver = nil
        }
        
        // 3. Remove layer from hierarchy
        if let layer = playerLayer {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer.removeFromSuperlayer()
            CATransaction.commit()
            playerLayer = nil
        }
        
        // 4. Release player
        player = nil
        containerView = nil
    }
    
    deinit {
        // Ensure cleanup even if dispose() wasn't called
        if player != nil {
            logger.warning("VideoRenderer deallocated without explicit dispose()")
            // Emergency cleanup
            player?.pause()
            playerLayer?.removeFromSuperlayer()
        }
    }
}
```

#### **DisplayController Lifecycle**

```swift
class DisplayController {
    deinit {
        logger.debug("DisplayController for display \(displayID) deallocating")
        
        // 1. Stop renderer
        if let renderer = renderer {
            Task {
                await renderer.dispose()
            }
        }
        renderer = nil
        
        // 2. Remove and release window
        if let window = window {
            window.orderOut(nil)
            window.close()
        }
        window = nil
        
        // 3. Cancel pending operations
        resizeObserver = nil
        
        // 4. Clean up content view
        contentView?.layer?.sublayers?.removeAll()
        contentView = nil
    }
}
```

---

## Environment Setup

### Prerequisites Verification

Before starting, verify your system is ready:

```bash
# macOS version (need 12.0+)
sw_vers -productVersion

# Disk space check (need 20+ GB free)
df -h / | tail -1

# RAM check
vm_stat | grep "Pages free"
```

### 1. Install and Verify Xcode

1. **Install Xcode:**
   - Download from Mac App Store (recommended)
   - Alternative: https://developer.apple.com/download (requires Apple Developer account)
   - First launch may take 15-30 minutes as it installs components

2. **Verify Command-Line Tools:**
   ```bash
   xcode-select -p
   # Should output: /Applications/Xcode.app/Contents/Developer
   
   # Verify Swift compiler
   xcrun -f swift
   # Should output path to swift binary
   
   # Verify sourcekit-lsp
   xcrun -f sourcekit-lsp
   # Should output path to sourcekit-lsp binary
   
   # Verify git
   git --version
   # Should show git 2.x or higher
   ```

3. **If any command fails:**
   ```bash
   xcode-select --install
   sudo xcode-select --reset
   ```

### 2. Install VSCode Insiders

1. Download VSCode Insiders from https://code.visualstudio.com/insiders/
2. Move to /Applications folder
3. Launch once to initialize settings
4. Configure shell:
   ```bash
   code-insiders --help  # Verify CLI works
   ```

### 3. VSCode Extensions Setup

#### **Required Extensions**

Install in VSCode (Cmd+Shift+X):

1. **Swift (Modern, as of 2026)**
   - Identifier: `swiftlang.swift-lang` (or `vknabel.vscode-swift-development-environment`)
   - Provides: IntelliSense, error checking, formatting
   - Backed by: sourcekit-lsp

2. **CodeLLDB**
   - Identifier: `vadimcn.vscode-lldb`
   - Provides: Debugging support for Swift binaries

3. **GitLens**
   - Identifier: `eamodio.gitlens`
   - Provides: Git history, blame, authorship

#### **Configuration: Swift Extension**

VSCode Settings (Cmd+, then search for "Swift"):

```json
{
  "sourcekit-lsp.serverPath": "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp",
  "sourcekit-lsp.trace.server": "off",
  "swift.format.formatOnSave": true,
  "swift.formatting.lineLength": 120,
  "swift.linting.strict": true,
  "[swift]": {
    "editor.defaultFormatter": "swiftlang.swift-lang",
    "editor.formatOnSave": true
  }
}
```

#### **Configuration: Terminal**

Ensure VSCode terminal uses login shell (important for PATH):

```json
{
  "terminal.integrated.defaultProfile.osx": "zsh",
  "terminal.integrated.shellArgs.osx": ["-l"]
}
```

Test in VSCode terminal (Ctrl+`):
```bash
echo $PATH
which swift
which xcodebuild
```

All commands should resolve correctly.

### 4. Git Configuration

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# For SSH (recommended over HTTPS)
ssh-keygen -t ed25519 -C "your.email@example.com"
# Add public key to GitHub: https://github.com/settings/keys
ssh -T git@github.com  # Test connection
```

---

## Project Structure & Build Strategy

### Option A: Xcode App Project (Recommended)

**Pros:**
- Simple initial setup; Xcode generates app bundle
- Full AppKit integration without custom scripts
- Built-in asset management
- Easier code signing and notarization later

**Cons:**
- `.pbxproj` files complex and prone to merge conflicts
- Occasional need to reopen Xcode

**Recommended for:** This project

### Option B: Swift Package + Thin Xcode Wrapper

**Pros:**
- Text-based `.swift` files (merge-friendly)
- Pure Swift, minimal Xcode involvement
- Better for library distribution

**Cons:**
- More manual build configuration
- Asset management complex

**Recommended for:** Large teams, code sharing emphasis

### Choosing: Option A (Recommended Path)

We will use **Option A** for this project. Follow these steps:

1. Open Xcode
2. File > New > Project
3. Select "macOS" > "App"
4. Configure:
   - **Product Name:** `PersonalWallpaperEngine`
   - **Team:** None (local only)
   - **Organization Identifier:** `com.local` (doesn't matter for local)
   - **Language:** Swift
   - **Interface:** SwiftUI
   - **Lifecycle:** SwiftUI App

5. Choose save location and create project
6. Close Xcode
7. Open in VSCode:
   ```bash
   code-insiders /path/to/PersonalWallpaperEngine
   ```

### Project File Organization

```
PersonalWallpaperEngine/
├── PersonalWallpaperEngine/
│   ├── PersonalWallpaperEngineApp.swift       # @main entry point
│   ├── ContentView.swift                       # Main UI (configuration)
│   ├── WallpaperManager.swift                  # Actor, orchestrator
│   ├── DisplayController.swift                 # Per-display window management
│   ├── Renderer.swift                          # Protocol definition
│   ├── VideoRenderer.swift                     # AVPlayer implementation
│   ├── WebRenderer.swift                       # WKWebView implementation (Phase 1.5)
│   ├── SettingsStore.swift                     # UserDefaults wrapper
│   └── Assets.xcassets/                        # Images, colors
├── PersonalWallpaperEngine.xcodeproj/
│   ├── project.pbxproj                         # Project file (managed by Xcode)
│   └── project.xcworkspace/                    # Workspace
├── .vscode/
│   ├── settings.json                           # VSCode workspace settings
│   ├── tasks.json                              # Build tasks
│   └── launch.json                             # Debugging configuration
├── .gitignore                                   # Git ignore rules
└── README.md                                    # Project documentation
```

### VSCode Tasks Configuration

Create `.vscode/tasks.json`:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Build (Debug)",
      "type": "shell",
      "command": "xcodebuild",
      "args": [
        "-project",
        "PersonalWallpaperEngine.xcodeproj",
        "-scheme",
        "PersonalWallpaperEngine",
        "-configuration",
        "Debug",
        "-destination",
        "platform=macOS",
        "build"
      ],
      "group": {
        "kind": "build",
        "isDefault": true
      },
      "problemMatcher": "$msCompile",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "panel": "shared"
      }
    },
    {
      "label": "Run (Debug)",
      "type": "shell",
      "command": "xcodebuild",
      "args": [
        "-project",
        "PersonalWallpaperEngine.xcodeproj",
        "-scheme",
        "PersonalWallpaperEngine",
        "-configuration",
        "Debug",
        "-destination",
        "platform=macOS",
        "run"
      ],
      "group": "test",
      "dependsOn": "Build (Debug)",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "panel": "shared"
      }
    },
    {
      "label": "Clean",
      "type": "shell",
      "command": "xcodebuild",
      "args": [
        "-project",
        "PersonalWallpaperEngine.xcodeproj",
        "-scheme",
        "PersonalWallpaperEngine",
        "clean"
      ],
      "problemMatcher": []
    }
  ]
}
```

To build: `Cmd+Shift+B` (or Terminal > Run Task > Build)
To run: `Cmd+Shift+P` > Tasks: Run Task > Run (Debug)

### VSCode Debug Configuration

Create `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug Wallpaper Engine",
      "type": "lldb",
      "request": "launch",
      "program": "${workspaceFolder}/build/Debug/PersonalWallpaperEngine.app/Contents/MacOS/PersonalWallpaperEngine",
      "args": [],
      "cwd": "${workspaceFolder}",
      "stopOnEntry": false,
      "console": "integratedTerminal",
      "preLaunchTask": "Build (Debug)"
    }
  ]
}
```

---

## Git & GitHub Integration

### 1. Initialize Local Repository

In project root (VSCode terminal):

```bash
git init

# Create .gitignore for Xcode/Swift
cat > .gitignore << 'EOF'
# Xcode
DerivedData/
*.pbxuser
*.mode1v3
*.mode2v3
*.perspectivev3
*.xcworkspace/xcuserdata
*.xcodeproj/xcuserdata
xcuserdata/
build/
*.app

# Swift
.build/
*.swiftpm

# macOS
.DS_Store
.AppleDouble
.LSOverride

# VS Code
.vscode/
EOF

git add .
git commit -m "Initial project structure with architecture documentation"
```

### 2. Connect to GitHub

1. Create empty repository on GitHub (no README, no .gitignore)
2. Copy repository URL (HTTPS or SSH)
3. In VSCode terminal:

```bash
git remote add origin git@github.com:yourusername/personal-wallpaper-engine.git
git branch -M main
git push -u origin main
```

### 3. Regular Workflow

In VSCode Source Control panel (Cmd+Shift+G):

- Stage changes (or use `git add`)
- Write commit messages
- Commit (Cmd+Enter)
- Push to GitHub (pull request for new features)
- Pull latest changes before starting work

---

## Step-by-Step Implementation

### Step 1: App Entry Point

Create `PersonalWallpaperEngineApp.swift`:

```swift
import SwiftUI

@main
struct PersonalWallpaperEngineApp: App {
    @State private var wallpaperManager: WallpaperManager?
    @State private var settingsStore: SettingsStore
    
    init() {
        _settingsStore = State(initialValue: SettingsStore())
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsStore)
                .onAppear {
                    // Initialize wallpaper manager
                    Task {
                        wallpaperManager = await WallpaperManager()
                        
                        // Start monitoring displays
                        await wallpaperManager?.startMonitoring()
                    }
                }
                .onDisappear {
                    // Cleanup
                    Task {
                        await wallpaperManager?.stop()
                    }
                }
        }
    }
}
```

### Step 2: WallpaperManager Implementation

Create `WallpaperManager.swift`:

```swift
import AppKit
import os.log

actor WallpaperManager: ObservableObject {
    @Published var displayControllers: [CGDirectDisplayID: DisplayController] = [:]
    @Published var currentWallpaperURL: URL?
    @Published var errorMessage: String?
    
    private let logger = Logger(subsystem: "com.local.wallpaper", category: "WallpaperManager")
    private var screenChangeTask: Task<Void, Never>?
    private var spaceChangeTask: Task<Void, Never>?
    
    nonisolated init() { }
    
    func startMonitoring() async {
        // Observe screen changes
        screenChangeTask = Task {
            for await _ in NSScreen.screensDidChangeNotifications() {
                await handleScreenChange()
            }
        }
        
        // Observe space changes
        spaceChangeTask = Task {
            for await _ in NSWorkspace.activeSpaceDidChangeNotifications() {
                await handleSpaceChange()
            }
        }
        
        // Initial display setup
        await handleScreenChange()
    }
    
    func handleScreenChange() async {
        logger.debug("Screen configuration changed")
        
        let currentScreens = NSScreen.screens
        let currentDisplayIDs = Set(currentScreens.compactMap { $0.displayID })
        let existingDisplayIDs = Set(displayControllers.keys)
        
        // Remove controllers for disconnected screens
        for disconnectedID in existingDisplayIDs.subtracting(currentDisplayIDs) {
            if let controller = displayControllers.removeValue(forKey: disconnectedID) {
                await controller.stop()
                logger.debug("Display \(disconnectedID) disconnected")
            }
        }
        
        // Create controllers for new screens
        await withTaskGroup(
            of: (CGDirectDisplayID, Result<DisplayController, WallpaperError>).self
        ) { group in
            for screen in currentScreens {
                if !existingDisplayIDs.contains(screen.displayID) {
                    group.addTask {
                        let result = await self.createDisplayController(for: screen)
                        return (screen.displayID, result)
                    }
                }
            }
            
            for await (displayID, result) in group {
                switch result {
                case .success(let controller):
                    displayControllers[displayID] = controller
                    logger.debug("Display \(displayID) added")
                case .failure(let error):
                    errorMessage = error.errorDescription
                    logger.error("Failed to add display: \(error)")
                }
            }
        }
    }
    
    func handleSpaceChange() async {
        logger.debug("Active Space changed")
        // Reorder windows to back in new space
        for controller in displayControllers.values {
            await controller.orderToBack()
        }
    }
    
    private func createDisplayController(for screen: NSScreen) async -> Result<DisplayController, WallpaperError> {
        do {
            let controller = DisplayController(screen: screen, manager: self)
            if let url = currentWallpaperURL {
                let result = await controller.startPlayback(url: url)
                if case .failure(let error) = result {
                    return .failure(error)
                }
            }
            return .success(controller)
        } catch {
            return .failure(.windowCreationFailed(reason: error.localizedDescription))
        }
    }
    
    func setWallpaper(url: URL) async -> Result<Void, WallpaperError> {
        // Validate file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            return .failure(.videoFileNotFound(path: url.path))
        }
        
        currentWallpaperURL = url
        
        // Start playback on all displays
        for controller in displayControllers.values {
            let result = await controller.startPlayback(url: url)
            if case .failure(let error) = result {
                errorMessage = error.errorDescription
                return .failure(error)
            }
        }
        
        return .success(())
    }
    
    func stop() async {
        screenChangeTask?.cancel()
        spaceChangeTask?.cancel()
        
        for controller in displayControllers.values {
            await controller.stop()
        }
        
        displayControllers.removeAll()
    }
}

// MARK: - Notification Extensions

extension NSScreen {
    nonisolated static func screensDidChangeNotifications() -> AsyncStream<Void> {
        AsyncStream { continuation in
            let observer = NotificationCenter.default.addObserver(
                forName: NSScreen.screensDidChangeNotification,
                object: nil,
                queue: .main
            ) { _ in
                continuation.yield()
            }
            
            continuation.onTermination = { _ in
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}

extension NSWorkspace {
    nonisolated static func activeSpaceDidChangeNotifications() -> AsyncStream<Void> {
        AsyncStream { continuation in
            let observer = NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.activeSpaceDidChangeNotification,
                object: nil,
                queue: .main
            ) { _ in
                continuation.yield()
            }
            
            continuation.onTermination = { _ in
                NSWorkspace.shared.notificationCenter.removeObserver(observer)
            }
        }
    }
}
```

### Step 3: DisplayController Implementation

Create `DisplayController.swift`:

```swift
import AppKit
import os.log

class DisplayController {
    private let logger = Logger(subsystem: "com.local.wallpaper", category: "DisplayController")
    private let screen: NSScreen
    private weak var manager: WallpaperManager?
    
    private var window: NSWindow?
    private var contentView: NSView?
    private var renderer: Renderer?
    
    var displayID: CGDirectDisplayID {
        screen.displayID
    }
    
    init(screen: NSScreen, manager: WallpaperManager?) {
        self.screen = screen
        self.manager = manager
        setupWindow()
    }
    
    private func setupWindow() {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.isOpaque = true
        window.backgroundColor = .black
        window.ignoresMouseEvents = true
        
        // Set desktop-level window
        let desktopLevel = CGWindowLevelForKey(.desktopWindow)
        window.level = NSWindow.Level(rawValue: Int(desktopLevel))
        
        // Prevent keyboard and mouse input
        window.canBecomeKey = false
        window.canBecomeMain = false
        
        // Create content view
        let contentView = NSView(frame: window.frame)
        window.contentView = contentView
        
        // Set collection behavior for spaces
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        window.orderBack(nil)
        
        self.window = window
        self.contentView = contentView
    }
    
    func startPlayback(url: URL) async -> Result<Void, WallpaperError> {
        guard let contentView = contentView else {
            return .failure(.windowCreationFailed(reason: "No content view"))
        }
        
        let renderer = VideoRenderer()
        let result = await renderer.start(in: contentView)
        
        if case .success = result {
            self.renderer = renderer
            window?.orderBack(nil)
        }
        
        return result
    }
    
    func stop() async {
        if let renderer = renderer {
            await renderer.dispose()
        }
        renderer = nil
        
        window?.orderOut(nil)
        window = nil
        contentView = nil
    }
    
    func orderToBack() async {
        window?.orderBack(nil)
    }
    
    deinit {
        logger.debug("DisplayController deallocating for display \(displayID)")
        Task {
            await stop()
        }
    }
}
```

### Step 4: Renderer Protocol and VideoRenderer

Create `Renderer.swift`:

```swift
import AppKit

protocol Renderer: AnyObject {
    func start(in containerView: NSView) async -> Result<Void, WallpaperError>
    func stop() async
    func pause() async
    func resume() async
    func resize(to newSize: CGSize) async
    func dispose() async
}
```

Create `VideoRenderer.swift`:

```swift
import AppKit
import AVFoundation
import os.log

class VideoRenderer: Renderer {
    private let logger = Logger(subsystem: "com.local.wallpaper", category: "VideoRenderer")
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var containerView: NSView?
    private var endObserver: NSObjectProtocol?
    
    func start(in containerView: NSView) async -> Result<Void, WallpaperError> {
        self.containerView = containerView
        
        let player = AVPlayer()
        player.isMuted = true
        self.player = player
        
        // Create and add layer
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        layer.frame = containerView.bounds
        
        if let contentLayer = containerView.layer {
            contentLayer.addSublayer(layer)
        }
        self.playerLayer = layer
        
        // Add end-of-playback observer for looping
        self.endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }
        
        player.play()
        logger.debug("VideoRenderer started")
        return .success(())
    }
    
    func stop() async {
        player?.pause()
        logger.debug("VideoRenderer stopped")
    }
    
    func pause() async {
        player?.pause()
    }
    
    func resume() async {
        player?.play()
    }
    
    func resize(to newSize: CGSize) async {
        playerLayer?.frame = CGRect(origin: .zero, size: newSize)
    }
    
    func dispose() async {
        // 1. Stop playback
        player?.pause()
        
        // 2. Remove observer
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
            endObserver = nil
        }
        
        // 3. Remove layer
        if let layer = playerLayer {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer.removeFromSuperlayer()
            CATransaction.commit()
            playerLayer = nil
        }
        
        // 4. Release player
        player = nil
        containerView = nil
        
        logger.debug("VideoRenderer disposed")
    }
    
    deinit {
        if player != nil {
            logger.warning("VideoRenderer deallocated without explicit dispose()")
        }
    }
}
```

### Step 5: SettingsStore Implementation

Create `SettingsStore.swift`:

```swift
import Foundation
import Observation

@Observable
final class SettingsStore {
    var videoFilePath: String = "" {
        didSet {
            UserDefaults.standard.set(videoFilePath, forKey: "videoPath")
        }
    }
    
    var scalingMode: VideoScalingMode = .resizeAspectFill {
        didSet {
            UserDefaults.standard.set(scalingMode.rawValue, forKey: "scalingMode")
        }
    }
    
    var isMuted: Bool = true {
        didSet {
            UserDefaults.standard.set(isMuted, forKey: "isMuted")
        }
    }
    
    init() {
        videoFilePath = UserDefaults.standard.string(forKey: "videoPath") ?? ""
        scalingMode = VideoScalingMode(
            rawValue: UserDefaults.standard.string(forKey: "scalingMode") ?? ""
        ) ?? .resizeAspectFill
        isMuted = UserDefaults.standard.bool(forKey: "isMuted")
    }
}

enum VideoScalingMode: String {
    case resizeAspectFill = "resizeAspectFill"
    case resizeAspect = "resizeAspect"
    case resizeAspectHeight = "resizeAspectHeight"
}
```

### Step 6: Error Handling

Create `Errors.swift`:

```swift
import Foundation

enum WallpaperError: LocalizedError, Equatable {
    case videoFileNotFound(path: String)
    case videoDecodingFailed(url: URL, reason: String)
    case windowCreationFailed(reason: String)
    case rendererInitializationFailed(reason: String)
    case screenNotFound(id: CGDirectDisplayID)
    case permissionDenied(resource: String)
    case internalError(description: String)
    
    var errorDescription: String? {
        switch self {
        case .videoFileNotFound(let path):
            return "Video file not found at: \(path)"
        case .videoDecodingFailed(let url, let reason):
            return "Unable to decode video '\(url.lastPathComponent)': \(reason)"
        case .windowCreationFailed(let reason):
            return "Failed to create desktop window: \(reason)"
        case .rendererInitializationFailed(let reason):
            return "Renderer setup failed: \(reason)"
        case .screenNotFound(let id):
            return "Display \(id) not found"
        case .permissionDenied(let resource):
            return "Permission denied: \(resource)"
        case .internalError(let description):
            return "Internal error: \(description)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .videoFileNotFound:
            return "Check that the file path is correct and the file exists."
        case .videoDecodingFailed:
            return "Ensure the video format is supported (MP4 or MOV) and not corrupted."
        case .windowCreationFailed:
            return "Restart the application and check system resources."
        case .rendererInitializationFailed:
            return "Check available system resources and try again."
        case .screenNotFound:
            return "Reconnect the display or restart the application."
        case .permissionDenied:
            return "Grant the necessary permissions in System Preferences."
        case .internalError:
            return "Contact support with application logs."
        }
    }
    
    static func == (lhs: WallpaperError, rhs: WallpaperError) -> Bool {
        switch (lhs, rhs) {
        case (.videoFileNotFound(let lhsPath), .videoFileNotFound(let rhsPath)):
            return lhsPath == rhsPath
        case (.windowCreationFailed(let lhsReason), .windowCreationFailed(let rhsReason)):
            return lhsReason == rhsReason
        default:
            return false
        }
    }
}
```

### Step 7: UI Configuration (ContentView)

Create `ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settings: SettingsStore
    @State private var showFileDialog = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Wallpaper Configuration")
                .font(.title)
            
            Section("Video") {
                HStack {
                    Text("Selected Video:")
                    Text(settings.videoFilePath.isEmpty ? "None" : settings.videoFilePath)
                        .lineLimit(1)
                    
                    Button("Select...") {
                        showFileDialog = true
                    }
                }
            }
            
            Section("Audio") {
                Toggle("Muted", isOn: $settings.isMuted)
            }
            
            Section("Scaling") {
                Picker("Scale Mode", selection: $settings.scalingMode) {
                    Text("Fill").tag(VideoScalingMode.resizeAspectFill)
                    Text("Fit").tag(VideoScalingMode.resizeAspect)
                    Text("Stretch").tag(VideoScalingMode.resizeAspectHeight)
                }
            }
            
            Spacer()
        }
        .padding()
        .fileImporter(
            isPresented: $showFileDialog,
            allowedContentTypes: [.video],
            onCompletion: handleFileSelection
        )
    }
    
    private func handleFileSelection(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            settings.videoFilePath = url.path
        case .failure(let error):
            print("Error selecting file: \(error)")
        }
    }
}
```

---

## Production Testing Checklist

Before considering the application production-ready, complete this comprehensive testing:

### 1. Single Display Testing
- [ ] App launches without crashes
- [ ] Desktop window appears behind icons
- [ ] Video playback begins automatically
- [ ] Video plays smoothly (no stuttering)
- [ ] CPU usage <10%, GPU <2% when idle
- [ ] Audio muting works correctly
- [ ] Wallpaper window doesn't respond to clicks
- [ ] Space/Mission Control doesn't affect playback
- [ ] Resolution changes (external monitor) handled gracefully
- [ ] App closes cleanly without zombie processes

### 2. Multi-Display Testing
- [ ] Video plays simultaneously on all connected displays
- [ ] Each display shows correct scaling
- [ ] Adding external display creates new window
- [ ] Removing external display stops playback on that display gracefully
- [ ] Switching between internal/external primary display works
- [ ] Different videos on different displays (if UI added)

### 3. Virtual Desktop (Spaces) Testing
- [ ] Wallpaper appears on all Spaces
- [ ] Mission Control shows wallpaper in thumbnail
- [ ] Switching Spaces maintains playback
- [ ] Fullscreen apps show over wallpaper correctly

### 4. Lifecycle Testing
- [ ] App launch time <3 seconds
- [ ] Screen lock pauses playback
- [ ] Screen unlock resumes playback
- [ ] Quit app -> reopen app preserves settings
- [ ] No memory leaks after 1 hour of continuous playback
- [ ] No file handles left open after playback stops

### 5. Error Handling Testing
- [ ] Missing video file shows user-friendly error
- [ ] Corrupted video file shows appropriate error
- [ ] Unsupported video format rejected with guidance
- [ ] Recovered from error by selecting valid video
- [ ] Error messages don't crash app

### 6. Performance Testing (Use Instruments)
- [ ] Allocations: <100MB heap at idle
- [ ] System Trace: <5% CPU sustained
- [ ] Core Animation: Frame rate maintained at 60fps
- [ ] Energy: Battery drain <2% per hour on MacBook

### 7. Stress Testing
- [ ] Rapid Space switching doesn't crash
- [ ] Repeated display connect/disconnect
- [ ] Long video file (2+ hours) plays correctly
- [ ] 4K resolution video plays smoothly

---

## Troubleshooting & Performance

### Common Issues and Solutions

| Issue | Symptom | Solution |
|-------|---------|----------|
| Window doesn't appear | Wallpaper not visible | Verify `CGWindowLevelForKey(.desktopWindow)`, check `orderBack(nil)` called |
| High CPU usage | 25%+ CPU | Check video codec (use H.264), reduce resolution, check for infinite loops in render |
| Stuttering playback | Video jerky/choppy | Reduce file size, ensure hardware supports codec, close other apps |
| Memory leak | RAM increases over time | Run Allocations instrument, check for retained observers/layers |
| Space switching breaks | Wallpaper vanishes on Space change | Verify `NSWindow.CollectionBehavior.canJoinAllSpaces` set, fix Space change handler |

### Performance Optimization Tips

1. **Video Codec:** Use H.264 (hardware-accelerated). Avoid VP9, AV1.
2. **Resolution:** Match display resolution; avoid up-scaling.
3. **Frame Rate:** Use 30fps or 60fps. Higher doesn't improve perceived quality for wallpapers.
4. **File Size:** Keep under 500MB for responsive seeks.
5. **Hardware:** Test on various Mac models (MacBook Air, Mac mini, iMac).

### Debug Logging

Enable debug logging for troubleshooting:

```swift
// Set environment variable: LOGLEVEL=DEBUG
import os.log

let logger = Logger(subsystem: "com.local.wallpaper", category: "Component")
logger.debug("Debug message")
logger.error("Error message")

// View logs in Console.app: System Log
```

---

## References

1. [Apple AVFoundation Documentation](https://developer.apple.com/documentation/avfoundation)
2. [NSWindow Desktop Level Management](https://jameshfisher.com/2020/08/03/what-is-the-order-of-nswindow-levels/)
3. [macOS Wallpaper Implementation Details](https://stackoverflow.com/questions/4982584/how-do-i-draw-the-desktop-on-mac-os-x)
4. [Swift Structured Concurrency (Swift.org)](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency)
5. [sourcekit-lsp Configuration](https://github.com/apple/sourcekit-lsp)
6. [VSCode Swift Development](https://nshipster.com/vscode/)
7. [LiveWallpaperMacOS Reference Implementation](https://github.com/thusvill/LiveWallpaperMacOS)
8. [Wallpaper Play (Feature Reference)](https://github.com/nhiroyasu/wallpaper-play)

---

**End of Roadmap**

This production-ready roadmap provides everything needed to build a professional macOS wallpaper engine with proper error handling, resource management, and multi-display support using VSCode and Xcode's hybrid workflow.
