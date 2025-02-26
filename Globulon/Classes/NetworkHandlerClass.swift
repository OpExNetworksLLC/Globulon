//
//  NetworkHandlerClass.swift
//  Globulon
//
//  Created by David Holeman on 02/26/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

/**
    - Version: 1.0.0 (2025.02.26)
    - Note;
 */

import SwiftUI
import Network
import Combine

@MainActor class NetworkHandler: ObservableObject {
    
    // Singleton instance
    static let shared = NetworkHandler()
    
    // Network monitoring variables
    private var monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkHandlerQueue")
    private var hasStartedNetworkUpdates = false
    
    // Published properties to update the UI
    @Published var isConnected: Bool = false
    @Published var isReachable: Bool = false
    @Published var wasDisconnected: Bool = false
    @Published var isExpensive: Bool = false
    @Published var isConstrained: Bool = false
    @Published var connectionType: NWInterface.InterfaceType = .other
    
    private init() {
        self.monitor = NWPathMonitor()
        startNetworkUpdates()
    }
    
    func startNetworkUpdates() {
        guard !hasStartedNetworkUpdates else { return }
        hasStartedNetworkUpdates = true
        
        LogEvent.print(module: "NetworkHandler.startNetworkUpdates()", message: "▶️ starting...")
        
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            // Use Task to manage concurrency properly
            Task {
                await self.handlePathUpdate(path: path)
            }
            
            // Perform asynchronous internet connectivity check
            Task {
                await self.checkInternetConnectivity()
            }
        }
        
        monitor.start(queue: queue)
    }
    
    private func stopNetworkUpdates() {
        guard hasStartedNetworkUpdates else { return }
        monitor.cancel()
        hasStartedNetworkUpdates = false
        LogEvent.print(module: "NetworkHandler.stopNetworkUpdates()", message: "⏹️...stopped")
    }
    
    // Handle path updates, ensure it's called from the correct actor
    @MainActor
    private func handlePathUpdate(path: NWPath) async {
        updateNetworkStatus(path: path)
    }
    
    // Updates network status based on the current path
    private func updateNetworkStatus(path: NWPath) {
        let isConnected = path.status == .satisfied
        self.isConnected = isConnected
        self.isExpensive = path.isExpensive
        self.isConstrained = path.isConstrained
        
        let connectionTypes: [NWInterface.InterfaceType] = [.cellular, .wifi, .wiredEthernet]
        self.connectionType = connectionTypes.first(where: path.usesInterfaceType) ?? .other
        
        // Handle connection/disconnection events
        if isConnected {
            if wasDisconnected {
                handleConnectivityChange(isConnected: true)
                wasDisconnected = false
                LogEvent.print(module: "NetworkHandler.updateNetworkStatus()", message: "Connected to the internet")
            }
        } else {
            if !wasDisconnected {
                handleConnectivityChange(isConnected: false)
                wasDisconnected = true
                LogEvent.print(module: "NetworkHandler.updateNetworkStatus()", message: "Disconnected from the internet")
            }
        }
    }
    
    // Asynchronous function to check if the internet is actually reachable
    func checkInternetConnectivity() async {
        guard let url = URL(string: "https://www.apple.com") else {
            await MainActor.run {
                self.isReachable = false
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                await MainActor.run {
                    self.isReachable = true
                }
            } else {
                await MainActor.run {
                    self.isReachable = false
                }
            }
        } catch {
            await MainActor.run {
                self.isReachable = false
            }
            print("Internet check failed: \(error.localizedDescription)")
        }
    }
    
    // Handle connectivity change and post a notification
    private func handleConnectivityChange(isConnected: Bool) {
        PostNotification.connectivityChangeNotification(isConnected: isConnected)
    }
}
