//
//  copyTripToHistorySummarySD.swift
//  ViDrive
//
//  Created by David Holeman on 5/5/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import SwiftData

/// Copy a trip based on trip date from the TripSummariesSD  to TripHistorySummarySD
///
func copyTripToHistorySummarySD(tripTimestamp: Date) -> Bool {
    LogEvent.print(module: "copyTripToHistorySummarySD()", message: "starting ...")
    
    let context = ModelContext(AppEnvironment.sharedModelContainer)
    
    var result = false
    
    do {
        
        /// Define a fetch descriptor that sorts the entries by timestamp in ascending order
        let fetchDescriptor = FetchDescriptor<TripSummariesSD>(sortBy: [SortDescriptor(\TripSummariesSD.originationTimestamp, order: .forward)])
        
        /// Fetch all entries from the context
        let tripSummariesSD = try context.fetch(fetchDescriptor)
        
        /// Find the first trip that matches the tripTimestamp
        let firstFilteredSummaries = tripSummariesSD.first { tripSummary in
            return tripSummary.originationTimestamp == tripTimestamp
        }
        
        /// Check if the filtered trip is found, else log an error and exit because there's nothing to add
        ///
        guard let firstSummaries = firstFilteredSummaries else {
            LogEvent.print(module: "copyTripToHistorySummarySD()", message: "No trip found for date: \(firstFilteredSummaries?.originationTimestamp ?? Date())")
            return false
        }
        
        /// Define a fetch descriptor that sorts the entries by timestamp in ascending order
        let fetchDescriptor2 = FetchDescriptor<TripHistorySummarySD>(sortBy: [SortDescriptor(\TripHistorySummarySD.datestamp, order: .forward)])
        
        /// Fetch all entries from the context
        let tripHistorySummarySD = try context.fetch(fetchDescriptor2)
        
        let firstFilteredTripHistorySummary = tripHistorySummarySD.first { tripSummary in
            return tripSummary.datestamp == formatDateYearMonth(tripTimestamp)
        }
        
        /// Frist trip for the month so create the summary and add the trip
        ///
        guard firstFilteredTripHistorySummary != nil else {
            /// Summary does not exist
            ///
            let newTripHistorySummary = TripHistorySummarySD(
                datestamp: formatDateYearMonth(firstSummaries.originationTimestamp),
                highestSpeed: firstSummaries.maxSpeed,
                totalDistance: firstSummaries.distance,
                totalDuration: firstSummaries.duration,
                totalTrips: 1,  // first trip
                totalSmoothness: firstSummaries.scoreSmoothness,
                totalAccleration: firstSummaries.scoreAcceleration,
                totalDeceleration: firstSummaries.scoreDeceleration,
                totalDistractions: 0.0
            )
            
            let newTripSummary = TripHistoryTripsSD(
                originationTimestamp: firstSummaries.originationTimestamp,
                originationLatitude: firstSummaries.originationLatitude,
                originationLongitude: firstSummaries.originationLongitude,
                originationAddress: firstSummaries.originationAddress,
                destinationTimestamp: firstSummaries.originationTimestamp,
                destinationLatitude: firstSummaries.destinationLatitude,
                destinationLongitude: firstSummaries.destinationLongitude,
                destinationAddress: firstSummaries.destinationAddress,
                maxSpeed: firstSummaries.maxSpeed,
                duration: firstSummaries.duration,
                distance: firstSummaries.distance,
                scoreAcceleration: firstSummaries.scoreAcceleration,
                scoreDeceleration: firstSummaries.scoreDeceleration,
                scoreSmoothness: firstSummaries.scoreSmoothness
            )
            
            newTripSummary.toTripSummary = newTripHistorySummary
            
            context.insert(newTripHistorySummary)
            context.insert(newTripSummary)
            
            /// Add the trip journal data to the trip summary
            ///
            for i in 0..<firstSummaries.toTripJournal!.count {
                let newTripJournal = TripHistoryTripJournalSD(
                    timestamp: firstSummaries.toTripJournal![i].timestamp,
                    longitude: firstSummaries.toTripJournal![i].longitude,
                    latitude: firstSummaries.toTripJournal![i].latitude,
                    speed: firstSummaries.toTripJournal![i].speed,
                    code: firstSummaries.toTripJournal![i].code,
                    note: firstSummaries.toTripJournal![i].note
                )
                
                /// Associate trip data with the trip and save
                newTripJournal.toTripHistoryTrips = newTripSummary
                context.insert(newTripSummary)
            }
            
            firstSummaries.archived = true
            
            do {
                try context.save()
                result = true
                LogEvent.print(module: "copyTripToHistorySummarySD()", message: "Created new month summary for \(newTripHistorySummary.datestamp)")
                LogEvent.print(module: "copyTripToHistorySummarySD()", message: "Copied trip dated \( formatDateShortUS(firstSummaries.originationTimestamp))")
                LogEvent.print(module: "copyTripToHistorySummarySD()", message: "... finished")
            } catch {
                LogEvent.print(module: "copyTripToHistorySummarySD()", message: "Error saving context after copying a trip: \(error)")
            }
            
            return true
        }
        
        /// Check here to see if the trip exists already.
        ///
        for i in 0..<(firstFilteredTripHistorySummary?.toTripHistoryTrips?.count)! {
            if firstFilteredTripHistorySummary?.toTripHistoryTrips![i].originationTimestamp == tripTimestamp {
                print("** trip exists: \(tripTimestamp)")
            }
        }
        
        var isTripSaved: Bool {
            result = false
            for i in 0..<(firstFilteredTripHistorySummary?.toTripHistoryTrips?.count)! {
                if firstFilteredTripHistorySummary?.toTripHistoryTrips![i].originationTimestamp == tripTimestamp {
                    result = true
                }
            }
            return result
        }
        
        /// From here we now add the trips for the month
        ///
        let newTripSummary = TripHistoryTripsSD(
            originationTimestamp: firstSummaries.originationTimestamp,
            originationLatitude: firstSummaries.originationLatitude,
            originationLongitude: firstSummaries.originationLongitude,
            originationAddress: firstSummaries.originationAddress,
            destinationTimestamp: firstSummaries.originationTimestamp,
            destinationLatitude: firstSummaries.destinationLatitude,
            destinationLongitude: firstSummaries.destinationLongitude,
            destinationAddress: firstSummaries.destinationAddress,
            maxSpeed: firstSummaries.maxSpeed,
            duration: firstSummaries.duration,
            distance: firstSummaries.distance,
            scoreAcceleration: firstSummaries.scoreAcceleration,
            scoreDeceleration: firstSummaries.scoreDeceleration,
            scoreSmoothness: firstSummaries.scoreSmoothness
        )
        
        /// Link trip back up to the summary
        newTripSummary.toTripSummary = firstFilteredTripHistorySummary
        //newTripSummary.toTripSummary?.totalTrips += 1
        
        context.insert(newTripSummary)
        
        /// Add the trip journal data to the trip summary
        ///
        for i in 0..<firstSummaries.toTripJournal!.count {
            let newTripJournal = TripHistoryTripJournalSD(
                timestamp: firstSummaries.toTripJournal![i].timestamp,
                longitude: firstSummaries.toTripJournal![i].longitude,
                latitude: firstSummaries.toTripJournal![i].latitude,
                speed: firstSummaries.toTripJournal![i].speed,
                code: firstSummaries.toTripJournal![i].code,
                note: firstSummaries.toTripJournal![i].note
            )
            
            /// Associate trip data with the trip and save
            newTripJournal.toTripHistoryTrips = newTripSummary
            context.insert(newTripSummary)
        }
        
        firstSummaries.archived = true
        
        do {
            try context.save()
            result = true
            LogEvent.print(module: "copyTripToHistorySummarySD()", message: "Copied trip dated \( formatDateShortUS(firstSummaries.originationTimestamp))")
            
            /// Update the trip history summer after the trip has been saved.  Important to update here so we have the latest in the monthly summary
            ///
            _ = updateTripHistoryMonthSummary(datestamp: firstFilteredTripHistorySummary!.datestamp)
            
        } catch {
            LogEvent.print(module: "copyTripToHistorySummarySD()", message: "Error saving context after copying a trip: \(error)")
        }
    } catch {
        LogEvent.print(module: "copyTripToHistorySummarySD()", message: "An error occurred: \(error)")
    }
    
    LogEvent.print(module: "copyTripToHistorySummarySD()", message: "... finished")
    
    return result
}

//MARK: code suggestions
//
/// Check here to see if the trip exists already.
///
//for i in 0..<(firstFilteredTripHistorySummary?.toTripHistoryTrips?.count)! {
//    if firstFilteredTripHistorySummary?.toTripHistoryTrips![i].originationTimestamp == tripTimestamp {
//        print("** trip exists: \(tripTimestamp)")
//    }
//}
//
//var isTripSaved: Bool {
//    result = false
//    for i in 0..<(firstFilteredTripHistorySummary?.toTripHistoryTrips?.count)! {
//        if firstFilteredTripHistorySummary?.toTripHistoryTrips![i].originationTimestamp == tripTimestamp {
//            result = true
//        }
//    }
//    return result
//}
