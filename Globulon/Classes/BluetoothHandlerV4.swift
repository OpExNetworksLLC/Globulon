//
//  BluetoothHandlerV4.swift
//  Globulon
//
//  Created by David Holeman on 4/18/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit

@MainActor
final class BluetoothHandlerV4: NSObject, ObservableObject {
    
    static let shared = BluetoothHandlerV4()
    
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var connectedDevices: [CBPeripheral] = []
    @Published var bluetoothState: CBManagerState = .unknown
    
    @Published var isPermission = false
    @Published var isAuthorized = false
    @Published var isAvailable = false
    @Published var isConnected = false
    @Published var updatesLive: Bool = UserDefaults.standard.bool(forKey: "bluetoothUpdatesLive") {
        didSet {
            UserDefaults.standard.set(updatesLive, forKey: "bluetoothUpdatesLive")
            LogEvent.print(module: "BluetoothHandler.updatesLive", message: "\(updatesLive ? "Bluetooth updates started ..." : "... stopped activity updates")")
        }
    }
    
    private var centralManager: CBCentralManager?
    
    private override init() {
        super.init()
    }
    
    func requestBluetoothPermission() async {
        print(">>> requestBluetoothPermission")
    }
    
    func startBluetoothUpdates() async {
        print(">>> startBluetoothUpdates")
    }
    
    
    func startScanning() {
        guard centralManager?.state == .poweredOn else { return }
        let connected = centralManager?.retrieveConnectedPeripherals(withServices: []) ?? []
        connectedDevices = connected
        centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    
    func stopScanning() {
        centralManager?.stopScan()
    }
    
    func stopBluetoothUpdates() {
        stopScanning()
        DispatchQueue.main.async {
            self.discoveredDevices.removeAll()
            self.connectedDevices.removeAll()
            self.updatesLive = false
            self.centralManager = nil
        }
    }
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = central.state // ✅ Capture early outside of Task
        
        Task { @MainActor in
            self.bluetoothState = state
            self.isAvailable = state == .poweredOn
            self.isAuthorized = state != .unauthorized
            self.isConnected = !self.connectedDevices.isEmpty
            
            if state == .poweredOn {
                self.startScanning()
            } else {
                self.stopScanning()
                self.discoveredDevices.removeAll()
                self.connectedDevices.removeAll()
            }
        }
    }
    // MARK: - Get bluetooth permissions
    
    /// This does not trigger the permission request which is imporant because we only want to know if is powered on
    func getBluetoothAvailablity(completion: @escaping (Bool) -> Void) {
        let permission = CBManager.authorization
        var result = false
        
        switch permission {
        case .allowedAlways:
            /// Allowed
            if let centralManager = centralManager {
                /// Safely unwrap and check the state
                let state = centralManager.state
                if state == .poweredOn {
                    self.isAvailable = true
                    result = true
                } else {
                    self.isAvailable = false
                    result = false
                }
            } else {
                /// centralManager is nil, handle gracefully
                self.isAvailable = false
                result = false
            }
        case .restricted, .denied, .notDetermined:
            /// Permission not granted or not determined
            self.isAvailable = false
            result = false
        @unknown default:
            /// Handle unknown cases cautiously
            self.isAvailable = false
            result = false
        }
        
        /// Log the result
        LogEvent.print(module: "BluetoothHandler.getBluetoothAvailablity()", message: "\(result)")
        completion(result)
    }
    
    /// This does not trigger the permission request which is important since we only wnat to enquire if is authorized
    func getBluetoothAuthorized(completion: @escaping (Bool) -> Void) {
        let permission = CBManager.authorization
        var result = false
        
        switch permission {
        case .allowedAlways:
            /// Allowed
            if let centralManager = centralManager {
                /// Safely unwrap and check the state
                let state = centralManager.state
                if state != .unauthorized {
                    self.isAuthorized = true
                    result = true
                } else {
                    self.isAuthorized = false
                    result = false
                }
                completion(result)
            } else {
                /// centralManager is nil, handle gracefully
                self.isAuthorized = false
                result = false
                completion(false)
            }
        case .restricted, .denied, .notDetermined:
            /// Permission not granted or not determined
            result = false
            completion(false)
        @unknown default:
            /// Handle unknown cases cautiously
            result = false
            completion(false)
        }
        
        /// Log the final result
        LogEvent.print(module: "BluetoothHandler.getBluetoothAuthorized()", message: "\(result)")
    }
    
    /// Get the permission status without invoking the bluetooth permission request
    func getBluetoothPermission(completion: @escaping (Bool) -> Void) {
        let permission = CBManager.authorization
        var result = false
        switch permission {
        case .allowedAlways:
            /// Permission granted
            self.isPermission = true
            result = true
        case .restricted, .denied, .notDetermined:
            /// Permission not granted or not determined
            self.isPermission = false
            result = false
        @unknown default:
            /// Handle unknown cases cautiously
            self.isPermission = false
            completion(false)
        }
        LogEvent.print(module: "BluetoothHandler.getBluetoothPermission()", message: "\(result)")
        completion(result)
    }
}
