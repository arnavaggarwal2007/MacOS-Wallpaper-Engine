import SwiftUI

/// Phase 7: Unified display preview showing all connected displays and their wallpapers
/// Replaces per-display preview mode complexity with single view of all displays
struct UnifiedDisplayPreview: View {
    let displays: [DisplayWallpaperInfo]
    
    var body: some View {
        if displays.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "display.2")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
                
                Text("No Displays Connected")
                    .font(DesignTokens.Typography.body)
                    .fontWeight(.semibold)
                
                Text("Connect a display to see wallpaper status")
                    .font(DesignTokens.Typography.subtitle)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: 200)
            .background(DesignTokens.Colors.cardBackground)
            .cornerRadius(DesignTokens.Corner.radius)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Corner.radius)
                    .stroke(DesignTokens.Colors.cardBorder, lineWidth: 1)
            )
        } else if displays.count == 1 {
            singleDisplayPreview(displays[0])
        } else {
            multipleDisplaysPreview()
        }
    }
    
    @ViewBuilder
    private func singleDisplayPreview(_ display: DisplayWallpaperInfo) -> some View {
        displayCard(display)
    }
    
    @ViewBuilder
    private func multipleDisplaysPreview() -> some View {
        VStack(spacing: 12) {
            // Grid layout for multiple displays (2 columns, 2 rows max)
            let gridLayout = [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ]
            
            LazyVGrid(columns: gridLayout, spacing: 12) {
                ForEach(displays) { display in
                    displayCard(display)
                }
            }
        }
    }
    
    @ViewBuilder
    private func displayCard(_ display: DisplayWallpaperInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Display header
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(display.displayName)
                            .font(DesignTokens.Typography.body)
                            .fontWeight(.semibold)
                        
                        if display.isPrimary {
                            Text("Primary")
                                .font(DesignTokens.Typography.subtitle)
                                .fontWeight(.semibold)
                                .padding(.vertical, 2)
                                .padding(.horizontal, 6)
                                .background(.blue.opacity(0.2))
                                .foregroundStyle(.blue)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text("\(Int(display.resolution.width))×\(Int(display.resolution.height))")
                        .font(DesignTokens.Typography.subtitle)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // Wallpaper thumbnail
            if let wallpaperURL = display.wallpaperURL {
                ZStack(alignment: .bottomLeading) {
                    if let previewImage = previewImageForURL(wallpaperURL) {
                        Image(nsImage: previewImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 120)
                            .clipped()
                            .cornerRadius(6)
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(DesignTokens.Colors.cardBackground)
                            .frame(height: 120)
                            .overlay(
                                Image(systemName: "photo.fill")
                                    .foregroundStyle(.secondary)
                            )
                    }
                    
                    // Metadata overlay
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: display.rendererMode == .web ? "globe" : "film")
                                .font(.caption)
                            Text(display.rendererMode.displayName)
                                .font(DesignTokens.Typography.subtitle)
                                .fontWeight(.semibold)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(.black.opacity(0.5))
                        .foregroundStyle(.white)
                        .cornerRadius(4)
                    }
                    .padding(8)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "photo.slash")
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary)
                    
                    Text("No Wallpaper")
                        .font(DesignTokens.Typography.subtitle)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .background(DesignTokens.Colors.cardBackground)
                .cornerRadius(6)
            }
            
            // Scaling mode indicator
            HStack(spacing: 6) {
                Image(systemName: "aspectratio")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(display.scalingMode.displayName)
                    .font(DesignTokens.Typography.subtitle)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(DesignTokens.Colors.cardBackground)
        .cornerRadius(DesignTokens.Corner.radius)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Corner.radius)
                .stroke(DesignTokens.Colors.cardBorder, lineWidth: 1)
        )
    }
    
    private func previewImageForURL(_ url: URL) -> NSImage? {
        let fileExtension = url.pathExtension.lowercased()
        if ["png", "jpg", "jpeg", "gif", "tiff", "bmp", "heic", "webp"].contains(fileExtension),
           let image = NSImage(contentsOf: url), image.size != .zero {
            return image
        }
        
        if let image = NSImage(contentsOf: url), image.size != .zero {
            return image
        }
        
        return nil
    }
}

#Preview {
    UnifiedDisplayPreview(displays: [])
        .padding()
}
