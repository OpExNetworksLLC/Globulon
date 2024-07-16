//
//  deleteHistoryTrip.swift
//  Globulon
//
//  Created by David Holeman on 5/7/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

/// # deleteHistoryTrip
/// Delete a trip in the trip history
///
/// # Version History
/// ### 0.1.0.63
/// # - cleaned up the code and more efficient
/// # - *Date*: 07/15/24

import Foundation
import SwiftData

func deleteHistoryTrip(tripTimestamp: Date) -> Bool {
    LogEvent.print(module: "deleteHistoryTrip()", message: "starting ...")

    let context = ModelContext(AppEnvironment.sharedModelContainer)
    var result = false

    do {
        // Fetch trip history entries
        let fetchDescriptor = FetchDescriptor<TripHistoryTripsSD>(sortBy: [SortDescriptor(\TripHistoryTripsSD.originationTimestamp, order: .forward)])
        let tripHistoryTripsSD = try context.fetch(fetchDescriptor)
        
        // Find and delete the matching trip
        if let tripToDelete = tripHistoryTripsSD.first(where: { $0.originationTimestamp == tripTimestamp }) {
            context.delete(tripToDelete)
            
            do {
                try context.save()
                result = true
                LogEvent.print(module: "deleteHistoryTrip()", message: "Deleted trip dated \(tripToDelete.originationTimestamp)")

                // Check if the trip summary needs updating
                let summaryFetchDescriptor = FetchDescriptor<TripSummariesSD>(sortBy: [SortDescriptor(\TripSummariesSD.originationTimestamp, order: .forward)])
                let tripSummariesSD = try context.fetch(summaryFetchDescriptor)

                if let summaryToDelete = tripSummariesSD.first(where: { $0.originationTimestamp == tripTimestamp }) {
                    // Fetch monthly summary entries
                    let monthlySummaryFetchDescriptor = FetchDescriptor<TripHistorySummarySD>(sortBy: [SortDescriptor(\TripHistorySummarySD.datestamp, order: .forward)])
                    let tripHistorySummarySD = try context.fetch(monthlySummaryFetchDescriptor)
                    
                    if tripHistorySummarySD.isEmpty {
                        context.delete(summaryToDelete)
                        try context.save()
                        LogEvent.print(module: "deleteHistoryTrip()", message: "Deleted summary for date: \(summaryToDelete.originationTimestamp)")

                        // Update the trip history monthly summary
                        _ = updateTripHistoryMonthSummary(datestamp: formatTimestampToDatestamp(tripTimestamp))
                    }
                } else {
                    LogEvent.print(module: "deleteHistoryTrip()", message: "No trip summary found for date: \(tripTimestamp)")
                }
            } catch {
                LogEvent.print(module: "deleteHistoryTrip()", message: "Error saving context after deleting a trip history: \(error)")
            }
        } else {
            LogEvent.print(module: "deleteHistoryTrip()", message: "No trip found for date: \(tripTimestamp)")
        }
    } catch {
        LogEvent.print(module: "deleteHistoryTrip()", message: "An error occurred: \(error)")
    }

    LogEvent.print(module: "deleteHistoryTrip()", message: "... finished")
    return result
}


//func deleteHistoryTrip(tripTimestamp: Date) -> Bool {
//    LogEvent.print(module: "deleteHistoryTrip()", message: "starting ...")
//    
//    let context = ModelContext(AppEnvironment.sharedModelContainer)
//    
//    var result = false
//    
//    do {
//        
//        /// Define a fetch descriptor that sorts the entries by timestamp in ascending order
//        let fetchDescriptor = FetchDescriptor<TripHistoryTripsSD>(sortBy: [SortDescriptor(\TripHistoryTripsSD.originationTimestamp, order: .forward)])
//        
//        /// Fetch all entries from the context
//        let tripHistoryTripsSD = try context.fetch(fetchDescriptor)
//        
//        /// Find the first trip that matches the tripTimestamp
//        var firstFilteredTrip: TripHistoryTripsSD? {
//            return tripHistoryTripsSD.first { tripSummary in
//                return tripSummary.originationTimestamp == tripTimestamp
//            }
//        }
//        
//        /// delete the trip here
//        context.delete(firstFilteredTrip!)
//        
//        do {
//            
//            //TODO:  Not deleting the monthly summary record
//            
//            try context.save()
//            result = true
//            LogEvent.print(module: "deleteHistoryTrip()", message: "Deleted trip dated \(firstFilteredTrip?.originationTimestamp ?? Date())")
//            
//            /// Define a fetch descriptor that sorts the entries by timestamp in ascending order
//            let fetchDescriptor = FetchDescriptor<TripSummariesSD>(sortBy: [SortDescriptor(\TripSummariesSD.originationTimestamp, order: .forward)])
//            
//            /// Fetch all entries from the context
//            let tripSummariesSD = try context.fetch(fetchDescriptor)
//            
//            /// Find the first trip that matches the tripTimestamp
//            let firstFilteredSummaries = tripSummariesSD.first { tripSummary in
//                return tripSummary.originationTimestamp == tripTimestamp
//            }
//            
//            /// Check if the filtered trip is found, else log an error and exit because there's nothing to add
//            ///
//            guard let firstSummaries = firstFilteredSummaries else {
//                LogEvent.print(module: "deleteHistoryTrip()", message: "No trip found for date: \(firstFilteredSummaries?.originationTimestamp ?? Date())")
//                return false
//            }
//            
//            /// Define a fetch descriptor that sorts the entries by timestamp in ascending order
//            let fetchDescriptor2 = FetchDescriptor<TripHistorySummarySD>(sortBy: [SortDescriptor(\TripHistorySummarySD.datestamp, order: .forward)])
//            
//            /// Fetch all entries from the context
//            let tripHistorySummarySD = try context.fetch(fetchDescriptor2)
//            
//            let firstFilteredTripHistorySummary = tripHistorySummarySD.first { tripSummary in
//                return tripSummary.datestamp == formatDateYearMonth(tripTimestamp)
//            }
//                        
//            if tripHistorySummarySD.count == 0 {
//                print("** entries in month history: \(tripHistoryTripsSD.count)")
//                context.delete(firstFilteredSummaries!)
//                do {
//                    try context.save()
//                    result = true
//                    LogEvent.print(module: "deleteHistoryTrip()", message: "Deleted trip dated \(firstFilteredTrip?.originationTimestamp ?? Date())")
//                } catch {
//                    print("** Error saving context after deleting history trip: \(error)")
//                    LogEvent.print(module: "deleteHistoryTrip()", message: "Error saving context after deleting a trip history: \(error)")
//                }
//                
//            }
//            
//            /// Update the trip history summer after the trip has been saved.  Important to update here so we have the latest in the monthly summary
//            ///
//            _ = updateTripHistoryMonthSummary(datestamp: formatTimestampToDatestamp(tripTimestamp))
//
//            
//        } catch {
//            // Handle the error, e.g., show an alert to the user
//            print("** Error saving context after deleting a trip: \(error)")
//            LogEvent.print(module: "deleteHistoryTrip()", message: "Error saving context after deleting a trip: \(error)")
//        }
//        
//    } catch {
//        LogEvent.print(module: "deleteHistoryTrip()", message: "An error occurred: \(error)")
//    }
//    
//    LogEvent.print(module: "deleteHistoryTrip()", message: "... finished")
//    
//    return result
//}
