//
//  AppInfoClass.swift
//  ViDrive
//
//  Created by David Holeman on 2/19/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation

class AppInfo {
    static var version: String {
        return Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    }
    static var build: String {
        return Bundle.main.infoDictionary!["CFBundleVersion"] as! String
    }
    static var release: String {
        return String(format: "%@.%@", Bundle.main.infoDictionary!["CFBundleShortVersionString"]! as! CVarArg, Bundle.main.infoDictionary!["CFBundleVersion"] as! CVarArg)
    }
}
