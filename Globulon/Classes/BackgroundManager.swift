//
//  BackgroundManager.swift
//  BackgroundManager
//
//  Created by David Holeman on 10/17/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

/**
 - Version: 2.0.0
 - Date: 2025-04-17
 
 - Version: 2.0.0 (2024.04.27)
     - Key improvements included:
        -

 - Note: This version is Swift 6 and Conncurrency compliant

 # Force background execution in simulator
 This command can be executed when the app is paused at 11db prompt to force the background task to execute:
    - `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.opexnetworks.ViDrive.backgroundTask"]
    - `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.opexnetworks.ViDrive.appRefreshTask"]
 - Ensure the pinfo.list is updated:
    - `Permitted background task scheduler identifiers = "com.opexnetworks.Globulon.backgroundTask"
 */

import BackgroundTasks
import Combine
import UserNotifications
import SwiftUI
import os.log

@MainActor class BackgroundManager: ObservableObject {
    
    static let shared = BackgroundManager()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.opexnetworks.app", category: "BackgroundManager")
    
    /// Deprecated: Use per-task state properties instead
    @Published var taskState: BackgroundTaskState = .idle
    
    /// New per-task status properties
    @Published var appRefreshTaskState: BackgroundTaskState = .idle
    @Published var backgroundProcessingTaskState: BackgroundTaskState = .idle
    
    private let appRefreshIntervalKey = "AppRefreshIntervalMinutes"
    private let backgroundIntervalKey = "BackgroundTaskIntervalMinutes"
    private var lastScheduledAppRefresh: Date? = nil
    private var lastScheduledProcessing: Date? = nil
        
    /// Enum to represent different task states
    enum BackgroundTaskState: String {
        case idle = "Idle"
        case scheduled = "Scheduled"
        case scheduledRFSH = "Scheduled Refresh"
        case scheduledBKG = "Scheduled Background"
        case pending = "Pending"
        case running = "Running"
        case completed = "Completed"
        case expired = "Expired"
        case failed = "Failed"
        case cancelled = "Cancelled"
        case allCancelled = "All Tasks Cancelled"
        
        /// Computed property to return string representation for each state
        var statusDescription: String {
            return self.rawValue
        }
    }
    
    /// Task identifiers
    let backgroundAppRefreshTask = "com.opexnetworks." + AppSettings.appName + ".appRefreshTask"
    let backgroundTaskIdentifier = "com.opexnetworks." + AppSettings.appName + ".backgroundTask"
    
    ///  Keys used to store if background tasks and processes have been scheduled.
    let backgroundAppRefreshTaskScheduledKey = "backgroundAppRefreshTaskScheduledKey"
    let backgroundTaskIdentifierScheduledKey = "backgroundTaskIdentifierScheduledKey"
    
    private var didRegisterBackgroundTasks = false
    private init() {}
    
    func registerBackgroundTask() {
        // Ensure idempotent registration; BGTask identifiers must only be registered once per process
        if didRegisterBackgroundTasks {
            logger.info("registerBackgroundTask() called again; skipping duplicate registration")
            LogManager.event(module: "BackgroundManager", message: "ℹ️ Background tasks already registered; skipping duplicate registration.")
            return
        }
        logger.info("Registering background tasks")
        LogManager.event(module: "BackgroundManager", message: "🧾 Registering background tasks…")
        
        /// Uncomment if you want to send a notification of registration
        ///
        // NotificationManager.sendNotification(title: "Background Tasks", body: "Registering background tasks…")
        
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundAppRefreshTask, using: nil) { task in
            Task {
                await self.handleAppRefresh(task: task as! BGAppRefreshTask)
            }
        }
        self.updateTaskState(to: .idle, logMessage: "✅ Background app refresh task '\(backgroundAppRefreshTask)' registered.")
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
            Task {
                await self.handleProcessingTask(task: task as! BGProcessingTask)
            }
        }
        self.updateTaskState(to: .idle, logMessage: "✅ Background processing task '\(backgroundTaskIdentifier)' registered.")
        
        didRegisterBackgroundTasks = true
    }
    
    /// Handle the app refresh task
    private func handleAppRefresh(task: BGAppRefreshTask) async {
        self.appRefreshTaskState = .running
        self.updateTaskState(to: .running, logMessage: "🔥 App refresh task is now running.")
        logger.info("App refresh task running")
        UserDefaults.standard.set(false, forKey: self.backgroundAppRefreshTaskScheduledKey)
        NotificationManager.sendNotification(title: "Task Running", body: "App refresh task is now running.")


        task.expirationHandler = {
            self.logger.error("App refresh task expired")
            self.appRefreshTaskState = .expired
            self.taskState = .expired
            UserDefaults.standard.set(false, forKey: self.backgroundAppRefreshTaskScheduledKey)
            task.setTaskCompleted(success: false)
            self.updateTaskState(to: .expired, logMessage: "💀 App refresh task expired before completion.")
            NotificationManager.sendNotification(title: "Task Expired", body: "App refresh task expired before completion \(self.formattedDate(Date())).")
        }

        do {
            try await doSomeShortTaskWork()
            task.setTaskCompleted(success: true)
            self.logger.info("App refresh task completed successfully")
            UserDefaults.standard.set(false, forKey: self.backgroundAppRefreshTaskScheduledKey)
            self.appRefreshTaskState = .completed
            self.taskState = .completed
            let completionDate = Date()
            UserDefaults.standard.set(completionDate, forKey: "LastAppRefreshTaskCompletionDate")
            self.updateTaskState(to: .completed, logMessage: "🏁 App refresh task completed at \(formattedDate(completionDate)).")
            NotificationManager.sendNotification(title: "Task Completed", body: "App refresh task completed at: \(formattedDate(completionDate))")
        } catch {
            self.logger.error("App refresh task failed: \(String(describing: error))")
            UserDefaults.standard.set(false, forKey: self.backgroundAppRefreshTaskScheduledKey)
            task.setTaskCompleted(success: false)
            self.appRefreshTaskState = .failed
            self.taskState = .failed
            self.updateTaskState(to: .failed, logMessage: "❌ App refresh task failed with error.")
            NotificationManager.sendNotification(title: "Task Failed", body: "App refresh task failed.")
        }

        scheduleAppRefresh()
    }

    /// Schedule app refresh task
    func scheduleAppRefresh() {
        logger.info("Scheduling app refresh request…")
        NotificationManager.sendNotification(title: "App Refresh", body: "Scheduling app refresh initiated…")
        let taskIdentifier = self.backgroundAppRefreshTask
        BGTaskScheduler.shared.getPendingTaskRequests { pending in
            // Check if a request with this identifier is already pending
            if pending.contains(where: { $0.identifier == taskIdentifier }) {
                Task { @MainActor in
                    self.logger.info("App refresh already pending; skipping submit")
                    self.appRefreshTaskState = .pending
                    self.updateTaskState(to: .pending, logMessage: "⚠️ Task Pending: '\(taskIdentifier)' is already pending with the system.")
                    NotificationManager.sendNotification(title: "Task Pending", body: "App refresh task is already pending.")
                }
                return
            }

            let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)

            // Use UserDefaults interval for earliestBeginDate, fallback to next hour
            let intervalMinutes = UserDefaults.standard.integer(forKey: self.appRefreshIntervalKey)
            if intervalMinutes > 0 {
                let next = Date().addingTimeInterval(TimeInterval(intervalMinutes * 60))
                request.earliestBeginDate = next
            } else {
                if let nextHour = Calendar.current.nextDate(after: Date(), matching: DateComponents(minute: 0), matchingPolicy: .nextTime) {
                    request.earliestBeginDate = nextHour
                }
            }

            do {
                try BGTaskScheduler.shared.submit(request)
                Task { @MainActor in
                    self.logger.info("App refresh submitted to BGTaskScheduler")
                    UserDefaults.standard.set(true, forKey: self.backgroundAppRefreshTaskScheduledKey)
                    let scheduledDate = request.earliestBeginDate
                    self.lastScheduledAppRefresh = scheduledDate
                    if let scheduledDate = scheduledDate {
                        UserDefaults.standard.set(scheduledDate, forKey: "NextAppRefreshDate")
                    }
                    self.appRefreshTaskState = .scheduledRFSH
                    self.taskState = .scheduled
                    let formatted = scheduledDate != nil ? self.formattedDate(scheduledDate!) : "unknown"
                    self.updateTaskState(to: .scheduledRFSH, logMessage: "✅ App refresh task '\(taskIdentifier)' successfully scheduled for: \(formatted).")
                    NotificationManager.sendNotification(title: "Task Scheduled", body: "App refresh task scheduled for: \(formatted)")
                }
            } catch {
                Task { @MainActor in
                    self.logger.error("Failed to submit app refresh request")
                    UserDefaults.standard.set(false, forKey: self.backgroundAppRefreshTaskScheduledKey)
                    self.appRefreshTaskState = .failed
                    self.taskState = .failed
                    self.updateTaskState(to: .failed, logMessage: "❌ Failed to schedule app refresh task.")
                    NotificationManager.sendNotification(title: "Task Scheduling Failed", body: "Failed to schedule the app refresh task.")
                }
            }
        }
    }

    /// Short task work simulation
    private func doSomeShortTaskWork() async throws {
        print("Doing some short task work...")
        try await Task.sleep(nanoseconds: 3 * 1_000_000_000) // Reduced sleep time to 3 seconds
        try Task.checkCancellation() // Check if the task has been cancelled
        print("Short task work completed.")
    }
    

    //MARK: Background task management

    /// Handle long-running processing task
    private func handleProcessingTask(task: BGProcessingTask) async {
        self.backgroundProcessingTaskState = .running
        self.updateTaskState(to: .running, logMessage: "🔥 Background processing task is now running.")
        logger.info("Background processing task running")
        UserDefaults.standard.set(false, forKey: self.backgroundTaskIdentifierScheduledKey)
        NotificationManager.sendNotification(title: "Task Running", body: "Background processing task is now running.")

        let operation = Task {
            do {
                try await doSomeLongProcessingWork()
                task.setTaskCompleted(success: true)
                self.logger.info("Background processing task completed successfully")
                UserDefaults.standard.set(false, forKey: self.backgroundTaskIdentifierScheduledKey)
                
                let completionDate = Date()
                UserDefaults.standard.set(completionDate, forKey: "LastBackgroundTaskCompletionDate")
                self.backgroundProcessingTaskState = .completed
                self.taskState = .completed
                self.updateTaskState(to: .completed, logMessage: "🏁 Background processing task completed at \(formattedDate(completionDate)).")
                NotificationManager.sendNotification(title: "Task Completed", body: "Background processing task completed at: \(formattedDate(completionDate))")
            } catch {
                self.logger.error("Background processing task failed: \(String(describing: error))")
                UserDefaults.standard.set(false, forKey: self.backgroundTaskIdentifierScheduledKey)
                task.setTaskCompleted(success: false)
                self.backgroundProcessingTaskState = .failed
                self.taskState = .failed
                self.updateTaskState(to: .failed, logMessage: "❌ Background processing task failed with error.")
                NotificationManager.sendNotification(title: "Task Failed", body: "Background processing task failed.")
            }

            scheduleProcessingTask()
        }
        task.expirationHandler = {
            self.logger.error("Background processing task expired")
            operation.cancel()
            self.backgroundProcessingTaskState = .expired
            self.taskState = .expired
            UserDefaults.standard.set(false, forKey: self.backgroundTaskIdentifierScheduledKey)
            self.updateTaskState(to: .expired, logMessage: "💀 Background processing task expired before completion.")
            NotificationManager.sendNotification(title: "Task Expired", body: "Background processing task expired before completion.")
            task.setTaskCompleted(success: false)
        }
    }

    /// Schedule long-running processing task
    func scheduleProcessingTask() {
        logger.info("Scheduling background processing request…")
        NotificationManager.sendNotification(title: "Processing Task", body: "Scheduling processing task initiated…")
        let taskIdentifier = self.backgroundTaskIdentifier

        BGTaskScheduler.shared.getPendingTaskRequests { pending in
            if pending.contains(where: { $0.identifier == taskIdentifier }) {
                Task { @MainActor in
                    self.logger.info("Processing task already pending; skipping submit")
                    self.backgroundProcessingTaskState = .pending
                    self.updateTaskState(to: .pending, logMessage: "⚠️ Task Pending: '\(taskIdentifier)' is already pending with the system.")
                    NotificationManager.sendNotification(title: "Task Pending", body: "Processing task is already pending.")
                }
                return
            }

            let request = BGProcessingTaskRequest(identifier: taskIdentifier)

            // Use UserDefaults interval for earliestBeginDate, fallback to 9:00 AM logic
            let intervalMinutes = UserDefaults.standard.integer(forKey: self.backgroundIntervalKey)
            if intervalMinutes > 0 {
                let next = Date().addingTimeInterval(TimeInterval(intervalMinutes * 60))
                request.earliestBeginDate = next
            } else {
                // Create date components for 9:00 AM
                var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                dateComponents.hour = 9
                dateComponents.minute = 0
                let calendar = Calendar.current
                if let dateAtNineAM = calendar.date(from: dateComponents) {
                    if Date() > dateAtNineAM {
                        if let tomorrowAtNineAM = calendar.date(byAdding: .day, value: 1, to: dateAtNineAM) {
                            request.earliestBeginDate = tomorrowAtNineAM
                        }
                    } else {
                        request.earliestBeginDate = dateAtNineAM
                    }
                }
            }

            do {
                try BGTaskScheduler.shared.submit(request)
                Task { @MainActor in
                    self.logger.info("Background processing submitted to BGTaskScheduler")
                    UserDefaults.standard.set(true, forKey: self.backgroundTaskIdentifierScheduledKey)
                    self.lastScheduledProcessing = request.earliestBeginDate
                    if let d = request.earliestBeginDate { UserDefaults.standard.set(d, forKey: "NextBackgroundTaskDate") }
                    self.backgroundProcessingTaskState = .scheduledBKG
                    self.taskState = .scheduled
                    let formatted = request.earliestBeginDate != nil ? self.formattedDate(request.earliestBeginDate!) : "unknown"
                    self.updateTaskState(to: .scheduledBKG, logMessage: "✅ Processing task '\(self.backgroundTaskIdentifier)' successfully scheduled for: \(formatted).")
                    NotificationManager.sendNotification(title: "Task Scheduled", body: "Processing task scheduled for: \(formatted)")
                }
            } catch {
                Task { @MainActor in
                    self.logger.error("Failed to submit background processing request")
                    UserDefaults.standard.set(false, forKey: self.backgroundTaskIdentifierScheduledKey)
                    self.backgroundProcessingTaskState = .failed
                    self.taskState = .failed
                    self.updateTaskState(to: .failed, logMessage: "‼️ Failed to schedule processing task.")
                    NotificationManager.sendNotification(title: "Task Scheduling Failed", body: "Failed to schedule the processing task.")
                }
            }
        }
    }

    // Long processing work simulation
    private func doSomeLongProcessingWork() async throws {
        print("Doing long processing task...")
        try await Task.sleep(nanoseconds: 20 * 1_000_000_000)
        print("Long processing work completed.")
    }
    
    func cancelBackgroundTask() {
        logger.info("Cancelling background processing request")
        NotificationManager.sendNotification(title: "Processing Task", body: "Cancelling processing task…")
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: backgroundTaskIdentifier)
        UserDefaults.standard.set(false, forKey: self.backgroundTaskIdentifierScheduledKey)
        self.backgroundProcessingTaskState = .cancelled
        self.taskState = .cancelled
        updateTaskState(to: .cancelled, logMessage: "⛔️ Background process task '\(backgroundTaskIdentifier)' has been cancelled.")
        NotificationManager.sendNotification(title: "Task Cancelled", body: "Background process task has been cancelled.")
    }
    
    func cancelAppRefreshTask() {
        logger.info("Cancelling app refresh request")
        NotificationManager.sendNotification(title: "App Refresh", body: "Cancelling app refresh task…")
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: backgroundAppRefreshTask)
        UserDefaults.standard.set(false, forKey: self.backgroundAppRefreshTaskScheduledKey)
        self.appRefreshTaskState = .cancelled
        self.taskState = .cancelled
        updateTaskState(to: .cancelled, logMessage: "⛔️ Background app refresh task '\(backgroundAppRefreshTask)' has been cancelled.")
        NotificationManager.sendNotification(title: "Task Cancelled", body: "Background app refresh task has been cancelled.")
    }
    
    func cancelAllBackgroundTasks() {
        logger.info("Cancelling all background task requests")
        NotificationManager.sendNotification(title: "Background Tasks", body: "Cancelling all background tasks…")
        BGTaskScheduler.shared.cancelAllTaskRequests()
        UserDefaults.standard.set(false, forKey: self.backgroundAppRefreshTaskScheduledKey)
        UserDefaults.standard.set(false, forKey: self.backgroundTaskIdentifierScheduledKey)
        UserDefaults.standard.removeObject(forKey: "NextAppRefreshDate")
        UserDefaults.standard.removeObject(forKey: "NextBackgroundTaskDate")
        self.lastScheduledAppRefresh = nil
        self.lastScheduledProcessing = nil
        self.appRefreshTaskState = .allCancelled
        self.backgroundProcessingTaskState = .allCancelled
        self.taskState = .allCancelled
        updateTaskState(to: .allCancelled, logMessage: "⛔️ All background tasks have been cancelled.")
        NotificationManager.sendNotification(title: "All Tasks Cancelled", body: "All background tasks have been cancelled.")
    }
    
    
    // Format the date for display
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd h:mm:ss a"
        return formatter.string(from: date)
    }
    
    /// Centralized state updater
    private func updateTaskState(to newState: BackgroundTaskState, logMessage: String? = nil) {
        DispatchQueue.main.async {
            self.taskState = newState
            if let message = logMessage {
                LogManager.event(module: "BackgroundManager", message: message)
            }
        }
    }
    
    func nextAppRefreshDate() -> Date? {
        if let d = UserDefaults.standard.object(forKey: "NextAppRefreshDate") as? Date { return d }
        return nil
    }

    func nextProcessingDate() -> Date? {
        if let d = UserDefaults.standard.object(forKey: "NextBackgroundTaskDate") as? Date { return d }
        return nil
    }
    
    /// Ensure background tasks are registered and scheduled appropriately on app launch/relaunch
    func ensureSchedulingOnLaunch() {
        // Registering is idempotent but should be done at launch as well
        logger.info("Ensuring scheduling on launch…")
        LogManager.event(module: "BackgroundManager", message: "🚀 Ensuring scheduling on launch…")

        // App Refresh policy: if user opted-in or if previously marked scheduled, ensure a request exists
        let intendedAppRefresh = UserDefaults.standard.bool(forKey: backgroundAppRefreshTaskScheduledKey) || UserDefaults.standard.bool(forKey: "AutoStartAppRefresh")
        if intendedAppRefresh {
            logger.info("Ensuring app refresh is scheduled")
            scheduleAppRefresh()
        }

        // Processing policy: if user opted-in or if previously marked scheduled, ensure a request exists
        let intendedProcessing = UserDefaults.standard.bool(forKey: backgroundTaskIdentifierScheduledKey) || UserDefaults.standard.bool(forKey: "AutoStartBackground")
        if intendedProcessing {
            logger.info("Ensuring background processing is scheduled")
            scheduleProcessingTask()
        }

        // Emit current known dates
        if let nextR = nextAppRefreshDate() {
            LogManager.event(module: "BackgroundManager", message: "📆 Next App Refresh: \(formattedDate(nextR))")
        }
        if let nextB = nextProcessingDate() {
            LogManager.event(module: "BackgroundManager", message: "📆 Next Processing: \(formattedDate(nextB))")
        }

        // Fire a lightweight local notification summarizing state
        NotificationManager.sendNotification(title: "Background Tasks", body: "Ensured scheduling on launch.")
    }
}

