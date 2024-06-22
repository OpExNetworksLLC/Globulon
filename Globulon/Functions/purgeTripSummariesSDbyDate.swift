//
//  purgeTripSummariesSDbyDate.swift
//  ViDrive
//
//  Created by David Holeman on 5/3/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import SwiftData

/// Purge trips greater than the time timestamp provided
///
func purgeTripSummariesSDbyDate(tripTimestamp: Date) -> Int {
    LogEvent.print(module: "purgeTripSummariesSDbyDate()", message: "starting ...")
    
    // Assuming ModelContext and AppEnvironment are properly defined elsewhere
    let context = ModelContext(AppEnvironment.sharedModelContainer)
    var count = 0
    
    do {
        // Fetch Descriptor for TripSummariesSD entities, sorted by timestamp ascending
        let fetchDescriptor = FetchDescriptor<TripSummariesSD>(
            sortBy: [SortDescriptor(\TripSummariesSD.originationTimestamp, order: .forward)]
        )
        
        // Fetch all entries from the context
        let tripSummariesSD = try context.fetch(fetchDescriptor)
        
        // Find all trips with a timestamp greater than the given tripTimestamp
        let tripsToDelete = tripSummariesSD.filter { tripSummary in
            tripSummary.originationTimestamp > tripTimestamp
        }
        
        // Delete each of those trips from the context
        for tripSummary in tripsToDelete {
            context.delete(tripSummary)
            count += 1
        }
        
        // Save the changes after deletion
        try context.save()
    } catch {
        // Log any errors that occurred
        LogEvent.print(module: "purgeTripSummariesSDbyDate()", message: "An error occurred: \(error)")
    }
    
    LogEvent.print(module: "purgeTripSummariesSDbyDate()", message: "Trip summaries purged: \(count)")
    LogEvent.print(module: "purgeTripSummariesSDbyDate()", message: "finished ...")
    
    return count
}
