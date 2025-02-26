//
//  passwordStrengthCheck.swift
//  Globulon
//
//  Created by David Holeman on 2/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import Foundation

// invoke let (value, image, label) = passwordStrength(string)

public func passwordStrengthCheck(string: String) -> (value: Int, image: String, label: String) {
    
    // reset each time we check so it reflects for each time strength check is called.
    var value = 0
    
    // lets check for length
    switch string.count {
    case 0,1,2:
        value = 0
    case 3...4:
        value = 1
    case 5...8:
        value = 2
    case let x where x > 8:
        value = 3
    default:
        value = 0
    }
    
    let characterset = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
    if string.rangeOfCharacter(from: characterset.inverted) != nil {
       value += 1
    }
    
    var image = ""
    var label = ""
    
    // now set the indicators for password Strength
    switch value {
    case 0:
        label = "(enter)"
        image = "imgStrengthOff"
    case 1:
        label = "(weak)"
        image = "imgStrengthMin"
    case 2:
        label = "(ok)"
        image = "imgStrengthMid"
    case let x where x > 2:
        label = "(strong)"
        image = "imgStrengthMax"
    default:
        label = ""
        image = "imgStrengthOff"
    }
    
    return (value, image, label)
}


