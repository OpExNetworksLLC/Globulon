//
//  BluetoothHandlerV3.swift
//  Globulon
//
//  Created by David Holeman on 4/18/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit

@MainActor
final class BluetoothHandlerV3: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    static let shared = BluetoothHandlerV3()
    
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
    private var permissionContinuation: CheckedContinuation<Void, Never>?
    
    private override init() {
        super.init()
        updateAuthorizationStatus()
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task {
                await self.startBluetoothUpdates()
            }
        }
        
        // Initialize manager early to avoid crashes
        //centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func requestBluetoothPermission() async {
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }
        
        if CBManager.authorization == .notDetermined {
            await withCheckedContinuation { continuation in
                self.permissionContinuation = continuation
            }
        } else {
            updateAuthorizationStatus()
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
            
            if let continuation = self.permissionContinuation {
                continuation.resume()
                self.permissionContinuation = nil
            }
        }
    }
    
    func startBluetoothUpdates() async {
        if CBManager.authorization == .notDetermined || CBManager.authorization != .allowedAlways {
            await showBluetoothSettingsAlert()
            return
        }
        
        await requestBluetoothPermission()
        
        guard let manager = centralManager else {
            print("Bluetooth manager not initialized.")
            return
        }
        
        switch manager.state {
        case .poweredOn:
            startScanning()
            LogEvent.print(module: "BluetoothHandler.startBluetoothUpdates()", message: "Bluetooth powered on.")
            self.updatesLive = true
        case .unknown:
            LogEvent.print(module: "BluetoothHandler.startBluetoothUpdates()", message: "Waiting for Bluetooth state update...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.startScanning()
                self.updatesLive = true
            }
        default:
            logBluetoothState()
            LogEvent.print(module: "BluetoothHandler.startBluetoothUpdates()", message: "Bluetooth not powered on.")
            self.updatesLive = false
        }
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
    
    func connect(to peripheral: CBPeripheral) {
        peripheral.delegate = self
        centralManager?.connect(peripheral, options: nil)
    }
    
    func disconnect(from peripheral: CBPeripheral) {
        centralManager?.cancelPeripheralConnection(peripheral)
    }
    
    func logBluetoothState() {
        let description: String
        switch centralManager?.state {
        case .unknown:
            description = "The Bluetooth state is unknown."
        case .resetting:
            description = "The Bluetooth connection is resetting."
        case .unsupported:
            description = "Bluetooth is not supported on this device."
        case .unauthorized:
            description = "The app is not authorized to use Bluetooth."
        case .poweredOff:
            description = "Bluetooth is currently powered off."
        case .poweredOn:
            description = "Bluetooth is powered on and available."
        default:
            description = "An unknown state occurred."
        }
        print("Bluetooth State: \(description)")
    }
    
    private func updateAuthorizationStatus() {
        let auth = CBManager.authorization
        isPermission = auth != .notDetermined
        isAuthorized = auth == .allowedAlways
    }
    
    private func showBluetoothSettingsAlert() async {
        let alert = UIAlertController(
            title: "Bluetooth Permission Needed",
            message: "Please enable Bluetooth in Settings to allow full functionality.",
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
    
    // MARK: - Get permissions
    
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
