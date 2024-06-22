//
//  Biometrics.swift
//  ViDrive
//
//  Created by David Holeman on 2/20/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import LocalAuthentication

enum BiometricTypes {
    case none
    case touchID
    case faceID
    case opticID
}

class Biometrics {
    
    let context = LAContext()
    
    func canEvaluatePolicy() -> Bool {
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
    
    // TODO: Deal with .opticID
    func biometricType() -> BiometricTypes {
        let _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .none:
            return .none
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        case .opticID:
            return .none
        @unknown default:
            fatalError("Unknown BiometricType encountered")
        }
    }
    
    // TODO: Deal with .opticID
    func isBiometric() -> Bool {
        let _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .none:
            return false
        case .touchID, .faceID:
            return true
        case .opticID:
            return false
        @unknown default:
            fatalError("Unknown BiometricType encountered")
        }
    }
}
