//
//  AppSettings.swift
//  ViDrive
//
//  Created by David Holeman on 2/19/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation

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
        static var isKeychainLoginEnabled:  Bool = true
        static var isFirebaseLoginEnabled:  Bool = false
    }
    
}
