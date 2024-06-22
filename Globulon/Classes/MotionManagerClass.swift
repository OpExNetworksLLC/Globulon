//
//  MotionManagerClass.swift
//  ViDrive
//
//  Created by David Holeman on 3/12/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import CoreMotion
import Foundation

class MotionManager {

    private let motionActivityManager = CMMotionActivityManager()
    //private let operationQueue = OperationQueue()
    
    class func getMotionTrackingPermission(completion: @escaping (Bool) -> Void) {
//        guard CMMotionActivityManager.isActivityAvailable() else {
//            LogEvent.print(module: "MotionManager.getMotionTrackingPermission()", message: "Motion activity is not available on this device.")
//            completion(false)
//            return
//        }

        // Check the authorization status to determine if permission was granted.
        switch CMMotionActivityManager.authorizationStatus() {
            case .authorized:
                LogEvent.print(module: "MotionManager.getMotionTrackingPermission()", message: "Motion tracking permission granted.")
                completion(true)
            case .denied:
                LogEvent.print(module: "MotionManager.getMotionTrackingPermission()", message: "Motion tracking permission denied.")
                completion(false)
            case .restricted, .notDetermined:
                LogEvent.print(module: "MotionManager.getMotionTrackingPermission()", message: "Motion tracking permission is restricted or not yet determined.")
                completion(false)
            @unknown default:
                // Handle future cases
                completion(false)
        }
    }

    /// Requests motion tracking permission from the user and reports the result.
    /// - Parameter completion: A closure that is called with the result of the permission request. `true` if permission was granted, `false` otherwise.
    ///
    //        guard CMMotionActivityManager.isActivityAvailable() else {
    //            LogEvent.print(module: "MotionManager.getMotionTrackingPermission()", message: "Motion activity is not available on this device.")
    //            completion(false)
    //            return
    //        }
    ///
    ///
    class func requestMotionTrackingPermission(completion: @escaping (Bool) -> Void) {

        let motionActivityManager = CMMotionActivityManager()

        // Start receiving motion activity updates. The system automatically requests permission the first time this is called.
        motionActivityManager.startActivityUpdates(to: .main, withHandler: { activity in
            // Handle the activity data here.
            // For the sake of this example, we'll just print a message indicating that updates have started.
            LogEvent.print(module: "MotionManager.getMotionTrackingPermission()", message: "Motion activity updates have started...")
        })
        
        let motionManager = CMMotionManager()
        motionManager.startDeviceMotionUpdates(to: OperationQueue.main) {
            (data, error) in
            // Handle motion data
            LogEvent.print(module: "MotionManager.getMotionTrackingPermission()", message: "Device motion updates have started...")

        }

        // Check the authorization status to determine if permission was granted.
        switch CMMotionActivityManager.authorizationStatus() {
            case .authorized:
                LogEvent.print(module: "MotionManager.getMotionTrackingPermission()", message: "Motion tracking permission granted.")
                completion(true)
            case .denied:
                LogEvent.print(module: "MotionManager.getMotionTrackingPermission()", message: "Motion tracking permission denied.")
                completion(false)
            case .restricted, .notDetermined:
                LogEvent.print(module: "MotionManager.getMotionTrackingPermission()", message: "Motion tracking permission is restricted or not yet determined.")
                completion(false)
            @unknown default:
                // Handle future cases
                completion(false)
        }

        // It's important to note that since the permission prompt is asynchronous and may be presented to the user
        // after this method returns, the completion handler might be called before the user responds to the prompt.
        // Therefore, relying solely on the completion handler to determine permission status immediately after calling
        // this method is not reliable. You should check the authorization status again in your app after some time or
        // after the app is restarted to get the updated status.
    }
}
