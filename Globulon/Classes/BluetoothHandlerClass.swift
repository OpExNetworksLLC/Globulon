//
//  BluetoothHandlerClass.swift
//  Globulon
//
//  Created by David Holeman on 2/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

/**
 - Version: 1.0.0 (2025.02.25)
 - Note:
*/

import Foundation
import CoreBluetooth
import Combine

typealias BluetoothHandler = BluetoothHandlerV2

@MainActor
class BluetoothHandlerV2:  NSObject, ObservableObject, @preconcurrency CBCentralManagerDelegate, CBPeripheralDelegate  {
    
    static let shared = BluetoothHandlerV2() // Singleton instance
    
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var connectedDevices: [CBPeripheral] = []
    @Published var bluetoothState: CBManagerState = .unknown
    
    @Published var isPermission = false
    @Published var isAuthorized = false
    @Published var isAvailable = false
    @Published var isConnected = false
    
    @Published var updatesLive: Bool {
        didSet {
            UserDefaults.standard.set(updatesLive, forKey: "bluetoothUpdatesLive")
            LogEvent.print(module: "BluetoothHandler.updatesLive", message: "\(updatesLive ? "Bluetooth updates started ..." : "... stopped activity updates")")
        }
    }
    
    private var centralManager: CBCentralManager!
    private var deviceMap: [UUID: CBPeripheral] = [:] // Track devices by UUID for easy management
    
    override init() {
        self.updatesLive = UserDefaults.standard.bool(forKey: "bluetoothUpdatesLive")
        
        /** This would start the bluetooth manager automatically
        ``` super.init()
            self.centralManager = CBCentralManager(delegate: self, queue: nil)
        ```
        */
    }
    
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
    
    /// Request the permission and start updates
    func requestBluetoothPermission() {
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        startBluetoothUpdates()
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothState = central.state
        if central.state == .poweredOn {
            startScanning()
        } else {
            stopScanning()
            discoveredDevices.removeAll()
            connectedDevices.removeAll()
        }
        /// Update values when the state updates
        self.isAvailable = central.state == .poweredOn
        self.isAuthorized = central.state != .unauthorized
        self.isConnected = !connectedDevices.isEmpty
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !discoveredDevices.contains(peripheral) {
            deviceMap[peripheral.identifier] = peripheral
            discoveredDevices.append(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if !connectedDevices.contains(peripheral) {
            connectedDevices.append(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedDevices.removeAll { $0.identifier == peripheral.identifier }
    }
    
    func connect(to peripheral: CBPeripheral) {
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }
    
    func disconnect(from peripheral: CBPeripheral) {
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    // MARK: - Public Methods
    
    /// Call this function to start Bluetooth
//    func startBluetoothUpdates() {
//        if centralManager == nil {
//            centralManager = CBCentralManager(delegate: self, queue: nil)
//        }
//
//        if centralManager?.state == .poweredOn {
//            startScanning()
//            LogEvent.print(module: "BluetoothHandler.startBluetoothUpdates()", message: "Bluetooth powered on.")
//            self.updatesLive = true
//        } else {
//            logBluetoothState()
//            LogEvent.print(module: "BluetoothHandler.startBluetoothUpdates()", message: "Bluetooth not powered on.")
//            self.updatesLive = false
//        }
//    }
    func startBluetoothUpdates() {
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }

        // Wait for the state to update via centralManagerDidUpdateState
        if centralManager.state == .unknown {
            LogEvent.print(module: "BluetoothHandler.startBluetoothUpdates()", message: "Waiting for Bluetooth state update...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.startScanning()
                self.updatesLive = true
            }
        } else if centralManager.state == .poweredOn {
            startScanning()
            LogEvent.print(module: "BluetoothHandler.startBluetoothUpdates()", message: "Bluetooth powered on.")
            self.updatesLive = true
        } else {
            logBluetoothState()
            LogEvent.print(module: "BluetoothHandler.startBluetoothUpdates()", message: "Bluetooth not powered on.")
            self.updatesLive = false
        }
    }
    func startScanning() {
        guard centralManager?.state == .poweredOn else { return }
        
        // Fetch already connected devices
        let connected = centralManager.retrieveConnectedPeripherals(withServices: [])
        connectedDevices = connected
        
        centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    
    func stopScanning() {
        centralManager?.stopScan()
    }
    
    func stopBluetoothUpdates() {
        stopScanning()
        DispatchQueue.main.async {
            self.discoveredDevices.removeAll() // Clear discovered devices
            self.connectedDevices.removeAll() // Clear connected devices
            self.deviceMap.removeAll()        // Clear device mapping
            self.updatesLive = false
            self.centralManager = nil // Release the Bluetooth manager
        }
    }
    
    //MARK: logging
    
    func logBluetoothState() {
        let stateDescription: String
        switch centralManager?.state {
        case .unknown:
            stateDescription = "The Bluetooth state is unknown."
        case .resetting:
            stateDescription = "The Bluetooth connection is resetting."
        case .unsupported:
            stateDescription = "Bluetooth is not supported on this device."
        case .unauthorized:
            stateDescription = "The app is not authorized to use Bluetooth."
        case .poweredOff:
            stateDescription = "Bluetooth is currently powered off."
        case .poweredOn:
            stateDescription = "Bluetooth is powered on and available."
        default:
            stateDescription = "An unknown state occurred."
        }
        print("Bluetooth State: \(stateDescription)")
    }
}

@MainActor
class BluetoothHandlerV1: NSObject, ObservableObject, @preconcurrency CBCentralManagerDelegate, CBPeripheralDelegate {
    
    static let shared = BluetoothHandlerV1() // Singleton instance
    
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var connectedDevices: [CBPeripheral] = []
    @Published var bluetoothState: CBManagerState = .unknown
    
    @Published var isConnected = false
    @Published var isAuthorized = false
    @Published var isAvailable = false
    
    private var centralManager: CBCentralManager!
    private var deviceMap: [UUID: CBPeripheral] = [:] // Track devices by UUID for easy management
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        self.bluetoothState = centralManager.state
        self.isAvailable = centralManager.state == .poweredOn
        self.isAuthorized = centralManager.state != .unauthorized
        self.isConnected = !connectedDevices.isEmpty
    }
    
    // MARK: - CBCentralManagerDelegate
    
//    func centralManagerDidUpdateState(_ central: CBCentralManager) {
//        bluetoothState = central.state
//        if central.state == .poweredOn {
//            startScanning()
//        } else {
//            stopScanning()
//            discoveredDevices.removeAll()
//            connectedDevices.removeAll()
//        }
//        /// Update values when the state updates
//        self.isAvailable = central.state == .poweredOn
//        self.isAuthorized = central.state != .unauthorized
//        self.isConnected = !connectedDevices.isEmpty
//    }
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
            self.bluetoothState = central.state
            switch central.state {
            case .poweredOn:
                LogEvent.print(module: "BluetoothHandler.centralManagerDidUpdateState()", message: "Bluetooth is powered on.")
                self.startScanning()
                self.isAvailable = true
                self.isAuthorized = true
            case .poweredOff:
                LogEvent.print(module: "BluetoothHandler.centralManagerDidUpdateState()", message: "Bluetooth is powered off.")
                self.stopScanning()
                self.isAvailable = false
            case .unauthorized:
                LogEvent.print(module: "BluetoothHandler.centralManagerDidUpdateState()", message: "Bluetooth is unauthorized.")
                self.isAuthorized = false
            case .unsupported:
                LogEvent.print(module: "BluetoothHandler.centralManagerDidUpdateState()", message: "Bluetooth is unsupported.")
                self.isAvailable = false
            case .resetting:
                LogEvent.print(module: "BluetoothHandler.centralManagerDidUpdateState()", message: "Bluetooth is resetting.")
            case .unknown:
                LogEvent.print(module: "BluetoothHandler.centralManagerDidUpdateState()", message: "Bluetooth state is unknown.")
            @unknown default:
                LogEvent.print(module: "BluetoothHandler.centralManagerDidUpdateState()", message: "An unknown Bluetooth state occurred.")
            }
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !discoveredDevices.contains(peripheral) {
            deviceMap[peripheral.identifier] = peripheral
            discoveredDevices.append(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if !connectedDevices.contains(peripheral) {
            connectedDevices.append(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedDevices.removeAll { $0.identifier == peripheral.identifier }
    }
    
    // MARK: - Public Methods
    
    func connect(to peripheral: CBPeripheral) {
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }
    
    func disconnect(from peripheral: CBPeripheral) {
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    
    func stopScanning() {
        centralManager.stopScan()
    }
    
    /// This does not trigger the permission request which is important since we only wnat to enquire if is authorized
    func getBluetoothAuthorized(completion: @escaping (Bool) -> Void) {
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: false])
        if centralManager.state == .unauthorized || centralManager.state == .unknown {
            completion(false)
        } else {
            completion(true)
        }
    }
    
    /// This does not trigger the permission request which is imporant because we only want to know if is powered on
    func getBluetoothAvailablity(completion: @escaping (Bool) -> Void) {
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: false])
        if self.centralManager.state == .poweredOn {
            completion(true)
        } else {
            completion(false)
        }
    }
    
    func getBluetoothConnected() -> Bool {
        return !connectedDevices.isEmpty
    }
    
    // Callback to notify permission status
    var onPermissionResult: ((CBManagerAuthorization) -> Void)?

    // Initialize and check Bluetooth status
    func requestBluetoothPermission() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
//    func checkBluetoothEnabled() -> Bool {
//        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: false])
//        // If state is .poweredOn, Bluetooth is enabled.
//        return centralManager?.state == .poweredOn
//    }
    
    func getBluetoothStateDescription(state: CBManagerState) -> String {
        switch state {
        case .unknown:
            return "The Bluetooth state is unknown."
        case .resetting:
            return "The Bluetooth connection is resetting."
        case .unsupported:
            return "Bluetooth is not supported on this device."
        case .unauthorized:
            return "The app is not authorized to use Bluetooth."
        case .poweredOff:
            return "Bluetooth is currently powered off."
        case .poweredOn:
            return "Bluetooth is powered on and available."
        @unknown default:
            return "An unknown Bluetooth state occurred."
        }
    }
}
