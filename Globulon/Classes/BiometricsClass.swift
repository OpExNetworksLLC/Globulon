//
//  BiometricsClass.swift
//  Globulon
//
//  Created by David Holeman on 02/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import LocalAuthentication

class Biometrics: @unchecked Sendable {
    
    let context = LAContext()
    
    func canEvaluatePolicy() -> Bool {
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
    
    /// Checks if the device supports biometric authentication.
    var isBiometricSupported: Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

//    /// Asynchronously checks if the device supports biometric authentication.
//    func isBiometricSupported() async -> Bool {
//        await withCheckedContinuation { continuation in
//            DispatchQueue.global(qos: .userInitiated).async { [self] in
//                var error: NSError?
//                let isSupported = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
//                DispatchQueue.main.async {
//                    continuation.resume(returning: isSupported)
//                }
//            }
//        }
//    }
    
    
    /// Returns the type of biometric authentication supported (Face ID, Touch ID, or None).
    var biometricType: BiometricType {
        guard isBiometricSupported else { return .none }

        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        default:
            return .none
        }
    }

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
