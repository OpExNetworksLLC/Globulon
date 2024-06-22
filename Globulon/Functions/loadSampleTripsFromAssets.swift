//
//  loadSampleTripFromAssets.swift
//  ViDrive
//
//  Created by David Holeman on 3/22/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import SwiftData

func loadSampleTripFromAssets(file: String) -> Int {
    
    /// Read JSON data from file in documents directory
    //let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    //let jsonFileURL = documentsDirectory.appendingPathComponent("date.json")
    
    let jsonFilePath = file
    guard let jsonFileURL = Bundle.main.url(forResource: jsonFilePath, withExtension: "json") else {
        fatalError("Failed to locate JSON file.")
    }

    var tripItemCount = 0
    do {
        let jsonData = try Data(contentsOf: jsonFileURL)
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
        
        let tripItems = try jsonDecoder.decode([TripItemJSON].self, from: jsonData)
  
        let context = ModelContext(AppEnvironment.sharedModelContainer)
        
        // Iterate through the decoded locations and create GpsJournalSD managed objects
        for tripItem in tripItems {
            let entry = GpsJournalSD(
                timestamp: tripItem.timestamp,
                longitude: tripItem.longitude,
                latitude: tripItem.latitude,
                speed: tripItem.speed,
                processed: tripItem.processed,
                code: tripItem.code,
                note: tripItem.note
            )
            context.insert(entry)
            tripItemCount += 1
        }
        
        /// Save the context to persist changes
        ///
        try context.save()
        LogEvent.print(module: "loadSampleTripFromAssetts()", message: "Loaded \(tripItemCount) GPS data points from \(jsonFilePath).json successfully")
        
    } catch {

        LogEvent.print(module: "loadSampleTripFromAssets()", message: "Error: \(error)")
    }
    
    return (tripItemCount)
}
