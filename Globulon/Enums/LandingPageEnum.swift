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
    //case location   = 1
    case travel     = 1
    case tours      = 2
    case myTours    = 3
    case motion     = 4
    
    var description: String {
        switch self {
        case .home      : return "home"
        //case .location  : return "location"
        case .travel    : return "travel"
        case .tours      : return "tours"
        case .myTours   : return "myTours"
        case .motion : return "motion"
        }
    }
}
