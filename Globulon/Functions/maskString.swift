//
//  maskString.swift
//  Globulon
//
//  Created by David Holeman on 02/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import Foundation

func maskString(_ string: String) -> String {
    guard AppSettings.log.isStringMaskEnabled else {
        return string
    }
    
    // Handle strings with less than 3 characters (can't mask in-between)
    guard string.count > 2 else {
        return string
    }
    
    if string.count > 7 {
        let firstCharacter = string.first!
        let lastCharacter = string.last!
        return "\(firstCharacter)*...*\(lastCharacter)"
    }
    
    let firstCharacter = string.first!
    let lastCharacter = string.last!
    let maskedMiddle = String(repeating: "*", count: string.count - 2)
    
    return "\(firstCharacter)\(maskedMiddle)\(lastCharacter)"
}
