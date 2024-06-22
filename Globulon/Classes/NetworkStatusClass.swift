//
//  NetworkStatus.swift
//  ViDrive
//
//  Created by David Holeman on 3/18/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import Network
import Combine

class NetworkStatus: ObservableObject {
    static let shared = NetworkStatus()

    private var monitor: NWPathMonitor?
    private var queue = DispatchQueue(label: "NetworkMonitor")

    @Published var isConnected: Bool = false
    @Published var isExpensive: Bool = false
    @Published var isConstrained: Bool = false
    @Published var connectionType = NWInterface.InterfaceType.other

    private init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        monitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let isConnected = path.status == .satisfied
                self?.isConnected = isConnected
                self?.isExpensive = path.isExpensive
                self?.isConstrained = path.isConstrained
                
                let connectionTypes: [NWInterface.InterfaceType] = [.cellular, .wifi, .wiredEthernet]
                self?.connectionType = connectionTypes.first(where: path.usesInterfaceType) ?? .other
                
                if ((self?.isConnected) == true) {
                    //NotificationCenter.default.post(name: .isInternetAvailable, object: nil, userInfo: ["isConnected": isConnected])
                    
                    //self?.handleConnectivityChange(isConnected: isConnected)
                    
                    LogEvent.print(module: "NetworkStatus.startMonitoring()", message: "Internet is available")
                    print(">>> Connected: \(path.status)")
                } else {
                    self?.handleConnectivityChange(isConnected: isConnected)
                    //NotificationCenter.default.post(name: .isInternetAvailable, object: nil, userInfo: ["isConnected": isConnected])
                    
                    LogEvent.print(module: "NetworkStatus.startMonitoring()", message: "Internet is not available")
                    print(">>> Disconnected: \(path.status)")
                }
            }
        }

        monitor?.start(queue: queue)
    }
    
    private func handleConnectivityChange(isConnected: Bool) {
        // Call the function to post a notification
        PostNotification.postConnectivityChangeNotification(isConnected: isConnected)
    }

    func stopMonitoring() {
        monitor?.cancel()
        monitor = nil
    }
}
