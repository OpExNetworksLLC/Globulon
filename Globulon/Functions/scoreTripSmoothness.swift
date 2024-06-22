//
//  scoreTripSmoothness.swift
//  ViDrive
//
//  Created by David Holeman on 2/19/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation

//func scoreTripSmoothness(_ entries: [TripJournalSD]) -> Double {
func scoreTripSmoothness(_ entries: [GpsJournalSD]) -> Double {
    let minEntries = 5
    
    guard entries.count > minEntries else {
            return 100 // Not enough data to calculate score
    }

    let mpsDelta = 10.0 // Meters per second
    
    var score: Double = 100
    var lastSpeed = entries.first!.speed

    for data in entries {
        let speedDifference = abs(data.speed - lastSpeed)
        
        if speedDifference > mpsDelta {
            score -= 5
        }
        lastSpeed = data.speed
    }

    return max(score, 0)
}
