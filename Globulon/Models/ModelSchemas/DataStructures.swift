//
//  DataStructures.swift
//  ViDrive
//
//  Created by David Holeman on 3/22/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation

/// This is a data structue used to load trip GPS location entries into for export to a JSON file.
///
struct TripItemJSON: Codable {
    var timestamp: Date
    var latitude: Double
    var longitude: Double
    var speed: Double
    var processed: Bool
    var code: String
    var note: String

}

struct GPSJournalJSON: Codable {
    var timestamp: Date
    var latitude: Double
    var longitude: Double
    var speed: Double
    var processed: Bool
    var code: String
    var note: String

}

struct LocationDataBuffer: Codable, Hashable {
    var timestamp: Date
    var latitude: Double
    var longitude: Double
    var speed: Double
    var processed: Bool
    var code: String
    var note: String
}

struct ActivityDataBuffer: Codable, Hashable {
    var timestamp: Date
    var latitude: Double
    var longitude: Double
    var speed: Double
    var processed: Bool
    var code: String
    var note: String
}

//struct HistoryTripGPStoJSON: Codable {
//    var timestamp: Date
//    var latitude: Double
//    var longitude: Double
//    var speed: Double
//    var processed: Bool
//    var archived: Bool
//    var code: String
//    var note: String
//
//}
