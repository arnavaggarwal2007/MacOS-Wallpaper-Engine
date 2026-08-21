//
//  Personal_Wallpaper_EngineApp.swift
//  Personal Wallpaper Engine
//
//  Created by Arnav Aggarwal on 4/30/26.
//

import AppKit
import SwiftUI

@main
struct Personal_Wallpaper_EngineApp: App {
    @StateObject private var appModel = AppViewModel()
    @StateObject private var menuBarController = MenuBarController()

    var body: some Scene {
        WindowGroup {
            TabbedMainView()
                .environmentObject(appModel)
                .task {
                    // Initialize menu bar with ViewModel
                    menuBarController.setup(with: appModel)
                    await appModel.start()
                }
                .onAppear {
                    DockAgentPolicy.applyInitialPolicy()
                    appModel.updateLaunchOnLoginStatus()
                    DockAgentPolicy.updateDockVisibility(hasVisibleMainWindows: true)
                }
                .onDisappear {
                    Task {
                        await appModel.stop()
                    }
                }
        }
        .commands {
            // The app ships no help book, so the stock Help item dead-ends.
            // These also satisfy the App Review expectation that privacy and
            // support are reachable from inside the app.
            CommandGroup(replacing: .help) {
                Button("\(AppInfo.displayName) Support") {
                    NSWorkspace.shared.open(AppLinks.support)
                }
                Button("Privacy Policy") {
                    NSWorkspace.shared.open(AppLinks.privacyPolicy)
                }
            }
        }
    }
}
