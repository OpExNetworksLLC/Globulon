//
//  updateTripHistoryMonthSummary.swift
//  ViDrive
//
//  Created by David Holeman on 5/7/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import SwiftData

func updateTripHistoryMonthSummary(datestamp: String) -> Bool {
    
    LogEvent.print(module: "updateTripHistoryMonthSummary()", message: "starting ...")
    
    let context = ModelContext(AppEnvironment.sharedModelContainer)

    var result = false
    
    do {
        /// Define a fetch descriptor that sorts the entries by timestamp in ascending order
        let fetchDescriptor = FetchDescriptor<TripHistorySummarySD>(sortBy: [SortDescriptor(\TripHistorySummarySD.datestamp, order: .forward)])
        
        /// Fetch all entries from the context
        let tripMonthSummarySD = try context.fetch(fetchDescriptor)
        
        let firstFilteredMonthSummary = tripMonthSummarySD.first { monthSummary in
            return monthSummary.datestamp == datestamp
        }
        
        guard let firstMonthSummary = firstFilteredMonthSummary else {
            LogEvent.print(module: "updateTripHistoryMonthSummary()", message: "No trip found for date: \(datestamp)")
            return false
        }
        
        /// Zero out some of the monthly history because we are going to recalculate as we loop through the trips to pick up any changes in the summary.
        ///
        firstMonthSummary.totalDistance = 0
        firstMonthSummary.totalDuration = 0
        firstMonthSummary.highestSpeed = 0
        
        // Loop through the trips for the summary
        for i in 0..<(firstMonthSummary.toTripHistoryTrips!.count) {
            firstMonthSummary.totalDistance += firstMonthSummary.toTripHistoryTrips![i].distance
            firstMonthSummary.totalDuration += firstMonthSummary.toTripHistoryTrips![i].duration
            if firstMonthSummary.highestSpeed < firstMonthSummary.toTripHistoryTrips![i].maxSpeed {
                firstMonthSummary.highestSpeed = firstMonthSummary.toTripHistoryTrips![i].maxSpeed
            }
        }
        
        /// Set the total this way because it's the count already of trips in the summary.
        firstMonthSummary.totalTrips = firstMonthSummary.toTripHistoryTrips!.count
        
        do {
            try context.save()
            result = true
            LogEvent.print(module: "updateTripHistoryMonthSummary()", message: "Summary for \(datestamp) updated \(firstMonthSummary.totalTrips) trips.")
        } catch {
            LogEvent.print(module: "updateTripHistoryMonthSummary()", message: "Error saving context after copying a trip: \(error)")
        }
        
    } catch {
        LogEvent.print(module: "updateTripHistoryMonthSummary()", message: "An error occurred: \(error)")

    }
    
    
    result = true
    
    LogEvent.print(module: "updateTripHistoryMonthSummary()", message: "... finished")
    return result
}
