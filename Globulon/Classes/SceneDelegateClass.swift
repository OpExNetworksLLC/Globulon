//
//  SceneDelegateClass.swift
//  Globulon
//
//  Created by David Holeman on 2/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

/**
 - Version: 1.0.0 (2024-02-25)
 - Note: This is used in helping determin if CarPlay is connected
 */

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    static var isCarPlayConnected: Bool = false

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            //let contentView = ContentView()
            let contentView = MasterView()
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
        updateCarPlayConnectionStatus(for: scene)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        if let screen = (scene as? UIWindowScene)?.screen,
           screen.traitCollection.userInterfaceIdiom == .carPlay {
            SceneDelegate.isCarPlayConnected = false
            NotificationCenter.default.post(name: .carPlayDisconnected, object: nil)
        }
    }

    func sceneDidActivate(_ scene: UIScene) {
        updateCarPlayConnectionStatus(for: scene)
    }

    private func updateCarPlayConnectionStatus(for scene: UIScene) {
        if let screen = (scene as? UIWindowScene)?.screen,
           screen.traitCollection.userInterfaceIdiom == .carPlay {
            SceneDelegate.isCarPlayConnected = true
            NotificationCenter.default.post(name: .carPlayConnected, object: nil)
        } else {
            SceneDelegate.isCarPlayConnected = false
        }
    }
}

