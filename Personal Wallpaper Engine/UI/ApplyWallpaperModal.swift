import SwiftUI
import AppKit
import AVFoundation

/// Phase 7: Modal dialog for choosing wallpaper apply scope
/// Appears after user selects a wallpaper file (not from collection)
/// Allows user to apply to all displays or choose specific displays
struct ApplyWallpaperModal: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var appModel: AppViewModel
    
    let wallpaperURL: URL
    let availableDisplays: [DisplayWallpaperInfo]
    let onApply: ([CGDirectDisplayID]) -> Void
    
    @State private var selectedDisplayIDs: Set<CGDirectDisplayID> = []
    @State private var applyMode: ApplyMode = .all
    
    enum ApplyMode {
        case all
        case specific
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Apply Wallpaper")
                    .font(DesignTokens.Typography.subtitle)
                    .fontWeight(.semibold)
                
                Text("Choose which displays to apply this wallpaper to")
                    .font(DesignTokens.Typography.body)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Wallpaper preview
            HStack(spacing: 12) {
                if let previewImage = previewImageForURL(wallpaperURL) {
                    Image(nsImage: previewImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .cornerRadius(6)
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(DesignTokens.Colors.cardBackground)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "photo.fill")
                                .foregroundStyle(.secondary)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(wallpaperURL.lastPathComponent)
                        .font(DesignTokens.Typography.body)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Text(formatFileSize(wallpaperURL))
                        .font(DesignTokens.Typography.subtitle)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(12)
            .background(DesignTokens.Colors.cardBackground)
            .cornerRadius(DesignTokens.Corner.radius)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Corner.radius)
                    .stroke(DesignTokens.Colors.cardBorder, lineWidth: 1)
            )
            
            // Apply mode selection
            VStack(spacing: 12) {
                // All displays option
                Button(action: { applyMode = .all; selectedDisplayIDs.removeAll() }) {
                    HStack(spacing: 12) {
                        Image(systemName: applyMode == .all ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(applyMode == .all ? .blue : .secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Apply to All Displays")
                                .font(DesignTokens.Typography.body)
                                .fontWeight(.semibold)
                            Text("Sets \(availableDisplays.count) display\(availableDisplays.count == 1 ? "" : "s") to this wallpaper")
                                .font(DesignTokens.Typography.subtitle)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(applyMode == .all ? DesignTokens.Colors.cardBackground : .clear)
                    .cornerRadius(DesignTokens.Corner.radius)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Corner.radius)
                            .stroke(applyMode == .all ? DesignTokens.Colors.cardBorder : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                
                // Specific displays option
                VStack(spacing: 12) {
                    Button(action: { applyMode = .specific }) {
                        HStack(spacing: 12) {
                            Image(systemName: applyMode == .specific ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(applyMode == .specific ? .blue : .secondary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Choose Specific Displays")
                                    .font(DesignTokens.Typography.body)
                                    .fontWeight(.semibold)
                                Text("Select which displays to update")
                                    .font(DesignTokens.Typography.subtitle)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(12)
                        .background(applyMode == .specific ? DesignTokens.Colors.cardBackground : .clear)
                        .cornerRadius(DesignTokens.Corner.radius)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Corner.radius)
                                .stroke(applyMode == .specific ? DesignTokens.Colors.cardBorder : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Display checklist (shown when specific mode selected)
                    if applyMode == .specific {
                        VStack(spacing: 8) {
                            ForEach(availableDisplays, id: \.displayID) { display in
                                displayCheckbox(for: display)
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
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                
                Button(action: applyWallpaper) {
                    Text("Apply")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(applyMode == .specific && selectedDisplayIDs.isEmpty)
            }
        }
        .padding(20)
        .frame(minWidth: 480, idealWidth: 520, maxWidth: 600)
    }
    
    @ViewBuilder
    private func displayCheckbox(for display: DisplayWallpaperInfo) -> some View {
        Button(action: { toggleDisplay(display.displayID) }) {
            HStack(spacing: 12) {
                Image(systemName: selectedDisplayIDs.contains(display.displayID) ? "checkmark.square.fill" : "square")
                    .foregroundStyle(selectedDisplayIDs.contains(display.displayID) ? .blue : .secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(display.displayName)
                        .font(DesignTokens.Typography.body)
                        .fontWeight(.semibold)
                    Text("\(Int(display.resolution.width))×\(Int(display.resolution.height))")
                        .font(DesignTokens.Typography.subtitle)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if display.isPrimary {
                    Text("Primary")
                        .font(DesignTokens.Typography.subtitle)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(.blue.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            .padding(8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func toggleDisplay(_ displayID: CGDirectDisplayID) {
        if selectedDisplayIDs.contains(displayID) {
            selectedDisplayIDs.remove(displayID)
        } else {
            selectedDisplayIDs.insert(displayID)
        }
    }
    
    private func applyWallpaper() {
        let displayIDs: [CGDirectDisplayID]
        
        if applyMode == .all {
            displayIDs = availableDisplays.map { $0.displayID }
        } else {
            displayIDs = Array(selectedDisplayIDs)
        }
        
        onApply(displayIDs)
        dismiss()
    }
    
    private func previewImageForURL(_ url: URL) -> NSImage? {
        let fileExtension = url.pathExtension.lowercased()
        // Image files: load directly
        if ["png", "jpg", "jpeg", "gif", "tiff", "bmp", "heic", "webp"].contains(fileExtension),
           let image = NSImage(contentsOf: url), image.size != .zero {
            return image
        }

        // For video files, try to generate a thumbnail
        if ["mp4", "mov", "avi", "webm"].contains(fileExtension) {
            let asset = AVURLAsset(url: url)
            let imgGen = AVAssetImageGenerator(asset: asset)
            imgGen.appliesPreferredTrackTransform = true
            imgGen.maximumSize = CGSize(width: 320, height: 180)
            let requestedTime = NSValue(time: CMTime(seconds: 1.0, preferredTimescale: 600))
            let semaphore = DispatchSemaphore(value: 0)
            var generatedImage: NSImage?
            imgGen.generateCGImagesAsynchronously(forTimes: [requestedTime]) { _, cgImage, _, result, _ in
                defer { semaphore.signal() }
                guard result == .succeeded, let cgImage else { return }
                generatedImage = NSImage(
                    cgImage: cgImage,
                    size: NSSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
                )
            }
            semaphore.wait()
            if let generatedImage { return generatedImage }
        }

        // Fallback: try to load as image
        if let image = NSImage(contentsOf: url), image.size != .zero {
            return image
        }

        return nil
    }
    
    private func formatFileSize(_ url: URL) -> String {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int64 else {
            return "Unknown"
        }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

#Preview {
    ApplyWallpaperModal(
        wallpaperURL: URL(fileURLWithPath: "/Users/test/wallpaper.mp4"),
        availableDisplays: [],
        onApply: { _ in }
    )
    .environmentObject(AppViewModel())
}
