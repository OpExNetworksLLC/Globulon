//
//  AuthModeEnum.swift
//  Globulon
//
//  Created by David Holeman on 2/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import Foundation

enum AuthModeEnum: Int, CaseIterable, Equatable {
    case none = 0
    case keychain = 1
    case firebase = 2
    
    var description: String {
        switch self {
        case .none: return "none"
        case .keychain: return "keychain"
        case .firebase: return "firebase"
        }
    }
}
