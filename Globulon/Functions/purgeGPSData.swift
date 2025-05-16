//
//  purgeGPSData.swift
//  Globulon
//
//  Created by David Holeman on 02/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

/**
 - Version: 1.0.0 (2025.02.25)
 - Note:
     - Version: 1.0.0 (2025.02.25)
         - Created
 */

import SwiftData

@MainActor
func purgeGPSData() -> Int {
    do {
        //let context = ModelContext(ModelContainerProvider.shared)
        let context = ModelContainerProvider.sharedContext

        do {
            
            let fetchDescriptor = FetchDescriptor<GPSData>()
            let entries = try context.fetch(fetchDescriptor)
            
            try context.delete(model: GPSData.self)
            LogManager.event(module: "purgeGPSData()", message: "Purged \(entries.count) GPSData entries.")
            
            return entries.count
            
        } catch {
            LogManager.event(module: "purgeGPSData()", message: "error purging GPSData.")
            return 0
        }
    }
}
