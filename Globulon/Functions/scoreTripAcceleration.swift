//
//  scoreTripAcceleration.swift
//  ViDrive
//
//  Created by David Holeman on 2/19/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftData
import CoreLocation

//func scoreTripAcceleration(_ entries: [TripJournalSD]) -> Double {
func scoreTripAcceleration(_ entries: [GpsJournalSD]) -> Double {

    let minEntries = 5
    
    guard entries.count > minEntries else {
            return 100 // Not enough data to calculate score
    }
        
    /// Notes on metrics:
    /// 0 -> 60/mph in 6 seconds is the equivalent acceleration rate of 4.4704/mps (meters per second).  
    /// The number is lower the slower the car.  Going 0 -> 60 in 9 seconds is at a rate of 2.98/mps
    /// 60 mph is equivalent to approximately 96.56 kph
    /// 60 mph is equivalent to 26.8224 meteres per second
    ///
    let accelerationLimit =  4.4704
    
    var score: Double = 100
    //var lastSpeed = entries.first!.speed

    /// Loop through current and next item. The next item is the next one in the array.
    /// To look further ahead adjust the offset so you don't blow past the end of the array.
    ///
    for i in 0..<(entries.count - 1) {
        // Define the current and next GPS locations
        //let latitude1 = entries[i].latitude
        //let longitude1 = entries[i].longitude
        //let latitude2 = entries[i + 1].latitude
        //let longitude2 = entries[i + 1].longitude
        
        // Translate into location
        //let location1 = CLLocation(latitude: latitude1, longitude: longitude1)
        //let location2 = CLLocation(latitude: latitude2, longitude: longitude2)
        
        // Calculate the distance in meters
        //let distanceDelta = location1.distance(from: location2)
        
        // Define the current and next speed samples
        let speed1 = entries[i].speed
        let speed2 = entries[i + 1].speed
        
        // If postive it's accleration if negative it's deceleration
        //let speedDiffInMPS = speed2 - speed1
        
        let time1 = entries[i].timestamp
        let time2 = entries[i+1].timestamp
        
        // Time difference
        let timeDelta = time2.timeIntervalSince(time1)
        
        let projectedSpeed = speed1 + accelerationLimit * timeDelta

        //print("\(i) \(formatDateStampM(time1)) \(Int(speed1)) \(Int(speed2)) Dist: \(Int(distanceDelta)) Dur: \(Int(timeDelta)) speed1: \(Int(convertMPStoMPH(speed1))) speed2: \(Int(convertMPStoMPH(speed2))) delta: \(Int(convertMPStoMPH(speedDiffInMPS))) \(Int(convertMPStoMPH(projectedSpeed)))")

        if speed2 > projectedSpeed {
            // Lower the score
            score -= 5
        }
    }
    
    //print("Acceleration score: \(score)")
    return max(score, 0)
}
