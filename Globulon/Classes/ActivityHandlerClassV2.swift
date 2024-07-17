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

import Foundation
import CoreMotion
import CoreLocation
import Combine

@MainActor
class ActivityHandler: ObservableObject {
    
    enum ActivityState: String {
        case walking = "Walking"
        case running = "Running"
        case driving = "Driving"
        case stationary = "Stationary"
        case unknown = "Unknown"
    }
    
    struct AccelerometerData {
        var x: Double
        var y: Double
        var z: Double
    }
    
    private let activityDataBufferLimit = 25
    @Published var activityDataBuffer: [ActivityDataBuffer] = []

    private let motionDataBufferLimit = 25
    @Published var motionDataBuffer: [MotionDataBuffer] = []

    
    @Published var accelerometerData: AccelerometerData
    
    private var locationHandler: LocationHandler {
        return LocationHandler.shared
    }
    
    static let shared = ActivityHandler()
    
    private let motionActivityManager = CMMotionActivityManager()
    private let motionManager = CMMotionManager()
    
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
        self.accelerometerData = AccelerometerData(x: 0.0, y: 0.0, z: 0.0)
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

    func startMotionUpdates() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
                guard let self = self, let data = data, error == nil else { return }
                self.processAccelerometerData(data)
            }
            LogEvent.print(module: "ActivityHandler.startMotionUpdates()", message: "Accelerometer updates have started...")
        } else {
            LogEvent.print(module: "ActivityHandler.startMotionUpdates()", message: "Accelerometer is not available.")
        }
    }
    
    func stopMotionUpdates() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        motionManager.stopDeviceMotionUpdates()
        LogEvent.print(module: "ActivityHandler.stopMotionUpdates()", message: "Device Motion Activity updates have stopped.")
    }
    
    func startActivityUpdates() {
        guard CMMotionActivityManager.isActivityAvailable() else {
            LogEvent.print(module: "** ActivityHandler.startActivityUpdates()", message: "Activity data is not available on this device.")
            return
        }
        
        self.isActivityMonitoringOn = true
        self.updatesStarted = true
        LogEvent.print(module: "ActivityHandler.startActivityUpdates()", message: "started ...")
        
        // Start motion updates when activity updates start
        startMotionUpdates()
        
        motionActivityManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let self = self, let activity = activity else { return }
            self.updateActivityState(activity)
            self.updateActivityDataBuffer(location: self.locationHandler.siftLocation)
        }
    }
    
    func stopActivityUpdates() {
        motionActivityManager.stopActivityUpdates()
        
        /// Also stop motion updates
        stopMotionUpdates()
        
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
        //LogEvent.print(module: "** ", message: entry.note)
        
    }
    
    func updateMotionDataBuffer(location: CLLocation?) {
        
        /// Guard to make sure location is not nil
        /// 
        guard let location = location else {
            return
        }
        
        //LogEvent.print(module: "updateLocationDataBuffer", message: "Location \(location)" )
        
        /// Check if the array has reached its capacity
        ///
        if motionDataBuffer.count >= motionDataBufferLimit {
            /// Remove the oldest entry to make space for the new one
            ///
            motionDataBuffer.removeLast()
        }
        /// Insert the new data at the beginning of the array, treating it as a queue
        ///
        let entry = MotionDataBuffer(
            timestamp: Date(),
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            speed: 0,
            accelerometerX: accelerometerData.x,
            accelerometerY: accelerometerData.y,
            accelerometerZ: accelerometerData.z,
            processed: false,
            code: "",
            note: "buffer:" + " " + "activity: \(isActivity ? "active" : "inactive")" + " / " + "\(activityState)"
        )
        motionDataBuffer.insert(entry, at: 0)
        //LogEvent.print(module: "** ", message: entry.note)
        
    }
    private func processAccelerometerData(_ data: CMAccelerometerData) {
        
        let acceleration = data.acceleration
        self.accelerometerData.x = acceleration.x
        self.accelerometerData.y = acceleration.y
        self.accelerometerData.z = acceleration.z
        
        // Create a mock location object (you should replace this with actual location data if available)
        let mockLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        
        // Update motionDataBuffer with mock location
        updateMotionDataBuffer(location: mockLocation)
    }
}


/*
 /// Accelerometer
 if motionManager.isAccelerometerAvailable {
     motionManager.accelerometerUpdateInterval = 0.1 // Update interval in seconds
     motionManager.startAccelerometerUpdates(to: OperationQueue.main) { (data, error) in
         guard let data = data else { return }
         let x = data.acceleration.x
         let y = data.acceleration.y
         let z = data.acceleration.z
         print("Accelerometer: x=\(x), y=\(y), z=\(z)")
         
         // Detect if phone is dropped
         if abs(x) > 2 || abs(y) > 2 || abs(z) > 2 {
             print("Phone might be dropped!")
         }
     }
 } else {
     print("Accelerometer is not available")
 }
 
 // Check if gyroscope is available
 if motionManager.isGyroAvailable {
     motionManager.gyroUpdateInterval = 0.1 // Update interval in seconds
     motionManager.startGyroUpdates(to: OperationQueue.main) { (data, error) in
         guard let data = data else { return }
         let rotationRateX = data.rotationRate.x
         let rotationRateY = data.rotationRate.y
         let rotationRateZ = data.rotationRate.z
         print("Gyroscope: x=\(rotationRateX), y=\(rotationRateY), z=\(rotationRateZ)")
     }
 } else {
     print("Gyroscope is not available")
 }
 
 // Check if device motion is available
 if motionManager.isDeviceMotionAvailable {
     motionManager.deviceMotionUpdateInterval = 0.1 // Update interval in seconds
     motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { (data, error) in
         guard let data = data else { return }
         let attitude = data.attitude
         let pitch = attitude.pitch
         let yaw = attitude.yaw
         let roll = attitude.roll
         print("Device Motion: pitch=\(pitch), yaw=\(yaw), roll=\(roll)")
     }
 } else {
     print("Device motion is not available")
 }

 */
