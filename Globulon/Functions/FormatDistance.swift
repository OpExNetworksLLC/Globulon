//
//  FormatDistance.swift
//  ViDrive
//
//  Created by David Holeman on 4/28/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation

func roundToDecimalPlace(value: Double, decimal: Int) -> Double {
    let decimal = decimal * 10
    return (value * Double(decimal)).rounded() / Double(decimal)
}
