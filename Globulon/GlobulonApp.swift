//
//  GlobulonApp.swift
//  Globulon
//
//  Created by David Holeman on 02/25/25
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import SwiftData
import BackgroundTasks
#if FIREBASE_ENABLED
import FirebaseAnalytics
#endif

/**
 - Version: 1.0.0 (2025.02.25)
 - Note:
    - Version: 1.0.0 (2024.02.25)
        - Created
*/
@main struct GlobulonApp: App {
    
    /// Register app delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @Environment(\.scenePhase) var scenePhase
    
    /// Set the state object so it can be accessed in any view
    /// eg: `@EnvironmentObject var appStatus: appStatus
    /// `
    @StateObject private var appStatus = AppStatus()
    @StateObject private var userStatus = UserStatus()
    @StateObject private var appEnvironment = AppEnvironment()
    
    private let backgroundFetchTaskIdentifier = "com.opexnetworks.Globulon.backgroundFetch"
    private let backgroundProcessingTaskIdentifier = "com.opexnetworks.Globulon.backgroundProcessing"
    
    init() {
        
        //deleteDefaultStore()
        
        /// Save the prior logfile
        LogEvent.ArchiveLogFile()
        
        LogEvent.print(module: "GlobulonApp.init()", message: "▶️ starting...")
        
        /// OPTION: Force set any settings here to start other than the app default settings
        ///
        UserSettings.init().userMode = .development
        
        /// OPTION: Set to true when using the simulator to autologin and save time in testing.
        /// This bypasses login and keychain/firebase authentication and assumes the user is authorized
        ///
        ///`UserSettings.init().isAutoLogin = true
        ///
        UserSettings.init().isAutoLogin = false
        
        //deleteDefaultStore()
        
        /// Based on`.userMode`chance some settings and values
        ///
        switch UserSettings.init().userMode {
        case .production:
            break
        case .test:
            break
        case .development:
            
            /// Override any default values:
            /// - If value has been not been changed here then the default is used
            ///
            ///`AppDefaults.gps.sampleRate = 1  // n per second
            ///`AppDefaults.gps.tripGPSHistoryLimit = 15
            ///`AppDefaults.gps.tripHistoryLimit = 10
            
            /// Override any user settings:
            ///
            
            /// Automatically purge so I don't have to manually
            _ = purgeGPSData()
            
            break
        }
        
        #if FIREBASE_ENABLED
            UserSettings.init().authMode = .firebase
            Analytics.setAnalyticsCollectionEnabled(UserSettings.init().isGDPRConsentGranted)
            LogEvent.print(module: "\(AppSettings.appName).init()", message: "firebase analytics enabled: \(UserSettings.init().isGDPRConsentGranted)")
        #endif
        #if KEYCHAIN_ENABLED
            UserSettings.init().authMode = .keychain
        #endif
        
        /// Print out the settings in the log
        LogEvent.print(module: "\(AppSettings.appName).init()", message: "Settings..." + printUserSettings(description: "Settings", indent: "  "))
        
        /// Check the permissions and availability of various handlers
        ///
        /// Location Handler
        LocationHandler.shared.getAuthorizedWhenInUse { result in
            LogEvent.print(module: AppSettings.appName + ".LocationHandler.getAuthorizedWhenInUse()", message: "\(result)")
        }
        LocationHandler.shared.getAuthorizedAlways { result in
            LogEvent.print(module: AppSettings.appName + ".LocationHandler.getAuthorizedAlways()", message: "\(result)")
        }
        LocationHandler.shared.getAuthorizedDescription { result in
            LogEvent.print(module: AppSettings.appName + ".LocationHandler.getAuthorizedDescription()", message: "\(result)")
        }
        
        /// Activity Handler
        ActivityHandler.shared.getMotionActivityAvailability { result in
            LogEvent.print(module: AppSettings.appName + ".ActivityHandler.getMotionActivityAvailability()", message: "\(result)")
        }
        ActivityHandler.shared.getMotionActivityPermission { result in
            LogEvent.print(module: AppSettings.appName + ".ActivityHandler.getMotionActivityPermission()", message: "\(result)")
        }
        
        ActivityHandler.shared.getActivityMonitoringStatus { result in
            LogEvent.print(module: AppSettings.appName + ".ActivityHandler.getActivityMonitoringStatus()", message: "\(result)")
            
            /** OPTION:  Use this code to start the handle
            ```
            if !result {
            ActivityHandler.shared.startActivityUpdates()
            }
            ```
            */
        }
        //LogEvent.getLogFileURL()
        LogEvent.print(module: "GlobulonApp.init()", message: "⏹️ ...finished")
        
    }
    
    var body: some Scene {
        WindowGroup {
            MasterView()
                .environmentObject(UserSettings())
                .environmentObject(UserStatus())
                .environmentObject(AppStatus())
                .environmentObject(AppEnvironment())
        }
        /// Heres is where we make the Shared Model Container available as a singleton across the App for use in views
        ///
        ///.modelContainer(AppEnvironment.sharedModelContainer)
        .modelContext(SharedModelContainer.shared.context)
        
        .onChange(of: scenePhase) { scenePhase, newScenePhase in
            switch newScenePhase {
            case .background:
                LogEvent.print(module: AppSettings.appName + ".onChangeOf", message: "Scene is in background")
                
                /// EXAMPLE:  In some apps you may want to save your context or other data before dropping into background mode
                ///`persistanceController.save()
                
                /// OPTION:  Schedule any background task(s)
                ///`BackgroundTaskHandler.shared.scheduleProcessingTask()
                
            case .inactive:
                //LogEvent.print(module: AppSettings.appName + ".onChangeOf", message: "Scene is inactive")
                break
            case .active:
                //LogEvent.print(module: AppSettings.appName + ".onChangeOf", message: "Scene is active")
                break
            @unknown default:
                //LogEvent.print(module: AppSettings.appName + ".onChangeOf", message: "Scene is unexpected")
                break
            }
        }
    }
}
