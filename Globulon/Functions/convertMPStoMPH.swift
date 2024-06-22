//
//  convertMPStoMPH.swift
//  ViDrive
//
//  Created by David Holeman on 2/15/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation

// Convert Meters per Second to Miles per Hour
//
func convertMPStoMPH(_ mps: Double) -> Double {
    let currentSpeedMPH = mps * 2.23694
    return currentSpeedMPH
}
