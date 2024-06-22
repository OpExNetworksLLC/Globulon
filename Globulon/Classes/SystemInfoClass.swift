//
//  SystemInfoClass.swift
//  ViDrive
//
//  Created by David Holeman on 2/19/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation

class SystemInfo {
    static var os: String {
        let iOS = ProcessInfo().operatingSystemVersion
        return String(format: "%@.%@.%@", String(iOS.majorVersion), String(iOS.minorVersion), String(iOS.patchVersion))
    }
    static var osMajorVersion: String {
        let iOS = ProcessInfo().operatingSystemVersion
        return String(iOS.majorVersion)
    }
    static var deviceCode: String {
        var sysInfo = utsname()
        uname(&sysInfo)
        let modelCode = withUnsafePointer(to: &sysInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String.init(validatingUTF8: ptr)
            }
        }
        return modelCode ?? "Unknown"
    }
}
