//
//  LocationHandlerClass.swift
//  Globulon
//
//  Created by David Holeman on 6/26/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import SwiftUI
import SwiftData
import CoreLocation
import MapKit


@MainActor class LocationHandler: ObservableObject {
    
    static let shared = LocationHandler()  // Create a single, shared instance of the object.

    private let manager: CLLocationManager
    private var background: CLBackgroundActivitySession?
    
    private let locationDataBufferLimit = 25
    @Published var locationDataBuffer: [LocationDataBuffer] = []

    @ObservedObject var activityHandler = ActivityHandler.shared  // access the ActivityHandler singleton

    @Published var priorLocation = CLLocation()
    @Published var priorCount = 0
    
    @Published var lastLocation = CLLocation()
    @Published var lastCount = 0
    @Published var lastSpeed = 0.0
    
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
            LogEvent.print(module: "LocationHandler.updatesStarted", message: "\(updatesStarted ? "Location updates started ..." : "... stopped location updates")")
        }
    }
    
    @Published
    var backgroundActivity: Bool = UserDefaults.standard.bool(forKey: "BGActivitySessionStarted") {
        didSet {
            backgroundActivity ? self.background = CLBackgroundActivitySession() : self.background?.invalidate()
            UserDefaults.standard.set(backgroundActivity, forKey: "BGActivitySessionStarted")
            LogEvent.print(module: "LocationHandler", message: "Background activty changed to: \(backgroundActivity)")
        }
    }
    
    private init() {
        self.manager = CLLocationManager()  // Creating a location manager instance is safe to call here in `MainActor`.
    }
    
    
    
    func requestWhenInUseAuthorization() {
        // Show UI to explain the need for always authorization before requesting it
        LogEvent.print(module: "LocationHandler.requestWhenInUseAuthorization", message: "Request when in use authorization...")
        self.manager.requestWhenInUseAuthorization()
    }
    
    func requestAuthorizedAlways() {
        // Show UI to explain the need for always authorization before requesting it
        LogEvent.print(module: "LocationHandler.requestAlwaysAuthorization", message: "Request always authorization...")
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
    
    
    var isTripInitiatd = false
    var isTripActive = false
    var walkingSpeed = 0.0 // MPS
    var locationUpdateCounter = 0
    
    func startLocationUpdates() {
        
        /// Double check here and ensure at least .requestWhenInUseAuthorization() has been asked
        ///
        if self.manager.authorizationStatus == .notDetermined {
            self.manager.requestWhenInUseAuthorization()
        }
        
        LogEvent.print(module: "LocationHandler.startLocationUpdates", message: "Starting location updates ...")
        
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
                        
                        
                        if self.lastLocation != self.priorLocation || loc.speed <= 0 {
                            self.siftLocation = self.lastLocation
                            self.siftCount += 1
                        } else {
                        }
                        
                        /// Update the buffer when speed is below the tracking threshold
                        ///
                        if loc.speed < UserSettings.init().trackingSpeedThreshold {
                            updateLocationDataBuffer(location: loc)
                            self.isTripInitiatd = false
                            self.isTripActive = false
                            if (loc.speed) > walkingSpeed {
                                print("** moving faster than walking: \(loc.speed) \(UserSettings.init().trackingSpeedThreshold)")
                            }
                        } else {
                            if isTripActive == false { self.isTripInitiatd = true }
                        }
                        
                        /// Action when speed is greater than 0
                        if loc.speed > 0 {
                            self.isMoving = true
                            self.lastSpeed = loc.speed
                        } else {
                            self.isMoving = false
                        }
                        
                        /// Set what defines walking
                        ///
                        if loc.speed > 0.9 && loc.speed < 1.8 {
                            self.isWalking = true
                        } else {
                            self.isWalking = false
                        }
                        
                        /// Set what defines driving  > 5 mph
                        ///
                        if loc.speed > 2.2352 {
                            self.isDriving = true
                        } else {
                            self.isDriving = false
                        }
                        
                        /// Update the buffer
                        //updateLocationDataBuffer(location: self.lastLocation)
                        
                        
                        if loc.speed >= UserSettings.init().trackingSpeedThreshold {
                            self.isTripActive = true
                        } else {
                            self.isTripActive = false
                        }
                        
                        /// Transfer buffer if trip initiated and active
                        ///
                        if isTripInitiatd && isTripActive {
                            LogEvent.print(module: "**LocationHandler.startLocationUpdates", message: "Transfering data from buffer")
                            saveLocationDataBuffer()
                            self.isTripInitiatd = false
                        }

                        /// We are driving at this point so do stuff

                        locationUpdateCounter += 1
                        if locationUpdateCounter >= UserSettings.init().trackingSampleRate {
                            
                            /// Save location only if the trip is active
                            ///
                            if isTripActive {
                                saveLocation(location: loc)
                            }
                            
                            locationUpdateCounter = 0
                        }
                        
                        //LogEvent.print(module: "LocationHandler", message: "Location \(self.lastCount): \(self.lastLocation)")
                        
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
    
    
    func updateLocationDataBuffer(location: CLLocation?) {
        
        /// Guard to make sure location is not nil and speed is valid
        ///
        guard let location = location, location.speed >= 0 else {
            /// Skip the update if location is nil or speed is invalid
            ///
            return
        }
        
        //LogEvent.print(module: "updateLocationDataBuffer", message: "Location \(location)" )

        
        /// Check if the array has reached its capacity
        ///
        if locationDataBuffer.count >= locationDataBufferLimit {
            /// Remove the oldest entry to make space for the new one
            ///
            locationDataBuffer.removeLast()
        }
        /// Insert the new data at the beginning of the array, treating it as a queue
        ///
        let entry = LocationDataBuffer(
            timestamp: Date(),
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            speed: location.speed,
            processed: false,
            code: "",
            note: "buffer:" + " " + "\(isMoving ? "Moving" : "") " + "\(isWalking ? "Walking" : "") " + "\(isDriving ? "Driving" : "") "  + "\(activityHandler.isActivity)" + "\(activityHandler.activityState)"
        )
        locationDataBuffer.insert(entry, at: 0)
                
    }
    
    func saveLocationDataBuffer() {
        var index = 0
        while index < locationDataBuffer.count {

            if locationDataBuffer[index].speed <= 0.0 {
                
                guard let container = AppEnvironment.sharedModelContainer else {
                    LogEvent.print(module: "LocationManager.saveLocation()", message: "shared model container has not been initialized")
                    return
                }
                
                let context = ModelContext(container)
                
                print("**% \(locationDataBuffer[index].timestamp), \(locationDataBuffer[index].speed), \(locationDataBuffer[index].latitude) : \(locationDataBuffer[index].longitude)")
                
                let entry = GpsJournalSD(
                    timestamp: locationDataBuffer[index].timestamp,
                    longitude: locationDataBuffer[index].longitude,
                    latitude: locationDataBuffer[index].latitude,
                    speed: locationDataBuffer[index].speed,
                    processed: false,
                    code: locationDataBuffer[index].code,
                    note: locationDataBuffer[index].note
                )
                
                context.insert(entry)
                
                var saveIndex = 0
                while saveIndex < index {
                    
                    LogEvent.print(module: "**LocationHandler.saveLocationDataBuffer()", message: "\(locationDataBuffer[saveIndex].timestamp), \(locationDataBuffer[saveIndex].speed), \(locationDataBuffer[saveIndex].latitude) : \(locationDataBuffer[saveIndex].longitude)")
                    
                    let entry = GpsJournalSD(
                        timestamp: locationDataBuffer[saveIndex].timestamp,
                        longitude: locationDataBuffer[saveIndex].longitude,
                        latitude: locationDataBuffer[saveIndex].latitude,
                        speed: locationDataBuffer[saveIndex].speed,
                        processed: false,
                        code: locationDataBuffer[saveIndex].code,
                        note: locationDataBuffer[saveIndex].note
                    )
                    
                    context.insert(entry)
                    
                    saveIndex += 1
                }
                
                locationDataBuffer.removeAll()
                break
            }
            
            index += 1
        }
    }

    func saveLocation(location: CLLocation) {
        do {
            // Access the sharedModelContainer
            guard let container = AppEnvironment.sharedModelContainer else {
                LogEvent.print(module: "LocationManager.saveLocation()", message: "shared model container has not been initialized")
                return
            }
            
            let context = ModelContext(container)
            
            let entry = GpsJournalSD(
                timestamp: Date(),
                longitude: location.coordinate.longitude,
                latitude: location.coordinate.latitude,
                speed: location.speed,
                processed: false,
                code: "",
                note: "\(isMoving ? "Moving" : "") " + "\(isWalking ? "Walking" : "") " + "\(isDriving ? "Driving" : "") "  + "\(activityHandler.activityState)"
            )
            
            context.insert(entry)
            
            LogEvent.print(module: "**LocationHandler.saveLocation()", message: "saved: \(entry.timestamp) \(formatMPH(convertMPStoMPH( entry.speed))) mph")
        }
    }
    
    func stopLocationUpdates() {
        LogEvent.print(module: "LocationHandler.stopLocationUpdates", message: "... Stopping location updates")
        self.updatesStarted = false
    }
}
