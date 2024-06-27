//
//  GlobulonApp.swift
//  Globulon
//
//  Created by David Holeman on 2/13/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
// 

import SwiftUI
import SwiftData

@main
struct GlobulonApp: App {
    
    /// Register app delegate 
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @Environment(\.scenePhase) var scenePhase

    //@StateObject private var networkMonitor = NetworkMonitor()
    
    init() {
        LogEvent.print(module: "\(AppValues.appName)App.init()", message: "starting ...")

        
        /// Print out the settings in the log
        ///
        LogEvent.print(module: "\(AppValues.appName)App.init()", message: "Settings..." + printUserSettings(description: "Settings", indent: "  "))
           
        /// Start monitoring the netwokr connectivity status
        ///
        NetworkStatus.shared.startMonitoring()
        
        AppEnvironment.sharedModelContainer = initializeModelContainer()
    
        //TODO: Flush out the history model context when I need to for testing
//        let context = ModelContext(AppEnvironment.sharedModelContainer)
//        do {
//            /// Zap these if you want to delete recent trips
//            //try context.delete(model: TripSummariesSD.self)
//            //try context.delete(model: TripJournalSD.self)
//            
//            /// Zap this if you want to delete the history
//            try context.delete(model: TripHistorySummarySD.self)
//            try context.delete(model: TripHistoryTripsSD.self)
//        } catch {
//            print("** error deleting history models")
//        }
        
        /// Set any default settings here
        ///
        UserSettings.init().userMode = .development
                
        LogEvent.print(module: "\(AppValues.appName).init()", message: "... finished")

    }
    
    private func initializeModelContainer() -> ModelContainer {
        let schema = Schema([
            GpsJournalSD.self,
            TripSummariesSD.self,
            TripJournalSD.self,
            TripHistorySummarySD.self,
            TripHistoryTripsSD.self,
            TripHistoryTripJournalSD.self,
            SectionsSD.self,
            ArticlesSD.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MasterView()
                .environmentObject(UserSettings())
                //.environmentObject(LocationManager.shared)  // Singleton implementation so that we force the use of the one instance.
                .environmentObject(UserStatus())
                .environmentObject(AppStatus())
                        
        }
        .modelContainer(AppEnvironment.sharedModelContainer)
        .onChange(of: scenePhase) { scenePhase, newScenePhase in
            switch newScenePhase {
            case .background:
                print("Scene is in background")
            case .inactive:
                print("Scene is inactive")
            case .active:
                print("Scene is active")
            @unknown default:
                print("Scenee is unexpected")
            }
        }
        
    }
}
