//
//  AppEnvironment.swift
//  ViDrive
//
//  Created by David Holeman on 2/16/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftData

// Define a global access point for the sharedModelContainer in a way that it can be accessed outside of SwiftUI views
class AppEnvironment {
    static var sharedModelContainer: ModelContainer!
}
