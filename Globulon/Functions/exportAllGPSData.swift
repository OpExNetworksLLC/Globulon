//
//  exportAllGPSData.swift
//  ViDrive
//
//  Created by David Holeman on 4/12/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import SwiftData

func exportAllGPSData() -> Int {

    LogEvent.print(module: "exportAllGPSData()", message: "Exporting GPS data ...")
    
    let context = ModelContext(AppEnvironment.sharedModelContainer)
    
    var entryCounter = 0
    
    do {
        /// Define a fetch descriptor that sorts the entries by timestamp in ascending order
        let fetchDescriptor = FetchDescriptor<GpsJournalSD>(sortBy: [SortDescriptor(\GpsJournalSD.timestamp, order: .forward)])
        
        /// Fetch all entries from the context
        let sortedGPSJournal = try context.fetch(fetchDescriptor)
        
        /// Load the data into the JSON structure
        ///
        var tripItems = [GPSJournalJSON]()
        for item in sortedGPSJournal {
            let entry = GPSJournalJSON(timestamp: item.timestamp, latitude: item.latitude, longitude: item.longitude, speed: item.speed, processed: false, code: item.code, note: item.note)
            tripItems.append(entry)
            
            entryCounter += 1
            
            print("** GPS: ", item.timestamp, item.latitude, item.longitude, item.speed)
            
        }
        
        
//        for i in 1..<sortedGPSJournal.count {
//            
//            print("** \(i) \(sortedGPSJournal[i].timestamp) \(sortedGPSJournal[i].latitude) : \(sortedGPSJournal[i].latitude) \(formatMPH(sortedGPSJournal[i].speed))")
//            
//            entryCounter += 1
//        }
        
        
        // Get the URL for the documents directory
        let exportFilename = "ViDrive GPS Data - \(formatDateStampFile(Date())).json"
        guard let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(exportFilename) else {
            fatalError("** Could not find the document directory.")
        }
        
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        
        // Encode the data
        do {
            // Encode the tripItems array to JSON
            let jsonData = try jsonEncoder.encode(tripItems)
            
            // Write the JSON data to the file
            try jsonData.write(to: fileURL, options: .atomic)
            print("** GPS data was successfully saved to \(String(describing: fileURL))")
        } catch {
            // Handle potential errors
            print("** Error encoding or saving GPS data: \(error)")
        }
        
        
    } catch {
        LogEvent.print(module: "exportAllGPSData()", message: "An error occurred: \(error)")
    }
    
    LogEvent.print(module: "exportAllGPSData()", message: "GPS entries exported: \(entryCounter)")

    return entryCounter
}
