//
//  deleteTripGPSJournalEntry.swift
//  Globulon
//
//  Created by David Holeman on 4/25/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

/// # deleteTripGPSJournalEntry
/// Display trip details
///
/// # Version History
/// ### 0.1.0.65
/// # - Fixed to delete the GPS entry instead of the trip
/// # - *Date*: 07/15/24

import Foundation
import SwiftData

/// Delete a specific trip GPS journal entry
/// 
func deleteTripGPSJournalEntry(tripTimestamp: Date, journalEntryTimestamp: Date) -> Bool {
    LogEvent.print(module: "deleteTripGPSJournalEntry()", message: "Delete trip journal entry ...")
    
    let context = ModelContext(AppEnvironment.sharedModelContainer)
    var result = false
    
    do {
        // Define a fetch descriptor that sorts the entries by timestamp in ascending order
        let fetchDescriptor = FetchDescriptor<TripSummariesSD>(sortBy: [SortDescriptor(\TripSummariesSD.originationTimestamp, order: .forward)])
        
        // Fetch all entries from the context
        let tripSummariesSD = try context.fetch(fetchDescriptor)
        
        // Find the first trip that matches the tripTimestamp
        guard let firstFilteredTrip = tripSummariesSD.first(where: { $0.originationTimestamp == tripTimestamp }) else {
            LogEvent.print(module: "deleteTripGPSJournalEntry()", message: "No trip found with the specified timestamp.")
            return result
        }
        
        // Find the journal entry that matches the journalEntryTimestamp
        if let journalEntry = firstFilteredTrip.toTripJournal?.first(where: { $0.timestamp == journalEntryTimestamp }) {
            // Delete the journal entry
            context.delete(journalEntry)
            
            // Save the context
            try context.save()
            result = true
            LogEvent.print(module: "deleteTripGPSJournalEntry()", message: "Deleted journal entry dated \(journalEntryTimestamp).")
        } else {
            LogEvent.print(module: "deleteTripGPSJournalEntry()", message: "No journal entry found with the specified timestamp.")
        }
    } catch {
        LogEvent.print(module: "deleteTripGPSJournalEntry()", message: "An error occurred: \(error)")
    }
    
    return result
}
