import Foundation
import CoreGraphics

/// Phase 7: Data model for display wallpaper state
struct DisplayWallpaperInfo: Identifiable {
    let displayID: CGDirectDisplayID
    let displayName: String              // e.g., "Built-in Retina", "LG 4K"
    let resolution: CGSize
    let wallpaperURL: URL?               // Current wallpaper
    let rendererMode: WallpaperRendererMode       // Video or Web
    let scalingMode: VideoScalingMode    // Fit, Fill, Stretch, etc.
    let isPrimary: Bool
    
    var id: CGDirectDisplayID { displayID }
}
