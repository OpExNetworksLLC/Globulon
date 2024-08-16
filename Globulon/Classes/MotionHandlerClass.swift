//
//  MotionHandlerClass.swift
//  Globulon
//
//  Created by David Holeman on 8/12/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

// MARK: - MotionHandler

import Foundation
import CoreMotion
import CoreLocation
import Combine
import SceneKit

@MainActor
class MotionHandler: ObservableObject {
    
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

    static let shared = MotionHandler()
    
    @Published var isActivity = false
    @Published var isMotionMonitoringOn = false

    @Published var isAccelerometer = false
    @Published var isGyroscope = false
    @Published var isAttitude = false
    
    @Published var updatesStarted: Bool {
        didSet {
            UserDefaults.standard.set(updatesStarted, forKey: "motionUpdatesStarted")
            LogEvent.print(module: "MotionHandler.updatesStarted", message: "\(updatesStarted ? "Motion updates started ..." : "... stopped activity updates")")
        }
    }

    @Published var accelerometerData: AccelerometerData
    @Published var gyroscopeData: GyroscopeData
    @Published var attitudeData: AttitudeData

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

    private var locationHandler: LocationHandler {
        return LocationHandler.shared
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
            LogEvent.print(module: "MotionHandler.startMotionUpdates()", message: "Accelerometer updates have started...")
        } else {
            LogEvent.print(module: "MotionHandler.startMotionUpdates()", message: "Accelerometer is not available.")
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
            LogEvent.print(module: "MotionHandler.startMotionUpdates()", message: "Gyroscope updates have started...")
        } else {
            LogEvent.print(module: "MotionHandler.startMotionUpdates()", message: "Gyroscope is not available.")
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
            LogEvent.print(module: "MotionHandler.startMotionUpdates()", message: "Device motion updates have started...")
        } else {
            LogEvent.print(module: "MotionHandler.startMotionUpdates()", message: "Device motion is not available.")
        }
    }

    func stopMotionUpdates() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        motionManager.stopDeviceMotionUpdates()
        self.isActivity = false
        self.isMotionMonitoringOn = false
        LogEvent.print(module: "MotionHandler.stopMotionUpdates()", message: "Device Motion Activity updates have stopped.")
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
            note: "buffer:" + " " + "activity: \(ActivityHandler.shared.isActivity ? "active" : "inactive")" + " / " + "\(ActivityHandler.shared.activityState)"
        )
        motionDataBuffer.insert(entry, at: 0)
    }
}
