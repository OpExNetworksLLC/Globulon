//
//  formatMMtoHHMM.swift
//  ViDrive
//
//  Created by David Holeman on 4/28/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation

func formatMMtoHHMM(minutes: Double) -> String {
    let totalMinutes = Int(minutes)
    let hours = totalMinutes / 60
    let remainingMinutes = totalMinutes % 60
    
    if hours == 0 {
        if remainingMinutes > 0 {
            return "\(remainingMinutes) min"
        } else {
            if remainingMinutes == 0 {
                return "0 min"
            } else {
                return "< 1 min"
            }
        }
    } else {
        return "\(hours)h \(remainingMinutes)m"
    }
}
