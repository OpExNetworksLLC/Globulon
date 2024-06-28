//
//  LocationManagerClass.swift
//  Globulon
//
//  Created by David Holeman on 6/26/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

//  TODO: Add the following to pinfo.list
//  All three are required
//  Privacy - Location When in Use Description = "This app requires access to device location"
//  Privacy - Location Always and When in Use Description = "This app requires access to device location"
//  Privacy - Location Always Usage Description = "This app always requires access to device location"


import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    static let shared = LocationManager()
    
    private var locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
        
        /// We could do this here but then it starts immediately vs. handling later through onboarding after asking for permissions
        ///
        /// ```
        /// startUpdatingtLocation()
        /// ```
        
        LogEvent.print(module: "LocationManager.init()", message: "init finished")
    }

    @MainActor func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        
        switch manager.authorizationStatus {
        case .notDetermined:
            LogEvent.print(module: "LocationManager.locationManagerDidChangeAuthorization", message: "Location permission: .notDetermined")
        case .restricted, .denied:
            print("Location permission: .restricted or .denied")
        case .authorizedWhenInUse:
            LogEvent.print(module: "LocationManager.locationManagerDidChangeAuthorization", message: "Location permission: .authorizedWhenInUse")
            LocationsHandler.shared.startLocationUpdates()
        case .authorizedAlways:
            LogEvent.print(module: "LocationManager.locationManagerDidChangeAuthorization", message: "Location permission: .athorizedAlways")
            LocationsHandler.shared.startLocationUpdates()
            LocationsHandler.shared.backgroundActivity = true
        default:
            print("** Location permission: Unknown")
        }
    }
    
    func requestWhenInUseAuthorization() {
        // Show UI to explain the need for always authorization before requesting it
        LogEvent.print(module: "LocationManager.requestWhenInUseAuthorization", message: "Request when in use authorization...")
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestAuthorizedAlways() {
        // Show UI to explain the need for always authorization before requesting it
        LogEvent.print(module: "LocationManager.requestAlwaysAuthorization", message: "Request always authorization...")
        locationManager.requestAlwaysAuthorization()
    }
    
    func getAuthorizedWhenInUseV2(completion: @escaping (Bool) -> Void) {
        let authorizationStatus: CLAuthorizationStatus
        authorizationStatus = locationManager.authorizationStatus
        
        switch authorizationStatus {
        case .authorizedWhenInUse:
            completion(true)
        default:
            completion(false)
        }
    }
    
    func getAuthorizedAlwaysV2(completion: @escaping (Bool) -> Void) {
        let authorizationStatus: CLAuthorizationStatus
        authorizationStatus = locationManager.authorizationStatus
        
        switch authorizationStatus {
        case .authorizedAlways:
            completion(true)
        default:
            completion(false)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Handle failure to get location
    }
    
}
