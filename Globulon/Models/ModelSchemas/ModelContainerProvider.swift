//
//  ModelContainerProvider.swift
//  Globulon
//
//  Created by David Holeman on 04/04/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

/**
- Version: 1.0.0 (2025-04-04)
- Note: When upgrading a schema follow this sequence:
    1. Create a new version of the schema you intend to migrate to from the last active one
    2. Add any new schemas to the new model schema array in the `ModelContainerProvider`
    3. Update the `CurrentModelSchema` to the name of your new model schema
    4. Add your data migration to the DataMigrationPlan.
    5. Update and add fieldnames and logic in your app to accomodate the new model and any associated logic
    6. Add your schema model to the `schemas` array in`DataMigrationPlan`
    7. Add your migration to the `stages`array in `DataMigrationPlan`
    
    Testing:
    - Use the `resetSchemaVersionForTesting` and `resetPersistentStoreIfNeeded` functions as needed
    - In your migration code hold off saving the version `SchemaVersionStore.save` with the new version until you are ready.  This will
      Make it easier to repeat the migration until you are sure it's complete otherwise when you run the app the version will update and think you
      are done.
 */

import Foundation
import SwiftData
import Combine

// MARK: - Type aliases for swift data schema

/// Specify the current model schema and it will uipdate the other typealias's.
///
typealias CurrentModelSchema = ModelSchemaV01_00_00

/// If your migratation adds new tables or renames them then add and change as required.
///
typealias HelpSection = CurrentModelSchema.HelpSection
typealias HelpArticle = CurrentModelSchema.HelpArticle
typealias GPSData = CurrentModelSchema.GPSData

// MARK: - Model Container Provider
final class ModelContainerProvider {
    static let shared: ModelContainer = {
        do {
            /// Add any new schema to the array
            let schema = Schema([HelpSection.self, HelpArticle.self, GPSData.self])
            let config = ModelConfiguration("Default", schema: schema)
            
            /// 1st time the app runs:
            ///  - `savedSchema` is initialized to 0.0.0
            ///
            /// 2+ times the app runs:
            ///  - `savedSchema` picks up the last saved value
            ///
            let savedVersion = SchemaVersionStore.load() ?? Schema.Version(0, 0, 0)
            let currentVersion = CurrentModelSchema.versionIdentifier
            LogEvent.print(module: "ModelContainerProvider", message: "📦 Current database schema: \(currentVersion), Saved schema: \(savedVersion)")

            if savedVersion == Schema.Version(0, 0, 0) {
                /// First-time app run
                SchemaVersionStore.save(currentVersion)
                LogEvent.print(module: "ModelContainerProvider", message: "🆕 First-time setup. Stored database schema version set to \(currentVersion)")
            } else if savedVersion == currentVersion {
                LogEvent.print(module: "ModelContainerProvider", message: "✅ Database is up-to-date at schema version \(currentVersion)")
            } else if savedVersion < currentVersion {
                LogEvent.print(module: "ModelContainerProvider", message: "🔄 Database migration needed: from schema version \(savedVersion) ➡️ \(currentVersion)")
            } else {
                LogEvent.print(module: "ModelContainerProvider", message: "⚠️ Warning: Saved schema version \(savedVersion) is NEWER than current \(currentVersion). Possible rollback or version mismatch.")
            }
            
            /// Perform the upgrade.  The new version of the schema is updated in the migration plan
            let container = try ModelContainer(
                for: schema,
                migrationPlan: DataMigrationPlan.self,
                configurations: [config]
            )

            return container
            
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }()
}

// MARK: - Data migration plan

enum DataMigrationPlan: SchemaMigrationPlan {
    
    /// Identify all your schema
    ///
    static var schemas: [any VersionedSchema.Type] {
        [
            ModelSchemaV01_00_00.self
            //,ModelSchemaV01_00_01.self
        ]
    }
    
    /// Identify your migration stages
    ///
    static var stages: [MigrationStage] {
        [
            //migrateV01_00_00toV01_00_01
        ]
    }
    
    /// Migrate - from:  ModelSchemaV01_00_00  to:  ModelSchemaV01_00_01
    ///
    static var migrateV01_00_00toV01_00_01: MigrationStage {
        .custom(
            fromVersion: ModelSchemaV01_00_00.self,
            toVersion: ModelSchemaV01_00_01.self,
            willMigrate: { context in
                LogEvent.print(module: "DataMigrationPlan", message: "Migrating from v01_00_00 to v01_00_01 ▶️ starting ...")
            },
            didMigrate: { context in
                SchemaVersionStore.save(Schema.Version(1, 0, 1))
                LogEvent.print(module: "DataMigrationPlan", message: "Migration from v01_00_00 to v01_00_01 ⏹️ ... finished")
            }
        )
    }
}

// MARK: - Schema version store

/// Store the current schema being used.  The `ModelContainerProvider` will look to this to see if a new schema has been created and a migration required.
///
struct SchemaVersionStore {
    private static let key = "lastSchemaVersion"

    static func save(_ version: Schema.Version) {
        UserDefaults.standard.set("\(version.major).\(version.minor).\(version.patch)", forKey: key)
    }
    
    static func load() -> Schema.Version? {
        guard let versionString = UserDefaults.standard.string(forKey: key) else { return nil }
        let components = versionString.split(separator: ".").compactMap { Int($0) }
        guard components.count == 3 else { return nil }
        return Schema.Version(components[0], components[1], components[2])
    }
}

// MARK: - Utilities to use as needed in dev and testing

/// Reset schema version for testing.  If no version is specified then use 1, 0, 0
///
func resetSchemaVersionForTesting(to version: Schema.Version? = nil) {
    let versionToSet = version ?? Schema.Version(1, 0, 0)
    SchemaVersionStore.save(versionToSet)
}

/// Reset the persistent store
///
func resetPersistentStoreIfNeeded(startFresh: Bool, container: ModelContainer? = nil) throws {
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
    
    /// Get the URL of the persistent store
    ///
    func getPersistentStoreURL(container: ModelContainer?) -> URL {
        if let container = container, let url = container.configurations.first?.url {
            return url
        }
        // Default fallback if the container isn't initialized
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("default.store")
    }
}

// MARK: - Old

//protocol VersionedSchema {
//    static var versionIdentifier: Schema.Version { get }
//    static var models: [any PersistentModel.Type] { get }
//}
//
//class SharedModelContainer: @unchecked Sendable {
//    static let shared = SharedModelContainer()
//
//    var container: ModelContainer
//    var context: ModelContext
//
//    private let accessQueue = DispatchQueue(label: "com." + AppSettings.appName + ".SharedModelContainerQueue", attributes: .concurrent)
//
//    /// Migration Map.  The applyMigrations() function will cycle through this map and apply the upgrades
//    ///
//    private static let migrationMap: [Schema.Version: () throws -> Void] = [
//        Schema.Version(1, 0, 0): {
//            let storedVersion = SharedModelContainer.getStoredSchemaVersion()
//            LogEvent.print(module: "SharedModelContainer.applyMigrations()", message: "Current stored SwiftData schema: \(storedVersion)")
//        }
//        //,Schema.Version(1, 0, 1): migrateV01_00_00_to_V01_00_01
//        //,Schema.Version(2, 0, 0): {}
//    ]
//
//    private init() {
//
//        /// Reset to the first version for testing
//        ///
//        SharedModelContainer.resetSchemaVersionForTesting()
//
//        do {
//            LogEvent.print(module: "SharedModelContainer()", message: "▶️ starting...")
//
//            let tempSchema = Schema(SharedModelContainer.getCurrentSchema().models)
//            let tempContainer = try ModelContainer(
//                for: tempSchema,
//                configurations: [ModelConfiguration(schema: tempSchema, isStoredInMemoryOnly: false)]
//            )
//
//            try SharedModelContainer.resetPersistentStoreIfNeeded(startFresh: false, container: tempContainer)
//
//            let currentSchema = SharedModelContainer.getCurrentSchema()
//            let schema = Schema(currentSchema.models)
//            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
//            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
//            context = ModelContext(container)
//
//            try applyMigrations()
//
//            LogEvent.print(module: "SharedModelContainer()", message: "⏹️ ...finished")
//
//        } catch {
//            LogEvent.print(module: "SharedModelContainer()", message: "Could not initialize SharedModelContainer: \(error)")
//            fatalError("Could not initialize SharedModelContainer: \(error)")
//
//        }
//    }
//
//    /// Get the current schema based on the stored schema
//    /// - Returns: VersionedSchema
//    ///
//    static func getCurrentSchema() -> VersionedSchema.Type {
//        let storedVersion = getStoredSchemaVersion()
//        switch storedVersion {
//        case Schema.Version(1, 0, 0):
//            return ModelSchemaV01_00_00.self
//        case Schema.Version(1, 0, 1):
//            return ModelSchemaV01_00_01.self
//        /*
//        case Schema.Version(2, 0, 0):
//            return ModelSchemaV2.self
//        */
//        default:
//            return ModelSchemaV01_00_00.self
//        }
//    }
//
//    private static func getPersistentStoreURL(container: ModelContainer?) -> URL {
//        if let container = container, let url = container.configurations.first?.url {
//            return url
//        }
//        // Default fallback if the container isn't initialized
//        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("default.store")
//    }
//
//    static func resetPersistentStoreIfNeeded(startFresh: Bool, container: ModelContainer? = nil) throws {
//        guard startFresh else { return }
//
//        let fileManager = FileManager.default
//        let storeURL = getPersistentStoreURL(container: container)
//
//        LogEvent.print(module: "SharedModelContainer.resetPersistentStoreIfNeeded()", message: "Resetting persistent store files located at: \(storeURL.deletingLastPathComponent().path)")
//
//        let relatedFiles = [
//            storeURL,
//            storeURL.appendingPathExtension("shm"),
//            storeURL.appendingPathExtension("wal")
//        ]
//
//        for file in relatedFiles {
//            if fileManager.fileExists(atPath: file.path) {
//                do {
//                    try fileManager.removeItem(at: file)
//                    LogEvent.print(module: "SharedModelContainer.resetPersistentStoreIfNeeded()", message: "Removed persistent store file: \(file.lastPathComponent)")
//                } catch {
//                    throw NSError(
//                        domain: "com." + AppSettings.appName + ".ModelContainer",
//                        code: 1,
//                        userInfo: [NSLocalizedDescriptionKey: "Failed to remove file: \(file.lastPathComponent)"]
//                    )
//                }
//            }
//        }
//
//        LogEvent.print(module: "SharedModelContainer.resetPersistentStoreIfNeeded()", message: "Perssistent store successfully reset.")
//    }
//
//    /// Create a new container
//    private static func createContainer() -> ModelContainer {
//        do {
//            let currentSchema = SharedModelContainer.getCurrentSchema()
//            let schema = Schema(currentSchema.models)
//            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
//            return try ModelContainer(for: schema, configurations: [modelConfiguration])
//        } catch {
//            fatalError("Could not create ModelContainer: \(error)")
//        }
//    }
//
//    // Synchronous access
//    func accessContainerSync<T>(_ block: @Sendable (ModelContainer) throws -> T) rethrows -> T {
//        return try accessQueue.sync {
//            return try block(container)
//        }
//    }
//
//
//    private static func getStoredSchemaVersion() -> Schema.Version {
//        // Retrieve the stored schema version from persistent storage
//        return UserDefaults.standard.string(forKey: "SchemaVersion")?.schemaVersion ?? Schema.Version(1, 0, 0)
//    }
//
//    private static func setStoredSchemaVersion(_ version: Schema.Version) {
//        // Save the new schema version to persistent storage
//        UserDefaults.standard.set(version.stringValue, forKey: "SchemaVersion")
//    }
//
//    // Reset schema version to 1.0.0 for testing
//    private static func resetSchemaVersionForTesting() {
//        setStoredSchemaVersion(Schema.Version(1, 0, 0))
//    }
//
//    /// Based on the stored version apply the right version based on conditions, usually to the next version
//    ///
//    private func applyMigrations() throws {
//
//        LogEvent.print(module: "SharedModelContainer.applyMigrations()", message: "starting...")
//
//        let storedVersion = SharedModelContainer.getStoredSchemaVersion()
//        LogEvent.print(module: "SharedModelContainer.applyMigrations()", message: "Current stored SwiftData schema: \(storedVersion)")
//
//        // Iterate through migrations and apply those required
//        for (version, migration) in SharedModelContainer.migrationMap.sorted(by: { $0.key < $1.key }) {
//            if storedVersion < version {
//                LogEvent.print(module: "SharedModelContainer.applyMigrations()", message: "Applying migration from version \(storedVersion) to \(version)...")
//                do {
//                    try migration()
//                    //SharedModelContainer.setStoredSchemaVersion(version)
//                    LogEvent.print(module: "SharedModelContainer.applyMigrations()", message: "Migration to version \(version) completed successfully.")
//                } catch {
//                    LogEvent.print(module: "SharedModelContainer.applyMigrations()", message: "Migration to version \(version) failed: \(error)")
//                    throw error
//                }
//            }
//        }
//
//        LogEvent.print(module: "SharedModelContainer.applyMigrations()", message: "⏹️ ...finished")
//    }
//
////    private static func migrateV01_00_00_to_V01_00_01() throws {
////        LogEvent.print(module: "SharedModelContainer.migrateV01_00_00_to_V01_00_01()", message: "starting...")
////
////        /// Perform migration logic to update schema to version
////        /// This might include data transformations, renaming attributes, etc.
////        /*
////        try accessContainerSync { container in
////            // Example: container.performMigrationTask()
////        }
////        */
////        LogEvent.print(module: "SharedModelContainer.migrateV01_00_00_to_V01_00_01()", message: "⏹️ ...finished")
////
////    }
//
//
//    /// This is pointed to from `migrationsMap()`
//    ///
//    private static func migrateV01_00_00_to_V01_00_01() throws {
//        LogEvent.print(module: "SharedModelContainer.migrateV01_00_00_to_V01_00_01()", message: "Starting migration from V01_00_00 to V01_00_01...")
//
//        let newSchema = Schema(ModelSchemaV01_00_01.models)
//        let newModelConfiguration = ModelConfiguration(schema: newSchema, isStoredInMemoryOnly: false)
//
//        do {
//            let newContainer = try ModelContainer(for: newSchema, configurations: [newModelConfiguration])
//            let context = ModelContext(newContainer)
//
//            // Explicitly fetch and migrate old data
//            let fetchRequest = FetchDescriptor<ModelSchemaV01_00_00.GPSData>()
//            let oldData = try context.fetch(fetchRequest)
//
//            for oldObject in oldData {
//                let newObject = ModelSchemaV01_00_01.GPSData(
//                    timestamp: oldObject.timestamp,
//                    latitude: oldObject.latitude,
//                    longitude: oldObject.longitude,
//                    speed: oldObject.speed,
//                    processed: oldObject.processed,
//                    codes: oldObject.code,  // Manually migrate "code" → "codes"
//                    note: oldObject.note
//                )
//
//                LogEvent.print(module: "SharedModelContainer.migrateV01_00_00_to_V01_00_01()", message: "Migrating old code: \(oldObject.code) to new codes: \(newObject.codes)")
//
//                context.insert(newObject)
//                context.delete(oldObject) // Remove the old version
//            }
//
//            try context.save()
//
//
//            LogEvent.print(module: "SharedModelContainer.migrateV01_00_00_to_V01_00_01()", message: "Migrated \(oldData.count) objects.")
//
//            // Replace the existing container with the new one
//            // Postpone updating SharedModelContainer.shared until initialization is done
//            DispatchQueue.main.async {
//                SharedModelContainer.shared.container = newContainer
//                SharedModelContainer.shared.context = context
//            }
//
//            // Update stored schema version
//            setStoredSchemaVersion(Schema.Version(1, 0, 1))
//
//            LogEvent.print(module: "SharedModelContainer.migrateV01_00_00_to_V01_00_01()", message: "Migration completed successfully.")
//
//        } catch {
//            LogEvent.print(module: "SharedModelContainer.migrateV01_00_00_to_V01_00_01()", message: "Migration failed: \(error)")
//            throw error
//        }
//
////        do {
////            let newContainer = try ModelContainer(for: newSchema, configurations: [newModelConfiguration])
////
////            // Replace the existing container with the new one
////            SharedModelContainer.shared.container = newContainer
////            SharedModelContainer.shared.context = ModelContext(newContainer)
////
////            // Update the stored schema version
////            setStoredSchemaVersion(Schema.Version(1, 0, 1))
////
////            LogEvent.print(module: "SharedModelContainer.migrateV01_00_00_to_V01_00_01()", message: "Migration completed successfully.")
////        } catch {
////            LogEvent.print(module: "SharedModelContainer.migrateV01_00_00_to_V01_00_01()", message: "Migration failed: \(error)")
////            throw error
////        }
//    }
//
//
////    private static func migrateV01_00_00_to_V01_00_01() throws {
////        LogEvent.print(module: "SharedModelContainer.migrateV01_00_00_to_V01_00_01()", message: "Starting lightweight migration...")
////
////        // Perform migration by creating a new ModelContainer with the updated schema
////        let newSchema = Schema(ModelSchemaV01_00_01.models)
////        let newModelConfiguration = ModelConfiguration(schema: newSchema, isStoredInMemoryOnly: false)
////
////        do {
////            let newContainer = try ModelContainer(for: newSchema, configurations: [newModelConfiguration])
////
////            // Replace the existing container
////            SharedModelContainer.shared.container = newContainer
////            SharedModelContainer.shared.context = ModelContext(newContainer)
////
////            LogEvent.print(module: "SharedModelContainer.migrateV01_00_00_to_V01_00_01()", message: "Migration completed successfully.")
////        } catch {
////            LogEvent.print(module: "SharedModelContainer.migrateV01_00_00_to_V01_00_01()", message: "Migration failed: \(error)")
////            throw error
////        }
////    }
//
////    private static func migrateToVersion2() throws {
////        LogEvent.print(module: "SharedModelContainer.migrateToVersion2()", message: "starting...")
////
////        /// Perform migration logic to update schema to version 2
////        /// This might include data transformations, renaming attributes, etc.
////        /*
////        try accessContainerSync { container in
////            // Example: container.performMigrationTask()
////        }
////        */
////        LogEvent.print(module: "SharedModelContainer.migrateToVersion2()", message: "⏹️ ...finished")
////
////    }
//
////    func performMigrationTask() throws {
////        /// Perform specific data transformations required for the migration
////        /// This might include:
////        /// - Renaming attributes
////        /// - Converting data formats
////        /// - Adding new attributes with default values
////        /// - Migrating relationships
////
////        /// Example: Renaming an attribute
////        ///
////        /*
////        let context = self.viewContext
////        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "YourEntityName")
////
////        do {
////            let results = try context.fetch(fetchRequest)
////            for object in results {
////                // Example: Renaming a field from oldField to newField
////                if let oldValue = object.value(forKey: "oldField") {
////                    object.setValue(oldValue, forKey: "newField")
////                    object.setValue(nil, forKey: "oldField")
////                }
////            }
////            try context.save()
////        } catch {
////            throw error
////        }
////        */
////    }
//
//}
//
///// Helper extensions for version conversions
/////
//extension Schema.Version {
//    var stringValue: String {
//        return "\(major).\(minor).\(patch)"
//    }
//}
//
//extension String {
//    var schemaVersion: Schema.Version {
//        let components = self.split(separator: ".")
//        let major = Int(components[0]) ?? 0
//        let minor = Int(components[1]) ?? 0
//        let patch = Int(components[2]) ?? 0
//        return Schema.Version(major, minor, patch)
//    }
//}
