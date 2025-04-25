//
//  countGPSDataAll.swift
//  Globulon
//
//  Created by David Holeman on 2/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftData

@MainActor
func countGPSDataAll() -> Int {
    //let context = ModelContext(ModelContainerProvider.shared)
    let context = ModelContainerProvider.sharedContext
    
    var entriesCount = 0
    
    do {
        // Assuming `fetch` returns an array of `GPSData` objects
        let fetchDescriptor = FetchDescriptor<GPSData>()
        let allEntries = try context.fetch(fetchDescriptor)

        entriesCount = allEntries.count
        
    } catch {
        LogEvent.print(module: "countGPSDataAll()", message: "Error counting all GPSData entries: \(error)")
    }
    return entriesCount // Return the count of entries
}
