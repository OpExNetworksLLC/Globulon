//
//  LocationManagerClassVx.swift
//  ViDrive
//
//  Created by David Holeman on 4/13/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//


//  TODO: Add the following to pinfo.list
//  All three are required
//  Privacy - Location When in Use Description = "This app requires access to device location"
//  Privacy - Location Always and When in Use Description = "This app requires access to device location"
//  Privacy - Location Always Usage Description = "This app always requires access to device location"


import Foundation
import CoreLocation
import SwiftData
import MapKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var region = MKCoordinateRegion()
    @Published var location: CLLocation?
    @Published var isDriverMode: Bool = false
    @Published var isLocationEnabled: Bool = false
    
    static let shared = LocationManager()
    
    private var locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    private var lastLocation: CLLocation?
    
    private var locationDataBuffer: [LocationDataBuffer] = []
    private let locationDataBufferLimit = 12  // This should never be larger than the trip separator
    
    var homeRadius: CLLocationDistance = 25  // Radius in meters
    
    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone  // updates as frequently as possible
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
        //startUpdatingtLocation()
        LogEvent.print(module: "LocationManager.init()", message: "init finished")
    }
    
    
    
    func requestAppropriateLocationPermission() {
        let currentStatus = locationManager.authorizationStatus
        
        /// if not determined then ask for when in use.  If when in use is set then ask for always in use
        ///
        if currentStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if currentStatus == .authorizedWhenInUse {
            requestAuthorizedAlways()
        }
        LogEvent.print(module: "LocationManager.requestAppropriateLocationPermissino", message: "requested")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        
        //let authorizationStatus = locationManager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .notDetermined:
            LogEvent.print(module: "LocationManager.locationManagerDidChangeAuthorization", message: "Location permission: .notDetermined")
            //manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            print("Location permission: .restricted or .denied")
        case .authorizedWhenInUse:
            LogEvent.print(module: "LocationManager.locationManagerDidChangeAuthorization", message: "Location permission: .authorizedWhenInUse")
            //locationManager.requestAlwaysAuthorization()
            startUpdatingtLocation()
        case .authorizedAlways:
            LogEvent.print(module: "LocationManager.locationManagerDidChangeAuthorization", message: "Location permission: .athorizedAlways")
            
            //TODO:  enable this here if it doesn't update in background.
            locationManager.startMonitoringSignificantLocationChanges()
            startUpdatingtLocation()

        default:
            print("Location permission: Unknown")
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
    
    func startUpdatingtLocation() {
        let authorizationStatus = locationManager.authorizationStatus
        if authorizationStatus == .authorizedAlways {
            
            /// Starting this service is needed to keep recording in the background running.  
            /// It detects significant changes and keeps up the recording.
            ///
            locationManager.startMonitoringSignificantLocationChanges()
            locationManager.startUpdatingLocation()
            
        } else if authorizationStatus == .authorizedWhenInUse {
            
            /// Starting this service is needed to keep recording in the background running.  
            /// It detects significant changes and keeps up the recording.
            ///
            locationManager.startMonitoringSignificantLocationChanges()
            locationManager.startUpdatingLocation()
        }
        LogEvent.print(module: "LocationManager.startUpdatingLocation", message: "Location tracking started...")
    }
    
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        LogEvent.print(module: "LocationManager.stopUpdatingLocation", message: "Location tracking stopped...")
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
    
    func getAuthorizedWhenInUse() -> Bool {
        if locationManager.authorizationStatus == .authorizedWhenInUse {
            return true
        } else {
            return false
        }
    }
    func getAuthorizedAlways() -> Bool {
        if locationManager.authorizationStatus == .authorizedAlways {
            return true
        } else {
            return false
        }
    }
    
    func getAuthorized() -> Bool {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse:
            return true
        case .authorizedAlways:
            return true
        default:
            return false
        }
    }
    func getLocationAuthorization() {
        /// Set to @Published value
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse:
            isLocationEnabled = true
        case .authorizedAlways:
            isLocationEnabled = true
        default:
            isLocationEnabled = false
        }
    }
    
    func getAddressFromLatLon(latitude: CLLocationDegrees, longitude: CLLocationDegrees) async -> String {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else {
                return "No address found"
            }
            
            var addressString = ""
            if let street = placemark.thoroughfare {
                addressString += street + ", "
            }
            if let city = placemark.locality {
                addressString += city + ", "
            }
            if let state = placemark.administrativeArea {
                addressString += state + ", "
            }
            if let postalCode = placemark.postalCode {
                addressString += postalCode + ", "
            }
            if let country = placemark.country {
                addressString += country
            }
            
            return addressString
        } catch {
            print("Reverse geocoding failed: \(error)")
            return "Reverse geocoding failed"
        }
    }
    
    func getFullAddressFromLatLon(latitude: CLLocationDegrees, longitude: CLLocationDegrees) async -> String {
        let locationX = CLLocation(latitude: latitude, longitude: longitude)
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(locationX)
            guard let placemark = placemarks.first else {
                return "No address found"
            }
            
            var addressString = ""
            if let streetNumber = placemark.subThoroughfare {
                addressString += streetNumber + " "
            }
            if let street = placemark.thoroughfare {
                addressString += street + ", "
            }
            if let city = placemark.locality {
                addressString += city + ", "
            }
            if let state = placemark.administrativeArea {
                addressString += state + ", "
            }
            if let postalCode = placemark.postalCode {
                addressString += postalCode + ", "
            }
            if let country = placemark.country {
                addressString += country
            }
            
            return addressString
        } catch {
            print("Reverse geocoding failed: \(error)")
            return "Reverse geocoding failed"
        }
    }
    
    private func updateRegion(_ location: CLLocation) {
        region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
    
    func updateLocationDataBuffer(location: CLLocation?) {
        
        /// Guard to make sure location is not nil and speed is valid
        ///
        guard let location = location, location.speed >= 0 else {
            /// Skip the update if location is nil or speed is invalid
            ///
            return
        }
        
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
            note: "buffer"
        )
        locationDataBuffer.insert(entry, at: 0)
    }
    
//    func saveLocationDataBuffer() {
//        guard let container = AppEnvironment.sharedModelContainer else {
//            LogEvent.print(module: "LocationManager.saveLocation()", message: "shared model container has not been initialized")
//            return
//        }
//        let context = ModelContext(container)
//
//        // Determine the start index to begin saving locations
//        var startIndex = 0
//        for index in stride(from: locationDataBuffer.count - 1, through: 0, by: -1) {
//            if locationDataBuffer[index].speed <= 0.0 {
//                startIndex = index
//                break
//            }
//        }
//
//        // Save entries from determined start index to end of buffer
//        for index in startIndex..<locationDataBuffer.count {
//            let location = locationDataBuffer[index]
//            print("**> \(index) of \(locationDataBuffer.count) \(location.timestamp), \(location.speed), \(location.latitude) : \(location.longitude)")
//            
//            let entry = GpsJournalSD(
//                timestamp: location.timestamp,
//                longitude: location.longitude,
//                latitude: location.latitude,
//                speed: location.speed,
//                processed: false,
//                code: location.code,
//                note: location.note
//            )
//            context.insert(entry)
//        }
//
//        // Clear the buffer after saving
//        locationDataBuffer.removeAll()
//    }

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
                    print("**> \(locationDataBuffer[saveIndex].timestamp), \(locationDataBuffer[saveIndex].speed), \(locationDataBuffer[saveIndex].latitude) : \(locationDataBuffer[saveIndex].longitude)")
                    
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
    
    var isTripInitiatd = false
    var isTripActive = false
    var walkingSpeed = 0.0 // MPS
    
    var locationUpdateCounter = 0
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        /*
        if let location = locations.last {
            // Optionally, reset geofence when location updates
            setupGeofenceForCurrentLocation()
        }
        */
        
        /// Buffer location information
        ///
        if locations.last?.speed ?? 0.0 < UserSettings.init().trackingSpeedThreshold {
            updateLocationDataBuffer(location: locations.last)
            self.isTripInitiatd = false
            self.isTripActive = false
            if (locations.last?.speed ?? 0.0) > walkingSpeed {
                print("** moving faster than walking: \(locations.last?.speed ?? 0.0) \(UserSettings.init().trackingSpeedThreshold)")
            }
        } else {
            if isTripActive == false { self.isTripInitiatd = true }
        }
        
        /// Manage trip status based on speed
        ///
        let speed = locations.last?.speed ?? 0.0
        if speed >= UserSettings.init().trackingSpeedThreshold {
            self.isTripActive = true
        } else {
            self.isTripActive = false
        }
        
        /// Transfer buffer if trip initiated and active
        ///
        if isTripInitiatd && isTripActive {
            print("** xfr buffer")
            saveLocationDataBuffer()
            self.isTripInitiatd = false
        }

        /// We are driving at this point so do stuff
        if let currentLocation = locations.last {
            locationUpdateCounter += 1
            if locationUpdateCounter >= UserSettings.init().trackingSampleRate {
                updateRegion(currentLocation)
                
                // Save location only if the trip is active
                if isTripActive {
                    saveLocation(location: currentLocation)
                }
                
                locationUpdateCounter = 0
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Handle failure to get location
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
                note: ""
            )
            
            context.insert(entry)
            
            print("**+ Location saved: \(entry.timestamp) \(formatMPH(convertMPStoMPH( entry.speed))) mph")
        }
    }
    
    
    func setupGeofenceForCurrentLocation() {
        if let currentLocation = locationManager.location {
            let geofenceRegion = CLCircularRegion(center: currentLocation.coordinate, radius: homeRadius, identifier: "home")
            geofenceRegion.notifyOnEntry = false
            geofenceRegion.notifyOnExit = true

            locationManager.startMonitoring(for: geofenceRegion)
            
            //print("** Geofence set at current location: \(currentLocation.coordinate)")
        } else {
            print("** Current location is not available.")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region.identifier == "home" {
            print("** Exited current location area")
            
            // Trigger necessary actions
            
            // try starting it
            //TODO:  enable this here if it doesn't update in background.
            locationManager.startMonitoringSignificantLocationChanges()
            startUpdatingtLocation()
        }
    }
    
}

/// Too slow, not driving so bail on the rest
///
//guard let speed = locations.last?.speed, speed >= UserSettings.init().trackingSpeedThreshold else {
//    return
//}
