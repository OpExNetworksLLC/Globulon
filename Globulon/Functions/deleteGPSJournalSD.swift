//
//  deleteGPSJournalSD.swift
//  ViDrive
//
//  Created by David Holeman on 2/25/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftData

/// Delete all the GPS journal entries.
/// 
func deleteGpsJournalSD() {
    do {
        let context = ModelContext(AppEnvironment.sharedModelContainer)

        do {
            try context.delete(model: GpsJournalSD.self)
            LogEvent.print(module: "deleteGPSJournalSD()", message: "GPSJournalSD has been deleted.")
        } catch {
            LogEvent.print(module: "deleteGPSJournalSD()", message: "error deleting GPSJournalSD.")
        }
    }
}
