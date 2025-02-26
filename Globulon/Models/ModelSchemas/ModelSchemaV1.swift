//
//  ModelSchemaV1.swift
//  Globulon
//
//  Created by David Holeman on 02/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import SwiftData
import CoreLocation


enum DummySchema: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        return Schema.Version(0, 0, 0)
    }
    static let models: [any PersistentModel.Type] = []
}

enum ModelSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        return Schema.Version(1, 0, 0)
    }
    
    static var models: [any PersistentModel.Type] {
        return [
            HelpArticle.self,
            HelpSection.self,
            GPSData.self,
            TourData.self,
            TourPOIData.self,
            CatalogToursData.self,
            CatalogTourData.self
        ]
    }
    
    /// Sections
    ///
    @Model
    class HelpSection {
        
        @Attribute(.unique) var id: String
        var section: String
        var rank: String
        
        var toArticles: [HelpArticle]?
        
        init(id:String, section: String, rank: String) {
            self.id = id
            self.section = section
            self.rank = rank
        }
    }

    /// Articles
    ///
    @Model
    class HelpArticle {
        var id: String
        var title: String
        var summary: String
        var search: String
        var section: String
        var body: String
        
        @Relationship(inverse: \HelpSection.toArticles) var toSection: HelpSection?

        init(id: String, title: String, summary: String, search: String, section: String, body: String) {
            self.id = id
            self.title = title
            self.summary = summary
            self.search = search
            self.section = section
            self.body = body
        }
    }
    
    /// GPS Journal
    /// This is the raw GPS location data collected by the Location Manager
    ///
    @Model
    class GPSData {

        @Attribute(.unique) var timestamp: Date
        var latitude: Double
        var longitude: Double
        var speed: Double
        var processed: Bool
        var code: String
        var note: String

        init(timestamp: Date, latitude: Double, longitude: Double, speed: Double, processed: Bool, code: String, note: String) {
            self.timestamp = timestamp
            self.latitude = latitude
            self.longitude = longitude
            self.speed = speed
            self.processed = processed
            self.code = code
            self.note = note
        }
    }
    
    @Model
    class TourData {
        @Attribute(.unique) var tour_id: String
        var isActive: Bool
        var application: String
        var version: String
        var created_on: Date
        var updated_on: Date
        var author: String
        var title: String
        var sub_title: String
        var desc: String
        @Relationship(deleteRule: .cascade) var toTourPOI: [TourPOIData]?

        init(tour_id: String, isActive: Bool, application: String, version: String, created_on: Date, updated_on: Date, author: String, title: String, sub_title: String, desc: String) {
            self.tour_id = tour_id
            self.isActive = isActive
            self.application = application
            self.version = version
            self.created_on = created_on
            self.updated_on = updated_on
            self.author = author
            self.title = title
            self.sub_title = sub_title
            self.desc = desc
        }
    }

    @Model
    class TourPOIData {
        @Attribute(.unique) var id: String
        var order_index: Int
        var title: String
        var sub_title: String
        var desc: String
        var latitude: Double
        var longitude: Double
        @Relationship(inverse: \TourData.toTourPOI) var toTourData: TourData?

        init(id: String, order_index: Int, title: String, sub_title: String, desc: String, latitude: Double, longitude: Double) {
            self.id = id
            self.order_index = order_index
            self.title = title
            self.sub_title = sub_title
            self.desc = desc
            self.latitude = latitude
            self.longitude = longitude
        }
    }
    
    // final means it can be subclassed and Sendable means that the structure can be trusted outside persistence
    @Model
    final class CatalogToursData: Sendable {
        @Attribute(.unique) var catalog_id: String
        var isActive: Bool
        var application: String
        var version: String
        var created_on: Date
        var updated_on: Date
        var author: String
        var title: String
        var sub_title: String
        var desc: String

        @Relationship(deleteRule: .cascade) var toCatalogTour: [CatalogTourData]?

        init(catalog_id: String, isActive: Bool, application: String, version: String, created_on: Date, updated_on: Date, author: String, title: String, sub_title: String, desc: String) {
            self.catalog_id = catalog_id
            self.isActive = isActive
            self.application = application
            self.version = version
            self.created_on = created_on
            self.updated_on = updated_on
            self.author = author
            self.title = title
            self.sub_title = sub_title
            self.desc = desc
        }
    }

    @Model
    final class CatalogTourData: Sendable {
        @Attribute(.unique) var tour_id: String
        var isActive: Bool
        var tour_file: String
        var tour_directory: String
        var order_index: Int
        var title: String
        var sub_title: String
        var desc: String

        @Relationship(inverse: \CatalogToursData.toCatalogTour) var toCatalogTours: CatalogToursData?

        init(tour_id: String, isActive: Bool, tour_file: String, tour_directory: String, order_index: Int, title: String, sub_title: String, desc: String) {
            self.tour_id = tour_id
            self.isActive = isActive
            self.tour_file = tour_file
            self.tour_directory = tour_directory
            self.order_index = order_index
            self.title = title
            self.sub_title = sub_title
            self.desc = desc
        }
    }
}

