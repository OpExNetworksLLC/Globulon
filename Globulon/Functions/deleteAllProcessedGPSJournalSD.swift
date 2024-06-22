//
//  deleteAllProcessedGPSJournalSD.swift
//  ViDrive
//
//  Created by David Holeman on 5/27/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import SwiftData

func deleteAllProcessedGPSJournalSD() -> Int {
    
    LogEvent.print(module: "deleteAllProcessedGPSJournalSD()", message: "starting ...")
    
    let context = ModelContext(AppEnvironment.sharedModelContainer)
    
    var deletedCount = 0
    
    do {
        let fetchDescriptor = FetchDescriptor<GpsJournalSD>()
        let allEntries = try context.fetch(fetchDescriptor)
        
        for entry in allEntries {
            if entry.processed == true {
                context.delete(entry)
                deletedCount += 1
            }
        }
        
        try context.save()
        LogEvent.print(module: "deleteAllProcessedGPSJournalSD()", message: "\(deletedCount) processed GPS Journal entries deleted.")

    } catch {
        print("Error deleting processed GpsJournalSD entries: \(error)")
    }
    
    LogEvent.print(module: "deleteAllProcessedGPSJournalSD()", message: "... finished")

    return deletedCount
}
