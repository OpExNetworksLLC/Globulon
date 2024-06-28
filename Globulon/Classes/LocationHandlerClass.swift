//
//  LocationHandlerClass.swift
//  Globulon
//
//  Created by David Holeman on 6/26/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import SwiftUI
import CoreLocation
import MapKit


@MainActor class LocationHandler: ObservableObject {
    
    static let shared = LocationHandler()  // Create a single, shared instance of the object.

    private let manager: CLLocationManager
    private var background: CLBackgroundActivitySession?
    
    let activityHandler = ActivityHandler.shared  // access the ActivityHandler singleton

    @Published var priorLocation = CLLocation()
    @Published var priorCount = 0
    
    @Published var lastLocation = CLLocation()
    @Published var lastCount = 0
    
    @Published var siftLocation = CLLocation()
    @Published var siftCount = 0
    
    @Published var isStationary = false
    @Published var isMoving = false
    @Published var isWalking = false
    @Published var isDriving = false
        
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0.0, longitude: -0.0),
        span: MKCoordinateSpan(latitudeDelta: 0.0, longitudeDelta: 0.0)
    )

    @Published
    var updatesStarted: Bool = UserDefaults.standard.bool(forKey: "liveUpdatesStarted") {
        didSet {
            UserDefaults.standard.set(updatesStarted, forKey: "liveUpdatesStarted")
            LogEvent.print(module: "LocationHandler", message: "Live updates \(updatesStarted ? "started..." : "...stopped")")
        }
    }
    
    @Published
    var backgroundActivity: Bool = UserDefaults.standard.bool(forKey: "BGActivitySessionStarted") {
        didSet {
            backgroundActivity ? self.background = CLBackgroundActivitySession() : self.background?.invalidate()
            UserDefaults.standard.set(backgroundActivity, forKey: "BGActivitySessionStarted")
            LogEvent.print(module: "LocationHandler", message: "Background acitivty changed to: \(backgroundActivity)")
        }
    }
    
    private init() {
        self.manager = CLLocationManager()  // Creating a location manager instance is safe to call here in `MainActor`.
    }
    
    func requestWhenInUseAuthorization() {
        // Show UI to explain the need for always authorization before requesting it
        LogEvent.print(module: "LocationManager.requestWhenInUseAuthorization", message: "Request when in use authorization...")
        self.manager.requestWhenInUseAuthorization()
    }
    
    func requestAuthorizedAlways() {
        // Show UI to explain the need for always authorization before requesting it
        LogEvent.print(module: "LocationManager.requestAlwaysAuthorization", message: "Request always authorization...")
        self.manager.requestAlwaysAuthorization()
    }
    
    func getAuthorizedWhenInUse(completion: @escaping (Bool) -> Void) {
        let authorizationStatus: CLAuthorizationStatus
        authorizationStatus = self.manager.authorizationStatus
        
        switch authorizationStatus {
        case .authorizedWhenInUse:
            completion(true)
        default:
            completion(false)
        }
    }
    
    func getAuthorizedAlways(completion: @escaping (Bool) -> Void) {
        let authorizationStatus: CLAuthorizationStatus
        authorizationStatus = self.manager.authorizationStatus
        
        switch authorizationStatus {
        case .authorizedAlways:
            completion(true)
        default:
            completion(false)
        }
    }
    
    func startLocationUpdates() {
        
        /// Double check here and ensure at least .requestWhenInUseAuthorization() has been asked
        ///
        if self.manager.authorizationStatus == .notDetermined {
            self.manager.requestWhenInUseAuthorization()
        }
        
        LogEvent.print(module: "LocationHandler", message: "Starting location updates...")
        
        Task() {
            do {
                self.updatesStarted = true
                let updates = CLLocationUpdate.liveUpdates()
                for try await update in updates {
                    if !self.updatesStarted { break }  // End location updates by breaking out of the loop.
                    
                    if let loc = update.location {
                        
                        self.priorLocation = self.lastLocation
                        self.priorCount = self.lastCount
                        
                        self.lastLocation = loc
                        self.lastCount += 1
                        
                        
                        if self.lastLocation != self.priorLocation {
                            self.siftLocation = self.lastLocation
                            self.siftCount += 1
                        } else {
                        }
                        
//                        let distance = loc.distance(from: priorLocation)
//                        if distance > 1.0 {
//                            self.siftLocation = self.lastLocation
//                        }
                        
                        
                        /// Set what defines moving
                        self.isMoving = loc.speed > 0.0
                        
                        /// Set what defines walking
                        if loc.speed > 0.9 && loc.speed < 1.8 {
                            self.isWalking = true
                        } else {
                            self.isWalking = false
                        }
                        
                        /// Set what defines driving
                        self.isDriving = loc.speed > 2.5
                        
                        //LogEvent.print(module: "**", message: "\(self.count): isActivity: \(self.activityHandler.isActivity), activityState: \(self.activityHandler.activityState), moving: \(self.isMoving), walking: \(self.isWalking), driving: \(self.isDriving)")
                        
                        //LogEvent.print(module: "LocationHandler", message: "Location \(self.count): \(self.lastLocation)")
                        
                        /// Update region
                        DispatchQueue.main.async {
                            self.region = MKCoordinateRegion(
                                center: self.lastLocation.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                            )
                        }
                    }
                }
            } catch {
                LogEvent.print(module: "LocationHandler", message: "Could not start location updates")
            }
            return
        }
    }
    
    func stopLocationUpdates() {
        LogEvent.print(module: "LocationHandler", message: "Stopping location updates")
        self.updatesStarted = false
    }
}
