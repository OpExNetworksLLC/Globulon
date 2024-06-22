//
//  NotificationManagerClass.swift
//  ViDrive
//
//  Created by David Holeman on 3/12/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import UserNotifications

class NotificationManager {
    
    class func getUserNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    LogEvent.print(module: "NotificationManager.getUserNotificationPermission()", message: "Notification permission has not been asked yet, it's not determined.")
                    completion(false)
                case .denied:
                    LogEvent.print(module: "NotificationManager.getUserNotificationPermission()", message: "Notification permission was previously denied.")
                    completion(false)
                case .authorized, .provisional, .ephemeral:
                    // Provisional and ephemeral authorization are treated as true for enabling basic notification functionality
                    LogEvent.print(module: "NotificationManager.getUserNotificationPermission()", message: "Notification authorized")
                    completion(true)
                @unknown default:
                    LogEvent.print(module: "NotificationManager.getUserNotificationPermission()", message: "Unknown notification permission status.")
                    completion(false)
                }
            }
        }
    }
    
    class func requestUserNotificationPermission(completion: @escaping (Bool) -> Void) {
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else {
                // If the authorization status is not .notDetermined, then the user has already made a choice.
                // We return false and a message explaining the situation.
                DispatchQueue.main.async {
                    let message = settings.authorizationStatus == .denied ? "Notifications are disabled. Please enable them in Settings." : "Notifications have already been enabled."
                    print(message)
                    completion(false)
                }
                return
            }
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    LogEvent.print(module: "Notifications.requestUserNotificationPermission", message: "Permission granted")
                    UIApplication.shared.registerForRemoteNotifications()
                    completion(true)
                } else {
                    if let error = error {
                        LogEvent.print(module: "Notifications.requestUserNotificationPermission", message: "Permission denied with error: \(error.localizedDescription)")
                    }
                    completion(false)
                }
            }
        }
    }
}
