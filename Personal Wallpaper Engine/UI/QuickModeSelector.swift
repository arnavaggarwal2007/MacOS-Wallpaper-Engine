import SwiftUI

struct QuickModeSelector: View {
    @EnvironmentObject private var appModel: AppViewModel

    var body: some View {
        Menu {
            ForEach(QuickMode.selectableCases, id: \.self) { mode in
                if mode == .pinnedSetup {
                    pinnedSetupSection
                } else {
                    modeButton(mode)
                }
            }

            if appModel.quickMode == .custom {
                Divider()
                Button {
                    applyQuickModeAfterMenuDismiss {
                        await appModel.returnToLastCommittedQuickMode()
                    }
                } label: {
                    Label("Return to Last Mode", systemImage: "arrow.uturn.backward")
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.system(size: 12, weight: .semibold))
                Text(appModel.quickMode.shortName)
                    .font(.system(size: 13, weight: .semibold))
            }
        }
        .help(appModel.quickMode.caption)
        .accessibilityLabel("Quick mode: \(appModel.quickMode.displayName)")
    }

    private var iconName: String {
        switch appModel.quickMode {
        case .singleAllDisplays: return "rectangle.on.rectangle"
        case .perDisplayCustom: return "rectangle.split.2x1"
        case .pinnedSetup: return "pin.fill"
        case .custom: return "slider.horizontal.3"
        }
    }

    @ViewBuilder
    private var pinnedSetupSection: some View {
        if let pinnedName = appModel.pinnedSetupName {
            Button {
                applyQuickModeAfterMenuDismiss {
                    await appModel.applyQuickMode(.pinnedSetup)
                }
            } label: {
                if appModel.quickMode == .pinnedSetup {
                    Label("Pinned: \(pinnedName)", systemImage: "checkmark")
                } else {
                    Label("Apply Pinned: \(pinnedName)", systemImage: "pin.fill")
                }
            }
        } else {
            Button {
                appModel.bringAppToFront(selecting: .setups)
            } label: {
                Label("Pin a setup in Setups…", systemImage: "pin")
            }
        }
    }

    private func modeButton(_ mode: QuickMode) -> some View {
        Button {
            applyQuickModeAfterMenuDismiss {
                await appModel.applyQuickMode(mode)
            }
        } label: {
            if appModel.quickMode == mode {
                Label(mode.displayName, systemImage: "checkmark")
            } else {
                Text(mode.displayName)
            }
        }
    }

    /// Defers apply until after the SwiftUI menu closes so visibility/occlusion state settles first.
    private func applyQuickModeAfterMenuDismiss(_ operation: @escaping () async -> Void) {
        DispatchQueue.main.async {
            Task { await operation() }
        }
    }
}
