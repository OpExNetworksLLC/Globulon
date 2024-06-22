//
//  LogEventClass.swift
//  ViDrive
//
//  Created by David Holeman on 2/13/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation

class LogEvent {
    class func print(module: String, message: Any) {
        Swift.print("[\(AppValues.appName)] \(module): \(message)")
    }
}
