//
//  NetworkHandlerClass.swift
//  Globulon
//
//  Created by David Holeman on 7/7/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

/// # NotificationHandler
/// This class handles location services
///
/// # Version History
/// ### 0.1.0.69
/// # - Revised to notify once if disconnected
/// # - *Date*: 07/18/24

import SwiftUI
import Network
import Combine

class NetworkHandler: ObservableObject {
    static let shared = NetworkHandler()

    private var monitor: NWPathMonitor?
    private var queue = DispatchQueue(label: "NetworkHandler")

    @Published var isConnected: Bool = false
    @Published var isReachable: Bool = false // new
    @Published var wasDisconnected: Bool = false
    @Published var isExpensive: Bool = false
    @Published var isConstrained: Bool = false
    @Published var connectionType = NWInterface.InterfaceType.other
    
    private init() {
        self.monitor = NWPathMonitor()
    }

    deinit {
        stopNetworkUpdates()
    }
    
    func startNetworkUpdates() {
        
        LogEvent.print(module: "NetworkHandler.startNetworkUpdates()", message: "started ...")
        
        var wasNotifiedOfDisconnect = false

        monitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let isConnected = path.status == .satisfied
                self?.isConnected = isConnected
                self?.isExpensive = path.isExpensive
                self?.isConstrained = path.isConstrained
                
                let connectionTypes: [NWInterface.InterfaceType] = [.cellular, .wifi, .wiredEthernet]
                self?.connectionType = connectionTypes.first(where: path.usesInterfaceType) ?? .other
                
                if wasNotifiedOfDisconnect == false {
                    if ((self?.isConnected) == false) {
                        self?.handleConnectivityChange(isConnected: isConnected)
                        wasNotifiedOfDisconnect = true
                        self?.wasDisconnected = true
                        LogEvent.print(module: "NetworkStatus.startMonitoring()", message: "Internet is not available")
                    }
                }
                
                /*
                if ((self?.isConnected) == true) {
                    if ((self?.wasDisconnected) == true) {
                        self?.handleConnectivityChange(isConnected: isConnected)
                        self?.wasDisconnected = false
                        LogEvent.print(module: "NetworkStatus.startMonitoring()", message: "Internet is available")
                    }
                } else {
                    if ((self?.wasDisconnected) == false) {
                        self?.handleConnectivityChange(isConnected: isConnected)
                        self?.wasDisconnected = true
                        LogEvent.print(module: "NetworkStatus.startMonitoring()", message: "Internet is not available")
                    }
                }
                */
            }
        }
        monitor?.start(queue: queue)
    }
    
    private func handleConnectivityChange(isConnected: Bool) {
        // Call the function to post a notification
        PostNotification.postConnectivityChangeNotification(isConnected: isConnected)
    }

    func stopNetworkUpdates() {
        monitor?.cancel()
        monitor = nil
    }
}
