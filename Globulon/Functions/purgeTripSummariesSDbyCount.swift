//
//  purgeTripSummariesSDbyCount.swift
//  ViDrive
//
//  Created by David Holeman on 5/3/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import SwiftData

/// Purge trips greater than the trip limit provided
///
func purgeTripSummariesSDbyCount(tripLimit: Int) -> Int {
    
    LogEvent.print(module: "purgeTripSummariesSDbyCount()", message: "starting ...")
    
    let context = ModelContext(AppEnvironment.sharedModelContainer)

    var purgedCount = 0

    do {
        // Define a fetch descriptor that sorts the entries by timestamp in descending order.
        let fetchDescriptor = FetchDescriptor<TripSummariesSD>(sortBy: [SortDescriptor(\TripSummariesSD.originationTimestamp, order: .reverse)])

        // Fetch all entries from the context.
        let tripSummariesSD = try context.fetch(fetchDescriptor)

        // Check the number of trips that exceed the tripLimit.
        if tripSummariesSD.count > tripLimit {
            // Keep the first `tripLimit` trips and identify those that should be deleted.
            let tripsToDelete = tripSummariesSD.dropFirst(tripLimit)
            for trip in tripsToDelete {
                context.delete(trip)
                purgedCount += 1
            }
            
            // Save changes to the context after deleting the trips.
            try context.save()
            LogEvent.print(module: "purgeTripSummariesSDbyCount()", message: "Purged \(purgedCount) trips.")
        } else {
            LogEvent.print(module: "purgeTripSummariesSDbyCount()", message: "No trips purged. Total trips (\(tripSummariesSD.count)) is within the limit (\(tripLimit)).")
        }
    } catch {
        // Handle and log any errors that occur during fetching or deleting.
        LogEvent.print(module: "purgeTripSummariesSDbyCount()", message: "An error occurred during fetch or save: \(error)")
    }
    LogEvent.print(module: "purgeTripSummariesSDbyCount()", message: "... finished")

    return purgedCount
}

