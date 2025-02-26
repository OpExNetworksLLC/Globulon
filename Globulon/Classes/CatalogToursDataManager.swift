//
//  CatalogToursDataManager.swift
//  Globulon
//
//  Created by David Holeman on 02/02/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import SwiftData

class CatalogToursDataManager {
    
    // Define the JSON Data Model
    struct CatalogToursDataJSON: Decodable {
        
        struct metadata: Codable {
            let application: String
            let version: String
            let catalog_id: String
            let created_on: String
            let updated_on: String
            let author: String
            let title: String
            let sub_title: String
            let desc: String
        }
        
        struct tours: Decodable {
            let tour_id: String
            let tour_file: String
            let tour_directory: String
            let order_index: Int
            let title: String
            let sub_title: String
            let desc: String
            
        }
        
        let metadata: metadata
        let tours: [tours]
    }
    
    @MainActor
    class func load(source: String) async -> (Bool, String) {
        LogEvent.print(module: "CatalogToursDataManager.load()", message: "▶️ starting...")
        
        var sourceType: TourFileLocationEnum
        var message: String
        
        // Extract the file name by stripping ".json" if it exists
        let filename = source.hasSuffix(".json") ? String(source.dropLast(5)) : source
        
        do {
            if let bundledFileURL = Bundle.main.url(forResource: filename, withExtension: "json") {
                // Source is a bundled file in the app
                sourceType = .bundle
                message = "Loading tour data from bundle..."
                try await handleLocalLoading(url: bundledFileURL, from: sourceType)
            } else if let url = URL(string: source), url.scheme == "http" || url.scheme == "https" {
                // Source is a remote URL
                sourceType = .remote
                message = "Loading tour data from remote..."
                try await handleRemoteLoading(url: url)
            } else if FileManager.default.fileExists(atPath: filename) {
                // Check if the file exists at the provided local directory path
                let fileURL = URL(fileURLWithPath: filename)
                sourceType = .local
                message = "Loading tour data from local directory file..."
                try await handleLocalLoading(url: fileURL, from: sourceType)
            } else {
                // No valid source found
                message = "Invalid source: Could not locate file or URL."
                return (false, message)
            }
            
            LogEvent.print(module: "CatalogToursDataManager.load()", message: message)
            LogEvent.print(module: "CatalogToursDataManager..load()", message: "⏹️ ...finished")
            return (true, "Data loaded successfully.")
        } catch {
            LogEvent.print(module: "CatalogToursDataManager.load()", message: "❌ Error loading data: \(error.localizedDescription)")
            return (false, "Failed to load data: \(error.localizedDescription)")
        }
    }
    
    private class func handleLocalLoading(url: URL, from location: TourFileLocationEnum) async throws {
        LogEvent.print(module: "CatalogToursDataManager.handleLocalLoading()", message: "Loading data from local URL: \(url), location: \(location)")
        
        do {
            // Load the data directly from the provided URL
            let data = try Data(contentsOf: url)
            
            // Decode JSON data into models
            let _ = try mapJSONToModels(data: data)
            
            //            await MainActor.run {
            //                AppEnvironment.shared.catalogToursCache.append(result)
            //            }
            
            LogEvent.print(module: "CatalogToursDataManager.handleLocalLoading()", message: "Local data successfully loaded.")
        } catch {
            LogEvent.print(module: "CatalogToursDataManager.handleLocalLoading()", message: "Error loading local data: \(error.localizedDescription)")
            throw error
        }
    }
    
    private class func handleRemoteLoading(url: URL) async throws {
        LogEvent.print(module: "CatalogToursDataManager.handleRemoteLoading()", message: "Loading data from remote URL: \(url)")
        
        do {
            // Download data asynchronously
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Check for HTTP response status
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw NSError(domain: "TourDataManagerError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])
            }
            
            // Decode JSON data into models
            let _ = try mapJSONToModels(data: data)
            
            LogEvent.print(module: "CatalogToursDataManager.handleRemoteLoading()", message: "Remote data successfully loaded.")
        } catch {
            LogEvent.print(module: "CatalogToursDataManager.handleRemoteLoading()", message: "Error loading remote data: \(error.localizedDescription)")
            throw error
        }
    }
    
    static func mapJSONToModels(data: Data) throws -> CatalogToursData {
        // Decode JSON into intermediate data structures
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601 // Ensure ISO8601 date decoding
        let decodedData = try decoder.decode(CatalogToursDataJSON.self, from: data)
        
        // Convert string dates to Date objects
        let createdOnDate = ISO8601DateFormatter().date(from: decodedData.metadata.created_on) ?? Date()
        let updatedOnDate = ISO8601DateFormatter().date(from: decodedData.metadata.updated_on) ?? Date()
        
        
        // Map the decoded data to `TourData`
        let catalogToursData = CatalogToursData(
            catalog_id: decodedData.metadata.catalog_id,
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
        
        // Map the tour data and establish relationships
        catalogToursData.toCatalogTour = decodedData.tours.enumerated().map { index, tour in
            let catalogTourData = CatalogTourData(
                tour_id: tour.tour_id,
                isActive: false,
                tour_file: tour.tour_file,
                tour_directory: tour.tour_directory,
                order_index: index,
                title: tour.title,
                sub_title: tour.sub_title,
                desc: tour.desc
            )
            catalogTourData.toCatalogTours = catalogToursData // Establish the inverse relationship
            return catalogTourData
        }
        
        
        // Save the TourData to the shared ModelContext
        let context = ModelContext(SharedModelContainer.shared.container)
        context.insert(catalogToursData)
        
        do {
            /// OPTION: Uncomment to save in the persistent data store
            try context.save()
            print("TourData successfully saved.")
        } catch {
            print("Failed to save TourData: \(error)")
        }
        
        // Update the `catalogToursCache` in AppEnvironment
        Task { @MainActor in
            AppEnvironment.shared.catalogToursCache.append(catalogToursData)
        }
        return catalogToursData
    }
    
    private class func printCatalogToursData(_ tourData: CatalogToursData) {
        print("CatalogToursData:")
        print("  Catalog ID: \(tourData.catalog_id)")
        print("  isActive: \(tourData.isActive)")
        print("  Application: \(tourData.application)")
        print("  Version: \(tourData.version)")
        print("  Created On: \(tourData.created_on)")
        print("  Updated On: \(tourData.updated_on)")
        print("  Author: \(tourData.author)")
        print("  Title: \(tourData.title)")
        print("  Subtitle: \(tourData.sub_title)")
        print("  Description: \(tourData.desc)")
        
        // Access related tours (CatalogTourData) via `toCatalogTour`
        if let toursArray = tourData.toCatalogTour?.sorted(by: { $0.order_index < $1.order_index }) { // Sort by order_index
            print("  Tours:")
            for tour in toursArray {
                print("    - ID: \(tour.tour_id)")
                print("      File: \(tour.tour_file)")
                print("      Order Index: \(tour.order_index)")
                print("      Title: \(tour.title)")
                print("      Subtitle: \(tour.sub_title)")
                print("      Description: \(tour.desc)")
            }
        } else {
            print("  No Tours found.")
        }
    }
    
    class func printTourDataForAll() async {
        let context = ModelContext(SharedModelContainer.shared.container)
        
        do {
            LogEvent.print(module: "CatalogToursDataManager.printTourDataForAll()", message: "🔄 Fetching all CatalogToursData from the store...")
            
            // Fetch all CatalogToursData records
            let fetchDescriptor = FetchDescriptor<CatalogToursData>()
            let savedCatalogData = try context.fetch(fetchDescriptor)
            
            if savedCatalogData.isEmpty {
                LogEvent.print(module: "CatalogToursDataManager.printTourDataForAll()", message: "No CatalogToursData records found.")
                return
            }
            
            for catalog in savedCatalogData {
                // Print CatalogToursData fields
                print("""
                CatalogToursData:
                  Catalog ID: \(catalog.catalog_id)
                  isActive: \(catalog.isActive)
                  Application: \(catalog.application)
                  Version: \(catalog.version)
                  Created On: \(catalog.created_on)
                  Updated On: \(catalog.updated_on)
                  Author: \(catalog.author)
                  Title: \(catalog.title)
                  Subtitle: \(catalog.sub_title)
                  Description: \(catalog.desc)
                """)
                
                // Print related tours sorted by order_index
                if let tourArray = catalog.toCatalogTour?.sorted(by: { $0.order_index < $1.order_index }) {
                    print("  Tours:")
                    for tour in tourArray {
                        print("""
                          - Tour ID: \(tour.tour_id)
                            isActive: \(tour.isActive)
                            File: \(tour.tour_file)
                            Order Index: \(tour.order_index)
                            Title: \(tour.title)
                            Subtitle: \(tour.sub_title)
                            Description: \(tour.desc)
                        """)
                    }
                } else {
                    print("  No Tours found.")
                }
            }
        } catch {
            LogEvent.print(module: "CatalogToursDataManager.printTourDataForAll()", message: "Failed to fetch CatalogToursData: \(error)")
        }
    }
    
    // MARK: - Data cleanups and deletions
    
    class func deleteAllTourData() async {
        LogEvent.print(module: "CatalogToursDataManager.deleteAllTourData()", message: "▶️ Starting...")
        
        let context = ModelContext(SharedModelContainer.shared.container)
        
        do {
            LogEvent.print(module: "CatalogToursDataManager.deleteAllTourData()", message: "🔄 Fetching all records for deletion...")
            
            // Fetch all TourData
            let fetchDescriptor = FetchDescriptor<CatalogToursData>()
            let allCatalogData = try context.fetch(fetchDescriptor)
            
            // Delete all TourData (this will cascade to TourPOIData)
            for tour in allCatalogData {
                context.delete(tour)
            }
            
            // Save the changes
            try context.save()
            LogEvent.print(module: "CatalogToursDataManager.deleteAllTourData()", message: "✅ All records successfully deleted.")
            LogEvent.print(module: "CatalogToursDataManager.deleteAllTourData()", message: "⏹️ ... finished")
        } catch {
            LogEvent.print(module: "CatalogToursDataManager.deleteAllTourData()", message: "❌ Failed to delete data: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Download tour files
    
    /// Downloads all files from a given HTTPS directory and saves them to the app's Documents Directory.
    ///
    static func downloadFiles(from website: String) async {
        guard let baseURL = URL(string: website) else {
            print("❌ Invalid URL: \(website)")
            return
        }
        
        do {
            let filenames = try await fetchFileList(from: baseURL)
            
            print(">>>filenames to download: \(filenames)")
            
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            
            await withTaskGroup(of: Void.self) { group in
                for filename in filenames {
                    group.addTask {
                        let fileURL = baseURL.appendingPathComponent(filename)
                        let destinationURL = documentsDirectory.appendingPathComponent(filename)
                        
                        do {
                            try await downloadFile(from: fileURL, to: destinationURL)
                            print("✅ Downloaded: \(filename) → \(destinationURL.path)")
                        } catch {
                            print("❌ Failed to download \(filename): \(error.localizedDescription)")
                        }
                    }
                }
            }
        } catch {
            print("❌ Error: \(error.localizedDescription)")
        }
    }
    
    static func fetchFileList(from url: URL) async throws -> [String] {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let responseString = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeRawData)
        }
        return responseString.components(separatedBy: "\n").filter { !$0.isEmpty }
    }
    
    static func downloadFile(from url: URL, to destination: URL) async throws {
        let (tempURL, _) = try await URLSession.shared.download(from: url)
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.moveItem(at: tempURL, to: destination)
    }

}
