//
//  deleteTripJournalEntry.swift
//  ZenTrac
//
//  Created by David Holeman on 4/25/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import SwiftData

/// Delete a specific trip GPS journal entry
/// 
func deleteTripJournalEntry(tripTimestamp: Date, journalEntryTimestamp: Date) -> Bool {
    
    LogEvent.print(module: "deleteTripJournalEntry()", message: "Delete trip journal entry ...")
    
    let context = ModelContext(AppEnvironment.sharedModelContainer)
    
    var result = false
    
    do {
        
        /// Define a fetch descriptor that sorts the entries by timestamp in ascending order
        let fetchDescriptor = FetchDescriptor<TripSummariesSD>(sortBy: [SortDescriptor(\TripSummariesSD.originationTimestamp, order: .forward)])
        
        /// Fetch all entries from the context
        let tripSummariesSD = try context.fetch(fetchDescriptor)
        
        /// Find the first trip that matches the tripTimestamp
        var firstFilteredTrip: TripSummariesSD? {
            return tripSummariesSD.first { tripSummary in
                return tripSummary.originationTimestamp == tripTimestamp
            }
        }
        
        var index = 0
        while index < (firstFilteredTrip?.toTripJournal!.count)! {
            if firstFilteredTrip?.toTripJournal![index].timestamp == journalEntryTimestamp {
                context.delete(firstFilteredTrip!.toTripJournal![index])
                break
            }
            index += 1
        }
        
        context.delete(firstFilteredTrip!)
        
        do {
            try context.save()
            result = true
            print("** Deleted trip item dated \(firstFilteredTrip?.originationTimestamp ?? Date())")
            LogEvent.print(module: "deleteTripJournalEntry()", message: "Deleted trip item dated \(firstFilteredTrip?.originationTimestamp ?? Date())")
        } catch {
            // Handle the error, e.g., show an alert to the user
            LogEvent.print(module: "deleteTripJournalEntry()", message: "Error saving context after deleting a trip item: \(error)")
        }
    } catch {
        LogEvent.print(module: "deleteTripSData()", message: "An error occurred: \(error)")
    }
    
    return result
}
