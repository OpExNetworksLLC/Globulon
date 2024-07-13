//
//  deleteGPSJournalSD.swift
//  ViDrive
//
//  Created by David Holeman on 2/25/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

/// # deleteGpsJournalSD
/// Delete all the data model thus deleting all the entries
///
/// # Version History
/// ### 0.1.0.62
/// # - added and return record count
/// # - *Date*: 07/13/24


import SwiftData


/// deleteGPSJournalSD()
/// - Returns: Record count
///
func deleteGpsJournalSD() -> Int {
    do {
        let context = ModelContext(AppEnvironment.sharedModelContainer)

        do {
            
            let fetchDescriptor = FetchDescriptor<GpsJournalSD>()
            let entries = try context.fetch(fetchDescriptor)
            
            try context.delete(model: GpsJournalSD.self)
            LogEvent.print(module: "deleteGPSJournalSD()", message: "Deleted \(entries.count) GPSJournalSD entries.")
            
            return entries.count
            
        } catch {
            LogEvent.print(module: "deleteGPSJournalSD()", message: "error deleting GPSJournalSD.")
            return 0
        }
    }
}
