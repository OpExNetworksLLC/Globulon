//
//  Notification+name.swift
//  ViDrive
//
//  Created by David Holeman on 3/17/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let isInternetAvailable = Notification.Name("isInternetAvailable")
    static let carPlayConnected = Notification.Name("carPlayConnected")
    static let carPlayDisconnected = Notification.Name("carPlayDisconnected")
}
