//
//  BackgroundManager.swift
//  Globulon
//
//  Created by David Holeman on 02/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

/**
 - Version: 1.0.0
 - Date: 09-27-2024
 
 - Note: This version only works under Swift5.   It crashes if run under Swift6

 # Force background execution in simulator
 This command can be executed when the app is paused at 11db prompt to force the background task to execute:
    - `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.opexnetworks.Globulon.backgroundTask"]
    - `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.opexnetworks.Globulon.appRefreshTask"]
 - Ensure the pinfo.list is updated:
    - `Permitted background task scheduler identifiers = "com.opexnetworks.Globulon.backgroundTask"
 */

import BackgroundTasks
import Combine
import UserNotifications
import SwiftUI

@MainActor class BackgroundManagerV1: ObservableObject {
    
    static let shared = BackgroundManagerV1()
    
    @Published var taskState: BackgroundTaskState = .idle
        
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
    
    /// App refresh task identifiers
    let backgroundAppRefreshTask = "com.opexnetworks." + AppSettings.appName + ".appRefreshTask"
    
    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundAppRefreshTask, using: nil) { [weak self] task in
            guard let self = self, let task = task as? BGAppRefreshTask else { return }
            self.handleAppRefresh(task: task)
        }
        self.updateTaskState(to: .idle, logMessage: "✅ Background app refresh task '\(backgroundAppRefreshTask)' registered.")
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { [weak self] task in
            guard let self = self, let task = task as? BGProcessingTask else { return }
            self.handleProcessingTask(task: task)
        }
        self.updateTaskState(to: .idle, logMessage: "✅ Background processing task '\(backgroundTaskIdentifier)' registered.")
    }
    
    /// Handle the app refresh task
    private func handleAppRefresh(task: BGAppRefreshTask) {
        self.updateTaskState(to: .running, logMessage: "🔥 Background app refresh task is now running.")
        NotificationManager.sendNotification(title: "Task Running", body: "App refresh task is now running.")

        let operation = Task {
            do {
                try await doSomeShortTaskWork()
                task.setTaskCompleted(success: true)
                let completionDate = Date()
                UserDefaults.standard.set(completionDate, forKey: "LastAppRefreshTaskCompletionDate")
                self.updateTaskState(to: .completed, logMessage: "🏁 App refresh task completed at \(formattedDate(completionDate)).")
                NotificationManager.sendNotification(title: "Task Completed", body: "App refresh task completed at: \(formattedDate(completionDate))")
            } catch {
                if Task.isCancelled {
                    self.updateTaskState(to: .expired, logMessage: "💀 App refresh task expired before completion.")
                    NotificationManager.sendNotification(title: "Task Expired", body: "App refresh task expired before completion \(self.formattedDate(Date())).")
                } else {
                    task.setTaskCompleted(success: false)
                    self.updateTaskState(to: .failed, logMessage: "❌ App refresh task failed with error.")
                    NotificationManager.sendNotification(title: "Task Failed", body: "App refresh task failed.")
                }
            }

            // Schedule the next app refresh task regardless of outcome
            scheduleAppRefresh()
        }

        task.expirationHandler = {
            operation.cancel()
            self.updateTaskState(to: .expired, logMessage: "💀 App refresh task expired before completion.")
            NotificationManager.sendNotification(title: "Task Expired", body: "App refresh task expired before completion \(self.formattedDate(Date())).")
        }
    }

    /// Schedule app refresh task
    func scheduleAppRefresh() {
        let taskIdentifier = self.backgroundAppRefreshTask
        
        //self.updateTaskState(to: .pending, logMessage: "scheduleAppRefreshTask: '\(taskIdentifier)'")
        //NotificationManager.sendNotification(title: "Schedule Task", body: "App Refresh placeholder")

        
        BGTaskScheduler.shared.getPendingTaskRequests { taskRequests in
            if taskRequests.contains(where: { $0.identifier == taskIdentifier }) {
                self.updateTaskState(to: .pending, logMessage: "⚠️ Task Pending: '\(taskIdentifier)' is already pending.")
                NotificationManager.sendNotification(title: "Task Pending", body: "App refresh task is already pending.")
                return
            }

            let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
            if let nextHour = Calendar.current.nextDate(after: Date(), matching: DateComponents(minute: 0), matchingPolicy: .nextTime) {
                request.earliestBeginDate = nextHour
            }

            do {
                try BGTaskScheduler.shared.submit(request)
                self.updateTaskState(to: .scheduledRFSH, logMessage: "✅ App refresh task '\(taskIdentifier)' successfully scheduled.")
                NotificationManager.sendNotification(title: "Task Scheduled", body: "App refresh task scheduled for the next hour.")
            } catch {
                self.updateTaskState(to: .failed, logMessage: "❌ Failed to schedule app refresh task.")
                NotificationManager.sendNotification(title: "Task Scheduling Failed", body: "Failed to schedule the app refresh task.")
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
    
    let backgroundTaskIdentifier = "com.opexnetworks." + AppSettings.appName + ".backgroundTask"

    /// Handle long-running processing task
    private func handleProcessingTask(task: BGProcessingTask) {
        self.updateTaskState(to: .running, logMessage: "🔥 Background processing task is now running.")
        NotificationManager.sendNotification(title: "Task Running", body: "Background processing task is now running.")

        let operation = Task {
            do {
                try await doSomeLongProcessingWork()
                task.setTaskCompleted(success: true)
                
                let completionDate = Date()
                UserDefaults.standard.set(completionDate, forKey: "LastBackgroundTaskCompletionDate")
                self.updateTaskState(to: .completed, logMessage: "🏁 Background processing task completed at \(formattedDate(completionDate)).")
                NotificationManager.sendNotification(title: "Task Completed", body: "Background processing task completed at: \(formattedDate(completionDate))")
            } catch {
                task.setTaskCompleted(success: false)
                self.updateTaskState(to: .failed, logMessage: "❌ Background processing task failed with error.")
                NotificationManager.sendNotification(title: "Task Failed", body: "Background processing task failed.")
            }

            scheduleProcessingTask()
        }
        task.expirationHandler = {
            operation.cancel()
            self.updateTaskState(to: .expired, logMessage: "💀 Background processing task expired before completion.")
            NotificationManager.sendNotification(title: "Task Expired", body: "Background processing task expired before completion.")
            task.setTaskCompleted(success: false)
        }
    }

    /// Schedule long-running processing task
    func scheduleProcessingTask() {
        let taskIdentifier = self.backgroundTaskIdentifier
        BGTaskScheduler.shared.getPendingTaskRequests { taskRequests in
            if taskRequests.contains(where: { $0.identifier == taskIdentifier }) {
                self.updateTaskState(to: .pending, logMessage: "⚠️ Task Pending: '\(taskIdentifier)' is already pending.")
                NotificationManager.sendNotification(title: "Task Pending", body: "Processing task is already pending.")
                return
            }
            let request = BGProcessingTaskRequest(identifier: taskIdentifier)
            
            /// Options:
            ///`request.requiresNetworkConnectivity = true
            
            /// Set the earliest begin date to 15 minutes from now
            /// eg:
            ///`request.earliestBeginDate = Date().addingTimeInterval(15 * 60)
            
            /// Create date components for 9:00 AM
            var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            dateComponents.hour = 9
            dateComponents.minute = 0

            /// Create a date for 9:00 AM today
            let calendar = Calendar.current
            if let dateAtNineAM = calendar.date(from: dateComponents) {
                /// If the current time is past 9:00 AM, set to 9:00 AM the next day
                if Date() > dateAtNineAM {
                    /// Move to the next day at 9:00 AM
                    if let tomorrowAtNineAM = calendar.date(byAdding: .day, value: 1, to: dateAtNineAM) {
                        request.earliestBeginDate = tomorrowAtNineAM
                    }
                } else {
                    /// Set to 9:00 AM today if it's still in the future
                    request.earliestBeginDate = dateAtNineAM
                }
            } else {
                // Fallback if for some reason the date couldn't be calculated
                print("Could not determine the 9:00 AM date.")
            }
            
            do {
                try BGTaskScheduler.shared.submit(request)
                self.updateTaskState(to: .scheduledBKG, logMessage: "✅ Processing task '\(taskIdentifier)' successfully scheduled.")
                NotificationManager.sendNotification(title: "Task Scheduled", body: "Processing task has been scheduled.")
            } catch {
                self.updateTaskState(to: .failed, logMessage: "‼️ Failed to schedule processing task.")
                NotificationManager.sendNotification(title: "Task Scheduling Failed", body: "Failed to schedule the processing task.")
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
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: backgroundTaskIdentifier)
        updateTaskState(to: .cancelled, logMessage: "⛔️ Background process task '\(backgroundTaskIdentifier)' has been cancelled.")
        NotificationManager.sendNotification(title: "Task Cancelled", body: "Background process task has been cancelled.")
    }
    
    func cancelAppRefreshTask() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: backgroundAppRefreshTask)
        updateTaskState(to: .cancelled, logMessage: "⛔️ Background app refresh task '\(backgroundAppRefreshTask)' has been cancelled.")
        NotificationManager.sendNotification(title: "Task Cancelled", body: "Background app refresh task has been cancelled.")
    }
    
    func cancelAllBackgroundTasks() {
        BGTaskScheduler.shared.cancelAllTaskRequests()
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
}
