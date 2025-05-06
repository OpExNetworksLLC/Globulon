//
//  AppDelegate.swift
//  Globulon
//
//  Created by David Holeman on 02/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import UserNotifications

#if FIREBASE_ENABLED
import Firebase
import FirebaseAuth
import FirebaseCore
import FirebaseMessaging
#endif

/**
 - Version: 1.0.0 (2025-02-25)
 - Note:
    - Version: 1.0.0 (2025-02-25)
        - (created)
 */

/// OPTION:  Turn off the log messages:
///
/// Code=4099 "The connection to service named com.apple.commcenter.coretelephony.xpc was invalidated."
///
/// Run in Terminal
/// xcrun simctl spawn booted log config --mode "level:off" --subsystem com.apple.CoreTelephony
///

#if FIREBASE_ENABLED
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    var fcmToken: String = ""
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        /// Start location monitoring...
        ///
//TODO: LOCFIX
        let locationManager = LocationManager.shared
//        if locationManager.updatesLive {
//            LogEvent.print(module: "AppDelegate", message: "Restart liveUpdates Session")
//            locationManager.startLocationUpdates()
//        }
        /// If a background activity session was previously active, reinstantiate it after the background launch.
        if locationManager.backgroundActivity {
            LogEvent.print(module: "AppDelegate", message: "Reinstantiate background activity Session")
            locationManager.backgroundActivity = true
        }
        
        /// Start activity monitoring...
        ///
        let activityManager = ActivityManager.shared
        if activityManager.updatesLive {
            LogEvent.print(module: "AppDelegate", message: "Restart activitiyUpdateHandler Session")
            activityManager.startActivityUpdates()
        }

        /// Start network monitoring...
        ///
        let NetworkManager = NetworkManager.shared
        NetworkManager.startNetworkUpdates()
        
        /// Start Bluetooth monitoring...
        /// - Must have permission
        /// - Start the updates if not already started
        ///
        let bluetoothHandler = BluetoothHandler.shared
        bluetoothHandler.getBluetoothPermission { result in
            if result {
                if bluetoothHandler.updatesLive == true {
                    Task {
                        await bluetoothHandler.awaitBluetoothPoweredOn()
                        await bluetoothHandler.startBluetoothUpdates()
                    }
                } else {
                    LogEvent.print(module: "AppDelegate", message: "Bluetooth updates are not started")
                }
            }
        }
        
        
        /// Assign UNUserNotificationCenter's delegate
        ///
        UNUserNotificationCenter.current().delegate = self
        
        /// Registering for notifications is called outside the AppDelegate because we don't want to prompt the user to
        /// to accept notfications immediately as soon as the app starts for the first time.  We ask for permissions during onboarding
        /// in a controlled way in this app.
        ///
        /// Uncomment here if we want to run immediate on startup for testing purposes
        /// ```
        /// registerForNotifications()
        /// ```
        
        /// Register background activities
        ///
        BackgroundManager.shared.registerBackgroundTask()
        
        /// Start Firebase...
        ///
        FirebaseApp.configure()
        
        /// Messaging
        ///
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
            LogEvent.print(module: "AppDelegate", message: "Installation ID: \(maskString(firebaseInstallationID))")
            LogEvent.debug(module: "AppDelegate", message: "Installation ID: \(firebaseInstallationID)")
            UserSettings.init().firebaseInstallationID = firebaseInstallationID

        }
        return true
    }
    
    /// This is called when the app is in the foreground and receives a notification
    /// - use this function when you want notifications in the foreground.  Remove it if not.
    ///
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        /// Define how to present the notification while the app is running (foreground)
        /// Alternatively, you can choose just sound or other options:
        ///
        ///`completionHandler([.sound])
        ///
        completionHandler([.banner, .sound, .badge])
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
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Handle remote notification registration
        
        // Get the Firebase Messaging token
        Messaging.messaging().apnsToken = deviceToken
        
        /// convert to string for masking
        let deviceTokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        LogEvent.print(module: "AppDelegate", message: "Success in AppDelegate.didRegisterForRemoteNotificationsWithDeviceToken: \(maskString(deviceTokenString))")
        
        LogEvent.debug(module: "AppDelegate", message: "Success in AppDelegate.didRegisterForRemoteNotificationsWithDeviceToken: \(deviceToken)")
    }
    
    //TODO:  or add preconcurrency to the import
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        
        // Update the Firebase token in your app
        DispatchQueue.main.async {
            self.fcmToken = fcmToken
            LogEvent.print(module: "AppDelegate", message: "FCM Token: \(maskString(fcmToken))")
            LogEvent.debug(module: "AppDelegate", message: "FCM Token: \(fcmToken)")
        }
    }
}
#else
@MainActor class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        /// Start location monitoring...
        ///
        let locationManager = LocationManager.shared
        print("locationManager.updatesLive:\(locationManager.updatesLive)")
        if !locationManager.updatesLive {
            LogEvent.print(module: "AppDelegate", message: "Restart locationManager Session")
            locationManager.startLocationUpdates()
        }
        /// If a background activity session was previously active, reinstantiate it after the background launch.
        ///
        if locationManager.backgroundActivity {
            LogEvent.print(module: "AppDelegate", message: "Reinstantiate background activity Session")
            locationManager.backgroundActivity = true
        }
        
        /// Start activity monitoring...
        ///
        let activityManager = ActivityManager.shared
        print("activityManager.updatesLive:\(activityManager.updatesLive)")
        if !activityManager.updatesLive {
            LogEvent.print(module: "AppDelegate", message: "Restart activitiyHandler Session")
            activityManager.startActivityUpdates()
        }
        //activityManager.startActivityUpdates()

        /// Start network monitoring...
        ///
        let NetworkManager = NetworkManager.shared
        NetworkManager.startNetworkUpdates()
        
        /// Start Bluetooth monitoring..
        ///
        let bluetoothHandler = BluetoothHandler.shared
        if bluetoothHandler.updatesLive == true {
            bluetoothHandler.startBluetoothUpdates()
        }
        
        /// Assign UNUserNotificationCenter's delegate
        ///
        UNUserNotificationCenter.current().delegate = self
        
        /// Registering for notifications is called outside the AppDelegate because we don't want to prompt the user to
        /// to accept notfications immediately as soon as the app starts for the first time.  We ask for permissions during onboarding
        /// in a controlled way in this app.
        ///
        /// Uncomment here if we want to run immediate on startup for testing purposes
        /// ```
        /// registerForNotifications()
        /// ```
        
        /// Register background activities
        ///
        BackgroundManager.shared.registerBackgroundTask()
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
    
}
#endif
