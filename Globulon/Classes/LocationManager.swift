//
//  LocationManager.swift
//  Globulon
//
//  Created by David Holeman on 4/11/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import SwiftUI
import SwiftData
import CoreLocation
import MapKit
import Combine

/**
 - Version: 1.0.0 (2025.04.11)
 - Note: Created from LocationHandlerV1
 */

@MainActor class LocationManager: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate {

    static let shared = LocationManager()  // Singleton instance

    private let manager: CLLocationManager
    private var background: CLBackgroundActivitySession?
    
    private var poiRegions: [CLCircularRegion] = []
    // Dictionary to track entered/exited states per region
    private var regionStates: [String: Bool] = [:]
    
    private let locationDataBufferLimit = 25
    @Published var locationDataBuffer: [GPSDataBuffer] = []
    
    @Published var priorLocation = CLLocation()     // Prior region location
    @Published var priorCount = 0                   // (not in use)
    @Published var lastLocation = CLLocation()      // Last GPS location
    @Published var lastCount = 0                    // TODO: Not used - remove?
    @Published var lastSpeed = 0.0                  // Speed at last GPS location
    @Published var lastHeading: CLLocationDirection = 0.0
    
    @Published var userLocation: CLLocation?
    @Published var userHeading: Double?
    
    // Internal flag states defined separately as we evaluate combinations of these in determining what to process and when
    @Published var isStationary = false
    @Published var isMoving = false
    @Published var isWalking = false
    @Published var isDriving = false
    @Published var isTripActive = false
    
    @Published var isAuthorized = false                     // Is locatoin tracking permission authorized in app permissions
    @Published var authorizedDescription = "Loading..."     // Initial description

    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0),
        span: MKCoordinateSpan(latitudeDelta: 0.0, longitudeDelta: 0.0)
    )
    
    @Published
    var updatesLive: Bool = UserDefaults.standard.bool(forKey: "locationUpdatesLive") {
        didSet {
            UserDefaults.standard.set(updatesLive, forKey: "locationUpdatesLive")
            LogManager.event(module: "LocationManager.updatesLive", message: "\(updatesLive ? "Location updates started ..." : "... stopped location updates")")
        }
    }
    
    @Published
    var updatesStopped: Bool = UserDefaults.standard.bool(forKey: "locationUpdatesStopped") {
        didSet {
            UserDefaults.standard.set(updatesStopped, forKey: "locationUpdatesStopped")
            LogManager.event(module: "LocationManager.updatesStopped", message: "\(updatesStopped ? "Location updates have been marked as stopped." : "Location updates not stopped.")")
        }
    }

    @Published
    var backgroundActivity: Bool = UserDefaults.standard.bool(forKey: "BGActivitySessionStarted") {
        didSet {
            backgroundActivity ? self.background = CLBackgroundActivitySession() : self.background?.invalidate()
            UserDefaults.standard.set(backgroundActivity, forKey: "BGActivitySessionStarted")
            LogManager.event(module: "LocationManager.backgroundActivity", message: "Background activity changed to: \(backgroundActivity)")
        }
    }

    //TODO: Build_84
    /// Compass-based heading in degrees (0–360)
    @Published var compassHeading: CLLocationDirection = 0.0
    
    var isTripInitiated = false
    // TODO: not being used - remove?
    // var isNotified = false
    var walkingSpeed = 0.0 // MPS
    var locationUpdateCounter = 0
    
    private let regionRadius: CLLocationDistance = UserSettings.init().regionRadius
    private var monitoredRegion: CLCircularRegion?
    
    enum ActivityState: String {
        case stationary = "Stationary"
        case walking    = "Walking"
        case running    = "Running"
        case driving    = "Driving"
        case unknown    = "Unknown"
    }
    @Published var activityState: ActivityState = .stationary
    
    private var cancellables: Set<AnyCancellable> = []
    
    private override init() {
        self.manager = CLLocationManager()
        
        super.init()
        self.manager.delegate = self
        
        // TODO:  (12-01-2024) playing with best accuracy options here.
        //
        //self.manager.desiredAccuracy = kCLLocationAccuracyBest
        self.manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation // Highest accuracy setting
        self.manager.headingFilter = 1
        
        self.manager.distanceFilter = kCLDistanceFilterNone
        self.manager.allowsBackgroundLocationUpdates = true
        self.manager.pausesLocationUpdatesAutomatically = false
        self.manager.showsBackgroundLocationIndicator = true
        self.manager.startMonitoringSignificantLocationChanges()
        
        LogManager.event(module: "LocationManager.init()", message: "Initialized location handler with background capabilities")

        /// Start location updates immediately to ensure continuous tracking
        /// 
        if self.updatesLive == false {
            LogManager.event(module: "LocationManager.init()", message: "Location updates currently inactive")
            startLocationUpdates()
        } else {
            LogManager.event(module: "LocationManager.init()", message: "Location updates currently active")
        }
    }

    func startLocationUpdates() {
        guard self.manager.authorizationStatus == .authorizedAlways || self.manager.authorizationStatus == .authorizedWhenInUse else {
            LogManager.event(module: "LocationManager.startLocationUpdates()", message: "Location updates cannot start without proper authorization")
            return
        }

        LogManager.event(module: "LocationManager.startLocationUpdates()", message: "Starting location updates ...")
        
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
            LogManager.event(module: "LocationManager.startLocationUpdates()", message: "Starting heading updates ...")

        } else {
            LogManager.event(module: "LocationManager.startLocationUpdates()", message: "Heading updates are not available on this device.")
        }

        self.manager.startUpdatingLocation()  // Start continuous real-time location updates
        self.updatesLive = true
    }
    
    func stopLocationUpdates() {
        LogManager.event(module: "LocationManager.stopLocationUpdates()", message: "... Stopping location updates")
        self.manager.stopUpdatingLocation()
        self.updatesLive = false
    }
    
    // Flags for tracking entry and exit states
    static var hasEnteredTargetArea = false
    static var hasExitedTargetArea = false
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }

        self.userLocation = loc
        
        // Update location data
        self.priorLocation = self.lastLocation
        self.lastLocation = loc
        // TODO: This count is not used - remove
        // self.lastCount += 1
        self.lastSpeed = loc.speed
        self.isStationary = loc.speed <= 0
        self.isMoving = loc.speed > 0
        self.isWalking = loc.speed > 0.9 && loc.speed < 1.8
        self.isDriving = loc.speed > 2.2352

        // Assign activity state based on priority
        if self.isDriving {
            self.activityState = .driving
        } else if self.isWalking {
            self.activityState = .walking
        } else if self.isStationary {
            self.activityState = .stationary
        }

        DispatchQueue.main.async {
            self.region = MKCoordinateRegion(
                center: self.lastLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }

        // Background processing: Save location if the user has moved significantly
        if UIApplication.shared.applicationState == .background {
            if priorLocation.coordinate.latitude != 0.0 && loc.distance(from: priorLocation) > regionRadius {
                LogManager.event(module: "LocationManager.locationManager()", message: "User moved more than \(regionRadius) meters, saving new location.")
                saveLocation(location: loc)
                startRegionMonitoring(location: loc)
            }
        }

        // OLD: Trip status handling
        if loc.speed < UserSettings.init().trackingSpeedThreshold {
            updateLocationDataBuffer(location: loc)
            self.isTripInitiated = false
            self.isTripActive = false
        } else {
            if !isTripActive { self.isTripInitiated = true }
        }

        self.isTripActive = loc.speed >= UserSettings.init().trackingSpeedThreshold
        

        // Handle trip initiation
        if isTripInitiated && isTripActive {
            LogManager.event(module: "LocationManager.startLocationUpdates()", message: "Transferring data from buffer")
            saveLocationDataBuffer()
            self.isTripInitiated = false
        }

        // Update location update counter only when trip is active
        if isTripActive {
            locationUpdateCounter += 1

            // Save location if the counter exceeds the threshold
            if locationUpdateCounter >= UserSettings.init().gpsSampleRate {
                saveLocation(location: loc)
                locationUpdateCounter = 0
            }
        }
        /*
        if loc.speed > 0 {
            print(">>> Speed: \(loc.speed), \(activityState), \(loc.coordinate.latitude), \(loc.coordinate.longitude)")
        }
        */
        
    }
    
    
//    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
//        lastHeading = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
//        userHeading = newHeading.trueHeading
//    }
    //TODO: Build_84
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let heading = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
        lastHeading = heading
        userHeading = heading
        compassHeading = heading
    }
    
    
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        // Return true if you want to show the heading calibration dialog
        return true
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let nsError = error as NSError
        if nsError.domain == kCLErrorDomain && nsError.code == 0 {
            return
        }
        LogManager.event(module: "LocationManager.locationManager()", message: "Failed to update location: \(error.localizedDescription)")
    }

    // MARK: - Location capture
    
    func updateLocationDataBuffer(location: CLLocation?) {
        guard let location = location, location.speed >= 0 else { return }

        if locationDataBuffer.count >= locationDataBufferLimit {
            locationDataBuffer.removeLast()
        }

        var state = ""
        if UIApplication.shared.applicationState == .background {
            state = ".background"
        } else {
            state = ".foreground"
        }
        
        let entry = GPSDataBuffer(
            timestamp: Date(),
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            speed: location.speed,
            processed: false,
            code: "",
            note: "buffer: \(isMoving ? "Moving" : "") \(activityState.rawValue.description) \(state)"
        )
        locationDataBuffer.insert(entry, at: 0)
        //LogManager.event(module: "updateLocationDataBuffer", message: "Location \(location)" )
    }
    
    func saveLocationDataBuffer() {
        var index = 0
        while index < locationDataBuffer.count {
            
            /// Find the first entry in the buffer that  indicates no speed and thus no real motion
            if locationDataBuffer[index].speed <= 0.0 {
                //let context = ModelContext(ModelContainerProvider.shared)
                let context = ModelContainerProvider.sharedContext
                
                LogManager.event(module: "LocationManager.saveLocationDataBuffer()", message: "\(locationDataBuffer[index].timestamp), \(locationDataBuffer[index].speed), \(locationDataBuffer[index].latitude) : \(locationDataBuffer[index].longitude)")
                
                let entry = GPSData(
                    timestamp: locationDataBuffer[index].timestamp,
                    latitude: locationDataBuffer[index].latitude,
                    longitude: locationDataBuffer[index].longitude,
                    speed: locationDataBuffer[index].speed,
                    processed: false,
                    code: locationDataBuffer[index].code,
                    //codes: locationDataBuffer[index].code,
                    note: locationDataBuffer[index].note
                )
                
                context.insert(entry)
                do {
                    try context.save()
                } catch {
                    LogManager.event(module: "LocationManager.saveLocationDataBuffer", message: "Failed to save location data: \(error.localizedDescription)")
                }
                
                for saveIndex in 0..<index {
                    LogManager.event(module: "LocationManager.saveLocationDataBuffer()", message: "\(locationDataBuffer[saveIndex].timestamp), \(locationDataBuffer[saveIndex].speed), \(locationDataBuffer[saveIndex].latitude) : \(locationDataBuffer[saveIndex].longitude)")
                    
                    let entry = GPSData(
                        timestamp: locationDataBuffer[saveIndex].timestamp,
                        latitude: locationDataBuffer[saveIndex].latitude,
                        longitude: locationDataBuffer[saveIndex].longitude,
                        speed: locationDataBuffer[saveIndex].speed,
                        processed: false,
                        code: locationDataBuffer[saveIndex].code,
                        //codes: locationDataBuffer[saveIndex].code,
                        note: locationDataBuffer[saveIndex].note
                    )
                    
                    context.insert(entry)
                    do {
                        try context.save()
                    } catch {
                        LogManager.event(module: "LocationManager.saveLocationDataBuffer", message: "Failed to save location data: \(error.localizedDescription)")
                    }
                }
                
                locationDataBuffer.removeAll()
                break
            }
            index += 1
        }
    }
    
    func saveLocation(location: CLLocation) {
        //let context = ModelContext(ModelContainerProvider.shared)
        let context = ModelContainerProvider.sharedContext
        
        var state = ""
        if UIApplication.shared.applicationState == .background {
            state = ".background"
        } else {
            state = ".foreground"
        }

        let entry = GPSData(
            timestamp: Date(),
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            speed: location.speed,
            processed: false,
            code: "",
            //codes: "",
            note: "live: \(isMoving ? "Moving" : "") \(activityState.rawValue.description) \(state)"
        )
        
        context.insert(entry)
        do {
            try context.save()
            LogManager.event(module: "LocationManager.saveLocation()", message: "saved: \(entry.timestamp) \(formatMPH(convertMPStoMPH(entry.speed))) mph  \(entry.latitude),\(entry.longitude)")
        } catch {
            LogManager.event(module: "LocationManager.saveLocation()", message: "Failed to save location data: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Region monitoring
    
    /// Monitor a nn-meter circular region around the last known location
    func startRegionMonitoring(location: CLLocation) {
        stopRegionMonitoring()  // Stop any existing region monitoring

        let newRegion = CLCircularRegion(center: location.coordinate, radius: regionRadius, identifier: "monitoredRegion")
        newRegion.notifyOnExit = true
        self.monitoredRegion = newRegion
        self.manager.startMonitoring(for: newRegion)
        
        LogManager.event(module: "LocationManager.startRegionMonitoring()", message: "Started region monitoring \(regionRadius) radius around \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }

    /// Stop monitoring the current region
    func stopRegionMonitoring() {
        if let region = monitoredRegion {
            manager.stopMonitoring(for: region)
            //LogManager.event(module: "LocationManager.stopRegionMonitoring", message: "Stopped region monitoring")
            monitoredRegion = nil
        }
    }
    
    // MARK: - Permissions
    func requestWhenInUseAuthorization() {
        LogManager.event(module: "LocationManager.requestWhenInUseAuthorization()", message: "Requesting when in use authorization...")
        self.manager.requestWhenInUseAuthorization()
    }

    func requestAuthorizedAlways() {
        LogManager.event(module: "LocationManager.requestAlwaysAuthorization()", message: "Requesting always authorization...")
        self.manager.requestAlwaysAuthorization()
    }
    
    func getAuthorizedWhenInUse(completion: @escaping (Bool) -> Void) {
        let authorizationStatus: CLAuthorizationStatus
        authorizationStatus = self.manager.authorizationStatus
        
        switch authorizationStatus {
        case .authorizedWhenInUse:
            self.isAuthorized = true
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
            self.isAuthorized = true
            completion(true)
        default:
            completion(false)
        }
    }
    
    func getAuthorizedDescription(completion: @escaping (String) -> Void) {
        let authorizationStatus: CLAuthorizationStatus
        authorizationStatus = self.manager.authorizationStatus
        
        switch authorizationStatus {
        case .notDetermined:
            self.isAuthorized = false
            self.authorizedDescription = "Not Determined"
            completion("Not Determined")
        case .restricted:
            self.isAuthorized = true
            self.authorizedDescription = "Restricted"
            completion("Restricted")
        case .denied:
            self.isAuthorized = false
            self.authorizedDescription = "Denied"
            completion("Denied")
        case .authorizedAlways:
            self.isAuthorized = true
            self.authorizedDescription = "Authorized Always"
            completion("Authorized Always")
        case .authorizedWhenInUse:
            self.isAuthorized = true
            self.authorizedDescription = "Authorized When In Use"
            completion("Authorized When In Use")
        @unknown default:
            self.isAuthorized = false
            self.authorizedDescription = "Unknown Status"
            completion("Unknown Status")
        }
    }
    
    // MARK: - Date functions
    
    // Format the date for display
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd h:mm:ss a"
        return formatter.string(from: date)
    }
}
