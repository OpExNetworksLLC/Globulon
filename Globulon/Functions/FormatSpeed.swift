//
//  FormatSpeed.swift
//  Globulon
//
//  Created by David Holeman on 2/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import Foundation

// MARK: - format MPH to the user specified number of decimal places
//
func formatMPH(_ speed: Double, decimalPoints: Int = 0) -> String {
    let formatString = "%.\(decimalPoints)f"
    return String(format: formatString, speed)
}
