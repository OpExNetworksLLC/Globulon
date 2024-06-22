//
//  PostNotificationClass.swift
//  ViDrive
//
//  Created by David Holeman on 3/20/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import UserNotifications

class PostNotification {
    
    class func postConnectivityChangeNotification(isConnected: Bool) {
        let content = UNMutableNotificationContent()
        content.title = "Internet Connectivity Changed"
        content.body = isConnected ? "You're now connected to the internet." : "You've lost internet connectivity."
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil) // Trigger now
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
}
