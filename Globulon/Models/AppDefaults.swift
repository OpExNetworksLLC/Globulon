//
//  AppDefaults.swift
//  ViDrive
//
//  Created by David Holeman on 2/16/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import SwiftUI

/// Thse are app defaults used during the initialization of various values and settings that may be later changed by the user.
/// Instead of scattered about in code we set them here.
///
class AppDefaults {
    static var alias = "<alias>"
    static var avatar = UIImage(imageLiteralResourceName: "imgAvatarDefault")
    
    struct gps {
        static var sampleRate = 5               // every n seconds approximately
        static var tripSeparator = 210          // how many Seconds between last gps reading and next befoer consider a new trip
        static var speedThreshold = 2.2352      // Meters per second 2.24mps = 5mph
        static var tripEntriesMin = 12          // Minimum samples to qualify as a trip
        static var tripGPSHistoryLimit = 100    // Max number of trips in GPSJournalSD
        static var tripHistoryLimit = 20        // Max number of trips in TripSummariesSD
    }
}
