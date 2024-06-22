//
//  dedupGPSJournalSD.swift
//  ViDrive
//
//  Created by David Holeman on 2/25/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftData

func dedupGpsJournalSD() -> Int {
    let context = ModelContext(AppEnvironment.sharedModelContainer)

    var duplicatesCount = 0 // Initialize a counter for duplicates

    do {
        // Assuming `fetch` returns an array of `GpsJournalSD` objects
        let fetchDescriptor = FetchDescriptor<GpsJournalSD>()
        let allEntries = try context.fetch(fetchDescriptor)
        
        // Identify duplicates (example based on timestamp and location)
        var uniqueEntries = [String: GpsJournalSD]() // Use a dictionary to track unique entries
        var duplicates = [GpsJournalSD]() // Collect duplicates here
        
        for entry in allEntries {
            // Assuming `timestamp` and `latitude` are properties of `GpsJournalSD`
            let identifier = "\(entry.timestamp)-\(entry.latitude)" // Unique identifier based on timestamp and location
            
            if uniqueEntries[identifier] == nil {
                uniqueEntries[identifier] = entry
            } else {
                duplicates.append(entry)
            }
        }
        
        // Remove duplicates
        for duplicate in duplicates {
            // Assuming `delete` method exists and takes an object of `GpsJournalSD`
            context.delete(duplicate)
        }
        
        duplicatesCount = duplicates.count // Set the duplicates count
        
        // Assuming there's a method to save or commit changes in the context
        try context.save()
        
        print("Removed \(duplicatesCount) duplicate entries from GpsJournalSD")
    } catch {
        print("Error processing GpsJournalSD entries: \(error)")
    }
    
    return duplicatesCount // Return the count of duplicates removed
}


/*
func dedupGpsJournalSD() {
    let context = ModelContext(AppEnvironment.sharedModelContainer)

    do {
        
        // Assuming `fetch` returns an array of `GpsJournalSD` objects
        let fetchDescriptor = FetchDescriptor<GpsJournalSD>()
        let allEntries = try context.fetch(fetchDescriptor)
        
        // Identify duplicates (example based on timestamp and location)
        var uniqueEntries = [String: GpsJournalSD]() // Use a dictionary to track unique entries
        var duplicates = [GpsJournalSD]() // Collect duplicates here
        
        for entry in allEntries {
            // Assuming `timestamp` and `latitude` are properties of `GpsJournalSD`
            let identifier = "\(entry.timestamp)-\(entry.latitude)" // Unique identifier based on timestamp and location
            
            if uniqueEntries[identifier] == nil {
                uniqueEntries[identifier] = entry
            } else {
                duplicates.append(entry)
            }
        }
        
        // Remove duplicates
        for duplicate in duplicates {
            // Assuming `delete` method exists and takes an object of `GpsJournalSD`
            context.delete(duplicate)
        }
        
        // Assuming there's a method to save or commit changes in the context
        try context.save()
        
        print("Removed \(duplicates.count) duplicate entries from GpsJournalSD")
    } catch {
        print("Error processing GpsJournalSD entries: \(error)")
    }
}
*/
