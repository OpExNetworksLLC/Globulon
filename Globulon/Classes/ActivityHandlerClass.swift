////
////  ActivityHandlerClass.swift
////  Globulon
////
////  Created by David Holeman on 6/26/24.
////  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
////
//
//import Foundation
//import CoreMotion
//import Combine
//
//@MainActor class ActivityHandler: ObservableObject {
//    
//    enum ActivityState: String {
//        case walking = "Walking"
//        case running = "Running"
//        case driving = "Driving"
//        case stationary = "Stationary"
//        case unknown = "Unknown"
//    }
//    
//    static let shared = ActivityHandler()
//    
//    private let manager: CMMotionActivityManager
//    
//    @Published var isActivityMonitoringOn = false
//    @Published var isActivity = false
//    @Published var activityState: ActivityState = .stationary
//    
//    @Published
//    var updatesStarted: Bool = UserDefaults.standard.bool(forKey: "activityUpdatesStarted") {
//        didSet {
//            UserDefaults.standard.set(updatesStarted, forKey: "activityUpdatesStarted")
//            LogEvent.print(module: "ActivityHandler.updatesStarted", message: "\(updatesStarted ? "Activity updates started ..." : "... stopped activity updates")")
//        }
//    }
//    
//    private init() {
//        self.manager = CMMotionActivityManager()
//    }
//    
//    class func getMotionActivityPermission(completion: @escaping (Bool) -> Void) {
////        guard CMMotionActivityManager.isActivityAvailable() else {
////            LogEvent.print(module: "MotionManager.getMotionTrackingPermission()", message: "Motion activity is not available on this device.")
////            completion(false)
////            return
////        }
//
//        // Check the authorization status to determine if permission was granted.
//        switch CMMotionActivityManager.authorizationStatus() {
//            case .authorized:
//                LogEvent.print(module: "MotionManager.getMotionTrackingPermission()", message: "Motion tracking permission is: true.")
//                completion(true)
//            case .denied:
//                LogEvent.print(module: "MotionManager.getMotionTrackingPermission()", message: "Motion tracking permission is: false.")
//                completion(false)
//            case .restricted, .notDetermined:
//                LogEvent.print(module: "MotionManager.getMotionTrackingPermission()", message: "Motion tracking permission is restricted or not yet determined.  State: false")
//                completion(false)
//            @unknown default:
//                // Handle future cases
//                completion(false)
//        }
//    }
//    
//    func getMotionActivityStatus(completion: @escaping (Bool) -> Void) {
//        if CMMotionActivityManager.isActivityAvailable() {
//            let status = CMMotionActivityManager.authorizationStatus()
//            switch status {
//            case .authorized:
//                completion(true)
//            default:
//                completion(false)
//            }
//        } else {
//            completion(false)
//        }
//    }
//    
//    class func requestMotionActivityPermission(completion: @escaping (Bool) -> Void) {
//        
//        /// It's important to note that since the permission prompt is asynchronous and may be presented to the user
//        /// after this method returns, the completion handler might be called before the user responds to the prompt.
//        /// Therefore, relying solely on the completion handler to determine permission status immediately after calling
//        /// this method is not reliable. You should check the authorization status again in your app after some time or
//        /// after the app is restarted to get the updated status.
//
//        let motionActivityManager = CMMotionActivityManager()
//
//        /// Start receiving motion activity updates. The system automatically requests permission the first time this is called.
//        ///
//        motionActivityManager.startActivityUpdates(to: .main, withHandler: { activity in
//            
//            /// Handle the activity data here.
//            /// For the sake of this example, we'll just print a message indicating that updates have started.
//            ///
//            LogEvent.print(module: "ActivityHandler.requestMotionActivityPermission()", message: "Motion activity updates have started...")
//        })
//        
//        let motionManager = CMMotionManager()
//        motionManager.startDeviceMotionUpdates(to: OperationQueue.main) {
//            (data, error) in
//            // Handle motion data
//            LogEvent.print(module: "ActivityHandler.requestMotionActivityPermission()", message: "Device Motion Activity updates have started...")
//
//        }
//
//        /// Check the authorization status to determine if permission was granted.
//        ///
//        switch CMMotionActivityManager.authorizationStatus() {
//            case .authorized:
//                LogEvent.print(module: "ActivityHandler.requestMotionActivityPermission()", message: "Motion Activity tracking permission granted.")
//                completion(true)
//            case .denied:
//                LogEvent.print(module: "ActivityHandler.requestMotionActivityPermission()", message: "Motion Activity tracking permission denied.")
//                completion(false)
//            case .restricted, .notDetermined:
//                LogEvent.print(module: "ActivityHandler.requestMotionActivityPermission()", message: "Motion Activity tracking permission restricted or not yet determined.")
//                completion(false)
//            @unknown default:
//                // Handle future cases
//                completion(false)
//        }
//    }
//    
//    func startActivityUpdates() {
//
//        guard CMMotionActivityManager.isActivityAvailable() else {
//            LogEvent.print(module: "** ActivityHandler.startActivityUpdates()", message: "Activity data is not available on this device.")
//            return
//        }
//        
//        self.isActivityMonitoringOn = true
//        self.updatesStarted = true
//        LogEvent.print(module: "ActivityHandler.startActivityUpdates()", message: "started ...")
//
//        
//        manager.startActivityUpdates(to: OperationQueue.main) { [weak self] activity in
//            guard let self = self, let activity = activity else { return }
//            
//            /// Published values to update to share with other functions and views
//            ///
//            self.updateActivityState(activity)
//        }
//    }
//    
//    func stopActivityUpdates() {
//        manager.stopActivityUpdates()
//        
//        isActivityMonitoringOn = false
//        
//        LogEvent.print(module: "ActivityHandler.stopActivityUpdates()", message: "Stopping activity updates")
//    }
//    
//    private func updateActivityState(_ activity: CMMotionActivity) {
//        Task { @MainActor in
//            if activity.walking {
//                self.activityState = .walking
//            } else if activity.running {
//                self.activityState = .running
//            } else if activity.automotive {
//                self.activityState = .driving
//            } else if activity.stationary {
//                self.activityState = .stationary
//            } else {
//                self.activityState = .unknown
//            }
//            
//            /// Update isActivity based on the activity state
//            self.isActivity = !activity.stationary && !activity.unknown
//            
//            // Log the activity state
//            //print("** Current activity state: \(activityState.rawValue)")
//            
//        }
//    }
//}
