//
//  roundDouble.swift
//  Globulon
//
//  Created by David Holeman on 7/19/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation

func roundDouble(_ value: Double, decimalPlaces places: Int) -> Double {
    let multiplier = pow(10.0, Double(places))
    return (value * multiplier).rounded() / multiplier
}
