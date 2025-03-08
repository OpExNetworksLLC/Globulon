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
    case tours      = 1
    case travel     = 2
    case motion     = 3
    case more       = 4
//    case travel     = 5
//    case activity   = 6
//    case bluetooth  = 7
    
    var description: String {
        switch self {
        case .home      : return "home"
        case .tours     : return "tours"
        case .travel    : return "travel"
        case .motion    : return "travel"
        case .more      : return "more"
//        case .travel    : return "travel"
//        case .activity  : return "activity"
//        case .bluetooth : return "bluetooth"
        }
    }
}
