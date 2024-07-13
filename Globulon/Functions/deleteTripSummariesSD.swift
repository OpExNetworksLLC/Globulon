//
//  deleteTripSummariesSD.swift
//  Globulon
//
//  Created by David Holeman on 2/25/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

/// # deleteTripSummariesSD
/// Delete all the data model thus deleting all the entries
///
/// # Version History
/// ### 0.1.0.62
/// # - added and return record count
/// # - *Date*: 07/13/24

import SwiftData


/// deleteTripSummariesSD()
/// - Returns: Record count
///
func deleteTripSummariesSD() -> Int {
    do {
        let context = ModelContext(AppEnvironment.sharedModelContainer)

        do {
            let fetchDescriptor = FetchDescriptor<TripSummariesSD>()
            let entries = try context.fetch(fetchDescriptor)

            try context.delete(model: TripSummariesSD.self)
            LogEvent.print(module: "deleteTripSummaries()", message: "Deleted \(entries.count) TripSummariesSD entries")

            return entries.count
        } catch {
            LogEvent.print(module: "deleteTripSummaries()", message: "Error deleting TripSummariesSD")
            return 0
        }
    }
}


//func deleteTripSummariesSD() {
//    do {
//        let context = ModelContext(AppEnvironment.sharedModelContainer)
//
//        do {
//            try context.delete(model: TripSummariesSD.self)
//            LogEvent.print(module: "deleteTripSummaries()", message: "Deleted TripSummariesSD")
//        } catch {
//            LogEvent.print(module: "deleteTripSummaries()", message: "Error deleting TripSummariesSD")
//        }
//    }
//}

