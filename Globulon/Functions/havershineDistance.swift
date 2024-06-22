//
//  havershineDistance.swift
//  ViDrive
//
//  Created by David Holeman on 4/28/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import CoreLocation

func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
    let earthRadiusMiles = 3958.8 // Earth radius in miles

    let dLat = degreesToRadians(degrees: lat2 - lat1)
    let dLon = degreesToRadians(degrees: lon2 - lon1)
    
    let lat1 = degreesToRadians(degrees: lat1)
    let lat2 = degreesToRadians(degrees: lat2)

    let a = sin(dLat / 2) * sin(dLat / 2) + sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2)
    let c = 2 * atan2(sqrt(a), sqrt(1 - a))

    let distance = earthRadiusMiles * c
    return distance
    
    func degreesToRadians(degrees: Double) -> Double {
        return degrees * .pi / 180
    }
}
