//
//  ModelSchemaV1.swift
//  ViDrive
//
//  Created by David Holeman on 2/13/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import SwiftData
import CoreLocation

enum ModelSchemaV1: VersionedSchema {
    
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    /// The list of models included in the Schema
    ///
    static var models: [any PersistentModel.Type] {
        [
            GpsJournalSD.self,
            TripSummariesSD.self,
            TripJournalSD.self,
            TripHistorySummarySD.self,
            TripHistoryTripsSD.self,
            TripHistoryTripJournalSD.self,
            ArticlesSD.self,
            SectionsSD.self
        ]
    }
    
    /// GPS Journal
    /// This is the raw GPS location data collected by the Location Manager
    ///
    @Model
    class GpsJournalSD {

        @Attribute(.unique) var timestamp: Date
        var longitude: Double
        var latitude: Double
        var speed: Double
        var processed: Bool
        var code: String
        var note: String

        init(timestamp: Date, longitude: Double, latitude: Double, speed: Double, processed: Bool, code: String, note: String) {
            self.timestamp = timestamp
            self.longitude = longitude
            self.latitude = latitude
            self.speed = speed
            self.processed = processed
            self.code = code
            self.note = note
        }
    }
    
    /// Trip Summaries
    /// This is where the the trip is summarized and the GPS location data for that trip are stored
    ///
    @Model
    class TripSummariesSD {
        
        @Attribute(.unique) var originationTimestamp: Date
        var originationLatitude: Double
        var originationLongitude: Double
        var originationAddress: String
        
        var destinationTimestamp: Date
        var destinationLatitude: Double
        var destinationLongitude: Double
        var destinationAddress: String
        
        var tripMap: Data?
        
        var maxSpeed: Double
        var duration: Double
        var distance: Double
        
        var scoreAcceleration: Double
        var scoreDeceleration: Double
        var scoreSmoothness: Double
        
        var archived: Bool
        
        var toTripJournal: [TripJournalSD]?
        
        init(originationTimestamp: Date, originationLatitude: Double, originationLongitude: Double, originationAddress: String, destinationTimestamp: Date, destinationLatitude: Double, destinationLongitude: Double, destinationAddress: String, tripMap: Data? = nil, maxSpeed: Double, duration: Double, distance: Double, scoreAcceleration: Double, scoreDeceleration: Double, scoreSmoothness: Double, archived: Bool) {
            self.originationTimestamp = originationTimestamp
            self.originationLatitude = originationLatitude
            self.originationLongitude = originationLongitude
            self.originationAddress = originationAddress
            self.destinationTimestamp = destinationTimestamp
            self.destinationLatitude = destinationLatitude
            self.destinationLongitude = destinationLongitude
            self.destinationAddress = destinationAddress
            self.tripMap = tripMap
            self.maxSpeed = maxSpeed
            self.duration = duration
            self.distance = distance
            self.scoreAcceleration = scoreAcceleration
            self.scoreDeceleration = scoreDeceleration
            self.scoreSmoothness = scoreSmoothness
            self.archived = archived
        }
        var sortedCoordinates: [CLLocationCoordinate2D] {
            guard let journals = toTripJournal else { return [] }
            let sortedJournals = journals.sorted(by: { $0.timestamp < $1.timestamp })
            return sortedJournals.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        }
    }
    /// Trip Journal
    /// - This is the detailed GPS location data for the trip
    ///
    @Model
    class TripJournalSD {
        @Attribute(.unique) var timestamp: Date
        var longitude: Double
        var latitude: Double
        var speed: Double
        var code: String
        var note: String

        @Relationship(inverse: \TripSummariesSD.toTripJournal) var toTripSummaries: TripSummariesSD?
        
        init(timestamp: Date, longitude: Double, latitude: Double, speed: Double, code: String, note: String) {
            self.timestamp = timestamp
            self.longitude = longitude
            self.latitude = latitude
            self.speed = speed
            self.code = code
            self.note = note
        }
    }
    
    @Model
    class TripHistorySummarySD {
        
        @Attribute(.unique) var datestamp: String
        var highestSpeed: Double
        var totalDistance: Double
        var totalDuration: Double
        var totalTrips: Int
        var totalSmoothness: Double
        var totalAcceleration: Double
        var totalDeceleration: Double
        var totalDistractions: Double
        
        var toTripHistoryTrips: [TripHistoryTripsSD]?

        init(datestamp: String, highestSpeed: Double, totalDistance: Double, totalDuration: Double, totalTrips: Int, totalSmoothness: Double, totalAccleration: Double, totalDeceleration: Double, totalDistractions: Double) {
            self.datestamp = datestamp
            self.highestSpeed = highestSpeed
            self.totalDistance = totalDistance
            self.totalDuration = totalDuration
            self.totalTrips = totalTrips
            self.totalSmoothness = totalSmoothness
            self.totalAcceleration = totalAccleration
            self.totalDeceleration = totalDeceleration
            self.totalDistractions = totalDistractions
        }
        
    }

    @Model
    class TripHistoryTripsSD {
        @Attribute(.unique) var originationTimestamp: Date
        var originationLatitude: Double
        var originationLongitude: Double
        var originationAddress: String
        
        var destinationTimestamp: Date
        var destinationLatitude: Double
        var destinationLongitude: Double
        var destinationAddress: String
        
        var maxSpeed: Double
        var duration: Double
        var distance: Double
        
        var scoreAcceleration: Double
        var scoreDeceleration: Double
        var scoreSmoothness: Double
        
//        var toTripJournal: [TripJournalSD]?
        var toTripHistoryTripJournal: [TripHistoryTripJournalSD]?
        
        @Relationship(inverse: \TripHistorySummarySD.toTripHistoryTrips) var toTripSummary: TripHistorySummarySD?
        
        init(originationTimestamp: Date, originationLatitude: Double, originationLongitude: Double, originationAddress: String, destinationTimestamp: Date, destinationLatitude: Double, destinationLongitude: Double, destinationAddress: String, maxSpeed: Double, duration: Double, distance: Double, scoreAcceleration: Double, scoreDeceleration: Double, scoreSmoothness: Double) {
            self.originationTimestamp = originationTimestamp
            self.originationLatitude = originationLatitude
            self.originationLongitude = originationLongitude
            self.originationAddress = originationAddress
            self.destinationTimestamp = destinationTimestamp
            self.destinationLatitude = destinationLatitude
            self.destinationLongitude = destinationLongitude
            self.destinationAddress = destinationAddress
            self.maxSpeed = maxSpeed
            self.duration = duration
            self.distance = distance
            self.scoreAcceleration = scoreAcceleration
            self.scoreDeceleration = scoreDeceleration
            self.scoreSmoothness = scoreSmoothness
        }
        var sortedCoordinates: [CLLocationCoordinate2D] {
            guard let journals = toTripHistoryTripJournal else { return [] }
            let sortedJournals = journals.sorted(by: { $0.timestamp < $1.timestamp })
            return sortedJournals.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        }
    }
    
    @Model
    class TripHistoryTripJournalSD {
        @Attribute(.unique) var timestamp: Date
        var longitude: Double
        var latitude: Double
        var speed: Double
        var code: String
        var note: String

//        @Relationship(inverse: \TripSummarySD.toTripJournal) var toTripSummaries: TripSummariesSD?
        @Relationship(inverse: \TripHistoryTripsSD.toTripHistoryTripJournal) var toTripHistoryTrips: TripHistoryTripsSD?

        init(timestamp: Date, longitude: Double, latitude: Double, speed: Double, code: String, note: String) {
            self.timestamp = timestamp
            self.longitude = longitude
            self.latitude = latitude
            self.speed = speed
            self.code = code
            self.note = note
        }
    }

    
    // Sections
    @Model
    class SectionsSD {
        
        @Attribute(.unique) var id: String
        var section: String
        var rank: String
        
        var toArticles: [ArticlesSD]?
        
        init(id:String, section: String, rank: String) {
            self.id = id
            self.section = section
            self.rank = rank
        }
    }
    
    // Articles
    @Model
    class ArticlesSD {
        var id: String
        var title: String
        var summary: String
        var search: String
        var section: String
        var body: String
        
        @Relationship(inverse: \SectionsSD.toArticles) var toSection: SectionsSD?

        init(id: String, title: String, summary: String, search: String, section: String, body: String) {
            self.id = id
            self.title = title
            self.summary = summary
            self.search = search
            self.section = section
            self.body = body
        }
    }
    
}
