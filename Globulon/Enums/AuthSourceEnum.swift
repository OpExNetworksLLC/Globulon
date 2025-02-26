//
//  AuthSourceEnum.swift
//  Globulon
//
//  Created by David Holeman on 2/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import Foundation

enum AuthSource: CustomStringConvertible {
    case biometric
    case manual
    case autoLogin
    case autoBiometric

    var description: String {
        switch self {
        case .biometric: return "Biometric Authentication"
        case .manual: return "Manual Login"
        case .autoLogin: return "Auto Login"
        case .autoBiometric: return "Auto Biometric Login"
        }
    }
}
