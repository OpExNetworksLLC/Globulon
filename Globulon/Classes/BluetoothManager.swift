//
//  BluetoothManager.swift
//  Globulon
//
//  Created by David Holeman on 4/18/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

/**
 - Version: 2.0.0 (2024.04.25)
     - Key improvements included:
        - proper handling of Start and Pause functions via `shouldStartScanning` and `startScanning()`
        - modified `centralManagerDidUpdateState` to start scanning only  if `updatesLive` is enabled

 - Note: This version is Swift 6 and Conncurrency compliant
 
 */

import Foundation
import CoreBluetooth
import UIKit

@MainActor
final class BluetoothManager: NSObject, ObservableObject, @preconcurrency CBCentralManagerDelegate, CBPeripheralDelegate {
    
    static let shared = BluetoothManager()
    
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
            LogManager.event(module: "BluetoothManager.updatesLive", message: "\(updatesLive ? "Bluetooth updates started ..." : "... stopped activity updates")")
        }
    }
    
    private var centralManager: CBCentralManager?
    private var deviceMap: [UUID: CBPeripheral] = [:] // Track devices by UUID for easy management

    private var shouldStartScanning: Bool = false
    private var hasStartedScanning: Bool = false
    
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
        LogManager.event(module: "BluetoothManager.Permission", message: "Permission was denied")

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
    
    func requestBluetoothPermissionAgain() async {
        // If permission is already granted, no need to do anything
        if CBManager.authorization == .allowedAlways {
            self.isPermission = true
            return
        }

        // Show alert to open settings
        await showBluetoothSettingsAlert()

        // Wait for user to potentially return from settings
        await waitForAuthorizationChange(maxWaitTime: 1)

        // Check permission again after delay
        let currentAuth = CBManager.authorization
        self.isPermission = currentAuth == .allowedAlways
        
        print(">>> Bluetooth permission is \(currentAuth) \(self.isPermission)")

        if !self.isPermission {
            handleBluetoothPermissionDeclined()
        }
    }
    
    private func showBluetoothSettingsAlert() async {
        let alert = UIAlertController(
            title: "Bluetooth Permission Needed",
            message: "Please enable Bluetooth in Settings to allow full functionality.  This app may may restart automatically after enabling Bluetooth.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString),
               UIApplication.shared.canOpenURL(url) {
                Task { @MainActor in
                    await UIApplication.shared.open(url)
                }
            }
        })
        
        if let topVC = topViewController() {
            topVC.present(alert, animated: true)
        }
    }
    
    private func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let root = base ?? UIApplication.shared
            .connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.rootViewController
        
        if let nav = root as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        } else if let tab = root as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        } else if let presented = root?.presentedViewController {
            return topViewController(base: presented)
        }
        return root
    }
    
    private func waitForAuthorizationChange(maxWaitTime: TimeInterval = 10) async {
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < maxWaitTime {
            let auth = CBManager.authorization
            if auth != .notDetermined {
                return
            }
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 sec delay
        }
    }
    
    func startBluetoothUpdates() async {
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }

        shouldStartScanning = true
        self.updatesLive = true

        guard let manager = centralManager else {
            LogManager.event(module: "BluetoothManager.startBluetoothUpdates()", message: "Central manager is unavailable.")
            self.updatesLive = false
            return
        }

        LogManager.event(module: "BluetoothManager.startBluetoothUpdates()", message: "Checking ...")

        switch manager.state {
        case .unknown:
            LogManager.event(module: "BluetoothManager.startBluetoothUpdates()", message: "State is unknown, attempting to start scanning...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if self.centralManager?.state == .poweredOn {
                    //self.startScanning()
                }
            }
        case .poweredOn:
            LogManager.event(module: "BluetoothManager.startBluetoothUpdates()", message: "Bluetooth powered on.")
            self.startScanning()
        default:
            LogManager.event(module: "BluetoothManager.startBluetoothUpdates()", message: "Bluetooth not powered on.")
            stopScanning()
            self.updatesLive = false
            shouldStartScanning = false
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

    func stopBluetoothUpdates() {
        stopScanning()
        DispatchQueue.main.async {
            self.discoveredDevices.removeAll()
            self.connectedDevices.removeAll()
            self.updatesLive = false
            self.centralManager = nil
            LogManager.event(module: "BluetoothManager.stopScanning()", message: "... finished")
        }
    }
    
    func awaitBluetoothPoweredOn() async {
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }

        if centralManager?.state == .poweredOn {
            return
        }

        await withCheckedContinuation { continuation in
            // Store and guard against multiple resumes
            self.poweredOnContinuation = continuation

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if self.centralManager?.state == .poweredOn {
                    if let cont = self.poweredOnContinuation {
                        cont.resume()
                        self.poweredOnContinuation = nil
                    }
                }
            }
        }
    }
    
    // MARK: - Scanning
    
    func startScanning() {
        guard centralManager?.state == .poweredOn, shouldStartScanning else { return }
        LogManager.event(module: "BluetoothManager.startScanning()", message: "started ...")
        let connected = centralManager?.retrieveConnectedPeripherals(withServices: []) ?? []
        connectedDevices = connected
        centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    
    func stopScanning() {
        centralManager?.stopScan()
    }
    


    // MARK: - Get bluetooth permissions
    
    func getBluetoothAvailability(completion: @escaping (Bool) -> Void) {
        Task { @MainActor in
            await awaitBluetoothPoweredOn()

            guard let state = centralManager?.state else {
                self.isAvailable = false
                LogManager.event(module: "BluetoothManager.getBluetoothAvailability()", message: "Central manager unavailable.")
                completion(false)
                return
            }

            let isPoweredOn = state == .poweredOn
            self.isAvailable = isPoweredOn
            LogManager.event(module: "BluetoothManager.getBluetoothAvailability()", message: "\(isPoweredOn)")
            completion(isPoweredOn)
        }
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
        LogManager.event(module: "BluetoothManager.getBluetoothAuthorized()", message: "\(result)")
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
        LogManager.event(module: "BluetoothManager.getBluetoothPermission()", message: "\(result)")
        completion(result)
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let newState = central.state
        let previousState = bluetoothState // Save old state before updating

        Task { @MainActor in
            self.bluetoothState = newState

            // 🔁 Notify async stream listeners about the new state
            bluetoothStateChangeContinuation?.yield(newState)

            self.isAvailable = newState == .poweredOn
            self.isAuthorized = newState != .unauthorized
            self.isConnected = !self.connectedDevices.isEmpty

            if previousState != newState {
                LogManager.event(module: "BluetoothManager.centralManagerDidUpdateState()", message: "State changed from \(bluetoothStateString(from: previousState)) to \(bluetoothStateString(from: newState))")
            }

            if newState == .poweredOn {
                if let cont = self.poweredOnContinuation {
                    cont.resume()
                    self.poweredOnContinuation = nil
                }
                if self.updatesLive {
                    LogManager.event(module: "BluetoothManager.centralManagerDidUpdateState()", message: "Bluetooth powered on.")
                    self.startScanning()
                }
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

//extension BluetoothManagerV4: CBCentralManagerDelegate {
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
//                LogManager.event(module: "BluetoothManager.centralManagerDidUpdateState()", message: "State changed from \(bluetoothStateString(from: previousState)) to \(bluetoothStateString(from: newState))")
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
