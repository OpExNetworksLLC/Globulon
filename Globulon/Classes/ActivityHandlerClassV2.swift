//
//  ActivityHandlerClassV2.swift
//  Globulon
//
//  Created by David Holeman on 7/16/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

/// # ActivityHandlerClass
/// Show live activity information
///
/// # Version History
/// ### 0.1.0.66
/// # - Created
/// # - *Date*: 07/16/24

import Combine
import CoreMotion
import CoreLocation

@MainActor
class ActivityHandler: ObservableObject {
    
    enum ActivityState: String {
        case walking = "Walking"
        case running = "Running"
        case driving = "Driving"
        case stationary = "Stationary"
        case unknown = "Unknown"
    }
    
    private let activityDataBufferLimit = 25
    @Published var activityDataBuffer: [ActivityDataBuffer] = []
    
    private var locationHandler: LocationHandler {
        return LocationHandler.shared
    }
    
    static let shared = ActivityHandler()
    
    private let manager = CMMotionActivityManager()
    
    @Published var isActivityMonitoringOn = false
    @Published var isActivity = false
    @Published var activityState: ActivityState = .stationary
    
    @Published var updatesStarted: Bool {
        didSet {
            UserDefaults.standard.set(updatesStarted, forKey: "activityUpdatesStarted")
            LogEvent.print(module: "ActivityHandler.updatesStarted", message: "\(updatesStarted ? "Activity updates started ..." : "... stopped activity updates")")
        }
    }
    
    private init() {
        self.updatesStarted = UserDefaults.standard.bool(forKey: "activityUpdatesStarted")
    }
    
    class func getMotionActivityPermission(completion: @escaping (Bool) -> Void) {
        let isAuthorized = CMMotionActivityManager.authorizationStatus() == .authorized
        LogEvent.print(module: "MotionManager.getMotionTrackingPermission()",
                       message: "Motion tracking permission is: \(isAuthorized ? "true" : "false").")
        completion(isAuthorized)
    }

    func getMotionActivityStatus(completion: @escaping (Bool) -> Void) {
        if CMMotionActivityManager.isActivityAvailable() {
            let status = CMMotionActivityManager.authorizationStatus()
            switch status {
            case .authorized:
                completion(true)
            default:
                completion(false)
            }
        } else {
            completion(false)
        }
    }
    
    class func requestMotionActivityPermission(completion: @escaping (Bool) -> Void) {
        let motionActivityManager = CMMotionActivityManager()
        motionActivityManager.startActivityUpdates(to: .main) { _ in
            LogEvent.print(module: "ActivityHandler.requestMotionActivityPermission()", message: "Motion activity updates have started...")
        }
        
        let motionManager = CMMotionManager()
        motionManager.startDeviceMotionUpdates(to: .main) { _, _ in
            LogEvent.print(module: "ActivityHandler.requestMotionActivityPermission()", message: "Device Motion Activity updates have started...")
        }
        
        getMotionActivityPermission(completion: completion)
    }
    
    func startActivityUpdates() {
        guard CMMotionActivityManager.isActivityAvailable() else {
            LogEvent.print(module: "** ActivityHandler.startActivityUpdates()", message: "Activity data is not available on this device.")
            return
        }
        
        self.isActivityMonitoringOn = true
        self.updatesStarted = true
        LogEvent.print(module: "ActivityHandler.startActivityUpdates()", message: "started ...")
        
        manager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let self = self, let activity = activity else { return }
            self.updateActivityState(activity)
            updateActivityDataBuffer(location: locationHandler.siftLocation)
        }
    }
    
    func stopActivityUpdates() {
        manager.stopActivityUpdates()
        isActivityMonitoringOn = false
        LogEvent.print(module: "ActivityHandler.stopActivityUpdates()", message: "Stopping activity updates")
    }
    
    private func updateActivityState(_ activity: CMMotionActivity) {
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
        
        self.isActivity = !(activity.stationary || activity.unknown)
    }
    
    func updateActivityDataBuffer(location: CLLocation?) {
        
        /// Guard to make sure location is not nil and speed is greater than or equal to zero before moving on
        ///
        guard let location = location, location.speed >= 0 else {
            return
        }
        
        //LogEvent.print(module: "updateLocationDataBuffer", message: "Location \(location)" )

        
        /// Check if the array has reached its capacity
        ///
        if activityDataBuffer.count >= activityDataBufferLimit {
            /// Remove the oldest entry to make space for the new one
            ///
            activityDataBuffer.removeLast()
        }
        /// Insert the new data at the beginning of the array, treating it as a queue
        ///
        let entry = ActivityDataBuffer(
            timestamp: Date(),
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            speed: location.speed,
            processed: false,
            code: "",
            note: "buffer:" + " " + "activity: \(isActivity ? "active" : "inactive")" + " / " + "\(activityState)"
        )
        activityDataBuffer.insert(entry, at: 0)
                
    }
}

