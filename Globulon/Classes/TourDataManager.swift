//
//  TourDataManager.swift
//  GeoGato
//
//  Created by David Holeman on 1/19/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import SwiftData

class TourDataManager {
    // structure to return just the metadata
    struct TourMetadata {
        let tour_id: String
        let isActive: Bool
        let application: String
        let version: String
        let created_on: Date
        let updated_on: Date
        let author: String
        let title: String
        let sub_title: String
        let desc: String
    }
    
    // Define a structure to hold the POI data
    struct POIData {
        let id: String
        let order_index: Int
        let title: String
        let sub_title: String
        let desc: String
        let latitude: Double
        let longitude: Double
    }
    
    // Define the JSON Data Model
    struct TourDataJSON: Decodable {
        
        struct metadata: Codable {
            let application: String
            let version: String
            let tour_id: String
            let created_on: String
            let updated_on: String
            let author: String
            let title: String
            let sub_title: String
            let desc: String
        }
        
        struct poi: Decodable {
            let id: String
            let order_index: Int
            let title: String
            let sub_title: String
            let desc: String
            let latitude: Double
            let longitude: Double
        }
        
        let metadata: metadata
        let poi: [poi]
    }
   
    @MainActor
    class func load(source: String, appRelativePath: String? = nil) async -> (Bool, String) {
        LogEvent.print(module: "TourDataManager.load()", message: "▶️ starting...")

        var sourceType: TourFileLocationEnum
        var message: String

        LogEvent.print(module: "TourDataManager.load()", message: "loading \(source)")

        do {
            // Check if the source is a bundled file
            if let bundledFileURL = Bundle.main.url(forResource: source, withExtension: "json") {
                sourceType = .bundle
                //message = "Loading tour data from bundle..."
                try await handleLocalLoading(url: bundledFileURL, from: sourceType)
            }
            
            // Check if the source is a remote URL
            else if let url = URL(string: source), url.scheme == "http" || url.scheme == "https" {
                sourceType = .remote
                //message = "Loading tour data from remote..."
                try await handleRemoteLoading(url: url)
            }
            
            // Check if the file exists in the Documents directory
            else {
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

                // Build the correct file path inside the subdirectory if `appRelativePath` is provided
                let fullFilePath = appRelativePath != nil ?
                    documentsDirectory.appendingPathComponent(appRelativePath!).appendingPathComponent(source) :
                    documentsDirectory.appendingPathComponent(source)

                // Ensure the file exists before trying to load it
                if FileManager.default.fileExists(atPath: fullFilePath.path) {
                    sourceType = .local
                    //message = "Loading tour data from local directory file..."
                    try await handleLocalLoading(url: fullFilePath, from: sourceType)
                } else {
                    message = "Invalid source: Could not locate file or URL."
                    return (false, message)
                }
            }

            //LogEvent.print(module: "TourDataManager.load()", message: message)
            LogEvent.print(module: "TourDataManager.load()", message: "⏹️ ...finished")
            return (true, "Data loaded successfully.")
        } catch {
            LogEvent.print(module: "TourDataManager.load()", message: "❌ Error loading data: \(error.localizedDescription)")
            return (false, "Failed to load data: \(error.localizedDescription)")
        }
    }
//    class func load(source: String) async -> (Bool, String) {
//        LogEvent.print(module: "TourDataManager.load()", message: "▶️ starting...")
//
//        var sourceType: TourFileLocationEnum
//        var message: String
//
//        print(">>> Loading tour data from: \(source)")
//
//        // Extract the file name by stripping ".json" if it exists
//        let fileName = source.hasSuffix(".json") ? String(source.dropLast(5)) : source
//
//        print(">>> File name: \(fileName)")
//
//        do {
//            if let bundledFileURL = Bundle.main.url(forResource: fileName, withExtension: "json") {
//                // Source is a bundled file in the app
//                sourceType = .bundle
//                message = "Loading tour data from bundle..."
//                try await handleLocalLoading(url: bundledFileURL, from: sourceType)
//            } else if let url = URL(string: source), url.scheme == "http" || url.scheme == "https" {
//                // Source is a remote URL
//                sourceType = .remote
//                message = "Loading tour data from remote..."
//                try await handleRemoteLoading(url: url)
//            } else if FileManager.default.fileExists(atPath: fileName) {
//                // Check if the file exists at the provided local directory path
//                let fileURL = URL(fileURLWithPath: fileName)
//                sourceType = .local
//                message = "Loading tour data from local directory file..."
//                try await handleLocalLoading(url: fileURL, from: sourceType)
//            } else {
//                // No valid source found
//                message = "Invalid source: Could not locate file or URL."
//                return (false, message)
//            }
//
//            LogEvent.print(module: "TourDataManager.load()", message: message)
//            LogEvent.print(module: "TourDataManager.load()", message: "⏹️ ...finished")
//            return (true, "Data loaded successfully.")
//        } catch {
//            LogEvent.print(module: "TourDataManager.load()", message: "❌ Error loading data: \(error.localizedDescription)")
//            return (false, "Failed to load data: \(error.localizedDescription)")
//        }
//    }

    /// Handles loading and processing data from a local file or bundle resource
    private class func handleLocalLoading(url: URL, from location: TourFileLocationEnum) async throws {
        //LogEvent.print(module: "TourDataManager.handleLocalLoading()", message: "Loading data from local URL: \(url), location: \(location)")

        do {
            // Load the data directly from the provided URL
            let data = try Data(contentsOf: url)

            // Decode JSON data into models
            let _ = try mapJSONToModels(data: data)

        } catch {
            LogEvent.print(module: "TourDataManager.handleLocalLoading()", message: "Error loading local data: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Handles downloading and processing data from a remote URL
    private class func handleRemoteLoading(url: URL) async throws {
        LogEvent.print(module: "TourDataManager.handleRemoteLoading()", message: "Loading data from remote URL: \(url)")

        do {
            // Download data asynchronously
            let (data, response) = try await URLSession.shared.data(from: url)

            // Check for HTTP response status
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw NSError(domain: "TourDataManagerError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])
            }

            // Decode JSON data into models
            let _ = try mapJSONToModels(data: data)

            LogEvent.print(module: "TourDataManager.handleRemoteLoading()", message: "Remote data successfully loaded.")
        } catch {
            LogEvent.print(module: "TourDataManager.handleRemoteLoading()", message: "Error loading remote data: \(error.localizedDescription)")
            throw error
        }
    }
    
    static func mapJSONToModels(data: Data) throws -> TourData {
        // Decode JSON into intermediate data structures
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601 // Ensure ISO8601 date decoding
        let decodedData = try decoder.decode(TourDataJSON.self, from: data)
        
        // Convert string dates to Date objects
        let createdOnDate = ISO8601DateFormatter().date(from: decodedData.metadata.created_on) ?? Date()
        let updatedOnDate = ISO8601DateFormatter().date(from: decodedData.metadata.updated_on) ?? Date()
        
        
        // Map the decoded data to `TourData`
        let tourData = TourData(
            tour_id: decodedData.metadata.tour_id,
            isActive: false,
            application: decodedData.metadata.application,
            version: decodedData.metadata.version,
            created_on: createdOnDate,
            updated_on: updatedOnDate,
            author: decodedData.metadata.author,
            title: decodedData.metadata.title,
            sub_title: decodedData.metadata.sub_title,
            desc: decodedData.metadata.desc
        )
        
        // Map the POI data and establish relationships
        tourData.toTourPOI = decodedData.poi.enumerated().map { index, poi in
            let poiData = TourPOIData(
                id: poi.id,
                order_index: index,
                title: poi.title,
                sub_title: poi.sub_title,
                desc: poi.desc,
                latitude: poi.latitude,
                longitude: poi.longitude
            )
            poiData.toTourData = tourData // Establish the inverse relationship
            return poiData
        }
        
        // Save the TourData to the shared ModelContext
        let context = ModelContext(SharedModelContainer.shared.container)
        context.insert(tourData)
        
        do {
            try context.save()
            LogEvent.print(module: "TourDataManager.mapJSONToModels()", message: "✅ Saved")
        } catch {
            LogEvent.print(module: "TourDataManager.mapJSONToModels()", message: "❌ Failed: \(error)")
        }
        
        return tourData
    }
    
    // MARK: - Update data
    class func setActiveTour(tourID: String) async {
        
        LogEvent.print(module: "TourDataManager.setActiveTour()", message: "▶️ starting...")
        
        let context = ModelContext(SharedModelContainer.shared.container)
        
        Task {
            do {
                
                // Fetch all `TourData` records
                let fetchDescriptor = FetchDescriptor<TourData>()
                let tours = try context.fetch(fetchDescriptor)
                
                var isTourUpdated = false
                
                // Update the `isActive` flag for all tours
                for tour in tours {
                    if tour.tour_id == tourID {
                        // Set isActive to true for the matching tour
                        tour.isActive = true
                        isTourUpdated = true
                    } else {
                        // Set isActive to false for all other tours
                        tour.isActive = false
                    }
                }
                
                // If no tour matches the tourID, log and exit without saving changes
                if !isTourUpdated {
                    LogEvent.print(module: "TourDataManager.setActiveTour()", message: "❌ No TourData found with ID: \(tourID). No changes made.")
                    return
                }
                // Save the changes
                try context.save()
                
                //AppEnvironment.shared.activeTourID = tourID
                await MainActor.run {
                    AppEnvironment.shared.activeTourID = tourID
                }
                
            } catch {
                LogEvent.print(module: "TourDataManager.setActiveTour()", message: "❌ Failed to update isActive flag: \(error.localizedDescription)")
            }
        }
        LogEvent.print(module: "TourDataManager.setActiveTour()", message: "⏹️ ... finished")
    }
    
    // MARK: - Retrieve specific data items
    
    class func fetchMetadata(for tourID: String) -> TourMetadata? {
        let context = SharedModelContainer.shared.context
        
        do {
            // Create a FetchDescriptor with a predicate to filter by tour_id
            let fetchDescriptor = FetchDescriptor<TourData>()
            
            // Fetch matching TourData
            if let tourData = try context.fetch(fetchDescriptor).first {
                // Map the metadata into the TourMetadata structure
                return TourMetadata(
                    tour_id: tourData.tour_id,
                    isActive: tourData.isActive,
                    application: tourData.application,
                    version: tourData.version,
                    created_on: tourData.created_on,
                    updated_on: tourData.updated_on,
                    author: tourData.author,
                    title: tourData.title,
                    sub_title: tourData.sub_title,
                    desc: tourData.desc
                )
            } else {
                print("❌ No TourData found for tour_id: \(tourID)")
            }
        } catch {
            print("❌ Failed to fetch metadata for tour_id: \(tourID). Error: \(error)")
        }
        
        return nil
    }
    
    class func fetchTourDataPOI(tourID: String, poiID: String) -> POIData? {
        let context = SharedModelContainer.shared.context

        do {
            // Create a FetchDescriptor to get the specific TourData
            let fetchDescriptor = FetchDescriptor<TourData>(
                predicate: #Predicate { $0.tour_id == tourID }
            )
            
            // Fetch the tour with the given tourID
            guard let tourData = try context.fetch(fetchDescriptor).first else {
                LogEvent.print(module: "TourDataManager.fetchTourDataPOI()", message: "❌ No TourData found for tour_id: \(tourID), poiID: \(poiID) ")
                return nil
            }
            
            // Find the specific POI within the TourData
            if let poiData = tourData.toTourPOI?.first(where: { $0.id == poiID }) {
                return POIData(
                    id: poiData.id,
                    order_index: poiData.order_index,
                    title: poiData.title,
                    sub_title: poiData.sub_title,
                    desc: poiData.desc,
                    latitude: poiData.latitude,
                    longitude: poiData.longitude
                )
            } else {
                LogEvent.print(module: "TourDataManager.fetchTourDataPOI()", message: "❌ No POI found with ID: \(poiID) in Tour ID: \(tourID)")
            }
        } catch {
            LogEvent.print(module: "TourDataManager.fetchTourDataPOI()", message: "❌ Failed to fetch POI data: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    // MARK: - Data cleanups and deletions
    
    class func deleteAllTourData() async {
        let context = ModelContext(SharedModelContainer.shared.container)

        do {
            LogEvent.print(module: "TourDataManager.deleteAllTourData()", message: "🔄 Fetching all TourData records for deletion...")

            // Fetch all TourData
            let fetchDescriptor = FetchDescriptor<TourData>()
            let allTourData = try context.fetch(fetchDescriptor)

            // Delete all TourData (this will cascade to TourPOIData)
            for tour in allTourData {
                context.delete(tour)
            }

            // Save the changes
            try context.save()
            LogEvent.print(module: "TourDataManager.deleteAllTourData()", message: "✅ All TourData and associated TourPOIData records successfully deleted.")
        } catch {
            LogEvent.print(module: "TourDataManager.deleteAllTourData()", message: "❌ Failed to delete data: \(error.localizedDescription)")
        }
    }
    
    class func deleteTourDataByID(for tourID: String) async {
        let context = ModelContext(SharedModelContainer.shared.container)

        do {
            LogEvent.print(module: "TourDataManager.deleteTourData()", message: "🔍 Searching for TourData with ID: \(tourID)")

            // Create a FetchDescriptor to find the tour with the given ID
            let fetchDescriptor = FetchDescriptor<TourData>(
                predicate: #Predicate { $0.tour_id == tourID }
            )

            // Fetch the matching TourData record
            let matchingTours = try context.fetch(fetchDescriptor)

            // Check if a matching tour was found
            guard let tourToDelete = matchingTours.first else {
                LogEvent.print(module: "TourDataManager.deleteTourData()", message: "❌ No TourData found with ID: \(tourID). No deletion performed.")
                return
            }
            
            // Perform the deletion
            context.delete(tourToDelete)

            // Save the changes
            try context.save()
            
            LogEvent.print(module: "TourDataManager.deleteTourData()", message: "✅ Successfully deleted TourData with ID: \(tourID)")
        } catch {
            LogEvent.print(module: "TourDataManager.deleteTourData()", message: "❌ Failed to delete TourData: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Print functions
    private class func printTourData(_ tourData: TourData) {
        print("TourData:")
        print("  Tour ID: \(tourData.tour_id)")
        print("  isActive: \(tourData.isActive)")
        print("  Application: \(tourData.application)")
        print("  Version: \(tourData.version)")
        print("  Created On: \(tourData.created_on)")
        print("  Updated On: \(tourData.updated_on)")
        print("  Author: \(tourData.author)")
        print("  Title: \(tourData.title)")
        print("  Subtitle: \(tourData.sub_title)")
        print("  Description: \(tourData.desc)")
        
        if let poiArray = tourData.toTourPOI?.sorted(by: { $0.order_index < $1.order_index }) { // Sort by order_index
            print("  Points of Interest:")
            for poi in poiArray {
                print("    - ID: \(poi.id)")
                print("      Order Index: \(poi.order_index)")
                print("      Title: \(poi.title)")
                print("      Subtitle: \(poi.sub_title)")
                print("      Description: \(poi.desc)")
                print("      Latitude: \(poi.latitude)")
                print("      Longitude: \(poi.longitude)")
            }
        } else {
            print("  No Points of Interest.")
        }
    }
    
    class func printTourDataForAll() {
        let context = ModelContext(SharedModelContainer.shared.container)
        
        Task {
            do {
                LogEvent.print(module: "TourDataManager.printTourDataForAll()", message: "Fetching all TourData from the store...")
                
                // Fetch all TourData records
                let fetchDescriptor = FetchDescriptor<TourData>()
                let savedTourData = try context.fetch(fetchDescriptor)
                
                if savedTourData.isEmpty {
                    print("No TourData records found.")
                    LogEvent.print(module: "TourDataManager.printTourDataForAll()", message: "No TourData records found.")
                    return
                }
                
                for tour in savedTourData {
                    // Print TourData fields
                    print("""
                    TourData:
                      Tour ID: \(tour.tour_id)
                      isActive: \(tour.isActive)
                      Application: \(tour.application)
                      Version: \(tour.version)
                      Created On: \(tour.created_on)
                      Updated On: \(tour.updated_on)
                      Author: \(tour.author)
                      Title: \(tour.title)
                      Subtitle: \(tour.sub_title)
                      Description: \(tour.desc)
                    """)
                    
                    // Print related POIs sorted by order_index
                    if let poiArray = tour.toTourPOI?.sorted(by: { $0.order_index < $1.order_index }) {
                        print("  Points of Interest:")
                        for poi in poiArray {
                            print("""
                              - ID: \(poi.id)
                                Order Index: \(poi.order_index)
                                Title: \(poi.title)
                                Subtitle: \(poi.sub_title)
                                Description: \(poi.desc)
                                Latitude: \(poi.latitude)
                                Longitude: \(poi.longitude)
                            """)
                        }
                    } else {
                        print("  No Points of Interest.")
                    }
                }
            } catch {
                LogEvent.print(module: "TourDataManager.printTourDataForAll()", message: "Failed to fetch TourData: \(error)")
            }
        }
    }
    
    class func printTourDataForID(_ tourID: String) {
        let context = ModelContext(SharedModelContainer.shared.container)
        
        Task {
            do {
                LogEvent.print(module: "TourDataManager.printTourDataForID()", message: "Fetching TourData with ID: \(tourID) from the store...")
                
                // Create a FetchDescriptor with a predicate for the specific tour_id
                // Create a FetchDescriptor with a predicate for the specific tour_id
                let fetchDescriptor = FetchDescriptor<TourData>(
                    predicate: #Predicate { $0.tour_id == tourID }
                )
                let matchingTourData = try context.fetch(fetchDescriptor)
                
                if matchingTourData.isEmpty {
                    LogEvent.print(module: "TourDataManager.printTourDataForID()", message: "No TourData records found with ID: \(tourID).")
                    return
                }
                
                for tour in matchingTourData {
                    // Print TourData fields
                    print("""
                    TourData:
                      Tour ID: \(tour.tour_id)
                      isActive: \(tour.isActive)
                      Application: \(tour.application)
                      Version: \(tour.version)
                      Created On: \(tour.created_on)
                      Updated On: \(tour.updated_on)
                      Author: \(tour.author)
                      Title: \(tour.title)
                      Subtitle: \(tour.sub_title)
                      Description: \(tour.desc)
                    """)
                    
                    // Print related POIs sorted by order_index
                    if let poiArray = tour.toTourPOI?.sorted(by: { $0.order_index < $1.order_index }) {
                        print("  Points of Interest:")
                        for poi in poiArray {
                            print("""
                              - ID: \(poi.id)
                                Order Index: \(poi.order_index)
                                Title: \(poi.title)
                                Subtitle: \(poi.sub_title)
                                Description: \(poi.desc)
                                Latitude: \(poi.latitude)
                                Longitude: \(poi.longitude)
                            """)
                        }
                    } else {
                        print("  No Points of Interest.")
                    }
                }
            } catch {
                LogEvent.print(module: "TourDataManager.printTourDataForID()", message: "Failed to fetch TourData with ID \(tourID): \(error)")
            }
        }
    }
}
