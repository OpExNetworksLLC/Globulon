//
//  AppDefaults.swift
//  Globulon
//
//  Created by David Holeman on 02/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import SwiftUI

/// Thse are app defaults used during the initialization of various values and settings that may be later changed by the user.
/// Instead of scattered about in code we set them here.
///

struct AppDefaults {
    static let alias = "<alias>"
    static let avatar = UIImage(imageLiteralResourceName: "imgAvatarDefault")
    
    struct gps {
        static let sampleRate = 5               // every n seconds approximately
        static let tripSeparator = 210          // how many Seconds between last gps reading and next befoer consider a new trip
        static let speedThreshold = 2.2352      // Meters per second 2.24mps = 5mph
        static let tripEntriesMin = 12          // Minimum samples to qualify as a trip
        static let tripGPSHistoryLimit = 100    // Max number of trips in GPSJournalSD
        static let tripHistoryLimit = 20        // Max number of trips in TripSummariesSD
    }
    
    struct region {
        static let radius = 15.0
    }
    
    /// Tour default vlaues
    struct tour {
        static let poiRadius = 5.0
    }
}
