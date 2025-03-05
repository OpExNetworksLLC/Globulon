//
//  LandingPageEnum.swift
//  Globulon
//
//  Created by David Holeman on 2/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import Foundation

enum LandingPageEnum: Int, CaseIterable, Equatable {
    case home       = 0
    case travel     = 1
    case tours      = 2
    case myTours    = 3
    case activity   = 4
    case motion     = 5
    case bluetooth  = 6
    
    var description: String {
        switch self {
        case .home      : return "home"
        case .travel    : return "travel"
        case .tours      : return "tours"
        case .myTours   : return "myTours"
        case .activity  : return "activity"
        case .motion : return "motion"
        case .bluetooth : return "bluetooth"
        }
    }
}
