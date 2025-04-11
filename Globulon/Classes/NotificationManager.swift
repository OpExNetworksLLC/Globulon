//
//  NotificationHandlerClass.swift
//  Globulon
//
//  Created by David Holeman on 2/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
@preconcurrency import UserNotifications

/**
    - Version: 1.0.0
    - Date: 08-05-2024
 
    # Description:
    NotficationsHandler
    - updateNotificationPermissionStatus() returns a true/false value indicating if notifications are permitted
    - getUserNotificationPermission() checks the status states and determines if access is true
    - requestUserNotificationPermission() is called to request the user to allow notifications via iOS permissions.  Based on that choice it returns the appropriate observed status
 */
@MainActor class NotificationManager: ObservableObject {
    
    static let shared = NotificationManager()
    
    @Published var isNotificationsEnabled: Bool = false
    
    private init() {
        // Initialize and check the current notification status
        Task {
            await updateNotificationPermissionStatus()
        }
    }
    
    // Method to update the notification permission status using async/await
    func updateNotificationPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        self.isNotificationsEnabled = settings.authorizationStatus == .authorized
    }
    
    // Method to request user notification permission and update `isNotificationsEnabled`
    func requestUserNotificationPermission() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        
        if settings.authorizationStatus == .notDetermined {
            // The permission has not been requested before, so let's request it
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
                if granted {
                    LogEvent.print(module: "Notifications.requestUserNotificationPermission", message: "Permission granted")
                    UIApplication.shared.registerForRemoteNotifications()
                    self.isNotificationsEnabled = true
                } else {
                    LogEvent.print(module: "Notifications.requestUserNotificationPermission", message: "Permission denied")
                    self.isNotificationsEnabled = false
                }
                return granted
            } catch {
                LogEvent.print(module: "Notifications.requestUserNotificationPermission", message: "Error requesting permission: \(error.localizedDescription)")
                self.isNotificationsEnabled = false
                return false
            }
        } else {
            // The permission was already determined (either granted or denied)
            let isEnabled = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional || settings.authorizationStatus == .ephemeral
            let message = isEnabled ? "Notifications have already been enabled." : "Notifications are disabled. Please enable them in Settings."
            LogEvent.print(module: "Notifications.requestUserNotificationPermission", message: message)
            self.isNotificationsEnabled = isEnabled
            return isEnabled
        }
    }
}



