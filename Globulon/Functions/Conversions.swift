//
//  Conversions.swift
//  Globulon
//
//  Created by David Holeman on 2/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

// MARK: Convert Meters per Second to Miles per Hour
//
func convertMPStoMPH(_ mps: Double) -> Double {
    let currentSpeedMPH = mps * 2.23694
    return currentSpeedMPH
}
