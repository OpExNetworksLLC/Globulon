//
//  replaceString.swift
//  ViDrive
//
//  Created by David Holeman on 2/20/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation

// MARK: Replace string content
//
func replaceString(string: String, old: String, new: String ) -> String {
    if let range = string.range(of: old) {
        
        let result = string[range.lowerBound...].replacingOccurrences(of: old, with: new)
        
        return result
    } else {
        return string
    }
}
