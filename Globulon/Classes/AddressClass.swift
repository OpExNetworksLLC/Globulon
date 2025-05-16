//
//  AddressClass.swift
//  ViDrive
//
//  Created by David Holeman on 3/13/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftData
import CoreLocation

class Address {
    class func getShortAddressFromLatLon(latitude: CLLocationDegrees, longitude: CLLocationDegrees) async -> String {
        let geocoder = CLGeocoder()
        
        let location = CLLocation(latitude: latitude, longitude: longitude)
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else {
                return "n/a"
            }
            
            var addressString = ""
            if let streetNumber = placemark.subThoroughfare {
                addressString += streetNumber + " "
            }
            if let street = placemark.thoroughfare {
                addressString += street + ", "
            }
            if let city = placemark.locality {
                addressString += city
            }
            return addressString
        } catch {
            LogManager.event(module: "Address.getShortAddressFromLatLong", message: "Reverse geocoding failed: \(error)")
            return "n/a"
        }
    }

    class func getFullAddressFromLatLon(latitude: CLLocationDegrees, longitude: CLLocationDegrees) async -> String {
        let geocoder = CLGeocoder()
        
        let location = CLLocation(latitude: latitude, longitude: longitude)
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else {
                return "n/a"
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
            LogManager.event(module: "Address.getFullAddressFromLatLong", message: "Reverse geocoding failed: \(error)")
            return "n/a"
        }
    }
}
