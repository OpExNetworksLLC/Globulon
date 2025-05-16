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
                    LogManager.event(module: "Notifications.requestUserNotificationPermission", message: "Permission granted")
                    UIApplication.shared.registerForRemoteNotifications()
                    self.isNotificationsEnabled = true
                } else {
                    LogManager.event(module: "Notifications.requestUserNotificationPermission", message: "Permission denied")
                    self.isNotificationsEnabled = false
                }
                return granted
            } catch {
                LogManager.event(module: "Notifications.requestUserNotificationPermission", message: "Error requesting permission: \(error.localizedDescription)")
                self.isNotificationsEnabled = false
                return false
            }
        } else {
            // The permission was already determined (either granted or denied)
            let isEnabled = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional || settings.authorizationStatus == .ephemeral
            let message = isEnabled ? "Notifications have already been enabled." : "Notifications are disabled. Please enable them in Settings."
            LogManager.event(module: "Notifications.requestUserNotificationPermission", message: message)
            self.isNotificationsEnabled = isEnabled
            return isEnabled
        }
    }
    
    class func sendNotification(title: String, body: String) {
        Task { @MainActor in
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default

            print(">>> \(content.title) - \(content.body)")

            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)

            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                LogManager.event(module: "NotificationManager.sendNotification()", message: "Error scheduling notification: \(error)")
            }
        }
    }

    class func connectivityChangeNotification(isConnected: Bool) {
        Task { @MainActor in
            let content = UNMutableNotificationContent()
            content.title = "Internet Connectivity Changed"
            content.body = isConnected ? "You're now connected to the internet." : "You've lost internet connectivity."
            content.sound = .default

            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)

            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                LogManager.event(module: "PostNotification.connectivityChangeNotification()", message: "Error scheduling notification: \(error)")
            }
        }
    }
//    class func sendNotification(title: String, body: String) {
//        let content = UNMutableNotificationContent()
//        content.title = title
//        content.body = body
//        content.sound = .default
//        
//        print(">>>\(content.title) - \(content.body)")
//        
//        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil) // Trigger now
//        
//        UNUserNotificationCenter.current().add(request) { error in
//            if let error = error {
//                LogManager.event(module: "NotificationManager.sendNotification()", message: "Error scheduling notification: \(error)")
//            }
//        }
//    }
//    
//    class func connectivityChangeNotification(isConnected: Bool) {
//        let content = UNMutableNotificationContent()
//        content.title = "Internet Connectivity Changed"
//        content.body = isConnected ? "You're now connected to the internet." : "You've lost internet connectivity."
//        content.sound = UNNotificationSound.default
//        
//        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil) // Trigger now
//        
//        UNUserNotificationCenter.current().add(request) { error in
//            if let error = error {
//                LogManager.event(module: "PostNotification.connectivityChangeNotification()", message: "Error scheduling notification: \(error)")
//            }
//        }
//    }
}



