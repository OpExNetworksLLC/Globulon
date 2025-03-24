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


typealias HelpSection = ModelSchemaV01_00_00.HelpSection
typealias HelpArticle = ModelSchemaV01_00_00.HelpArticle
typealias GPSData = ModelSchemaV01_00_00.GPSData

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
    
    /// Migration Map.  The applyMigrations() function will cycle through this map and apply the upgrades
    ///
    private static let migrationMap: [Schema.Version: () throws -> Void] = [
        Schema.Version(1, 0, 1): migrateV01_00_00_to_V01_00_01
        //,Schema.Version(2, 0, 0): {}
    ]
    
    private init() {
        
        /// Reset to the first version for testing
        ///
        SharedModelContainer.resetSchemaVersionForTesting()
        
        do {
            LogEvent.print(module: "SharedModelContainer()", message: "▶️ starting...")
            
            let tempSchema = Schema(SharedModelContainer.getCurrentSchema().models)
            let tempContainer = try ModelContainer(
                for: tempSchema,
                configurations: [ModelConfiguration(schema: tempSchema, isStoredInMemoryOnly: false)]
            )
            
            try SharedModelContainer.resetPersistentStoreIfNeeded(startFresh: false, container: tempContainer)

            let currentSchema = SharedModelContainer.getCurrentSchema()
            let schema = Schema(currentSchema.models)
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            context = ModelContext(container)
            
            try applyMigrations()

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
            return ModelSchemaV01_00_00.self
        case Schema.Version(1, 0, 1):
            return ModelSchemaV01_00_01.self
        /*
        case Schema.Version(2, 0, 0):
            return ModelSchemaV2.self
        */
        default:
            return ModelSchemaV01_00_00.self
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
    
    // Reset schema version to 1.0.0 for testing
    private static func resetSchemaVersionForTesting() {
        setStoredSchemaVersion(Schema.Version(1, 0, 0))
    }
    
    /// Based on the stored version apply the right version based on conditions, usually to the next version
    ///
    private func applyMigrations() throws {

        LogEvent.print(module: "SharedModelContainer.applyMigrations()", message: "starting...")
        
        let storedVersion = SharedModelContainer.getStoredSchemaVersion()
        LogEvent.print(module: "SharedModelContainer.applyMigrations()", message: "Current stored SwiftData schema: \(storedVersion)")
        
        // Iterate through migrations and apply those required
        for (version, migration) in SharedModelContainer.migrationMap.sorted(by: { $0.key < $1.key }) {
            if storedVersion < version {
                LogEvent.print(module: "SharedModelContainer.applyMigrations()", message: "Applying migration from version \(storedVersion) to \(version)...")
                do {
                    //try migration()
                    //SharedModelContainer.setStoredSchemaVersion(version)
                    LogEvent.print(module: "SharedModelContainer.applyMigrations()", message: "Migration to version \(version) completed successfully.")
                } catch {
                    LogEvent.print(module: "SharedModelContainer.applyMigrations()", message: "Migration to version \(version) failed: \(error)")
                    throw error
                }
            }
        }
        
        LogEvent.print(module: "SharedModelContainer.applyMigrations()", message: "⏹️ ...finished")
    }
    
    private static func migrateV01_00_00_to_V01_00_01() throws {
        LogEvent.print(module: "SharedModelContainer.migrateV01_00_00_to_V01_00_01()", message: "starting...")

        /// Perform migration logic to update schema to version
        /// This might include data transformations, renaming attributes, etc.
        /*
        try accessContainerSync { container in
            // Example: container.performMigrationTask()
        }
        */
        LogEvent.print(module: "SharedModelContainer.migrateV01_00_00_to_V01_00_01()", message: "⏹️ ...finished")

    }
//    private static func migrateV01_00_00_to_V01_00_01() throws {
//        LogEvent.print(module: "SharedModelContainer.migrateV01_00_00_to_V01_00_01()", message: "Starting lightweight migration...")
//
//        // Perform migration by creating a new ModelContainer with the updated schema
//        let newSchema = Schema(ModelSchemaV01_00_01.models)
//        let newModelConfiguration = ModelConfiguration(schema: newSchema, isStoredInMemoryOnly: false)
//
//        do {
//            let newContainer = try ModelContainer(for: newSchema, configurations: [newModelConfiguration])
//
//            // Replace the existing container
//            SharedModelContainer.shared.container = newContainer
//            SharedModelContainer.shared.context = ModelContext(newContainer)
//
//            LogEvent.print(module: "SharedModelContainer.migrateV01_00_00_to_V01_00_01()", message: "Migration completed successfully.")
//        } catch {
//            LogEvent.print(module: "SharedModelContainer.migrateV01_00_00_to_V01_00_01()", message: "Migration failed: \(error)")
//            throw error
//        }
//    }
    
    private static func migrateToVersion2() throws {
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
