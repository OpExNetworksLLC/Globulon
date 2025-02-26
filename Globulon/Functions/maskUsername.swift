//
//  maskUsername.swift
//  Globulon
//
//  Created by David Holeman on 2/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import Foundation

func maskUsername(_ username: String) -> String {
    if AppSettings.log.isUsernameMaskEnabled {
        // Check if the username contains '@' to determine if it's an email address
        if let atIndex = username.firstIndex(of: "@") {
            let localPart = username[..<atIndex]
            let domainPart = username[atIndex...]
            
            // Ensure local part has at least two characters
            guard localPart.count >= 2 else {
                return username // Return unchanged if the local part is too short
            }
            
            let firstCharacter = localPart.prefix(1) // First character
            let lastCharacter = localPart.suffix(1)  // Last character
            let maskedMiddle = String(repeating: "*", count: max(0, localPart.count - 2))
            
            return "\(firstCharacter)\(maskedMiddle)\(lastCharacter)\(domainPart)"
        } else {
            // If not an email, mask the entire username
            return String(repeating: "*", count: username.count)
        }
    } else {
        // Return unchanged if masking is disabled
        return username
    }
}
