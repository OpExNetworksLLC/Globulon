//
//  ActivityManager.swift
//  Globulon
//
//  Created by David Holeman on 02/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

/**
 - Version: 1.0.0 (2025-02-25)
 - Note:
    - Version: 1.0.0 (2025-02-25)
        - (created)
*/

import Foundation
import CoreMotion
import CoreLocation
import Combine
import SceneKit

struct ActivityDataBuffer: Codable, Hashable {
    var timestamp: Date
    var latitude: Double
    var longitude: Double
    var speed: Double
    var state: String
    var processed: Bool
    var code: String
    var note: String
}

@MainActor
class ActivityManager: ObservableObject {
    
    enum ActivityState: String {
        case walking = "Walking"
        case running = "Running"
        case driving = "Driving"
        case stationary = "Stationary"
        case unknown = "Unknown"
    }

    static let shared = ActivityManager()

    @Published var isActivity = false
    @Published var isActivityMonitoringOn = false
    @Published var isAuthorized = false
    @Published var isAvailable = false
    
    @Published var activityState: ActivityState = .stationary
    @Published var updatesLive: Bool {
        didSet {
            UserDefaults.standard.set(updatesLive, forKey: "activityupdatesLive")
            LogManager.event(module: "ActivityManager.updatesLive", message: "\(updatesLive ? "Activity updates started ..." : "... stopped activity updates")")
        }
    }

    private let motionActivityManager = CMMotionActivityManager()
    
//    private var locationHandler: LocationHandler {
//        return LocationHandler.shared
//    }
    
    private let activityDataBufferLimit = 25
    @Published var activityDataBuffer: [ActivityDataBuffer] = []

    private init() {
        self.updatesLive = UserDefaults.standard.bool(forKey: "activityupdatesLive")
        
        // Initialize the properties based on current states
        self.isAvailable = CMMotionActivityManager.isActivityAvailable()
        self.isAuthorized = CMMotionActivityManager.authorizationStatus() == .authorized

    }

    func getMotionActivityPermission(completion: @escaping (Bool) -> Void) {
        let isAuthorized = CMMotionActivityManager.authorizationStatus() == .authorized
        //LogManager.event(module: "MotionManager.getMotionTrackingPermission()", message: "Motion tracking permission is: \(isAuthorized ? "true" : "false").")
        self.isAuthorized = isAuthorized
        completion(isAuthorized)
    }
    
    /// Get motion device availability
    func getMotionActivityAvailability(completion: @escaping (Bool) -> Void) {
        let status = CMMotionActivityManager.isActivityAvailable()
        self.isAvailable = status
        completion(status)
    }

    /// Get motion device monitoring status.  Used to check from a function call outside a view
    func getActivityMonitoringStatus(completion: @escaping (Bool) -> Void) {
        completion(self.isActivityMonitoringOn)
    }
    
    class func requestMotionActivityPermission(completion: @escaping (Bool) -> Void) {
        let motionActivityManager = CMMotionActivityManager()
        motionActivityManager.startActivityUpdates(to: .main) { _ in
            LogManager.event(module: "ActivityManager.requestMotionActivityPermission()", message: "Motion activity updates have started...")
        }
        
        //getMotionActivityPermission(completion: completion)
    }

    func startActivityUpdates() {
        guard CMMotionActivityManager.isActivityAvailable() else {
            LogManager.event(module: "** ActivityManager.startActivityUpdates()", message: "Activity data is not available on this device.")
            return
        }
        self.isAvailable = true
        
        self.updatesLive = true
        self.isActivityMonitoringOn = true
        LogManager.event(module: "ActivityManager.startActivityUpdates()", message: "started ...")

        motionActivityManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let self = self, let activity = activity else { return }
            self.updateActivityState(activity)
            //self.updateActivityDataBuffer(location: self.locationHandler.lastLocation)
        }
    }

    func stopActivityUpdates() {
        motionActivityManager.stopActivityUpdates()
        isActivityMonitoringOn = false
        updatesLive = false
        LogManager.event(module: "ActivityManager.stopActivityUpdates()", message: "Stopping activity updates")
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

    private func updateActivityDataBuffer(location: CLLocation?) {
        guard let location = location, location.speed >= 0 else { return }

        if activityDataBuffer.count >= activityDataBufferLimit {
            activityDataBuffer.removeLast()
        }

        let entry = ActivityDataBuffer(
            timestamp: Date(),
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            speed: location.speed,
            state: activityState.rawValue,
            processed: false,
            code: "",
            note: "buffer:" + " " + "activity: \(isActivity ? "active" : "inactive")" + " / " + "\(activityState)"
        )
        activityDataBuffer.insert(entry, at: 0)
    }
}
