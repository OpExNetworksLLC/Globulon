//
//  ModelContainerProvider.swift
//  GeoGato
//
//  Created by David Holeman on 04/04/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

/**
- Version:  1.0.0 (2025-04-04)
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
 
 - Version:  1.1.0 (2025-04-24)
 - Note:   Fixed several bugs around concurrency
   - Use `let context = ModelContainerProvider.sharedContext` in your code to reference the `context`
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
@MainActor
final class ModelContainerProvider {
    static let shared: ModelContainer = {
        do {
            let schema = Schema([HelpSection.self, HelpArticle.self, GPSData.self])
            let config = ModelConfiguration("Default", schema: schema)
            
            let savedVersion = SchemaVersionStore.load() ?? Schema.Version(0, 0, 0)
            let currentVersion = CurrentModelSchema.versionIdentifier
            
            LogManager.event(module: "ModelContainerProvider", message: "📦 Current database schema: \(currentVersion), Saved schema: \(savedVersion)")
            
            if savedVersion == Schema.Version(0, 0, 0) {
                SchemaVersionStore.save(currentVersion)
                LogManager.event(module: "ModelContainerProvider", message: "🆕 First-time setup. Stored database schema version set to \(currentVersion)")
            } else if savedVersion == currentVersion {
                LogManager.event(module: "ModelContainerProvider", message: "✅ Database is up-to-date at schema version \(currentVersion)")
            } else if savedVersion < currentVersion {
                LogManager.event(module: "ModelContainerProvider", message: "🔄 Database migration needed: from schema version \(savedVersion) ➡️ \(currentVersion)")
            } else {
                LogManager.event(module: "ModelContainerProvider", message: "⚠️ Warning: Saved schema version \(savedVersion) is NEWER than current \(currentVersion). Possible rollback or version mismatch.")
            }
            
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
    
    /// 🔁 Shared context built from the shared container
    static let sharedContext = ModelContext(shared)
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
    /*
    static var migrateV01_00_00toV01_00_01: MigrationStage {
        .custom(
            fromVersion: ModelSchemaV01_00_00.self,
            toVersion: ModelSchemaV01_00_01.self,
            willMigrate: { context in
                LogManager.event(module: "DataMigrationPlan", message: "Migrating from v01_00_00 to v01_00_01 ▶️ starting ...")
            },
            didMigrate: { context in
                SchemaVersionStore.save(Schema.Version(1, 0, 1))
                LogManager.event(module: "DataMigrationPlan", message: "Migration from v01_00_00 to v01_00_01 ⏹️ ... finished")
            }
        )
    }
    */
}

// MARK: - Schema version store

/// Store the current schema being used.  The `ModelContainerProvider` will look to this to see if a new schema has been created and a migration required.
///
struct SchemaVersionStore {
    private static let key = "lastSchemaVersion"

    static func save(_ version: Schema.Version) {
        UserDefaults.standard.set("\(version.major).\(version.minor).\(version.patch)", forKey: key)
    }
    
    static func getDesc() -> String {
        return UserDefaults.standard.string(forKey: key) ?? ""
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
    
    LogManager.event(module: "SharedModelContainer.resetPersistentStoreIfNeeded()", message: "Resetting persistent store files located at: \(storeURL.deletingLastPathComponent().path)")
    
    let relatedFiles = [
        storeURL,
        storeURL.appendingPathExtension("shm"),
        storeURL.appendingPathExtension("wal")
    ]
    
    for file in relatedFiles {
        if fileManager.fileExists(atPath: file.path) {
            do {
                try fileManager.removeItem(at: file)
                LogManager.event(module: "SharedModelContainer.resetPersistentStoreIfNeeded()", message: "Removed persistent store file: \(file.lastPathComponent)")
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






////
////  ModelContainerProvider.swift
////  GeoGato
////
////  Created by David Holeman on 04/04/25.
////  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
////
//
///**
//- Version:  1.0.0 (2025-04-04)
//- Note: When upgrading a schema follow this sequence:
//    1. Create a new version of the schema you intend to migrate to from the last active one
//    2. Add any new schemas to the new model schema array in the `ModelContainerProvider`
//    3. Update the `CurrentModelSchema` to the name of your new model schema
//    4. Add your data migration to the DataMigrationPlan.
//    5. Update and add fieldnames and logic in your app to accomodate the new model and any associated logic
//    6. Add your schema model to the `schemas` array in`DataMigrationPlan`
//    7. Add your migration to the `stages`array in `DataMigrationPlan`
//    
//    Testing:
//    - Use the `resetSchemaVersionForTesting` and `resetPersistentStoreIfNeeded` functions as needed
//    - In your migration code hold off saving the version `SchemaVersionStore.save` with the new version until you are ready.  This will
//      Make it easier to repeat the migration until you are sure it's complete otherwise when you run the app the version will update and think you
//      are done.
// 
// - Version:  1.1.0 (2025-04-24)
// - Note:   Fixed several bugs around concurrency
//   - Use `let context = ModelContainerProvider.sharedContext` in your code to reference the `context`
// */
//
//import Foundation
//import SwiftData
//import Combine
//
//// MARK: - Type aliases for swift data schema
//
///// Specify the current model schema and it will uipdate the other typealias's.
/////
//typealias CurrentModelSchema = ModelSchemaV01_00_00
//
///// If your migratation adds new tables or renames them then add and change as required.
/////
//typealias HelpSection = CurrentModelSchema.HelpSection
//typealias HelpArticle = CurrentModelSchema.HelpArticle
//typealias GPSData = CurrentModelSchema.GPSData
//typealias TourData = CurrentModelSchema.TourData
//typealias TourPOIData = CurrentModelSchema.TourPOIData
//typealias CatalogToursData = CurrentModelSchema.CatalogToursData
//typealias CatalogTourData = CurrentModelSchema.CatalogTourData
//
//// MARK: - Model Container Provider
//@MainActor
//final class ModelContainerProvider {
//    static let shared: ModelContainer = {
//        do {
//            let schema = Schema([HelpSection.self, HelpArticle.self, GPSData.self, TourData.self, TourPOIData.self, CatalogToursData.self, CatalogTourData.self])
//            let config = ModelConfiguration("Default", schema: schema)
//            
//            let savedVersion = SchemaVersionStore.load() ?? Schema.Version(0, 0, 0)
//            let currentVersion = CurrentModelSchema.versionIdentifier
//            
//            LogManager.event(module: "ModelContainerProvider", message: "📦 Current database schema: \(currentVersion), Saved schema: \(savedVersion)")
//            
//            if savedVersion == Schema.Version(0, 0, 0) {
//                SchemaVersionStore.save(currentVersion)
//                LogManager.event(module: "ModelContainerProvider", message: "🆕 First-time setup. Stored database schema version set to \(currentVersion)")
//            } else if savedVersion == currentVersion {
//                LogManager.event(module: "ModelContainerProvider", message: "✅ Database is up-to-date at schema version \(currentVersion)")
//            } else if savedVersion < currentVersion {
//                LogManager.event(module: "ModelContainerProvider", message: "🔄 Database migration needed: from schema version \(savedVersion) ➡️ \(currentVersion)")
//            } else {
//                LogManager.event(module: "ModelContainerProvider", message: "⚠️ Warning: Saved schema version \(savedVersion) is NEWER than current \(currentVersion). Possible rollback or version mismatch.")
//            }
//            
//            let container = try ModelContainer(
//                for: schema,
//                migrationPlan: DataMigrationPlan.self,
//                configurations: [config]
//            )
//            
//            return container
//        } catch {
//            fatalError("Failed to initialize ModelContainer: \(error)")
//        }
//    }()
//    
//    /// 🔁 Shared context built from the shared container
//    static let sharedContext = ModelContext(shared)
//}
//
//// MARK: - Data migration plan
//
//enum DataMigrationPlan: SchemaMigrationPlan {
//    
//    /// Identify all your schema
//    ///
//    static var schemas: [any VersionedSchema.Type] {
//        [
//            ModelSchemaV01_00_00.self
//            //,ModelSchemaV01_00_01.self
//        ]
//    }
//    
//    /// Identify your migration stages
//    ///
//    static var stages: [MigrationStage] {
//        [
//            //migrateV01_00_00toV01_00_01
//        ]
//    }
//    
//    /// Migrate - from:  ModelSchemaV01_00_00  to:  ModelSchemaV01_00_01
//    ///
//    /*
//    static var migrateV01_00_00toV01_00_01: MigrationStage {
//        .custom(
//            fromVersion: ModelSchemaV01_00_00.self,
//            toVersion: ModelSchemaV01_00_01.self,
//            willMigrate: { context in
//                LogManager.event(module: "DataMigrationPlan", message: "Migrating from v01_00_00 to v01_00_01 ▶️ starting ...")
//            },
//            didMigrate: { context in
//                SchemaVersionStore.save(Schema.Version(1, 0, 1))
//                LogManager.event(module: "DataMigrationPlan", message: "Migration from v01_00_00 to v01_00_01 ⏹️ ... finished")
//            }
//        )
//    }
//    */
//}
//
//// MARK: - Schema version store
//
///// Store the current schema being used.  The `ModelContainerProvider` will look to this to see if a new schema has been created and a migration required.
/////
//struct SchemaVersionStore {
//    private static let key = "lastSchemaVersion"
//
//    static func save(_ version: Schema.Version) {
//        UserDefaults.standard.set("\(version.major).\(version.minor).\(version.patch)", forKey: key)
//    }
//    
//    static func getDesc() -> String {
//        return UserDefaults.standard.string(forKey: key) ?? ""
//    }
//    
//    static func load() -> Schema.Version? {
//        guard let versionString = UserDefaults.standard.string(forKey: key) else { return nil }
//        let components = versionString.split(separator: ".").compactMap { Int($0) }
//        guard components.count == 3 else { return nil }
//        return Schema.Version(components[0], components[1], components[2])
//    }
//}
//
//// MARK: - Utilities to use as needed in dev and testing
//
///// Reset schema version for testing.  If no version is specified then use 1, 0, 0
/////
//func resetSchemaVersionForTesting(to version: Schema.Version? = nil) {
//    let versionToSet = version ?? Schema.Version(1, 0, 0)
//    SchemaVersionStore.save(versionToSet)
//}
//
///// Reset the persistent store
/////
//func resetPersistentStoreIfNeeded(startFresh: Bool, container: ModelContainer? = nil) throws {
//    guard startFresh else { return }
//    
//    let fileManager = FileManager.default
//    let storeURL = getPersistentStoreURL(container: container)
//    
//    LogManager.event(module: "SharedModelContainer.resetPersistentStoreIfNeeded()", message: "Resetting persistent store files located at: \(storeURL.deletingLastPathComponent().path)")
//    
//    let relatedFiles = [
//        storeURL,
//        storeURL.appendingPathExtension("shm"),
//        storeURL.appendingPathExtension("wal")
//    ]
//    
//    for file in relatedFiles {
//        if fileManager.fileExists(atPath: file.path) {
//            do {
//                try fileManager.removeItem(at: file)
//                LogManager.event(module: "SharedModelContainer.resetPersistentStoreIfNeeded()", message: "Removed persistent store file: \(file.lastPathComponent)")
//            } catch {
//                throw NSError(
//                    domain: "com." + AppSettings.appName + ".ModelContainer",
//                    code: 1,
//                    userInfo: [NSLocalizedDescriptionKey: "Failed to remove file: \(file.lastPathComponent)"]
//                )
//            }
//        }
//    }
//    
//    /// Get the URL of the persistent store
//    ///
//    func getPersistentStoreURL(container: ModelContainer?) -> URL {
//        if let container = container, let url = container.configurations.first?.url {
//            return url
//        }
//        // Default fallback if the container isn't initialized
//        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("default.store")
//    }
//}
//
