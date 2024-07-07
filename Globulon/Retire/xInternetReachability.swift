//////
//////  InternetReachability.swift
//////  ViDrive
//////
//////  Created by David Holeman on 3/18/24.
//////  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//////
////
//import Network
//
//class InternetReachability {
//    static let shared = InternetReachability()
//    
//    private let monitor = NWPathMonitor()
//    private var isInternetAvailable = false
//    
//    private init() {
//        startMonitoring()
//    }
//    
//    private func startMonitoring() {
//        monitor.pathUpdateHandler = { path in
//            self.isInternetAvailable = path.status == .satisfied
//            print("* InternetReachabilty: Internet is \(self.isInternetAvailable ? "available" : "unavailable")")
//        }
//        
//        let queue = DispatchQueue(label: "InternetReachabilityMonitor")
//        monitor.start(queue: queue)
//    }
//    
//    func isInternetReachable() -> Bool {
//        return isInternetAvailable
//    }
//}
