//
//  AppValues.swift
//  ViDrive
//
//  Created by David Holeman on 2/13/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

/// Various values used throughout the app.  Instead of scattered values that are reused through the code we set them here.
///
class AppValues {
    static var appName = "Globulon"
    static var supportEmail = "support+globulon@opexnetworks.com"
    
    // Articles
    static var pinnedTag = "*|PINNED|*"
    static var pinnedUnicode = "\u{2605}"

    struct articlesLocation {
        static var remote = "https://opexnetworks.github.io/Apps/ViDrive/articles.json"
        static var local = "Articles"
        static var error = "NoArticles"
    }
    
    // Hosted up on github
    static var licenseURL = "https://opexnetworks.github.io/Apps/ViDrive/license.html"
    static var privacyURL = "https://opexnetworks.github.io/Apps/ViDrive/privacy.html"

    
    static var screen = UIScreen.main.bounds
    static var settingsMenuWidth: CGFloat = 200
    static var settingsMenuOffset: CGFloat = 110
    
//    struct features {
//        static var isDeveloperModeEnabled = true
//    }
    
    struct logos {
        static var appLogo = "appLogo"
        static var appLogoBlack = "appLogoBlack"
        static var appLogoWhite = "appLogoWhite"
        static var appLogoDarkMode = "appLogoDarkMode"
        static var appLogoTransparent = "appLogoTransparent"
    }
    
    class pallet {
        /// Color pallet for the app.
        /// Example:
        ///    Image("symLogo")
        ///        .resizable()
        ///        .renderingMode(.template)
        ///        .foregroundStyle(AppPallet.primaryLight, AppPallet.Primary, AppPallet.PrimaryDark)
        ///        .aspectRatio(contentMode: .fit)
        ///        .frame(width: 32, height: 32)
        /// or
        ///    Image("symLogo")
        ///        .resizable()
        ///        .renderingMode(.original)
        ///        .foregroundStyle(.blue)
        ///        .aspectRatio(contentMode: .fit)
        ///        .frame(width: 32, height: 32)
        ///
        static let primaryLight = Color(red: 232/255, green: 196/255, blue: 104/255)
        static let primary = Color(red: 245/255, green: 164/255, blue: 98/255)
        static let primaryDark = Color(red: 232/255, green: 111/255, blue: 81/255)
        static let Accent = Color(red: 43/255, green: 158/255, blue: 145/255)
        static let iconText = UIColor(red: 33, green: 33, blue: 33, alpha: 1.0)
        static let primaryText = UIColor(red: 33, green: 33, blue: 33, alpha: 1.0)
        static let secondaryText = UIColor(red: 117, green: 117, blue: 117, alpha: 1.0)
        static let divider = UIColor(red: 189, green: 189, blue: 189, alpha: 1.0)
    }
    
    struct sideMenu {
        static var settingsMenuWidth: CGFloat = 200
        static var settingsMenuOffset: CGFloat = 110
    }
    
    struct backgroundGradient {
     
        static var login: LinearGradient {
            // handle any conditional changes here and pass as values to the returned valueg
            //
            return LinearGradient(gradient: Gradient(colors: [Color("viewBackgroundColorLoginBegin"), Color("viewBackgroundColorLoginEnd")]), startPoint: .top, endPoint: .bottomTrailing)
        }
        
        static var forgotPassword: LinearGradient {
            // handle any conditional changes here and pass as values to the returned valueg
            //
            return LinearGradient(gradient: Gradient(colors: [Color("viewBackgroundColorLoginBegin"), Color("viewBackgroundColorLoginEnd")]), startPoint: .top, endPoint: .bottomTrailing)
        }
    }
    
    struct demoValues {
        static var loremIpsum: String {
            return "Lorem ipsum dolor sit er elit lamet, consectetaur cillium adipisicing pecu, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Nam liber te conscient to factor tum poen legum odioque civiuda."
        }
    }
    
}
