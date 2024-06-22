//
//  scoreTripDeceleration.swift
//  ViDrive
//
//  Created by David Holeman on 2/19/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftData
import CoreLocation

//func scoreTripDeceleration(_ entries: [TripJournalSD]) -> Double {
func scoreTripDeceleration(_ entries: [GpsJournalSD]) -> Double {
    let minEntries = 5
    
    guard entries.count > minEntries else {
            return 100 // Not enough data to calculate score
    }
        
    /// Notes on metrics:
    /// 0 -> 60/mph in 3 seconds is the equivalent decelration rate of -8.94/mps (meters per second).
    /// Reminder: It's negative because we are decelrating.
    /// 60 mph is equivalent to approximately 96.56 kph
    /// 60 mph is equivalent to 26.8224 meteres per second
    ///
    let decelerationLimit = -8.94
    
    var score: Double = 100
    //var lastSpeed = entries.first!.speed
    
    /// Loop through current and next item. The next item is the next one in the array.
    /// To look further ahead adjust the offset so you don't blow past the end of the array.
    ///
    for i in 0..<(entries.count - 1) {
//        let latitude1 = entries[i].latitude
//        let longitude1 = entries[i].longitude
//        let latitude2 = entries[i + 1].latitude
//        let longitude2 = entries[i + 1].longitude
        
        //let location1 = CLLocation(latitude: latitude1, longitude: longitude1)
        //let location2 = CLLocation(latitude: latitude2, longitude: longitude2)
        
        //let distanceDelta = location1.distance(from: location2)
        
        let speed1 = entries[i].speed
        let speed2 = entries[i + 1].speed
        
        // Speed difference in meters per second (m/s), negative for deceleration
        //let speedDiffInMPS = speed2 - speed1
        
        let time1 = entries[i].timestamp
        let time2 = entries[i + 1].timestamp
        
        let timeDelta = time2.timeIntervalSince(time1)
        
        // Calculate the speed at the end of the interval if only decelerating at `decelerationLimit`
        let projectedSpeed = speed1 + decelerationLimit * timeDelta
        
        //print("\(i) \(formatDateStampM(time1)) \(Int(speed1)) \(Int(speed2)) Dist: \(Int(distanceDelta)) Dur: \(Int(timeDelta)) speed1: \(Int(convertMPStoMPH(speed1))) speed2: \(Int(convertMPStoMPH(speed2))) delta: \(Int(convertMPStoMPH(speedDiffInMPS))) \(Int(convertMPStoMPH(projectedSpeed)))")
        
        // If speed2 is less than projectedSpeed (indicating deceleration beyond the limit), lower the score
        if speed2 < projectedSpeed {
            score -= 5
        }
    }
    
    //print("Deceleration score: \(score)")
    return max(score, 0)
}
