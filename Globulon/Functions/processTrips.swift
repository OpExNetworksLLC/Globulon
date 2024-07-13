//
//  processTrips.swift
//  ViDrive
//
//  Created by David Holeman on 7/11/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import SwiftData
import MapKit

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
            
            //var tripMapData: Data?
            
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
                                tripMap: nil,
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
                            
                            // Initialize min and max values
                            var minLatitude =  tripGpsWorkspace[0].latitude
                            var maxLatitude = tripGpsWorkspace[0].latitude
                            var minLongitude = tripGpsWorkspace[0].longitude
                            var maxLongitude = tripGpsWorkspace[0].longitude
                            
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
                                
                                /// Find the min and max latitude and longitude
                                if tripData.latitude < minLatitude {
                                    minLatitude = tripData.latitude
                                }
                                if tripData.latitude > maxLatitude {
                                    maxLatitude = tripData.latitude
                                }
                                if tripData.longitude < minLongitude {
                                    minLongitude = tripData.longitude
                                }
                                if tripData.longitude > maxLongitude {
                                    maxLongitude = tripData.longitude
                                }
                                
                                
                                /// Find the max speed
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
                                                        
                            /// Calculate the center point
                            ///
                            let centerLatitude = (minLatitude + maxLatitude) / 2
                            let centerLongitude = (minLongitude + maxLongitude) / 2
                            //let center = CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
                            
                            /// Calculate the span with 10% padding
                            ///
                            let latitudeDelta = (maxLatitude - minLatitude) * 1.4
                            let longitudeDelta = (maxLongitude - minLongitude) * 1.4
                            
                            let region = MKCoordinateRegion(
                                center: CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude),
                                span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
                            )
                            
                            let size = CGSize(width: 300, height: 200)  //430x430
                    
                            newTrip.tripMap = convertImageToData(image: generateTripImage(region: region, trip: newTrip, size: size)!)
                            
                            /*
                            var tripMapData: Data?
                            generateMapImage(region: region, trip: newTrip, size: size) { image in
                                if let image = image {
                                    // Do something with the image, e.g., save it to Photos or display it in an UIImageView
                                    print("Map image generated successfully")
                                    
                                    if let imageData = convertImageToData(image: image) {
                                        //newTrip.tripMap = imageData
                                        tripMapData = imageData
                                    }
                                    saveImageToPNG(image)
                                } else {
                                    tripMapData = nil
                                    print("Failed to generate map image")
                                }
                            }
                            */
                            
                            /*
                            var tripMapData: Data?
                            let dispatchGroup = DispatchGroup()
                            dispatchGroup.enter()
                            processMapImage(region: region, trip: newTrip, size: size) { imageData in
                                tripMapData = imageData
                                dispatchGroup.leave()
                            }
                            dispatchGroup.notify(queue: .main) {
                                if let tripMapData = tripMapData {
                                    // Handle the updated imageData here
                                    print("Image data received: \(tripMapData)")
                                    newTrip.tripMap = tripMapData
                                } else {
                                    print("Failed to generate or convert map image to data")
                                }
                            }
                            */
                            
                            /*
                            var tripMapData: Data?
                            processTripMap(region: region, trip: newTrip, size: size) { imageData in
                                if let data = imageData {
                                    newTrip.tripMap = data
                                } else {
                                    print("Failed to set tripMapData")
                                }
                            }
                            */
                            
                            /*
                            processMapImage(region: region, trip: newTrip, size: size) { imageData in
                                DispatchQueue.main.async {
                                    if let data = imageData {
                                        print("Image data received: \(data)")
                                        newTrip.tripMap = data
                                        /// Save context if using a managed object context
                                        do {
                                            try context.save()
                                            print("Context successfully saved.")
                                        } catch {
                                            print("Failed to save context: \(error)")
                                        }
                                    } else {
                                        print("Failed to set tripMapData")
                                    }
                                }
                            }
                            */
                            
                            // ... end stuff
                            
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
