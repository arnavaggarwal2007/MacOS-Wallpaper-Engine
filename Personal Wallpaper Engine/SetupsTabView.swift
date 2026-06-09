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

                GlassCardView {
                    HStack(spacing: 10) {
                        Button(action: { isSaveSetupModalPresented = true }) {
                            Label("Save Current Setup", systemImage: "square.and.arrow.down.fill")
                        }
                        .buttonStyle(.borderedProminent)

                        if let pinned = appModel.pinnedSetupName {
                            statusChip(title: "Pinned", value: pinned, icon: "pin.fill")
                        }

                        if let active = appModel.selectedSetupName {
                            statusChip(title: "Active", value: active, icon: "checkmark.circle")
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
                                    : "Select a setup to preview, restore, pin for Quick Modes, or delete.")
                                    .font(DesignTokens.Typography.subtitle)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                            }

                            Spacer()
                        }

                        if setupNames.isEmpty {
                            emptyState
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(setupNames, id: \.self) { name in
                                    if let setup = appModel.savedSetups[name] {
                                        SetupPreviewCard(
                                            setup: setup,
                                            viewModel: appModel,
                                            isPinned: appModel.isSetupPinned(name),
                                            onSelect: { appModel.selectedSetupName = name }
                                        )
                                    }
                                }
                            }

                            if let selectedName = appModel.selectedSetupName {
                                setupActions(for: selectedName)
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

    private var emptyState: some View {
        VStack(spacing: 14) {
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
        }
    }

    @ViewBuilder
    private func setupActions(for name: String) -> some View {
        HStack(spacing: 10) {
            Button(action: {
                Task { _ = await appModel.restoreSetup(name: name) }
            }) {
                Label("Restore & Apply", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .disabled(appModel.isApplyingWallpaper)

            if appModel.isSetupPinned(name) {
                Button(action: { appModel.unpinSetup() }) {
                    Label("Unpin", systemImage: "pin.slash")
                }
                .buttonStyle(.bordered)
            } else {
                Button(action: { appModel.pinSetup(name: name) }) {
                    Label("Pin for Quick Modes", systemImage: "pin.fill")
                }
                .buttonStyle(.bordered)
            }

            Button(role: .destructive, action: {
                Task { _ = await appModel.deleteSetup(name: name) }
            }) {
                Label("Delete", systemImage: "trash")
            }
            .buttonStyle(.bordered)
        }
    }

    private func statusChip(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                Text(value)
                    .font(DesignTokens.Typography.subtitle)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Capsule(style: .continuous)
                .fill(DesignTokens.Colors.cardBackground)
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(DesignTokens.Colors.cardBorder, lineWidth: 1)
                }
        }
    }
}

#Preview {
    SetupsTabView()
        .environmentObject(AppViewModel())
}
