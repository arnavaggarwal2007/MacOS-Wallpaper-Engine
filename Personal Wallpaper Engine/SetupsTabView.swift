import SwiftUI

/// Dedicated tab for saving and restoring full desktop state snapshots.
struct SetupsTabView: View {
    @EnvironmentObject private var appModel: AppViewModel
    @State private var isSaveSetupModalPresented = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
                TabHeaderView(
                    title: "Setups",
                    subtitle: "Save and restore full desktop wallpaper configurations.",
                    systemImage: "square.and.arrow.down.fill"
                )

                let setupNames = appModel.allSetupNames()
                let selectedSetup = appModel.selectedSetupName.flatMap { appModel.savedSetups[$0] }

                GlassCardView {
                    HStack(spacing: 10) {
                        Button(action: { isSaveSetupModalPresented = true }) {
                            Label("Save Current Setup", systemImage: "square.and.arrow.down.fill")
                        }
                        .buttonStyle(.borderedProminent)

                        if let active = appModel.selectedSetupName {
                            Text("Active: \(active)")
                                .font(DesignTokens.Typography.subtitle)
                                .foregroundStyle(DesignTokens.Colors.textSecondary)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 0)
                    }
                }

                GlassCardView(title: "Saved Setups") {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "square.and.arrow.down")
                                            .foregroundStyle(.secondary)

                                        Text("\(setupNames.count) saved setup\(setupNames.count == 1 ? "" : "s")")
                                            .font(DesignTokens.Typography.subtitle)
                                            .fontWeight(.semibold)
                                    }

                                    Text(setupNames.isEmpty
                                        ? "Save the current wallpaper configuration to restore it later."
                                        : "Select a setup to preview, restore, or delete.")
                                        .font(DesignTokens.Typography.subtitle)
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                }

                                Spacer()

                                if let active = appModel.selectedSetupName {
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("Active")
                                            .font(.caption)
                                            .foregroundColor(DesignTokens.Colors.textSecondary)
                                        Text(active)
                                            .font(DesignTokens.Typography.subtitle)
                                            .fontWeight(.medium)
                                    }
                                }
                            }

                            if setupNames.isEmpty {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "archivebox")
                                        .foregroundStyle(.secondary)
                                        .font(.title3)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("No Setups Yet")
                                            .font(DesignTokens.Typography.subtitle)
                                            .fontWeight(.semibold)
                                        Text("Capture your current display configuration from the Home tab or here.")
                                            .font(DesignTokens.Typography.subtitle)
                                            .foregroundColor(DesignTokens.Colors.textSecondary)
                                    }

                                    Spacer()
                                }
                                .padding(14)
                                .background {
                                    RoundedRectangle(cornerRadius: DesignTokens.Corner.radius, style: .continuous)
                                        .fill(DesignTokens.Colors.cardBackground)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: DesignTokens.Corner.radius, style: .continuous)
                                                .stroke(DesignTokens.Colors.cardBorder, lineWidth: 1)
                                        }
                                }

                                Button(action: { isSaveSetupModalPresented = true }) {
                                    Label("Save Current Setup", systemImage: "plus.circle.fill")
                                        .labelStyle(.titleAndIcon)
                                }
                                .buttonStyle(.borderedProminent)
                                .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                Picker(
                                    "Setup",
                                    selection: Binding(
                                        get: { appModel.selectedSetupName ?? "" },
                                        set: { newValue in
                                            if newValue.isEmpty {
                                                appModel.selectedSetupName = nil
                                            } else {
                                                appModel.selectedSetupName = newValue
                                            }
                                        }
                                    )
                                ) {
                                    Text("Select Setup").tag("")
                                    ForEach(setupNames, id: \.self) { name in
                                        Text(name).tag(name)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)

                                if let selectedSetup {
                                    SetupPreviewCard(setup: selectedSetup, viewModel: appModel)
                                }

                                HStack(spacing: 10) {
                                    Button(action: {
                                        Task {
                                            guard let name = appModel.selectedSetupName else { return }
                                            _ = await appModel.restoreSetup(name: name)
                                        }
                                    }) {
                                        Label("Restore & Apply", systemImage: "arrow.counterclockwise")
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .frame(maxWidth: .infinity)
                                    .disabled(appModel.selectedSetupName == nil || appModel.isApplyingWallpaper)

                                    Button(role: .destructive, action: {
                                        Task {
                                            guard let name = appModel.selectedSetupName else { return }
                                            _ = await appModel.deleteSetup(name: name)
                                        }
                                    }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .buttonStyle(.bordered)
                                    .frame(maxWidth: .infinity)
                                    .disabled(appModel.selectedSetupName == nil)
                                }
                            }
                        }
                    }
            }
            .padding(DesignTokens.Spacing.large)
            .padding(.top, DesignTokens.Surfaces.mainTabBarReservedHeight + 8)
        }
        .frame(minWidth: 800, minHeight: 600)
        .task {
            await appModel.loadSavedSetups()
        }
        .sheet(isPresented: $isSaveSetupModalPresented) {
            SaveSetupModal(viewModel: appModel)
                .frame(minWidth: 400, minHeight: 520)
        }
    }
}

#Preview {
    SetupsTabView()
        .environmentObject(AppViewModel())
}
