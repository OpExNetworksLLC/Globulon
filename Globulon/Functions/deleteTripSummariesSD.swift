//
//  deleteTripSummariesSD.swift
//  ViDrive
//
//  Created by David Holeman on 2/25/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftData

/// Delete all trips
///
func deleteTripSummariesSD() {
    do {
        let context = ModelContext(AppEnvironment.sharedModelContainer)

        do {
            try context.delete(model: TripSummariesSD.self)
            LogEvent.print(module: "deleteTripSummaries()", message: "Deleted TripSummariesSD")
        } catch {
            LogEvent.print(module: "deleteTripSummaries()", message: "Error deleting TripSummariesSD")
        }
    }
}

