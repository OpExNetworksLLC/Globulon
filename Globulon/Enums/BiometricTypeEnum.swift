//
//  BiometricTypeEnum.swift
//  Globulon
//
//  Created by David Holeman on 2/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import Foundation

enum BiometricType: Sendable {
    case none
    case faceID
    case touchID

    /// Returns the appropriate system image name for the biometric type.
    var imageName: String {
        switch self {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .none: return "lock"
        }
    }
}
