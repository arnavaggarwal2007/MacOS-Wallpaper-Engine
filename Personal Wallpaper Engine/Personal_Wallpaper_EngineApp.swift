//
//  Personal_Wallpaper_EngineApp.swift
//  Personal Wallpaper Engine
//
//  Created by Arnav Aggarwal on 4/30/26.
//

import SwiftUI

@main
struct Personal_Wallpaper_EngineApp: App {
    @StateObject private var appModel = AppViewModel()
    @StateObject private var menuBarController = MenuBarController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appModel)
                .task {
                    // Initialize menu bar with ViewModel
                    menuBarController.setup(with: appModel)
                    await appModel.start()
                }
                .onDisappear {
                    Task {
                        await appModel.stop()
                    }
                }
        }
    }
}
