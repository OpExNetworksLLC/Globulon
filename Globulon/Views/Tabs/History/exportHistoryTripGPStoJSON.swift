//
//  exportHistoryTripGPStoJSON.swift
//  ViDrive
//
//  Created by David Holeman on 5/7/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//


import Foundation
import SwiftData

func exportHistoryTripGPStoJSON(tripTimestamp: Date) -> Int {
    LogEvent.print(module: "exportHistoryTripGPStoJSON()", message: "Exporting trip data ...")
    
    var entryCounter = 0
    
    let context = ModelContext(AppEnvironment.sharedModelContainer)
    
    do {
        
//        /// Define a fetch descriptor that sorts the entries by timestamp in ascending order
//        let fetchDescriptor = FetchDescriptor<TripSummariesSD>(sortBy: [SortDescriptor(\TripSummariesSD.originationTimestamp, order: .forward)])
//        
//        /// Fetch all entries from the context
//        let tripSummariesSD = try context.fetch(fetchDescriptor)
//        
//        /// Find the first trip that matches the tripTimestamp
//        var firstFilteredTrip: TripSummariesSD? {
//            return tripSummariesSD.first { tripSummary in
//                return tripSummary.originationTimestamp == tripTimestamp
//            }
//        }

        /// Define a fetch descriptor that sorts the entries by timestamp in ascending order
        let fetchDescriptor = FetchDescriptor<TripHistoryTripsSD>(sortBy: [SortDescriptor(\TripHistoryTripsSD.originationTimestamp, order: .forward)])
        
        /// Fetch all entries from the context
        let tripHistoryTripsSD = try context.fetch(fetchDescriptor)
        
        /// Find the first trip that matches the tripTimestamp
        var firstFilteredTrip: TripHistoryTripsSD? {
            return tripHistoryTripsSD.first { tripSummary in
                return tripSummary.originationTimestamp == tripTimestamp
            }
        }
        
        /// Loop through the details and export the data
        /// Grap the GPS waypoints from the trip journal
        ///
        var sortedTrip: [TripHistoryTripJournalSD] {
            firstFilteredTrip?.toTripHistoryTripJournal?.sorted {$0.timestamp < $1.timestamp } ?? []
        }
        
        /// Initialize an empty array to hold TripItem instances
        ///
        var tripItems = [TripItemJSON]()
        
        //var tripItems = [HistoryTripGPStoJSON]()
        for item in sortedTrip {
            let tripItem = TripItemJSON(
                timestamp: item.timestamp,
                latitude: item.latitude,
                longitude: item.longitude,
                speed: item.speed,
                processed: false,
                //archived: false,
                code: item.code,
                note: item.note
            )
            tripItems.append(tripItem)
            
            entryCounter += 1
            print("** Exporting \(tripTimestamp):", item.timestamp, item.latitude, item.longitude, item.speed)
        }
        
        /// Since sortedTrip is a full representation of the swift data model with a an inverse relationship to TripSummaries we run into some complexities since we can not straight up encode the structure as is.  So, we copy the data to our working structure then export that which is the goal.  We want to get this data into format compativle with gpsJournalSD.
        
        // Get the URL for the documents directory
        let exportFilename = "ViDrive Trip - \(formatDateStampFile(tripTimestamp)).json"
        guard let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(exportFilename) else {
            fatalError("Could not find the document directory.")
        }
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        
        do {
            // Encode the tripItems array to JSON
            let jsonData = try jsonEncoder.encode(tripItems)
            
            // Write the JSON data to the file
            try jsonData.write(to: fileURL, options: .atomic)
            LogEvent.print(module: "** exportHistoryTripGPStoJSON()", message: "Trip items were successfully saved to \(String(describing: fileURL))")

        } catch {
            // Handle potential errors
            print("Error encoding or saving trip items: \(error)")
            LogEvent.print(module: "exportHistoryTripGPStoJSON()", message: "Error encoding or saving trip items: \(error)")
        }
        
        /// Save the file
        ///
        do {
            let jsonData = try Data(contentsOf: fileURL)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                saveTextToFile(jsonString, fileName: exportFilename)
            }
        } catch {
            LogEvent.print(module: "exportHistoryTripGPStoJSON()", message: "An error occurred saving the export file: \(error)")

        }

    } catch {
        LogEvent.print(module: "exportHistoryTripGPStoJSON()", message: "An error occurred: \(error)")
    }

    return entryCounter
}

