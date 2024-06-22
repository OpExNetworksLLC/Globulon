//
//  purgeGPSJournalSDbyCount.swift
//  ViDrive
//
//  Created by David Holeman on 3/15/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//
import Foundation
import SwiftData

func purgeGPSJournalSDbyCount(tripLimit: Int) -> Int {

    LogEvent.print(module: "purgeGPSJournalSDbyCount()()", message: "starting ...")
    
    let context = ModelContext(AppEnvironment.sharedModelContainer)
    
    var tripCounter = 0 // Initialize trip counter
    
    do {
        // Define a fetch descriptor that sorts the entries by timestamp in descending order
        let fetchDescriptor = FetchDescriptor<GpsJournalSD>(sortBy: [SortDescriptor(\GpsJournalSD.timestamp, order: .forward)])
        
        // Fetch all entries from the context
        let allEntries = try context.fetch(fetchDescriptor)
        
        // Variables to track trips and their start indexes
        var trips = [[GpsJournalSD]]()
        var currentTrip = [GpsJournalSD]()

        for (index, entry) in allEntries.enumerated() {
            // Append the first entry to the current trip
            if currentTrip.isEmpty {
                currentTrip.append(entry)
            } else {
                let previousEntry = allEntries[index - 1]
                // Calculate the absolute time gap between the current and previous entry
                let timeGap = abs(Int(previousEntry.timestamp.timeIntervalSince(entry.timestamp)))
                
                // If time gap exceeds the trip separator threshold, start a new trip
                if timeGap >= UserSettings.init().trackingTripSeparator {
                    trips.append(currentTrip)
                    currentTrip = [entry]
                    tripCounter += 1 // Increment trip counter for each new trip
                } else {
                    // Otherwise, continue with the current trip
                    currentTrip.append(entry)
                }
            }
        }
        
        // Don't forget to add the last trip, if it's not empty
        if !currentTrip.isEmpty {
            trips.append(currentTrip)
            tripCounter += 1 // Also increment for the last trip
        }
        
        // Delete older trips if the trip count exceeds tripLimit
        if trips.count > tripLimit {
            let tripsToDelete = trips.suffix(from: tripLimit)
            
            for trip in tripsToDelete {
                for entry in trip {
                    context.delete(entry)
                }
            }
        }
        
        // Attempt to save any changes made to the context
        try context.save()
        
    } catch {
        // Handle errors by printing them
        LogEvent.print(module: "purgeGPSJournalSDbyCount()()", message: "An error occurred: \(error)")
    }

    let result = (tripCounter - tripLimit) < 0 ? 0 : (tripCounter - tripLimit)
    
    if result > 0 {
        LogEvent.print(module: "purgeGPSJournalSDbyCount()", message: "\(result) older trips were purged")
    } else {
        LogEvent.print(module: "purgeGPSJournalSDbyCount()", message: "No trips purged. Total trips (\(tripCounter)) is within the limit (\(tripLimit)).")
    }
    LogEvent.print(module: "purgeGPSJournalSDbyCount()", message: "... finished")

    return result
}
