//
//  ActivityHandlerClass.swift
//  Globulon
//
//  Created by David Holeman on 6/26/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import CoreMotion
import Combine

@MainActor class ActivityHandler: ObservableObject {
    
    static let shared = ActivityHandler()
    
    private let manager: CMMotionActivityManager
    
    @Published var isActivity = false
    @Published var activityState: ActivityState = .stationary
    
    private init() {
        self.manager = CMMotionActivityManager()
    }
    
    func startActivityUpdates() {
        guard CMMotionActivityManager.isActivityAvailable() else {
            print("Activity data is not available on this device.")
            return
        }
        
        manager.startActivityUpdates(to: OperationQueue.main) { [weak self] activity in
            guard let self = self, let activity = activity else { return }
            LogEvent.print(module: "ActivityHandler.startActivityUpdates()", message: "Starting activity updates")
            self.updateActivityState(activity)
        }
    }
    
    func stopActivityUpdates() {
        manager.stopActivityUpdates()
        LogEvent.print(module: "ActivityHandler.stopActivityUpdates()", message: "Stopping activity updates")
    }
    
    private func updateActivityState(_ activity: CMMotionActivity) {
        Task { @MainActor in
            if activity.walking {
                self.activityState = .walking
            } else if activity.running {
                self.activityState = .running
            } else if activity.automotive {
                self.activityState = .driving
            } else if activity.stationary {
                self.activityState = .stationary
            } else {
                self.activityState = .unknown
            }
            
            // Update isActivity based on the activity state
            self.isActivity = !activity.stationary && !activity.unknown
            
            // Log the activity state
            print("Current activity state: \(activityState.rawValue)")
        }
    }
}

enum ActivityState: String {
    case walking = "Walking"
    case running = "Running"
    case driving = "Driving"
    case stationary = "Stationary"
    case unknown = "Unknown"
}
