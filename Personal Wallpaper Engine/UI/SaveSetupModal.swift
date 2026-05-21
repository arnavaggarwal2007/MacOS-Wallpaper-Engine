import SwiftUI

/// Modal for saving the current wallpaper engine state as a named setup
struct SaveSetupModal: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var setupName: String = ""
    @State private var setupDescription: String = ""
    @State private var isSaving: Bool = false
    @State private var showError: Bool = false
    @State private var errorTitle: String = ""
    @State private var errorMessage: String = ""
    
    var isValid: Bool {
        !setupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Save Current Setup")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Capture the current wallpaper engine configuration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            // Form Fields
            VStack(alignment: .leading, spacing: 12) {
                // Setup Name
                VStack(alignment: .leading, spacing: 6) {
                    Label("Setup Name", systemImage: "tag.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    TextField("e.g., Work Setup", text: $setupName)
                        .textFieldStyle(.roundedBorder)
                        .font(.body)
                }
                
                // Setup Description
                VStack(alignment: .leading, spacing: 6) {
                    Label("Description (optional)", systemImage: "note.text")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $setupDescription)
                        .frame(height: 80)
                        .font(.body)
                        .border(Color.gray.opacity(0.3), width: 1)
                        .cornerRadius(6)
                }
            }
            
            // Current State Summary
            VStack(alignment: .leading, spacing: 10) {
                Text("Current Configuration")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    // Renderer Mode
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Renderer")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(viewModel.rendererMode.rawValue.capitalized)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    Divider()
                    
                    // Scaling
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scaling")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(viewModel.scalingMode.rawValue.replacingOccurrences(of: "resizeAspect", with: "Aspect"))
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Displays")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(NSScreen.screens.count) connected")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                }
                .padding(10)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(6)
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isSaving)
                
                Button(action: saveSetup) {
                    if isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Save Setup")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid || isSaving)
            }
        }
        .padding(20)
        .frame(width: 400)
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveSetup() {
        isSaving = true
        Task { @MainActor in
            let result = await viewModel.saveCurrentStateAsSetup(
                name: setupName,
                description: setupDescription
            )
            
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                errorTitle = "Failed to Save Setup"
                errorMessage = error.errorDescription ?? "An unknown error occurred."
                showError = true
            }
            
            isSaving = false
        }
    }
}

#Preview {
    SaveSetupModal(viewModel: AppViewModel())
}
