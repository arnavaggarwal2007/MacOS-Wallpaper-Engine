//
//  LoginItemManager.swift
//  Personal Wallpaper Engine
//
//  Created by Arnav Aggarwal on 5/3/26.
//  Phase 5G: Launch-on-Login support using SMAppService

import Foundation
import ServiceManagement
import Combine
import os.log

final class LoginItemManager: ObservableObject {
    private let logger = Logger(subsystem: "com.personal.wallpaper-engine", category: "LoginItemManager")
    
    @Published var isLaunchOnLoginEnabled: Bool = false
    @Published var statusMessage: String?
    @Published var errorMessage: String?
    
    private let settingsStore = SettingsStore.shared
    
    init() {
        // Load current state from SMAppService
        updateStatus()
    }
    
    /// Updates the published state based on current SMAppService status
    private func updateStatus() {
        #if os(macOS)
        if #available(macOS 13.2, *) {
            let appService = SMAppService.mainApp
            self.isLaunchOnLoginEnabled = (appService.status == .enabled)
            self.errorMessage = nil
        } else {
            // Fallback for older macOS versions
            self.errorMessage = "Launch-on-Login requires macOS 13.2 or later"
        }
        #endif
    }
    
    /// Enables launch-on-login for the application
    func enableLaunchOnLogin() {
        #if os(macOS)
        if #available(macOS 13.2, *) {
            do {
                let appService = SMAppService.mainApp
                try appService.register()
                self.isLaunchOnLoginEnabled = true
                self.statusMessage = "Launch-on-Login enabled"
                self.errorMessage = nil
                logger.info("Launch-on-Login enabled successfully")
            } catch {
                let errorDesc = error.localizedDescription
                logger.error("Failed to enable launch-on-login: \(errorDesc)")
                self.errorMessage = "Failed to enable: \(errorDesc)"
                self.statusMessage = nil
            }
        }
        #endif
    }
    
    /// Disables launch-on-login for the application
    func disableLaunchOnLogin() {
        #if os(macOS)
        if #available(macOS 13.2, *) {
            do {
                let appService = SMAppService.mainApp
                try appService.unregister()
                self.isLaunchOnLoginEnabled = false
                self.statusMessage = "Launch-on-Login disabled"
                self.errorMessage = nil
                logger.info("Launch-on-Login disabled successfully")
            } catch {
                let errorDesc = error.localizedDescription
                logger.error("Failed to disable launch-on-login: \(errorDesc)")
                self.errorMessage = "Failed to disable: \(errorDesc)"
                self.statusMessage = nil
            }
        }
        #endif
    }
    
    /// Toggles launch-on-login state
    func toggleLaunchOnLogin() {
        if isLaunchOnLoginEnabled {
            disableLaunchOnLogin()
        } else {
            enableLaunchOnLogin()
        }
    }
}
