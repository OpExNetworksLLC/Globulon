//
//  AppDelegate.swift
//  Globulon
//
//  Created by David Holeman on 02/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import UIKit
import UserNotifications

#if FIREBASE_ENABLED
import Firebase
import FirebaseAuth
import FirebaseCore
import FirebaseMessaging
#endif

/**
 - Version: 1.1.0 (2025-05-09)
 - Note:
    - Version: 1.0.0 (2025-02-25)
        - (created)
    - Version: 1.1.0 (2025-05-09)
        - Massive rewrite to streamline compiler flags and consolidate code.
 */

/// OPTION:  Turn off the log messages:
///
/// Code=4099 "The connection to service named com.apple.commcenter.coretelephony.xpc was invalidated."
///
/// Run in Terminal
/// xcrun simctl spawn booted log config --mode "level:off" --subsystem com.apple.CoreTelephony
///

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var fcmToken: String = ""
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        LogManager.event(module: "AppDelegate", message: "▶️ starting...")
        
        /// Register background activities
        ///
        BackgroundManager.shared.registerBackgroundTask()
        BackgroundManager.shared.ensureSchedulingOnLaunch()
        
        /// setup
        setupLocationServices()
        setupActivityMonitoring()
        setupNetworkMonitoring()
        setupBluetoothMonitoring()
        setupUserNotifications()
        
        #if FIREBASE_ENABLED
        setupFirebase()
        #endif

        LogManager.event(module: "AppDelegate", message: "⏹️ ...finished")

        return true
    }
    
    #if FIREBASE_ENABLED
    private func setupFirebase() {
        /// Start Firebase...
        ///
        FirebaseApp.configure()
        
        /// Messaging
        ///
        Messaging.messaging().delegate = self

        Installations.installations().installationID { (firebaseInstallationID, error) in
            if let error = error {
                LogManager.event(module: "AppDelegate.setupFirebase()", message: "Error fetching installation ID: \(error)")
                return
            }
            guard let firebaseInstallationID = firebaseInstallationID else {
                LogManager.event(module: "AppDelegate.setupFirebase()", message: "Installation ID is not available")
                return
            }
            LogManager.event(module: "AppDelegate.setupFirebase()", message: "Installation ID: \(maskString(firebaseInstallationID))")
            LogManager.event(output: .debugOnly, module: "AppDelegate.setupFirebase()", message: "Installation ID: \(firebaseInstallationID)")
            UserSettings.init().firebaseInstallationID = firebaseInstallationID
        }
    }
    #endif
    
    // If you need to handle background task registration or other app-level events,
    // you can add them here. For example, forwarding registration to BackgroundManager
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Optionally re-register background tasks when app becomes active
        BackgroundManager.shared.registerBackgroundTask()
        BackgroundManager.shared.ensureSchedulingOnLaunch()
    }
    
    private func setupLocationServices() {
        /// Start location monitoring...
        ///
        let locationManager = LocationManager.shared

        /// This is absolutely required to line the location manager back up with load of the app for interactive use.
        if locationManager.updatesLive {
            LogManager.event(module: "AppDelegate.setupLocationServices()", message: "Restart liveUpdates Session")
            locationManager.startLocationUpdates()
        }

        /// If a background activity session was previously active, reinstantiate it after the background launch.
        if locationManager.backgroundActivity {
            LogManager.event(module: "AppDelegate.setupLocationServices()", message: "Reinstantiate background activity Session")
            locationManager.backgroundActivity = true
        }
    }
    
    private func setupActivityMonitoring() {
        /// Start activity monitoring...
        ///
        let activityManager = ActivityManager.shared
        
        if activityManager.updatesLive {
            LogManager.event(module: "AppDelegate.setupActivityMonitoring()", message: "Restart activitiyUpdateHandler Session")
            activityManager.startActivityUpdates()
        }
    }
    
    private func setupNetworkMonitoring() {
        /// Start network monitoring...
        ///
        let networkManager = NetworkManager.shared
        networkManager.startNetworkUpdates()
    }
    
    private func setupUserNotifications() {
        /// Assign UNUserNotificationCenter's delegate
        ///
        UNUserNotificationCenter.current().delegate = self
        
        /// Registering for notifications is called outside the AppDelegate because we don't want to prompt the user to
        /// to accept notfications immediately as soon as the app starts for the first time.  We ask for permissions during onboarding
        /// in a controlled way in this app.
        ///
        /// DEBUG:  Uncomment here if we want to run immediate on startup for testing purposes
        /// 
        ///`registerForNotifications()
        
    }
    
    private func setupBluetoothMonitoring() {
        /// Start Bluetooth monitoring...
        /// - Must have permission
        /// - Start the updates if not already started
        ///
        let bluetoothManager = BluetoothManager.shared
        bluetoothManager.getBluetoothPermission { result in
            if result {
                if bluetoothManager.updatesLive == true {
                    Task {
                        await bluetoothManager.awaitBluetoothPoweredOn()
                        await bluetoothManager.startBluetoothUpdates()
                    }
                } else {
                    LogManager.event(module: "AppDelegate.setupBluetoothMonitoring()", message: "Bluetooth updates are not started")
                }
            }
        }
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
                    LogManager.event(module: "AppDelegate", message: "Request Authorization Failed (\(error), \(error.localizedDescription))")
                }
                return
            }
            LogManager.event(module: "AppDelegate", message: "Success in APNS registry")
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Handle failure to register for remote notifications
        // Example: NotificationManager.shared.handleRegistrationError(error)
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Handle silent push (content-available:1) or background updates here
        // Do your background fetch/update and call completionHandler when done
        completionHandler(.noData)
    }
    
    #if FIREBASE_ENABLED
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Handle remote notification registration
        
        // Get the Firebase Messaging token
        Messaging.messaging().apnsToken = deviceToken
        
        /// convert to string for masking
        let deviceTokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        LogManager.event(module: "AppDelegate", message: "Success in AppDelegate.didRegisterForRemoteNotificationsWithDeviceToken: \(maskString(deviceTokenString))")
        
        LogManager.event(output: .debugOnly, module: "AppDelegate", message: "Success in AppDelegate.didRegisterForRemoteNotificationsWithDeviceToken: \(deviceToken)")
    }
    
    //TODO:  or add preconcurrency to the import
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        
        // Update the Firebase token in your app
        DispatchQueue.main.async {
            self.fcmToken = fcmToken
            LogManager.event(module: "AppDelegate", message: "FCM Token: \(maskString(fcmToken))")
            LogManager.event(output: .debugOnly, module: "AppDelegate", message: "FCM Token: \(fcmToken)")
        }
    }
    #endif
}

#if FIREBASE_ENABLED
extension AppDelegate: MessagingDelegate {}
#endif
