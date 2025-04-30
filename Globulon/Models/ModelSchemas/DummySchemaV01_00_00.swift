//
//  DummySchemaV01_00_00.swift
//  Globulon
//
//  Created by David Holeman on 3/24/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import SwiftData

enum DummySchema: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        return Schema.Version(0, 0, 0)
    }
    static let models: [any PersistentModel.Type] = []
}
