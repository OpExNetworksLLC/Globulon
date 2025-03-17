//
//  SharedModelContainer.swift
//  Globulon
//
//  Created by David Holeman on 2/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

/**
- Version: 1.0.0 (2025-02-26)
- Note:
 */

import Foundation
import SwiftData
import Combine


typealias HelpSection = ModelSchemaV1.HelpSection
typealias HelpArticle = ModelSchemaV1.HelpArticle
typealias GPSData = ModelSchemaV1.GPSData

protocol VersionedSchema {
    static var versionIdentifier: Schema.Version { get }
    static var models: [any PersistentModel.Type] { get }
}

import Foundation

class SharedModelContainer: @unchecked Sendable {
    static let shared = SharedModelContainer()

    var container: ModelContainer
    var context: ModelContext
    
    private let accessQueue = DispatchQueue(label: "com." + AppSettings.appName + ".SharedModelContainerQueue", attributes: .concurrent)
    
    private init() {
        do {
            
            LogEvent.print(module: "SharedModelContainer()", message: "▶️ starting...")
            
            // Step 1: Use a temporary container to locate and reset the persistent store
            let tempSchema = Schema(SharedModelContainer.getCurrentSchema().models)
            let tempContainer = try ModelContainer(
                for: tempSchema,
                configurations: [ModelConfiguration(schema: tempSchema, isStoredInMemoryOnly: false)]
            )
            
            /// Set the parameter startFresh = true if you want to reset.
            try SharedModelContainer.resetPersistentStoreIfNeeded(startFresh: false, container: tempContainer)

            // Step 2: Define the main schema
            let currentSchema = SharedModelContainer.getCurrentSchema()
            let schema = Schema(currentSchema.models)

            // Step 3: Initialize the main container
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            context = ModelContext(container)
            
            // Step 4:
            //try applyMigrations()

            LogEvent.print(module: "SharedModelContainer()", message: "⏹️ ...finished")

        } catch {
            LogEvent.print(module: "SharedModelContainer()", message: "Could not initialize SharedModelContainer: \(error)")
            fatalError("Could not initialize SharedModelContainer: \(error)")

        }
    }

    private static func getPersistentStoreURL(container: ModelContainer?) -> URL {
        if let container = container, let url = container.configurations.first?.url {
            return url
        }
        // Default fallback if the container isn't initialized
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("default.store")
    }
    
    static func resetPersistentStoreIfNeeded(startFresh: Bool, container: ModelContainer? = nil) throws {
        guard startFresh else { return }

        let fileManager = FileManager.default
        let storeURL = getPersistentStoreURL(container: container)

        LogEvent.print(module: "SharedModelContainer.resetPersistentStoreIfNeeded()", message: "Resetting persistent store files located at: \(storeURL.deletingLastPathComponent().path)")

        let relatedFiles = [
            storeURL,
            storeURL.appendingPathExtension("shm"),
            storeURL.appendingPathExtension("wal")
        ]

        for file in relatedFiles {
            if fileManager.fileExists(atPath: file.path) {
                do {
                    try fileManager.removeItem(at: file)
                    LogEvent.print(module: "SharedModelContainer.resetPersistentStoreIfNeeded()", message: "Removed persistent store file: \(file.lastPathComponent)")
                } catch {
                    throw NSError(
                        domain: "com." + AppSettings.appName + ".ModelContainer",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to remove file: \(file.lastPathComponent)"]
                    )
                }
            }
        }

        LogEvent.print(module: "SharedModelContainer.resetPersistentStoreIfNeeded()", message: "Perssistent store successfully reset.")
    }
    
    /// Create a new container
    private static func createContainer() -> ModelContainer {
        do {
            let currentSchema = SharedModelContainer.getCurrentSchema()
            let schema = Schema(currentSchema.models)
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    // Synchronous access
    func accessContainerSync<T>(_ block: @Sendable (ModelContainer) throws -> T) rethrows -> T {
        return try accessQueue.sync {
            return try block(container)
        }
    }
    
    /// Get the current schema based on the stored schema
    /// - Returns: VersionedSchema
    ///
    static func getCurrentSchema() -> VersionedSchema.Type {
        let storedVersion = getStoredSchemaVersion()
        switch storedVersion {
        case Schema.Version(1, 0, 0):
            return ModelSchemaV1.self
        /*
        case Schema.Version(2, 0, 0):
            return ModelSchemaV2.self
        */
        default:
            return ModelSchemaV1.self
        }
    }

    private static func getStoredSchemaVersion() -> Schema.Version {
        // Retrieve the stored schema version from persistent storage
        return UserDefaults.standard.string(forKey: "SchemaVersion")?.schemaVersion ?? Schema.Version(1, 0, 0)
    }

    private static func setStoredSchemaVersion(_ version: Schema.Version) {
        // Save the new schema version to persistent storage
        UserDefaults.standard.set(version.stringValue, forKey: "SchemaVersion")
    }

    
    /// Based on the stored version apply the right version based on conditions, usually to the next version
    ///
    private func applyMigrations() throws {

        LogEvent.print(module: "SharedModelContainer.applyMigrations()", message: "starting...")
        
        let storedVersion = SharedModelContainer.getStoredSchemaVersion()
        LogEvent.print(module: "SharedModelContainer.applyMigrations()", message: "Current stored SwiftData schema: \(storedVersion)")
        
        /*
         
        /// Apply migrations based on stored version
        if storedVersion < ModelSchemaV2.versionIdentifier {
            try migrateToVersion2()
        }
        
        /// Update the stored schema version
        SharedModelContainer.setStoredSchemaVersion(SharedModelContainer.getCurrentSchema().versionIdentifier)
         
        */
        LogEvent.print(module: "SharedModelContainer.applyMigrations()", message: "⏹️ ...finished")
    }
    
    private func migrateToVersion2() throws {
        LogEvent.print(module: "SharedModelContainer.migrateToVersion2()", message: "starting...")

        /// Perform migration logic to update schema to version 2
        /// This might include data transformations, renaming attributes, etc.
        /*
        try accessContainerSync { container in
            // Example: container.performMigrationTask()
        }
        */
        LogEvent.print(module: "SharedModelContainer.migrateToVersion2()", message: "⏹️ ...finished")

    }
    
    func performMigrationTask() throws {
        /// Perform specific data transformations required for the migration
        /// This might include:
        /// - Renaming attributes
        /// - Converting data formats
        /// - Adding new attributes with default values
        /// - Migrating relationships

        /// Example: Renaming an attribute
        ///
        /*
        let context = self.viewContext
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "YourEntityName")
        
        do {
            let results = try context.fetch(fetchRequest)
            for object in results {
                // Example: Renaming a field from oldField to newField
                if let oldValue = object.value(forKey: "oldField") {
                    object.setValue(oldValue, forKey: "newField")
                    object.setValue(nil, forKey: "oldField")
                }
            }
            try context.save()
        } catch {
            throw error
        }
        */
    }

}

/// Helper extensions for version conversions
///
extension Schema.Version {
    var stringValue: String {
        return "\(major).\(minor).\(patch)"
    }
}

extension String {
    var schemaVersion: Schema.Version {
        let components = self.split(separator: ".")
        let major = Int(components[0]) ?? 0
        let minor = Int(components[1]) ?? 0
        let patch = Int(components[2]) ?? 0
        return Schema.Version(major, minor, patch)
    }
}
