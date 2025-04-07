//
//  DataStructures.swift
//  ViDrive
//
//  Created by David Holeman on 3/22/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation

// MARK: - Data structures

struct GPSDataBuffer: Codable, Hashable {
    var timestamp: Date
    var latitude: Double
    var longitude: Double
    var speed: Double
    var processed: Bool
    var code: String
    var note: String
}
