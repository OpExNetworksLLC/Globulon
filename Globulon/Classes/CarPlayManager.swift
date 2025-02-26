//
//  CarPlayManager.swift
//  Globulon
//
//  Created by David Holeman on 2/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import Combine

@MainActor
class CarPlayManager: ObservableObject {
    
    static let shared = CarPlayManager()
    
    // Published property to notify SwiftUI of changes
    @Published var isCarPlayConnected: Bool = SceneDelegate.isCarPlayConnected

    // Initializer to set up notifications
    init() {
        registerForNotifications()
        updateConnectionStatus() // Ensure initial state is correct
    }

    private func registerForNotifications() {
        NotificationCenter.default.addObserver(
            forName: .carPlayConnected,
            object: nil,
            queue: nil // Let it run on the current thread
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleCarPlayConnected()
            }
        }

        NotificationCenter.default.addObserver(
            forName: .carPlayDisconnected,
            object: nil,
            queue: nil // Let it run on the current thread
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleCarPlayDisconnected()
            }
        }
    }

    private func updateConnectionStatus() {
        isCarPlayConnected = SceneDelegate.isCarPlayConnected
    }

    private func handleCarPlayConnected() {
        isCarPlayConnected = true
    }

    private func handleCarPlayDisconnected() {
        isCarPlayConnected = false
    }

    deinit {
        // Swift automatically unregisters observers when using blocks
    }
}

