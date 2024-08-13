//
//  ActivityHandlerClass.swift
//  Globulon
//
//  Created by David Holeman on 8/12/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import CoreMotion
import CoreLocation
import Combine
import SceneKit

// MARK: - AccelerationData
struct AccelerationData: Identifiable {
    let id = UUID()
    let timestamp: Date
    let x: Double
    let y: Double
    let z: Double
}

// MARK: - ActivityHandler
@MainActor
class ActivityHandler: ObservableObject {
    
    enum ActivityState: String {
        case walking = "Walking"
        case running = "Running"
        case driving = "Driving"
        case stationary = "Stationary"
        case unknown = "Unknown"
    }

    static let shared = ActivityHandler()

    @Published var isActivity = false
    @Published var isActivityMonitoringOn = false
    @Published var activityState: ActivityState = .stationary
    @Published var updatesStarted: Bool {
        didSet {
            UserDefaults.standard.set(updatesStarted, forKey: "activityUpdatesStarted")
            LogEvent.print(module: "ActivityHandler.updatesStarted", message: "\(updatesStarted ? "Activity updates started ..." : "... stopped activity updates")")
        }
    }

    private let motionActivityManager = CMMotionActivityManager()
    private var locationHandler: LocationHandler {
        return LocationHandler.shared
    }
    
    private let activityDataBufferLimit = 25
    @Published var activityDataBuffer: [ActivityDataBuffer] = []

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
        
        getMotionActivityPermission(completion: completion)
    }

    func startActivityUpdates() {
        guard CMMotionActivityManager.isActivityAvailable() else {
            LogEvent.print(module: "** ActivityHandler.startActivityUpdates()", message: "Activity data is not available on this device.")
            return
        }
        
        self.updatesStarted = true
        self.isActivityMonitoringOn = true
        LogEvent.print(module: "ActivityHandler.startActivityUpdates()", message: "started ...")

        motionActivityManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let self = self, let activity = activity else { return }
            self.updateActivityState(activity)
            self.updateActivityDataBuffer(location: self.locationHandler.lastLocation)
        }
    }

    func stopActivityUpdates() {
        motionActivityManager.stopActivityUpdates()
        isActivityMonitoringOn = false
        updatesStarted = false
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
            processed: false,
            code: "",
            note: "buffer:" + " " + "activity: \(isActivity ? "active" : "inactive")" + " / " + "\(activityState)"
        )
        activityDataBuffer.insert(entry, at: 0)
    }
}
