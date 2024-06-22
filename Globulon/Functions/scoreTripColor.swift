//
//  scoreTripColor.swift
//  ZenTrac
//
//  Created by David Holeman on 4/27/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

func scoreTripColor(_ score: Double) -> Color {
    
    switch Int(score) {
    case ...69:
        return Color.red
    case 70...79:
        return Color(red: 1.0, green: 0.5, blue: 0.5)
    case 80...89:
        return Color(red: 1.0, green: 1.0, blue: 0.5)
    case 90...:
        return Color(red: 0.5, green: 1.0, blue: 0.5)
    default:
        return Color(red: 0.5, green: 1.0, blue: 0.5)
    }
}
