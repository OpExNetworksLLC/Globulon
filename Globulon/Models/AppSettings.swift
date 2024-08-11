//
//  AppSettings.swift
//  ViDrive
//
//  Created by David Holeman on 2/19/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

/// These settings control the behavior of the app.  It is here that we set which features are enabled or disabled.
/// 
class AppSettings: ObservableObject {
    static var isIntroductionEnabled: Bool = true
    static var isOnboardingEnabled: Bool = true
    static var isTermsEnabled: Bool = true
    static var isWelcomeEnabled: Bool = true
    static var isLoginEnabled: Bool = true
    // TODO:  More ?
    
    struct login {
        static let isKeychainLoginEnabled:  Bool = true
        static let isFirebaseLoginEnabled:  Bool = false
    }
    struct pallet {
        static let primaryLight = Color(red: 232/255, green: 196/255, blue: 104/255)
        static let primary = Color(red: 245/255, green: 164/255, blue: 98/255)
        static let primaryDark = Color(red: 232/255, green: 111/255, blue: 81/255)
    }
}
