//
//  processTrips.swift
//  ViDrive
//
//  Created by David Holeman on 3/1/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import SwiftData


func processTrips() async {
    LogEvent.print(module: "processTrips()", message: "starting...")
    
    do {
        guard let container = AppEnvironment.sharedModelContainer else {
            LogEvent.print(module: "processTrips()", message: "container is nil")
            return
        }
        let context = ModelContext(container)
        
        /// Fetch all the raw GPS data
        do {

            
            /// Fetch trips that have not been processed
            let fetchDescriptor = FetchDescriptor<GpsJournalSD>(
                predicate: #Predicate { $0.processed == false }
            )
            
            /// Fetch all location data
            //let gpsJournalSD = try context.fetch(FetchDescriptor<GpsJournalSD>())
            let gpsJournalSD = try context.fetch(fetchDescriptor)
            
            /// Is there any data and if not return out
            guard !gpsJournalSD.isEmpty else {
                LogEvent.print(module: "processTrips()", message: "No trip gps data available")
                return
            }
            
            /// Sort has to happen after the fetch on the result
            let sortedGpsJournal = gpsJournalSD.sorted { $0.timestamp < $1.timestamp }
                        
            /// Setup an array to store the extracted gpsJournalSD into a a tripGpsWorkspace array
            var tripGpsWorkspace: [GpsJournalSD] = []
            tripGpsWorkspace.sort { $0.timestamp < $1.timestamp }
            
            /// Set values before looping through the data
            let tripSeparator = UserSettings.init().trackingTripSeparator
            let tripEntriesMin = UserSettings.init().trackingTripEntriesMin
            var tripGpsEntriesIndex = 0
            var tripCount = 0
            
            /// Cycle through the raw data and build the trips
            for i in 1..<sortedGpsJournal.count {
                                
                let previousLocation = sortedGpsJournal[i - 1]
                let currentLocation = sortedGpsJournal[i]
                
                /// Override processed settings and reprocess 
                if UserSettings.init().isTripReprocessingAllowed {
                    previousLocation.processed = false
                    currentLocation.processed = false
                }

                /// Only process data that has not been processed yet.
                if previousLocation.processed == false {
                    
                    let timeDifference = Calendar.current.dateComponents([.second], from: previousLocation.timestamp, to: currentLocation.timestamp).second ?? 0
                    
                    let entry = GpsJournalSD(
                        timestamp: previousLocation.timestamp,
                        longitude: previousLocation.longitude,
                        latitude: previousLocation.latitude,
                        speed: previousLocation.speed,
                        processed: previousLocation.processed,
                        code: previousLocation.code,
                        note: previousLocation.note
                    )
                    tripGpsWorkspace.append(entry)
                    previousLocation.processed = true
                    
                    tripGpsEntriesIndex += 1
                    
                    /// If the time difference is greater than the trip separator or we are at the end of the data.
                    if timeDifference > tripSeparator {
                        
                        /// New trip detected
                        tripGpsEntriesIndex = 0
                        
                    } else if i == sortedGpsJournal.count - 1 {
                        
                        /// We are at the end of the last trip in the data
                        let entry = GpsJournalSD(
                            timestamp: currentLocation.timestamp,
                            longitude: currentLocation.longitude,
                            latitude: currentLocation.latitude,
                            speed: currentLocation.speed,
                            processed: currentLocation.processed,
                            code: currentLocation.code,
                            note: currentLocation.note
                        )
                        tripGpsWorkspace.append(entry)
                        
                        /// Mark the data as processed
                        currentLocation.processed = true
                        
                        /// Reset the index
                        tripGpsEntriesIndex = 0
                    }
                    
                    if tripGpsEntriesIndex == 0 {
                        
                        /// Process the workspace if the count meets the minimum threshold for trip entries
                        if tripGpsWorkspace.count >= tripEntriesMin {
                            let entryStart = 0
                            let entryFinish = tripGpsWorkspace.count - 1
                            
                            let originationAddress = await Address.getShortAddressFromLatLon(latitude: tripGpsWorkspace[entryStart].latitude, longitude: tripGpsWorkspace[entryStart].longitude)
                            let destinationAddress = await Address.getShortAddressFromLatLon(latitude: tripGpsWorkspace[entryFinish].latitude, longitude: tripGpsWorkspace[entryFinish].longitude)
                            let duration = Double(Calendar.current.dateComponents([.minute], from: tripGpsWorkspace[entryStart].timestamp, to: tripGpsWorkspace[entryFinish].timestamp).minute!)
                            
                            /// Set an initial distiance by air
                            var distance = 0.0
                            
                            /// Create the trip summary
                            let newTrip = TripSummariesSD(
                                originationTimestamp: tripGpsWorkspace[entryStart].timestamp,
                                originationLatitude: tripGpsWorkspace[entryStart].latitude,
                                originationLongitude: tripGpsWorkspace[entryStart].longitude,
                                originationAddress: originationAddress,
                                destinationTimestamp: tripGpsWorkspace[entryFinish].timestamp,
                                destinationLatitude: tripGpsWorkspace[entryFinish].latitude,
                                destinationLongitude: tripGpsWorkspace[entryFinish].longitude,
                                destinationAddress: destinationAddress,
                                maxSpeed: 0.0,
                                duration: duration,
                                distance: distance,
                                scoreAcceleration: 0.0,
                                scoreDeceleration: 0.0,
                                scoreSmoothness: 0.0,
                                archived: false
                            )
                            
                            /// Save the new trip
                            context.insert(newTrip)
                            
                            /// Reset so we we can calculate a more accurate distance
                            var lastLatitude = 0.0
                            var lastLongitude = 0.0
                            
                            /// Add the detail
                            for i in 0..<tripGpsWorkspace.count {
                                
                                let tripData = TripJournalSD(
                                    timestamp: tripGpsWorkspace[i].timestamp,
                                    longitude: tripGpsWorkspace[i].longitude,
                                    latitude: tripGpsWorkspace[i].latitude,
                                    speed: tripGpsWorkspace[i].speed,
                                    code: tripGpsWorkspace[i].code,
                                    note: tripGpsWorkspace[i].note
                                )
                                
                                if tripData.speed > newTrip.maxSpeed {
                                    newTrip.maxSpeed = tripData.speed
                                }
                                
                                /// Start with same location
                                if i == 0 {
                                    lastLatitude = tripData.latitude
                                    lastLongitude = tripData.longitude
                                }
                                
                                distance += haversineDistance(lat1: lastLatitude, lon1: lastLongitude, lat2: tripGpsWorkspace[i].latitude, lon2: tripGpsWorkspace[i].longitude)
                                
                                /// Save the last location
                                lastLatitude = tripData.latitude
                                lastLongitude = tripData.longitude
                                
                                /// Save the total distance once we get to the end of the data
                                if i == tripGpsWorkspace.count - 1 {
                                    newTrip.distance = distance
                                }
                                
                                // Validated that adding in order
                                //print("adding data to trip\(newTrip.originationTimestamp): \(tripData.timestamp)")
                                
                                /// Associate trip data with the trip and save
                                tripData.toTripSummaries = newTrip
                                context.insert(tripData)
                            }
                            
                            /// Do the scoring (and/or do later)
                            ///
                            newTrip.scoreSmoothness = scoreTripSmoothness(tripGpsWorkspace)
                            newTrip.scoreAcceleration = scoreTripAcceleration(tripGpsWorkspace)
                            newTrip.scoreDeceleration = scoreTripDeceleration(tripGpsWorkspace)
                            
                            tripCount += 1
                            LogEvent.print(module: "processTrips()", message: "Processing trip for \(newTrip.originationTimestamp)...")
                            
                        }
                        
                        /// clear the workspace for the next trip
                        tripGpsWorkspace.removeAll()
                    }
                }
            }
            do {
                try context.save()
                LogEvent.print(module: "processTrips()", message: "Trip summaries created: \(tripCount)")
                
                
            } catch {
                LogEvent.print(module: "processTrips()", message: "Failed to save trip data: \(error)")
                throw error
            }
            
        } catch {
            LogEvent.print(module: "processTrips()", message: "An error occured access: \(error)")
        }
        
        LogEvent.print(module: "processTrips()", message: "...finished")
        
    }
    

}
