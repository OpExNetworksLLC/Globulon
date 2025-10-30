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
    
    @AppStorage("AutoStartAppRefresh") private var autoStartAppRefresh: Bool = false
    @AppStorage("AutoStartBackground") private var autoStartBackground: Bool = false
    
    /// Register app delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @Environment(\.scenePhase) var scenePhase
    
    /// Set the state object so it can be accessed in any view
    /// eg: `@EnvironmentObject var appStatus: appStatus
    /// ...
     
    @StateObject private var appStatus = AppStatus()
    @StateObject private var userStatus = UserStatus()
    @StateObject private var appEnvironment = AppEnvironment()
    @StateObject private var userSettings = UserSettings()

    @State private var isStartupSequenceComplete = false
    
    private let backgroundFetchTaskIdentifier = "com.opexnetworks.Globulon.backgroundFetch"
    private let backgroundProcessingTaskIdentifier = "com.opexnetworks.Globulon.backgroundProcessing"
    
    init() {
        
        /// Save the prior logfile
        LogManager.ArchiveLogFile()
        
        LogManager.event(module: "GlobulonApp.init()", message: "▶️ starting...")
        
        /// OPTION: Force set any settings here to start other than the app default settings
        ///
        userSettings.userMode = .development
        
        /// OPTION: Set to true when using the simulator to autologin and save time in testing.
        /// This bypasses login and keychain/firebase authentication and assumes the user is authorized
        ///
        ///`userSettings.isAutoLogin = true
        ///
        userSettings.isAutoLogin = false
        
        /// DEBUG:  Enable if you need to wipe out the entire swift data store
        ///`deleteDefaultStore()
        
        /// Based on`.userMode`chance some settings and values
        ///
        switch userSettings.userMode {
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
            /// 
            _ = purgeGPSData()
            
            break
        }
        
        #if FIREBASE_ENABLED
            userSettings.authMode = .firebase
            Analytics.setAnalyticsCollectionEnabled(userSettings.isGDPRConsentGranted)
            LogManager.event(module: "\(AppSettings.appName).init()", message: "firebase analytics enabled: \(userSettings.isGDPRConsentGranted)")
        #endif
        #if KEYCHAIN_ENABLED
            userSettings.authMode = .keychain
        #endif
        
        /// Print out the settings in the log
        LogManager.event(module: "\(AppSettings.appName).init()", message: "Settings..." + userSettings.returnAllSettings())

        /// DEBUG:  Show the log file url
        ///`LogEvent.getLogFileURL()
        
        LogManager.event(module: AppSettings.appName + "App.init()", message: "⏹️ ...finished")
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
                    .onAppear {
                        guard !isStartupSequenceComplete else { return }

                        Task(priority: .userInitiated) {
                            await startupSequence()
                            isStartupSequenceComplete = true
                        }
                        
                    }
            }
        }
        
        /// Heres is where we make the Shared Model Container available as a singleton across the App for use in views
        ///
        .modelContainer(ModelContainerProvider.shared)
        
        .onChange(of: scenePhase) { scenePhase, newScenePhase in
            switch newScenePhase {
            case .background:
                LogManager.event(module: AppSettings.appName + ".onChangeOf", message: "Scene is in background")
                
                /// EXAMPLE:  In some apps you may want to save your context or other data before dropping into background mode
                ///`persistanceController.save()
                
                /// OPTION:  Schedule any background task(s)
                ///`BackgroundManager.shared.scheduleProcessingTask()
                
                saveSettings()
            case .inactive:
                //LogManager.event(module: AppSettings.appName + ".onChangeOf", message: "Scene is inactive")
                break
            case .active:
                //LogManager.event(module: AppSettings.appName + ".onChangeOf", message: "Scene is active")
                break
            @unknown default:
                //LogManager.event(module: AppSettings.appName + ".onChangeOf", message: "Scene is unexpected")
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
        
        LogManager.event(module: AppSettings.appName + "App.startupSequence", message: "▶️ starting...")
        
        let versionManager = VersionManager.shared
        
        var isSaveRelease = false
        
        // Debug stuff (remove)
        //
        //versionManager.resetRelease()
        //Articles.deleteArticles()
        //userSettings.articlesDate = DateInfo.zeroDate
        //userSettings.lastAuth = DateInfo.zeroDate
        
        
        /// Background processing
        ///
        if autoStartAppRefresh {
            BackgroundManager.shared.scheduleAppRefresh()
        }
        if autoStartBackground {
            BackgroundManager.shared.scheduleProcessingTask()
        }
        
        
        /// ARTICLES
        ///
        let now = Date()
        let isNewRelease = versionManager.isNewRelease()
        let lastCheck = userSettings.lastArticlesCheck
        let daysSinceCheck = Calendar.current.dateComponents([.day], from: lastCheck, to: now).day ?? Int.max

        if isNewRelease {
            LogManager.event(module: AppSettings.appName + "App.startupSequence", message: "New app release detected: \(VersionManager.release)")
            
            Articles.deleteArticles()
            userSettings.articlesDate = DateInfo.zeroDate
            userSettings.lastArticlesCheck = now
            
            LogManager.event(module: AppSettings.appName + "App.startupSequence", message: "loading articles ...")
            let (success, _) = await Articles.load()
            
            if success {
                VersionManager.shared.isVersionUpdate = true
                isSaveRelease = true
                userSettings.lastArticlesCheck = now
            }

        } else if daysSinceCheck > 14 || (daysSinceCheck > 7 && userSettings.lastAuth < lastCheck) {
            LogManager.event(module: AppSettings.appName + "App.startupSequence", message: "🕒 Time-based article check triggered (days since last check: \(daysSinceCheck)).")

            let (success, _) = await Articles.load()
            if success {
                userSettings.lastArticlesCheck = now
            }
        }
        
        /// Check the permissions and availability of various handlers
        ///
        /// Location Manager
        /// 
        LocationManager.shared.getAuthorizedWhenInUse { result in
            LogManager.event(module: AppSettings.appName + "App.LocationManager.getAuthorizedWhenInUse()", message: "\(result)")
        }
        LocationManager.shared.getAuthorizedAlways { result in
            LogManager.event(module: AppSettings.appName + "App.LocationManager.getAuthorizedAlways()", message: "\(result)")
        }
        LocationManager.shared.getAuthorizedDescription { result in
            LogManager.event(module: AppSettings.appName + "App.LocationManager.getAuthorizedDescription()", message: "\(result)")
        }
        
        /// Activity Handler
        ActivityManager.shared.getMotionActivityAvailability { result in
            LogManager.event(module: AppSettings.appName + "App.ActivityManager.getMotionActivityAvailability()", message: "\(result)")
        }
        ActivityManager.shared.getMotionActivityPermission { result in
            LogManager.event(module: AppSettings.appName + "App.ActivityManager.getMotionActivityPermission()", message: "\(result)")
        }
        
        ActivityManager.shared.getActivityMonitoringStatus { result in
            LogManager.event(module: AppSettings.appName + "App.ActivityManager.getActivityMonitoringStatus()", message: "\(result)")
            
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

        let processor = AsyncProcessor()
        Task(priority: .low) {
            if !processor.isProcessing {
                LogManager.event(module: AppSettings.appName + "App.startupSequence()", message: "▶️ starting AsyncProcessor()...")
                
                await processor.performAsyncTask()
                
                LogManager.event(module: AppSettings.appName + "App.startupSequence()", message: "⏹️ ...finished AsyncProcessor()")
            } else {
                LogManager.event(module: AppSettings.appName + "App.startupSequence()", message: "AsyncProcessor() is processing")
            }
        }
        
        LogManager.event(module: AppSettings.appName + "App.startupSequence()", message: "⏹️ ...finished")
    }
    
    
    // MARK: - Save settings
    
    private func saveSettings() {
        
        /// Saving lastAuth - only when not the same as today
        ///
        let calendar = Calendar.current
        let now = Date()
        if !calendar.isDate(userSettings.lastAuth, inSameDayAs: now) {
            userSettings.lastAuth = now
        }
    }
}
