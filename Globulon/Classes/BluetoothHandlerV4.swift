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
final class BluetoothHandlerV4: NSObject, ObservableObject, @preconcurrency CBCentralManagerDelegate, CBPeripheralDelegate {
    
    static let shared = BluetoothHandlerV4()
    
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var connectedDevices: [CBPeripheral] = []
    @Published var bluetoothState: CBManagerState = .unknown
    
    @Published var isPermission = false  // Permission was requested.  The state the is either .alwaysAllowed or
    
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
    private var deviceMap: [UUID: CBPeripheral] = [:] // Track devices by UUID for easy management

    
    private override init() {
        super.init()
    }
    
    func requestBluetoothPermission() async {
        
        // Initialize centralManager to trigger permission prompt
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }
        
        // Wait for the authorization status to change
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                let authorization = CBManager.authorization
                if authorization != .notDetermined {
                    timer.invalidate()
                    Task { @MainActor in
                        self.isPermission = authorization == .allowedAlways
                        if !self.isPermission {
                            self.handleBluetoothPermissionDeclined()
                        }
                        continuation.resume(returning: ())
                    }
                }
            }
        }
    }
    
    func handleBluetoothPermissionDeclined() {
        LogEvent.print(module: "BluetoothHandler.Permission", message: "Permission was denied")

        // Optionally notify the UI with another @Published var
        self.isPermission = false
                
        // Or show an alert using a delegate or NotificationCenter

        // Open settings as an option
        /*
        if let url = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        */
    }
    
    /// Permissions should be checked and this function called when
    /// - The service is poweredOn in settings
    /// - The user has granted permission
    ///
    func startBluetoothUpdates() async {
        
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }

        guard let manager = centralManager else {
            LogEvent.print(module: "BluetoothHandler.startBluetoothUpdates()", message: "Central manager is unavailable.")
            self.updatesLive = false
            return
        }
        
        LogEvent.print(module: "BluetoothHandler.startBluetoothUpdates()", message: "Checking ...")

        switch manager.state {
        case .unknown:
            LogEvent.print(module: "BluetoothHandler.startBluetoothUpdates()", message: "State is unknown, attempting to start scanning...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if self.centralManager?.state == .poweredOn {
                    self.startScanning()
                    LogEvent.print(module: "BluetoothHandler.startBluetoothUpdates()", message: "State \".poweredOn\" after \".unknown\" state.")
                } else {
                    LogEvent.print(module: "BluetoothHandler.startBluetoothUpdates()", message: "Scan could not start - still not powered on.")
                }
            }

        case .poweredOn:
            print("2")
            LogEvent.print(module: "BluetoothHandler.startBluetoothUpdates()", message: "Bluetooth powered on.")
            startScanning()
            self.updatesLive = true


        default:
            LogEvent.print(module: "BluetoothHandler.startBluetoothUpdates()", message: "Bluetooth not powered on.")
            stopScanning()
            self.updatesLive = false
        }
    }
    
    private var poweredOnContinuation: CheckedContinuation<Void, Never>?
    private var bluetoothStateChangeStream: AsyncStream<CBManagerState>?
    private var bluetoothStateChangeContinuation: AsyncStream<CBManagerState>.Continuation?

    func startBluetoothStateListener() {
        guard bluetoothStateChangeStream == nil else { return } // prevent duplicate

        bluetoothStateChangeStream = AsyncStream<CBManagerState> { continuation in
            bluetoothStateChangeContinuation = continuation
        }
    }

    func awaitBluetoothPoweredOn() async {
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }

        if centralManager?.state == .poweredOn {
            return
        }

        var shouldResume = true

        await withCheckedContinuation { continuation in
            self.poweredOnContinuation = continuation

            // Double-check after a short delay in case the state gets updated instantly
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if self.centralManager?.state == .poweredOn, shouldResume {
                    continuation.resume()
                    self.poweredOnContinuation = nil
                    shouldResume = false
                }
            }
        }
    }
    
    func startScanning() {
        guard centralManager?.state == .poweredOn else { return }
        LogEvent.print(module: "BluetoothHandler.startScanning()", message: "started ...")
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
            LogEvent.print(module: "BluetoothHandler.stopScanning()", message: "... finished")
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
    /// 
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
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let newState = central.state

        Task { @MainActor in
            /*
            let previousState = self.bluetoothState
            */
            self.bluetoothState = newState

            // 🔁 Notify async stream listeners about the new state
            bluetoothStateChangeContinuation?.yield(newState)

            self.isAvailable = newState == .poweredOn
            self.isAuthorized = newState != .unauthorized
            self.isConnected = !self.connectedDevices.isEmpty

            /*
            if previousState != newState {
                LogEvent.print(module: "BluetoothHandler.centralManagerDidUpdateState()", message: "State changed from \(bluetoothStateString(from: previousState)) to \(bluetoothStateString(from: newState))")
            }
            */

            if newState == .poweredOn {
                if let continuation = self.poweredOnContinuation {
                    continuation.resume()
                    self.poweredOnContinuation = nil
                }
                self.startScanning()
            }
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
    
    func connect(to peripheral: CBPeripheral) {
        peripheral.delegate = self
        centralManager?.connect(peripheral, options: nil)
    }
    
    func disconnect(from peripheral: CBPeripheral) {
        centralManager?.cancelPeripheralConnection(peripheral)
    }
    
    func bluetoothStateString(from state: CBManagerState) -> String {
        switch state {
        case .unknown: return ".unknown"
        case .resetting: return ".resetting"
        case .unsupported: return ".unsupported"
        case .unauthorized: return ".unauthorized"
        case .poweredOff: return ".poweredOff"
        case .poweredOn: return ".poweredOn"
        @unknown default: return ".unknown(default)"
        }
    }
    
    func bluetoothStateDescription() -> String {
        guard let centralManager = self.centralManager else {
            return "Central Manager is not initialized."
        }
        let state = centralManager.state

        let stateName: String
        switch state {
        case .unknown:
            stateName = "unknown"
        case .resetting:
            stateName = "resetting"
        case .unsupported:
            stateName = "unsupported"
        case .unauthorized:
            stateName = "unauthorized"
        case .poweredOff:
            stateName = "poweredOff"
        case .poweredOn:
            stateName = "poweredOn"
        @unknown default:
            stateName = "unknown(default)"
        }

        let explanation: String
        switch state {
        case .unknown:
            explanation = "The Bluetooth state is unknown."
        case .resetting:
            explanation = "The Bluetooth connection is resetting."
        case .unsupported:
            explanation = "Bluetooth is not supported on this device."
        case .unauthorized:
            explanation = "The app is not authorized to use Bluetooth."
        case .poweredOff:
            explanation = "Bluetooth is currently powered off."
        case .poweredOn:
            explanation = "Bluetooth is powered on and available."
        @unknown default:
            explanation = "An unknown Bluetooth state occurred."
        }

        return "\(stateName): \(explanation)"
    }

    
}

//extension BluetoothHandlerV4: CBCentralManagerDelegate {
//    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
//        let newState = central.state
//
//        Task { @MainActor in
//            /*
//            let previousState = self.bluetoothState
//            */
//            self.bluetoothState = newState
//
//            // 🔁 Notify async stream listeners about the new state
//            bluetoothStateChangeContinuation?.yield(newState)
//
//            self.isAvailable = newState == .poweredOn
//            self.isAuthorized = newState != .unauthorized
//            self.isConnected = !self.connectedDevices.isEmpty
//
//            /*
//            if previousState != newState {
//                LogEvent.print(module: "BluetoothHandler.centralManagerDidUpdateState()", message: "State changed from \(bluetoothStateString(from: previousState)) to \(bluetoothStateString(from: newState))")
//            }
//            */
//
//            if newState == .poweredOn {
//                if let continuation = self.poweredOnContinuation {
//                    continuation.resume()
//                    self.poweredOnContinuation = nil
//                }
//                self.startScanning()
//            }
//        }
//    }
    
//    func bluetoothStateString(from state: CBManagerState) -> String {
//        switch state {
//        case .unknown: return ".unknown"
//        case .resetting: return ".resetting"
//        case .unsupported: return ".unsupported"
//        case .unauthorized: return ".unauthorized"
//        case .poweredOff: return ".poweredOff"
//        case .poweredOn: return ".poweredOn"
//        @unknown default: return ".unknown(default)"
//        }
//    }
//    
//    func bluetoothStateDescription() -> String {
//        guard let centralManager = self.centralManager else {
//            return "Central Manager is not initialized."
//        }
//        let state = centralManager.state
//
//        let stateName: String
//        switch state {
//        case .unknown:
//            stateName = "unknown"
//        case .resetting:
//            stateName = "resetting"
//        case .unsupported:
//            stateName = "unsupported"
//        case .unauthorized:
//            stateName = "unauthorized"
//        case .poweredOff:
//            stateName = "poweredOff"
//        case .poweredOn:
//            stateName = "poweredOn"
//        @unknown default:
//            stateName = "unknown(default)"
//        }
//
//        let explanation: String
//        switch state {
//        case .unknown:
//            explanation = "The Bluetooth state is unknown."
//        case .resetting:
//            explanation = "The Bluetooth connection is resetting."
//        case .unsupported:
//            explanation = "Bluetooth is not supported on this device."
//        case .unauthorized:
//            explanation = "The app is not authorized to use Bluetooth."
//        case .poweredOff:
//            explanation = "Bluetooth is currently powered off."
//        case .poweredOn:
//            explanation = "Bluetooth is powered on and available."
//        @unknown default:
//            explanation = "An unknown Bluetooth state occurred."
//        }
//
//        return "\(stateName): \(explanation)"
//    }
//}
