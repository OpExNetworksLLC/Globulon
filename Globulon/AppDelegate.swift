//
//  AppDelegate.swift
//  Globulon
//
//  Created by David Holeman on 2/20/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import UserNotifications

import Firebase
import FirebaseAuth
import FirebaseCore
import FirebaseMessaging

import CoreLocation

/// Turn off the log messages:
/// Code=4099 "The connection to service named com.apple.commcenter.coretelephony.xpc was invalidated."
///
/// Run in Terminal
/// xcrun simctl spawn booted log config --mode "level:off" --subsystem com.apple.CoreTelephony


class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    var fcmToken: String = ""
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        /// Check saved status in the app and adjust as appropriate for the locationHandler()
        let locationHandler = LocationHandler.shared
        
        /// If location updates were previously active and you stopped them then you'll have to restart them manually after the background launch.
        if locationHandler.updatesStarted {
            LogEvent.print(module: "AppDelegate", message: "Restart liveUpdates Session")
            locationHandler.startLocationUpdates()
        }
        /// If a background activity session was previously active, reinstantiate it after the background launch.
        if locationHandler.backgroundActivity {
            LogEvent.print(module: "AppDelegate", message: "Reinstantiate background activity Session")
            locationHandler.backgroundActivity = true
        }
        
        let activityHandler = ActivityHandler.shared
        
        if activityHandler.updatesStarted {
            LogEvent.print(module: "AppDelegate", message: "Restart activitiyUpdateHandler Session")
            activityHandler.startActivityUpdates()
        }

        let networkHandler = NetworkHandler.shared
        networkHandler.startNetworkUpdates()

        // Start Firebase...
        FirebaseApp.configure()
        FirebaseConfiguration.shared.setLoggerLevel(.min)
                
        // Assign UNUserNotificationCenter's delegate
        UNUserNotificationCenter.current().delegate = self
        
        /// Registering for notifications is called outside the AppDelegate because we don't want to prompt the user to
        /// to accept notfications immediately as soon as the app starts for the first time.  We ask for permissions during onboarding
        /// in a controlled way in this app.
        ///
        /// Uncomment here if we want to run immediate on startup for testing purposes
        /// ```
        /// registerForNotifications()
        /// ```
        
        // Messaging
        Messaging.messaging().delegate = self

        Installations.installations().installationID { (firebaseInstallationID, error) in
            if let error = error {
                LogEvent.print(module: "AppDelegate", message: "Error fetching installation ID: \(error)")
                return
            }
            guard let firebaseInstallationID = firebaseInstallationID else {
                LogEvent.print(module: "AppDelegate", message: "Installation ID is not available")
                return
            }
            UserSettings.init().firebaseInstallationID = firebaseInstallationID
            LogEvent.print(module: "AppDelegate", message: "Installation ID: \(firebaseInstallationID)")
        }
        return true
    }
    
    /// This method is called to request message authorization.  Not used for now since we request access directly as part of onboarding.
    ///
    func registerForNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { success, error in
            guard success else {
                if let error = error {
                    LogEvent.print(module: "AppDelegate", message: "Request Authorization Failed (\(error), \(error.localizedDescription))")
                }
                return
            }
            LogEvent.print(module: "AppDelegate", message: "Success in APNS registry")
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    //TODO: This may not be necessary.  Test this out.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Handle remote notification registration
        
        // Get the Firebase Messaging token
        Messaging.messaging().apnsToken = deviceToken
        LogEvent.print(module: "AppDelegate", message: "Success in AppDelegate.didRegisterForRemoteNotificationsWithDeviceToken: \(deviceToken)")
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        
        // Update the token in your app
        DispatchQueue.main.async {
            self.fcmToken = fcmToken
            LogEvent.print(module: "AppDelegate", message: "FCM Token: \(fcmToken)")
        }
    }
}
