//
//  deleteTripData.swift
//  ViDrive
//
//  Created by David Holeman on 4/15/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import SwiftData


/// Delete a specific trip
/// 
func deleteTripData(tripTimestamp: Date) -> Bool {
    LogEvent.print(module: "deleteTripData()", message: "starting ...")
    
    let context = ModelContext(AppEnvironment.sharedModelContainer)
    
    var result = false
    
    do {
        
        /// Define a fetch descriptor that sorts the entries by timestamp in ascending order
        let fetchDescriptor = FetchDescriptor<TripSummariesSD>(sortBy: [SortDescriptor(\TripSummariesSD.originationTimestamp, order: .forward)])
        
        /// Fetch all entries from the context
        let tripSummariesSD = try context.fetch(fetchDescriptor)
        
        /// Find the first trip that matches the tripTimestamp
        var firstFilteredTrip: TripSummariesSD? {
            return tripSummariesSD.first { tripSummary in
                return tripSummary.originationTimestamp == tripTimestamp
            }
        }
        
        context.delete(firstFilteredTrip!)
        
        do {
            try context.save()
            result = true
            LogEvent.print(module: "deleteTripData()", message: "Deleted trip dated \(firstFilteredTrip?.originationTimestamp ?? Date())")
        } catch {
            // Handle the error, e.g., show an alert to the user
            print("** Error saving context after deleting a trip: \(error)")
            LogEvent.print(module: "deleteTripData()", message: "Error saving context after deleting a trip: \(error)")
        }
    } catch {
        LogEvent.print(module: "deleteTripData()", message: "An error occurred: \(error)")
    }

    LogEvent.print(module: "deleteTripData()", message: "... finished")

    return result
}
