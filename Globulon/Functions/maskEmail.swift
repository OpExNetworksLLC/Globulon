//
//  maskEmail.swift
//  Globulon
//
//  Created by David Holeman on 2/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import Foundation

func maskEmail(_ email: String) -> String {
    if AppSettings.log.isEmailMaskEnabled {
        guard let atIndex = email.firstIndex(of: "@") else {
            return email // If not a valid email, return unchanged
        }
        let localPart = email[..<atIndex]
        let domainPart = email[atIndex...]
        
        // Ensure local part has at least two characters
        guard localPart.count >= 2 else {
            return email // Return unchanged if the local part is too short
        }
        
        let firstCharacter = localPart.prefix(1) // First character
        let lastCharacter = localPart.suffix(1)  // Last character
        let maskedMiddle = String(repeating: "*", count: max(0, localPart.count - 2))
        
        return "\(firstCharacter)\(maskedMiddle)\(lastCharacter)\(domainPart)"
    } else {
        return email // Return unchanged if masking is disabled
    }
}
