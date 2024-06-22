//
//  FormatPhoneNumbers.swift
//  ViDrive
//
//  Created by David Holeman on 2/20/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation

// MARK: Format the number to the mask
func formattedNumber(number: String, mask: String, char: Character) -> String {
    let cleanPhoneNumber = number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    
    var result = ""
    var index = cleanPhoneNumber.startIndex
    for ch in mask {
        if index == cleanPhoneNumber.endIndex {
            break
        }
        if ch == char {
            result.append(cleanPhoneNumber[index])
            index = cleanPhoneNumber.index(after: index)
        } else {
            result.append(ch)
        }
    }
    return result
}
// MARK:  Return unformatted phone number.  Just the digits.
func unformattedNumber(number: String) -> String {
    return number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
}
