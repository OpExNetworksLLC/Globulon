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
    @StateObject private var userSettings = UserSettings()

    @State private var isStartupSequenceComplete = false
    
    private let backgroundFetchTaskIdentifier = "com.opexnetworks.Globulon.backgroundFetch"
    private let backgroundProcessingTaskIdentifier = "com.opexnetworks.Globulon.backgroundProcessing"
    
    private var isVersionManagerSuccess = false
    
    
    init() {
        
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
            userSettings.articlesLocation = .remote
            
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
        
        //LogEvent.getLogFileURL()
        
        LogEvent.print(module: AppSettings.appName + "App.init()", message: "⏹️ ...finished")
    }

    
    // MARK: - Main body
    
    var body: some Scene {
        WindowGroup {
            if isStartupSequenceComplete {
                MasterView()
                    .environmentObject(userSettings)
                    .environmentObject(userStatus)
                    .environmentObject(appStatus)
                    .environmentObject(AppEnvironment.shared)
            } else {
                StartupSequenceView() // Optional: or use ProgressView/spinner
                    .task {
                        //try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds artificial delay
                        await startupSequence()
                        isStartupSequenceComplete = true
                        print(">>> Startup sequence complete")
                    }
            }
        }
//        WindowGroup {
//            MasterView()
//                .environmentObject(UserSettings())
//                .environmentObject(UserStatus())
//                .environmentObject(AppStatus())
//                .environmentObject(AppEnvironment())
//                // 👇 Here's where we start the startup sequence task
//                .task {
//                    await startupSequence()
//                }
//        }
        
        /// Heres is where we make the Shared Model Container available as a singleton across the App for use in views
        ///
        ///.modelContainer(AppEnvironment.sharedModelContainer)
        ///.modelContext(SharedModelContainer.shared.context)
        .modelContainer(ModelContainerProvider.shared)
        
        .onChange(of: scenePhase) { scenePhase, newScenePhase in
            switch newScenePhase {
            case .background:
                LogEvent.print(module: AppSettings.appName + ".onChangeOf", message: "Scene is in background")
                
                /// EXAMPLE:  In some apps you may want to save your context or other data before dropping into background mode
                ///`persistanceController.save()
                
                /// OPTION:  Schedule any background task(s)
                ///`BackgroundManager.shared.scheduleProcessingTask()
                
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
    
    // MARK: - Async Startup Logic
    
    /// The startup sequence is triggered as a task from the MasterView in a task.  Doing this outside the init() function allows us to
    /// support executing async tasks in order.  Init() does not honor an order regarding asycn calls so we can't force a wait until an
    /// async process finishes there.
    ///
    private func startupSequence() async {
        
        LogEvent.print(module: AppSettings.appName + "App.startupSequence", message: "▶️ starting...")
        
        let versionManager = VersionManager.shared
        
        var isSaveRelease = false
        
        // Debug stuff (remove)
        //
        versionManager.resetRelease()
        Articles.deleteArticles()
        UserSettings.init().articlesDate = DateInfo.zeroDate
        
        //userSettings.lastAuth = DateInfo.zeroDate

        if versionManager.isNewRelease() {
            LogEvent.print(module: AppSettings.appName + "App.startupSequence", message: "New app release detected: \(VersionManager.release)")
            
            Task {
                let (success, message) = await Articles.load()
                LogEvent.print(module: AppSettings.appName + "App.startupSequence", message: message)
                
                if success {
                    await MainActor.run {
                        VersionManager.shared.isVersionUpdate = true
                        isSaveRelease = true
                    }
                }
                
            }
        }
        
        /*
        if let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()),
           userSettings.lastAuth < oneWeekAgo {
            LogEvent.print(module: AppSettings.appName + "App.startupSequence", message: "🕒 Last article check was more than 7 days ago.  Checking for updates...")
            
            Task {
                let (success, message) = await Articles.load()
                LogEvent.print(module: AppSettings.appName + "App.startupSequence", message: message)
                
                if success {
                    await MainActor.run {
                        VersionManager.shared.isVersionUpdate = true
                        isSaveRelease = true
                    }
                }
                
            }
        }
        */
        
        /// Check the permissions and availability of various handlers
        ///
        /// Location Handler
        LocationManager.shared.getAuthorizedWhenInUse { result in
            LogEvent.print(module: AppSettings.appName + "App.LocationManager.getAuthorizedWhenInUse()", message: "\(result)")
        }
        LocationManager.shared.getAuthorizedAlways { result in
            LogEvent.print(module: AppSettings.appName + "App.LocationManager.getAuthorizedAlways()", message: "\(result)")
        }
        LocationManager.shared.getAuthorizedDescription { result in
            LogEvent.print(module: AppSettings.appName + "App.LocationManager.getAuthorizedDescription()", message: "\(result)")
        }
        
        /// Activity Handler
        ActivityManager.shared.getMotionActivityAvailability { result in
            LogEvent.print(module: AppSettings.appName + "App.ActivityManager.getMotionActivityAvailability()", message: "\(result)")
        }
        ActivityManager.shared.getMotionActivityPermission { result in
            LogEvent.print(module: AppSettings.appName + "App.ActivityManager.getMotionActivityPermission()", message: "\(result)")
        }
        
        ActivityManager.shared.getActivityMonitoringStatus { result in
            LogEvent.print(module: AppSettings.appName + "App.ActivityManager.getActivityMonitoringStatus()", message: "\(result)")
            
            /** OPTION:  Use this code to start the handle
            ```
            if !result {
            ActivityManager.shared.startActivityUpdates()
            }
            ```
            */
        }
        
        /// If any of the prior actions trigger a change that completes as a result of detecting a new version then save the new release version
        ///
        if isSaveRelease {
            versionManager.saveRelease()
        }
        
        /// BACKGROUND
        ///
        /// Schedule any apps you want automatically scheduled when the app starts
        ///
        ///`BackgroundManager.shared.scheduleAppRefresh()
        ///`BackgroundManager.shared.scheduleProcessingTask()
        
        /// ASYNC PROCESSING
        ///
        /// Launch an async process that completes based on priority..
        /// Status can be checked by checking published variables.
        /// OPTION: Set the level of priority you want this task to have.  The higher the level
        /// the more impact on the user experience as they are entering the app.
        ///
        /// `Task(priority: .background)`
        ///
        let processor = AsyncProcessor()
        Task(priority: .low) {
            if !processor.isProcessing {
                LogEvent.print(module: "LaunchView.task", message: "▶️ starting AsyncProcessor()...")
                
                await processor.performAsyncTask()
                
                LogEvent.print(module: "LaunchView.task", message: "⏹️ ...finished AsyncProcessor()")
            } else {
                LogEvent.print(module: "LaunchView.task", message: "AsyncProcessor() is processing")
            }
        }
        
        LogEvent.print(module: AppSettings.appName + "App.startupSequence()", message: "⏹️ ...finished")
    }
}
