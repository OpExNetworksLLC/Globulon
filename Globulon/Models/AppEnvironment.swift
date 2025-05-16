//
//  AppEnvironment.swift
//  Globulon
//
//  Created by David Holeman on 02/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import Combine

/**
 - Version: 1.0.0 (2025.02.25)
 - Note:
 */

@MainActor
class AppEnvironment: ObservableObject {
    
    static let shared = AppEnvironment()
    
    private let userSettings = UserSettings() // Assuming this is safe to instantiate once
    
//    @AppStorage("activeTourID") var activeTourID: String = "" {
//        didSet {
//            userSettings.activeTourID = activeTourID
//            LogManager.event(module: "AppEnvironment.activeTourID", message: "changed to \(activeTourID)")
//            LocationManager.shared.loadTourData(for: activeTourID)
//        }
//    }
    
    /// Optional key-value store for less common data
    ///
    private var storage: [String: Any] = [:]
    
    func setValue<T>(_ key: String, value: T) {
        storage[key] = value
        objectWillChange.send()
    }

    func getValue<T>(_ key: String, as type: T.Type) -> T? {
        guard let value = storage[key] as? T else {
            LogManager.event(module: "AppEnvironment", message: "Type mismatch for key: \(key)")
            return nil
        }
        return value
    }

    func removeValue(forKey key: String) {
        storage[key] = nil
    }
}
