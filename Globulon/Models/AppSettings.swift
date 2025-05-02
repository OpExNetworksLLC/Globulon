//
//  AppSettings.swift
//  Globulon
//
//  Created by David Holeman on 02/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct AppSettings {
    static let appName = "Globulon"
    static let appCopyright = "Copyright © 2025 OpEx Networks, LLC. All rights reserved."
    
    static let supportEmail = "support+Globulon@opexnetworks.com"
    
    // Articles
    static let pinnedTag = "*|PINNED|*"
    static let pinnedUnicode = "\u{2605}"

    struct articlesLocation {
        //static let remote = "https://opexnetworks.github.io/Apps/Globulon/articles.json"
        static let remote = "https://opexnetworks.com/apps/globulon/articles.json"

        static let local = "Articles"
        static let error = "NoArticles"
    }
    
    /// Hosted up on GitHub
    ///
    //static let licenseURL = "https://opexnetworks.github.io/Apps/GeoGato/License.html"
    //static let privacyURL = "https://opexnetworks.github.io/Apps/GeoGato/Privacy.html"
    
    /// Hosted on opexnetworks.com
    /// 
    static let licenseURL = "https://opexnetworks.com/apps/globulon/license.html"
    static let privacyURL = "https://opexnetworks.com/apps/globulon/privacy.html"

    
    /// A local HTML file with full disclosure on what exact events and data is collected
    static let analyticsConsentURL = "AnalyticsConsentDetails.html"
    
    struct GitHub {
        static let owner = "opexnetworks"
        static let repo = "Apps"
        static let appName = "GitHub"
    }
    
    struct feature {
        static let isIntroductionEnabled: Bool = true
        static let isOnboardingEnabled: Bool = true
        static let isTermsEnabled: Bool = true
        static let isWelcomeEnabled: Bool = true
        static let isLoginEnabled: Bool = true
        static let isLoginBiometricEnabled: Bool = true
        static let isGDPRConsentEnabled: Bool = true
    }
    
    struct log {
        static let isPasswordMaskEnabled: Bool = true
        static let isUsernameMaskEnabled: Bool = false
        static let isEmailMaskEnabled: Bool = false
        static let isStringMaskEnabled: Bool = true
        static let filename = "EventLog.txt"

    }
    
    struct sideMenu {
        static let menuWidth: CGFloat = 225
        static let isSideMenuDraggable: Bool = false
    }
    
    struct pallet {
        static let primaryLight = Color(red: 232/255, green: 196/255, blue: 104/255)
        static let primary = Color(red: 245/255, green: 164/255, blue: 98/255)
        static let primaryDark = Color(red: 232/255, green: 111/255, blue: 81/255)
    }
    
    struct symLogo {
        static let primaryLight = Color(red: 232/255, green: 196/255, blue: 104/255)
        static let primary = Color(red: 245/255, green: 164/255, blue: 98/255)
        static let primaryDark = Color(red: 232/255, green: 111/255, blue: 81/255)
    }
    
}
