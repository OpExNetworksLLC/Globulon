//
//  deprocessGPSJournalSD.swift
//  ViDrive
//
//  Created by David Holeman on 5/1/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftData

/// Set all the GPS Journal entry process status to false
///
func deprocessGpsJournalSD() -> Int {
    let context = ModelContext(AppEnvironment.sharedModelContainer)

    var entriesCount = 0
    
    do {
        // Assuming `fetch` returns an array of `GpsJournalSD` objects
        let fetchDescriptor = FetchDescriptor<GpsJournalSD>()
        let allEntries = try context.fetch(fetchDescriptor)
        
        for entry in allEntries {

            if entry.processed == true {
                entry.processed = false
                entriesCount += 1
            }
        }

        try context.save()
        
    } catch {
        print("Error processing GpsJournalSD entries: \(error)")
    }
    
    return entriesCount // Return the count of duplicates removed
}
