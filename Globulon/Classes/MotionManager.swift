//
//  MotionManager.swift
//  Globulon
//
//  Created by David Holeman on 3/4/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

/**
 - Version: 1.0.0 (2025-03-04)
 - Note:
    - Version: 1.0.0 (2025-03-04)
        - (created)
*/

import Foundation
import CoreMotion
import CoreLocation
import Combine
import SceneKit

// MARK: - MotionDataBuffer:  global

struct MotionDataBuffer: Codable, Hashable {
    var timestamp: Date
    var latitude: Double
    var longitude: Double
    var speed: Double
    var accelerometerX: Double
    var accelerometerY: Double
    var accelerometerZ: Double
    var gyroscopeX: Double
    var gyroscopeY: Double
    var gyroscopeZ: Double
    var attitudePitch: Double
    var attitudeYaw: Double
    var attitudeRoll: Double
    var processed: Bool
    var code: String
    var note: String
}

// MARK: - AccelerationData:  global

struct AccelerationData: Identifiable {
    let id = UUID()
    let timestamp: Date
    let x: Double
    let y: Double
    let z: Double
}

// MARK: - MotionManager

@MainActor class MotionManager: ObservableObject {
    
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

    //TODO: Build_84
    struct AttitudeData: Equatable {
        var pitch: Double
        var yaw: Double
        var roll: Double
    }

    static let shared = MotionManager()
    
    @Published var isActivity = false
    @Published var isMotionMonitoringOn = false

    @Published var isAccelerometer = false
    @Published var isGyroscope = false
    @Published var isAttitude = false
    
    @Published var updatesStarted: Bool {
        didSet {
            UserDefaults.standard.set(updatesStarted, forKey: "motionUpdatesStarted")
            LogManager.event(module: "MotionManager.updatesStarted", message: "\(updatesStarted ? "Motion updates started ..." : "... stopped activity updates")")
        }
    }

    @Published var accelerometerData: AccelerometerData
    @Published var gyroscopeData: GyroscopeData
    @Published var attitudeData: AttitudeData
    //TODO: build_84
//    var yawDegrees: Double {
//        let degrees = attitudeData.yaw * 180 / .pi - 90
//        return degrees < 0 ? degrees + 360 : degrees
//    }
    
    var yawDegrees: Double {
        // Invert yaw to correct rotation direction and align with map's forward
        let inverted = -attitudeData.yaw
        let degrees = inverted * 180 / .pi + 90 // Align device top with map forward
        return (degrees < 0 ? degrees + 360 : degrees).truncatingRemainder(dividingBy: 360)
    }

    
    private var motionDataBufferLimit = 25
    @Published var motionDataBuffer: [MotionDataBuffer] = []
    
    private let motionManager = CMMotionManager()
    
    private var accelerometerUpdated = false
    private var gyroscopeUpdated = false
    private var attitudeUpdated = false
    
    @Published var rotation = SCNVector3(0, 0, 0)
    
    let scene = SCNScene()
    private var cubeNode: SCNNode!
    
    private var lastRotation = SCNVector4Zero
    private let filterFactor: Float = 0.05
    private let threshold: Float = 0.01

    private var locationManager: LocationManager {
        return LocationManager.shared
    }

    @Published var accelerationHistory: [AccelerationData] = []

    private init() {
        
        self.updatesStarted = UserDefaults.standard.bool(forKey: "motionUpdatesStarted")

        let cube = SCNGeometry.cubeWithColoredSides(sideLength: 1.0)
        cubeNode = SCNNode(geometry: cube)
        scene.rootNode.addChildNode(cubeNode)

        self.accelerometerData = AccelerometerData(x: 0.0, y: 0.0, z: 0.0)
        self.gyroscopeData = GyroscopeData(x: 0.0, y: 0.0, z: 0.0)
        self.attitudeData = AttitudeData(pitch: 0.0, yaw: 0.0, roll: 0.0)
    }

    func startMotionUpdates() {
        
        self.updatesStarted = true
        
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
                guard let self = self, let data = data, error == nil else { return }
                
                let result = data.acceleration
                self.accelerometerData.x = result.x
                self.accelerometerData.y = result.y
                self.accelerometerData.z = result.z

                let newAccelerationData = AccelerationData(
                    timestamp: Date(),
                    x: self.accelerometerData.x,
                    y: self.accelerometerData.y,
                    z: self.accelerometerData.z
                )
                
                self.accelerationHistory.append(newAccelerationData)
                if self.accelerationHistory.count > 100 {
                    self.accelerationHistory.removeFirst()
                }
                self.checkAndUpdateMotionDataBuffer()
            }
            self.accelerometerUpdated = true
            self.isActivity = true
            self.isMotionMonitoringOn = true
            LogManager.event(module: "MotionManager.startMotionUpdates()", message: "Accelerometer updates have started...")
        } else {
            LogManager.event(module: "MotionManager.startMotionUpdates()", message: "Accelerometer is not available.")
        }

        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = 0.1
            motionManager.startGyroUpdates(to: .main) { [weak self] data, error in
                guard let self = self, let data = data, error == nil else { return }

                DispatchQueue.main.async {
                    let result = data.rotationRate
                    self.gyroscopeData.x = result.x
                    self.gyroscopeData.y = result.y
                    self.gyroscopeData.z = result.z

                    let rotation4 = SCNVector4(
                        x: Float(self.gyroscopeData.x),
                        y: Float(self.gyroscopeData.y),
                        z: Float(self.gyroscopeData.z),
                        w: Float(data.timestamp)
                    )

                    if abs(rotation4.x) > self.threshold ||
                       abs(rotation4.y) > self.threshold ||
                       abs(rotation4.z) > self.threshold {

                        self.lastRotation.x = (self.lastRotation.x * (1.0 - self.filterFactor)) + (rotation4.x * self.filterFactor)
                        self.lastRotation.y = (self.lastRotation.y * (1.0 - self.filterFactor)) + (rotation4.y * self.filterFactor)
                        self.lastRotation.z = (self.lastRotation.z * (1.0 - self.filterFactor)) + (rotation4.z * self.filterFactor)
                        self.lastRotation.w = rotation4.w

                        DispatchQueue.main.async {
                            self.cubeNode.rotation = self.lastRotation
                        }
                    }
                }
                self.checkAndUpdateMotionDataBuffer()
            }
            self.gyroscopeUpdated = true
            self.isActivity = true
            self.isMotionMonitoringOn = true
            LogManager.event(module: "MotionManager.startMotionUpdates()", message: "Gyroscope updates have started...")
        } else {
            LogManager.event(module: "MotionManager.startMotionUpdates()", message: "Gyroscope is not available.")
        }

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
                self.checkAndUpdateMotionDataBuffer()
            }
            self.attitudeUpdated = true
            self.isActivity = true
            self.isMotionMonitoringOn = true
            LogManager.event(module: "MotionManager.startMotionUpdates()", message: "Device motion updates have started...")
        } else {
            LogManager.event(module: "MotionManager.startMotionUpdates()", message: "Device motion is not available.")
        }
    }

    func stopMotionUpdates() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        motionManager.stopDeviceMotionUpdates()
        self.isActivity = false
        self.isMotionMonitoringOn = false
        LogManager.event(module: "MotionManager.stopMotionUpdates()", message: "Device Motion Activity updates have stopped.")
    }

    private func checkAndUpdateMotionDataBuffer() {
        if accelerometerUpdated && gyroscopeUpdated && attitudeUpdated {
            updateMotionDataBuffer()
            accelerometerUpdated = false
            gyroscopeUpdated = false
            attitudeUpdated = false
        }
    }

    private func updateMotionDataBuffer() {
        if motionDataBuffer.count >= motionDataBufferLimit {
            motionDataBuffer.removeLast()
        }

        let entry = MotionDataBuffer(
            timestamp: Date(),
            latitude: locationManager.lastLocation.coordinate.latitude,
            longitude: locationManager.lastLocation.coordinate.longitude,
            speed: locationManager.lastSpeed,
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
            note: "buffer:" + " " + "activity: \(ActivityManager.shared.isActivity ? "active" : "inactive")" + " / " + "\(ActivityManager.shared.activityState)"
        )
        motionDataBuffer.insert(entry, at: 0)
    }
}
