//
//  formatMPH.swift
//  ViDrive
//
//  Created by David Holeman on 2/15/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation

//func formatMPH(_ speed: Double) -> String {
//    // for two decimal points: "%.2f"
//    return String(format: "%.0f", speed)
//    
//}
func formatMPH(_ speed: Double, decimalPoints: Int = 0) -> String {
    let formatString = "%.\(decimalPoints)f"
    return String(format: formatString, speed)
}
