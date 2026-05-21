import SwiftUI
import AppKit

/// Modal presented after file picker to allow user to select which displays to apply wallpaper to.
/// Supports both "Apply to All" quick action and "Select Specific" for granular control.
struct DisplaySelectionModal: View {
    let videoURL: URL
    @Environment(\.dismiss) var dismiss
    @ObservedObject var appModel: AppViewModel
    
    @State private var selectedDisplayIDs: Set<CGDirectDisplayID> = []
    @State private var isApplying = false
    
    private var displayOptions: [NSScreen] {
        NSScreen.screens.sorted { screen1, screen2 in
            screen1.frame.origin.x < screen2.frame.origin.x
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Displays")
                    .font(DesignTokens.Typography.title)
                    .fontWeight(.semibold)
                
                Text("Choose which displays this wallpaper should be applied to")
                    .font(DesignTokens.Typography.subtitle)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            
            // Quick actions
            VStack(alignment: .leading, spacing: 12) {
                Button(action: selectAllDisplays) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Apply to All Displays")
                                .font(DesignTokens.Typography.subtitle)
                                .fontWeight(.semibold)
                            Text("Set the same wallpaper on every connected display")
                                .font(DesignTokens.Typography.subtitle)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background {
                        RoundedRectangle(cornerRadius: DesignTokens.Corner.radius, style: .continuous)
                            .fill(DesignTokens.Colors.cardBackground)
                            .overlay {
                                RoundedRectangle(cornerRadius: DesignTokens.Corner.radius, style: .continuous)
                                    .stroke(DesignTokens.Colors.primary.opacity(0.3), lineWidth: 1.5)
                            }
                    }
                }
                .buttonStyle(.plain)
                
                Divider()
                    .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Specific Displays")
                        .font(DesignTokens.Typography.subtitle)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(displayOptions, id: \.displayID) { screen in
                            let isSelected = selectedDisplayIDs.contains(screen.displayID)
                            
                            Button(action: { toggleDisplay(screen.displayID) }) {
                                HStack(spacing: 12) {
                                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                                        .font(.title3)
                                        .foregroundColor(isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.textSecondary)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(screen.localizedName)
                                            .font(DesignTokens.Typography.subtitle)
                                            .fontWeight(.medium)
                                        
                                        Text("Resolution: \(Int(screen.frame.width))×\(Int(screen.frame.height))")
                                            .font(DesignTokens.Typography.subtitle)
                                            .foregroundColor(DesignTokens.Colors.textSecondary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(10)
                                .background {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(isSelected ? DesignTokens.Colors.primary.opacity(0.1) : Color.clear)
                                }
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(isSelected ? DesignTokens.Colors.primary.opacity(0.3) : Color.clear, lineWidth: 1)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: DesignTokens.Corner.radius, style: .continuous)
                    .fill(DesignTokens.Colors.cardBackground)
                    .opacity(0.5)
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(DesignTokens.Typography.subtitle)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button(action: applyToSelectedDisplays) {
                    if isApplying {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Text("Apply")
                            .font(DesignTokens.Typography.subtitle)
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(selectedDisplayIDs.isEmpty || isApplying)
            }
        }
        .padding(24)
        .frame(minWidth: 420, minHeight: 500)
        .onAppear {
            // Pre-select all displays by default
            selectedDisplayIDs = Set(displayOptions.map { $0.displayID })
        }
    }
    
    private func selectAllDisplays() {
        selectedDisplayIDs = Set(displayOptions.map { $0.displayID })
        applyToSelectedDisplays()
    }
    
    private func toggleDisplay(_ displayID: CGDirectDisplayID) {
        if selectedDisplayIDs.contains(displayID) {
            selectedDisplayIDs.remove(displayID)
        } else {
            selectedDisplayIDs.insert(displayID)
        }
    }
    
    private func applyToSelectedDisplays() {
        guard !selectedDisplayIDs.isEmpty else { return }
        
        isApplying = true
        
        Task { @MainActor in
            let displayIDArray = Array(selectedDisplayIDs).sorted()
            await appModel.selectVideoForDisplays(url: videoURL, displayIDs: displayIDArray)
            
            isApplying = false
            dismiss()
        }
    }
}

#Preview {
    DisplaySelectionModal(
        videoURL: URL(fileURLWithPath: "/path/to/video.mp4"),
        appModel: AppViewModel()
    )
}
