//
//  ReachabilityClass.swift
//  ViDrive
//
//  Created by David Holeman on 3/17/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Network

typealias ReachabilityCallback = (Bool) -> Void
class Reachability {
    static let shared = Reachability()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue.global(qos: .background)
    private var isNetworkReachable: Bool = false {
        didSet {
            // Notify through callback whenever the network reachability status changes
            reachabilityChangedCallback?(isNetworkReachable)
        }
    }
    var reachabilityChangedCallback: ReachabilityCallback?
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isNetworkReachable = path.status == .satisfied
        }
        monitor.start(queue: queue)
    }
    
    static func checkReachability(completion: @escaping ReachabilityCallback) {
        // Directly return the current network status and set the callback for future updates
        DispatchQueue.main.async {
            completion(shared.isNetworkReachable)
            shared.reachabilityChangedCallback = completion
        }
    }
}


