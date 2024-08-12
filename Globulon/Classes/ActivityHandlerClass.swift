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
/// ### 0.1.0.70
/// # - Added Dispatch Queue to Gyro and Attitude data processing
/// # - Cleaned up some comments
/// # - *Date*: 07/16/24
/// ### 0.1.0.69
/// # - added motion sensor data collection into buffer
/// # - *Date*: 07/16/24
/// ### 0.1.0.66
/// # - Created
/// # - *Date*: 07/16/24

import Foundation
import CoreMotion
import CoreLocation
import Combine
import SceneKit

struct AccelerationData: Identifiable {
    let id = UUID()
    let timestamp: Date
    let x: Double
    let y: Double
    let z: Double
}

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
    
    struct GyroscopeData {
        var x: Double
        var y: Double
        var z: Double
    }
    
    struct AttitudeData {
        var pitch: Double
        var yaw: Double
        var roll: Double
    }
    
    
    private let activityDataBufferLimit = 25
    @Published var activityDataBuffer: [ActivityDataBuffer] = []

    private let motionDataBufferLimit = 25
    @Published var motionDataBuffer: [MotionDataBuffer] = []

    
    @Published var accelerometerData: AccelerometerData
    @Published var gyroscopeData: GyroscopeData
    @Published var attitudeData: AttitudeData
    
    private var locationHandler: LocationHandler {
        return LocationHandler.shared
    }
    
    static let shared = ActivityHandler()
    
    @Published var isActivityMonitoringOn = false
    @Published var isActivity = false
    @Published var activityState: ActivityState = .stationary
    
    @Published var updatesStarted: Bool {
        didSet {
            UserDefaults.standard.set(updatesStarted, forKey: "activityUpdatesStarted")
            LogEvent.print(module: "ActivityHandler.updatesStarted", message: "\(updatesStarted ? "Activity updates started ..." : "... stopped activity updates")")
        }
    }
    
    private let motionActivityManager = CMMotionActivityManager()
    private let motionManager = CMMotionManager()
    
    private var accelerometerUpdated = false
    private var gyroscopeUpdated = false
    private var attitudeUpdated = false
    
    @Published var rotation = SCNVector3(0, 0, 0)
    
    let scene = SCNScene()
    private var cubeNode: SCNNode!
    
    // Low-pass filter parameters
    private var lastRotation = SCNVector4Zero
    private let filterFactor: Float = 0.05    // the lower the number means more smoothing because less of the new data is used.
    private let threshold:    Float = 0.01   // gyroscope absolute values x,y,z have to be greater than this to update

    @Published var accelerationHistory: [AccelerationData] = []

    private init() {
        // Create a 3D cube
        //let cube = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.0)
        
        // Create a 3D cube with colored sides
        let cube = SCNGeometry.cubeWithColoredSides(sideLength: 1.0)
        
        //cube.firstMaterial?.diffuse.contents = UIColor.red
        
        cubeNode = SCNNode(geometry: cube)
        
        // Add cube to the scene
        scene.rootNode.addChildNode(cubeNode)
        

        
        self.accelerometerData = AccelerometerData(x: 0.0, y: 0.0, z: 0.0)
        self.gyroscopeData = GyroscopeData(x: 0.0, y: 0.0, z: 0.0)
        self.attitudeData = AttitudeData(pitch: 0.0, yaw: 0.0, roll: 0.0)
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

    /*
    func startMotionUpdates() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
                guard let self = self, let data = data, error == nil else { return }
                
                //self.processAccelerometerData(data)
                let acceleration = data.acceleration
                self.accelerometerData.x = acceleration.x
                self.accelerometerData.y = acceleration.y
                self.accelerometerData.z = acceleration.z
                updateMotionDataBuffer()
                
            }
            LogEvent.print(module: "ActivityHandler.startMotionUpdates()", message: "Accelerometer updates have started...")
        } else {
            LogEvent.print(module: "ActivityHandler.startMotionUpdates()", message: "Accelerometer is not available.")
        }
    }
    */

    /*
    func startMotionUpdates() {
        updateQueue.maxConcurrentOperationCount = 1 // Ensure operations execute serially
        
        // Start accelerometer updates
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: updateQueue) { [weak self] data, error in
                guard let self = self, let data = data, error == nil else { return }
                
                self.dispatchGroup.enter()
                let acceleration = data.acceleration
                self.accelerometerData.x = acceleration.x
                self.accelerometerData.y = acceleration.y
                self.accelerometerData.z = acceleration.z
                LogEvent.print(module: "ActivityHandler.startMotionUpdates()", message: "Accelerometer data updated: x: \(acceleration.x), y: \(acceleration.y), z: \(acceleration.z)")
                self.dispatchGroup.leave()
            }
            LogEvent.print(module: "ActivityHandler.startMotionUpdates()", message: "Accelerometer updates have started...")
        } else {
            LogEvent.print(module: "ActivityHandler.startMotionUpdates()", message: "Accelerometer is not available.")
        }
        
        // Start gyroscope updates
        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = 0.1
            motionManager.startGyroUpdates(to: updateQueue) { [weak self] data, error in
                guard let self = self, let data = data, error == nil else { return }
                
                self.dispatchGroup.enter()
                let rotationRate = data.rotationRate
                self.gyroscopeData.x = rotationRate.x
                self.gyroscopeData.y = rotationRate.y
                self.gyroscopeData.z = rotationRate.z
                LogEvent.print(module: "ActivityHandler.startMotionUpdates()", message: "Gyroscope data updated: x: \(rotationRate.x), y: \(rotationRate.y), z: \(rotationRate.z)")
                self.dispatchGroup.leave()
            }
            LogEvent.print(module: "ActivityHandler.startMotionUpdates()", message: "Gyroscope updates have started...")
        } else {
            LogEvent.print(module: "ActivityHandler.startMotionUpdates()", message: "Gyroscope is not available.")
        }
        
        // Notify the update queue when both accelerometer and gyroscope data are updated
        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.updateMotionDataBuffer()
        }
    }
    */
    
    func startMotionUpdates() {
        
        /// Start accelerometer updates
        ///
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
                guard let self = self, let data = data, error == nil else { return }
                
                let result = data.acceleration
                self.accelerometerData.x = result.x
                self.accelerometerData.y = result.y
                self.accelerometerData.z = result.z
                
                /*
                let newAccelerationData = AccelerationData(
                    timestamp: Date(),
                    x: data.acceleration.x,
                    y: data.acceleration.y,
                    z: data.acceleration.z
                )
                */
                
                /// Load into structure
                ///
                let newAccelerationData = AccelerationData(
                    timestamp: Date(),
                    x: accelerometerData.x,
                    y: accelerometerData.y,
                    z: accelerometerData.z
                )
                
                /// Add to the history array
                ///
                self.accelerationHistory.append(newAccelerationData)
                
                if self.accelerationHistory.count > 100 {
                    self.accelerationHistory.removeFirst()
                }
                
                self.accelerometerUpdated = true
                
                self.checkAndUpdateMotionDataBuffer()
                
            }
            LogEvent.print(module: "ActivityHandler.startMotionUpdates()", message: "Accelerometer updates have started...")
        } else {
            LogEvent.print(module: "ActivityHandler.startMotionUpdates()", message: "Accelerometer is not available.")
        }
        
        /// Start gyroscope updates
        ///
        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = 0.1
            motionManager.startGyroUpdates(to: .main) { [weak self] data, error in
                guard let self = self, let data = data, error == nil else { return }
                
                DispatchQueue.main.async {
                    let result = data.rotationRate
                    self.gyroscopeData.x = result.x
                    self.gyroscopeData.y = result.y
                    self.gyroscopeData.z = result.z
                    
                    
//                    self.rotation = SCNVector3(
//                        Float(self.gyroscopeData.x),
//                        Float(self.gyroscopeData.y),
//                        Float(self.gyroscopeData.z)
//                    )
                    
                    let rotation4 = SCNVector4(
                        x: Float(self.gyroscopeData.x),
                        y: Float(self.gyroscopeData.y),
                        z: Float(self.gyroscopeData.z),
                        w: Float(data.timestamp)
                    )
                    
//                    let rotation4 = SCNVector4(
//                        x: Float(roundDouble(self.gyroscopeData.x, decimalPlaces: 2)),
//                        y: Float(roundDouble(self.gyroscopeData.y, decimalPlaces: 2)),
//                        z: Float(roundDouble(self.gyroscopeData.z, decimalPlaces: 2)),
//                        w: Float(data.timestamp)
//                    )
//                    DispatchQueue.main.async {
//                        self.cubeNode.rotation = rotation4
//                    }
                    /*
                    self.lastRotation.x = (self.lastRotation.x * (1.0 - self.filterFactor)) + (rotation4.x * self.filterFactor)
                    self.lastRotation.y = (self.lastRotation.y * (1.0 - self.filterFactor)) + (rotation4.y * self.filterFactor)
                    self.lastRotation.z = (self.lastRotation.z * (1.0 - self.filterFactor)) + (rotation4.z * self.filterFactor)
                    self.lastRotation.w = rotation4.w  // Timestamp doesn't need filtering
                    
                    DispatchQueue.main.async {
                        self.cubeNode.rotation = self.lastRotation
                    }
                    */
                    // Apply threshold filter
                    if abs(rotation4.x) > self.threshold ||
                       abs(rotation4.y) > self.threshold ||
                       abs(rotation4.z) > self.threshold {
                        
                        // Apply low-pass filter
                        self.lastRotation.x = (self.lastRotation.x * (1.0 - self.filterFactor)) + (rotation4.x * self.filterFactor)
                        self.lastRotation.y = (self.lastRotation.y * (1.0 - self.filterFactor)) + (rotation4.y * self.filterFactor)
                        self.lastRotation.z = (self.lastRotation.z * (1.0 - self.filterFactor)) + (rotation4.z * self.filterFactor)
                        self.lastRotation.w = rotation4.w  // Timestamp doesn't need filtering
                        
                        DispatchQueue.main.async {
                            self.cubeNode.rotation = self.lastRotation
                        }
                    }
                }
                
                self.gyroscopeUpdated = true
                
                self.checkAndUpdateMotionDataBuffer()

            }
            LogEvent.print(module: "ActivityHandler.startMotionUpdates()", message: "Gyroscope updates have started...")
        } else {
            LogEvent.print(module: "ActivityHandler.startMotionUpdates()", message: "Gyroscope is not available.")
        }
        
        // Start device motion updates
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] data, error in
                guard let self = self, let data = data, error == nil else { return }
                
                DispatchQueue.main.async {
                    let result = data.attitude
                    self.attitudeData.pitch = result.pitch
                    self.attitudeData.yaw = result.yaw
                    self.attitudeData.roll = result.roll
                }
                
                self.attitudeUpdated = true
                
                self.checkAndUpdateMotionDataBuffer()
            }
            LogEvent.print(module: "ActivityHandler.startMotionUpdates()", message: "Device motion updates have started...")
        } else {
            LogEvent.print(module: "ActivityHandler.startMotionUpdates()", message: "Device motion is not available.")
        }
    }
    
    /// Once you have all inputs from the sensors then perform the update
    ///
    private func checkAndUpdateMotionDataBuffer() {
        if accelerometerUpdated && gyroscopeUpdated && attitudeUpdated {
            updateMotionDataBuffer()
            accelerometerUpdated = false
            gyroscopeUpdated = false
            attitudeUpdated = false
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
        
        /// Start motion updates when activity updates start
        ///
        // TODO:  I've turned off here because I want to only start either manually or when a trip starts.
        //
        //startMotionUpdates()
        
        motionActivityManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let self = self, let activity = activity else { return }
            self.updateActivityState(activity)
            self.updateActivityDataBuffer(location: self.locationHandler.lastLocation)
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
    
    func updateMotionDataBuffer() {
        
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
            latitude: locationHandler.siftLocation.coordinate.latitude,
            longitude: locationHandler.siftLocation.coordinate.longitude,
            speed: locationHandler.lastSpeed,
            accelerometerX: accelerometerData.x,
            accelerometerY: accelerometerData.y,
            accelerometerZ: accelerometerData.z,
            gyroscopeX: gyroscopeData.x,
            gyroscopeY: gyroscopeData.y,
            gyroscopeZ: gyroscopeData.z,
            attitudePitch: attitudeData.pitch,
            attitudeYaw: attitudeData.yaw,
            attitudeRoll: attitudeData.roll,
            processed: false,
            code: "",
            note: "buffer:" + " " + "activity: \(isActivity ? "active" : "inactive")" + " / " + "\(activityState)"
        )
        motionDataBuffer.insert(entry, at: 0)
        //LogEvent.print(module: "** ", message: entry.note)
        
    }
}
